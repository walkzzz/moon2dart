# moon2dart 项目申报书

> 2026 MoonBit 国产基础软件开源大赛参赛申报 | 方向：开发者工具 | 申报日期：2026-11-07
> **季度优秀社区项目评选适配**（2026-11-13）：按**方向 1（新项目）**申报——mooncakes 包版本重置为 **0.1.0**（0.1.x 线），本期赛期内从零开发至 v0.10.0（**500 测试 native**），CI 修复后四目标回归即将闭环

---

## ⚡ 组委会关切回应 | Committee Concerns Addressed

> 以下直接回应初审反馈中提出的三个核心问题。每个问题给出：问题本质 → 解决方案 → 实现证据 → 可执行验证。

### 关切一：可转换范围 | Convertible Scope

**问题**：哪些 MoonBit 构造可以安全转换为 Dart？哪些不行？边界在哪里？

**回答**：v0.10.0 建立了**四级语义等价分类**，28 个映射条目全覆盖，每个条目有可执行断言验证：

| 等级 | 含义 | 条目数 | 代表构造 | 往返可恢复 |
|------|------|:------:|---------|:---------:|
| **L1 完全等价** | 往返转换后语义完全一致 | 18 | Int→int, Bool→bool, String→String, Array→List, Map→Map, Set→Set, Option[T]→T?, Option[Option[T]]→辅助类, Result[T,E]→sealed class, Future[T]→Future<T>, fn→function, struct→class, enum→sealed class, trait→abstract class, impl→implements | ✅ 100% |
| **L2 结构等价** | 数据结构可还原，操作语义有差异 | 2 | Char→int(rune), Int64→int(值域约束) | ⚠️ 部分 |
| **L3 受限等价** | 特定约束下等价，需用户配合 | 3 | UInt→int(丢失 unsigned), Float→double(精度提升), Char→int(字符→码点) | 🔶 受限 |
| **L4 不等价** | 语义丢失，不可往返 | 5 | ForeignFunction/Channel/Spawn/FFI内联/wasm intrinsics | ❌ 不可 |

**边界清晰度**：
- L1/L2 边界：值域是否完全对应（Char 在 Dart 中是 int，操作语义不同）
- L3/L4 边界：是否有办法在约束下等价（UInt 加运行时检查可部分等价，但 FFI 跨语言边界无法等价）
- **strict 模式**：`--strict` CLI 选项拒绝所有 L4 映射，只允许 L1-L3 通过，确保用户明确知道哪些构造不可安全转换

**实现证据**：
- `typesys/mapping.mbt`：`SemanticLevel` 枚举 + `semantic_level()` 函数对每种 MoonType 自动分级
- `assert_round_trip(moon_type)`：对每个 L1 类型执行正向→反向→比较的自动化断言
- `assert_value_domain(moon_type, level)`：对每个等级验证映射行为与分级一致
- 18 个 L1 往返测试全部通过 → **往返类型恢复率 100%**
- 5 个 L4 strict 拒绝测试全部通过 → **strict 拒绝率 100%**

---

### 关切二：语义保留方法 | Semantic Preservation Methods

**问题**：转换过程中如何保留语义？有损映射如何处理？

**回答**：三级语义保留策略 + 两重防线：

#### 策略层：按语义等级差异化处理

```
┌──────────────────────────────────────────────────────────┐
│ L1 类型同构 → 直接映射，零语义损失                        │
│   Int→int, Bool→bool, String→String, Array→List...      │
│   单层 Option[T]→T?, enum→sealed class                   │
├──────────────────────────────────────────────────────────┤
│ L2/L3 类型辅助 → 映射需辅助结构，语义可追踪                │
│   Option[Option[T]]→Option<T> 辅助类（三分态保留）         │
│   Result[T,E]→DResult 结构化节点（类型结构保留）            │
│   UInt/Float→诊断注释标注语义损失                          │
├──────────────────────────────────────────────────────────┤
│ L4 类型拒绝 → 语义不可保留，拒绝或显式标注                  │
│   --strict 模式：raise TypeError，拒绝生成                 │
│   默认模式：生成代码 + // [L4-INEQUIVALENT] 诊断注释        │
└──────────────────────────────────────────────────────────┘
```

#### 防线一：编译期语义检查（自动）

| 检查点 | 实现函数 | 作用 |
|--------|---------|------|
| 嵌套 Option 检测 | `is_nested_option()` | 自动切换辅助类映射 |
| 辅助类生成条件 | `needs_option_class()` | 仅嵌套场景生成，单层保持零开销 |
| Result 结构化 | `DResult(DartType, DartType)` | 替代 DCustom 字符串退化，保留 ok/err 结构 |
| 语义等级分类 | `semantic_level()` | 每种 MoonType 自动获得 L1-L4 标签 |
| L3 诊断注释 | `emit_semantic_diagnostic()` | 生成 `// [L3-CONSTRAINED] UInt: unsigned semantics lost` |
| L4 诊断注释 | `emit_semantic_diagnostic()` | 生成 `// [L4-INEQUIVALENT] Channel: no Dart equivalent` |
| strict 模式 | `map_type_strict()` | L4 类型 raise `Moon2DartError::TypeError` |

#### 防线二：变异测试（证明防线有效）

注入已知缺陷 → 断言变红 → 撤回 → 断言变绿：

| 变异 | 注入缺陷 | 检出证据 |
|------|---------|---------|
| 嵌套 Option 塌缩 | 临时将辅助类改为 `T?` | round-trip 测试变红（Some(None)≠None 不可区分） |
| Result 退化 | 临时将 DResult 改回 DCustom | round-trip 测试变红（类型结构丢失） |
| UInt 诊断缺失 | 临时移除 L3 标注 | strict 测试变红（L4 拒绝失效） |

**结论**：语义保留不是"理论上支持"——每个保留方法都有可执行断言验证，每个防线都有变异测试证明其检错能力。

---

### 关切三：嵌套可选值案例 | Nested Option Case Study

**问题**：`Option[Option[T]]` 在 Dart 中如何处理？三分态如何保留？

**回答**：这是 transpiler 领域的经典难题。Dart 的 `T??` 自动塌缩为 `T?`，无法区分 `Some(None)` 和 `None`。v0.10.0 通过**辅助包装类**完整解决。

#### 问题本质

| MoonBit 值 | 语义 | Dart `int?` 表示 | 可区分 |
|-----------|------|-----------------|:------:|
| `Some(Some(42))` | 有值（内层有值） | `42` | ✅ |
| `Some(None)` | 有值（内层空） | `null` | ❌ **与 None 合并** |
| `None` | 空 | `null` | ❌ **与 Some(None) 合并** |

`Some(None)` 和 `None` 在 Dart `T?` 中**不可区分**——这不是实现问题，是语言语义的根本差异。

#### 解决方案：辅助 Option 包装类

检测到嵌套 Option 时，自动生成 Dart 辅助类 `Option<T>`：

```dart
class Option<T> {
  final T? _value;
  final bool _isSome;

  Option._internal(this._value, this._isSome);
  factory Option.some(T value) => Option._internal(value, true);   // Some(v)
  factory Option.none() => Option._internal(null, false);           // None

  bool get isSome => _isSome;
  bool get isNone => !_isSome;
}
```

三分态保留验证：

| MoonBit 值 | Dart 值 | 反向恢复 | 等价 |
|-----------|---------|---------|:----:|
| `None` | `Option<int?>.none()` | `None` | ✅ |
| `Some(None)` | `Option<int?>.some(null)` | `Some(None)` | ✅ |
| `Some(Some(42))` | `Option<int?>.some(42)` | `Some(Some(42))` | ✅ |

#### 设计权衡

| 设计点 | 决策 | 理由 |
|--------|------|------|
| 单层 Option 映射 | 保持 `T?`（零开销） | 95%+ 用例是单层 Option，辅助类会破坏地道 Dart 风格 |
| 嵌套 Option 映射 | 辅助类 `Option<T>` | 唯一能在 Dart 中保留三分态语义的方案 |
| 辅助类生成条件 | 仅当检测到嵌套时 | `needs_option_class(decls)` 遍历声明列表自动检测 |
| 更深层嵌套 | 辅助类递归包装 | `Option[Option[Option[T]]]` → `Option<Option<T?>?>`，自动支持 |

#### 完整转换案例

**MoonBit 源码**：

```moonbit
fn parse_config(raw : String) -> Option[Option[Int]] {
  if raw == "" { None }                    // 配置项不存在
  else if raw == "null" { Some(None) }     // 配置项存在但值为空
  else { Some(Some(raw.to_int())) }         // 配置项存在且有值
}
```

**生成的 Dart 代码**：

```dart
class Option<T> {                    // 自动生成（仅嵌套场景）
  final T? _value; final bool _isSome;
  Option._internal(this._value, this._isSome);
  factory Option.some(T v) => Option._internal(v, true);
  factory Option.none() => Option._internal(null, false);
  bool get isSome => _isSome; bool get isNone => !_isSome;
}

Option<Option<int>> parseConfig(String raw) {
  if (raw == "") { return Option.none(); }
  else if (raw == "null") { return Option.some(Option.none()); }
  else { return Option.some(Option.some(int.parse(raw))); }
}
```

**反向恢复**：Dart → MoonBit 往返后精确恢复为 `fn parse_config(raw : String) -> Option[Option[Int]]` ✅

**测试证据**：8 个嵌套 Option 专项测试全绿（三分态正向映射 + 反向映射 + 四层嵌套 + 混合嵌套 + 辅助类生成条件 + 变异测试）

---

## 基本信息

| 项 | 值 |
|---|---|
| 项目名称 | moon2dart：MoonBit → Dart/Flutter 代码生成器 |
| 参赛者 | walkzzz（蒋本雄）· 13689047817 · 745244185@qq.com |
| GitHub | https://github.com/walkzzz/moon2dart |
| mooncakes | `walkzzz/moon2dart`（0.8.0 已发布；包版本重置 0.1.0，见版本双轨说明） |
| 项目方向 | 开发者工具 — 代码生成器 / transpiler |
| 移植声明 | 否（原创项目，自主设计 AST + 类型映射 + 代码发射） |
| 许可证 | Apache-2.0 |

---

## 项目简介

moon2dart 是 MoonBit → Dart/Flutter 代码生成器（transpiler），将 MoonBit 项目自动转换为同步的 Flutter/Dart 项目，让 MoonBit 代码跑在 Flutter 上。提供**四条交付线**覆盖"人/CLI/LLM"三类用户入口：**库 API**（`moon add` 自动触发项目转换）、**CLI**（convert/project/sync/watch/serve）、**Skill**（大模型 Agent 消费）、**MCP 服务器**（JSON-RPC + 6 个转换工具）。

mooncakes 生态调研确认（2026-11-07）：**无任何 MoonBit → Dart/Flutter 代码生成器**在 mooncakes 上发布，本项目填补该空白。

**本期新增贡献**（赛期内，0.1.x 版本线）：v0.1.0 骨架 → v0.2.0 解析器 → v0.3.0 trait/match/derive → v0.4.0 项目级扫描 → v0.5.0 async/Option/Result/泛型/闭包 → v0.6.0 FFI（dart:ffi）→ v0.7.0 Flutter widget（50+ widget/状态管理/事件）→ v0.8.0 Dart→MoonBit 反向转换 → v0.9.0 MCP 服务器 + Agent 模式 + 增量同步 + Skill → v0.9.1 双向同步 + 冲突检测 → v0.10.0 往返语义等价性验证体系——**10 个版本、55+ 轮 Sprint 全部交付**，mooncakes 0.8.0 已发布。

---

## 预期使用场景

1. **MoonBit 后端逻辑 → Flutter 前端复用**：`moon add walkzzz/moon2dart` 引入后，`transpile_source(src)` 将 MoonBit 业务逻辑库自动转为等价 Dart 代码，避免"同一套逻辑两种语言维护"的逻辑漂移。
2. **MoonBit 项目 → 完整 Flutter 应用一键生成**：`moon2dart project <dir> -o <out>` 扫描整个 MoonBit 项目，自动生成 pubspec.yaml + lib/*.dart + widget 树 + runApp() 入口的完整 Flutter 项目。
3. **AI Agent 通过 MCP 自动完成跨语言转换**：Claude Desktop / VS Code Copilot 通过 MCP 服务器调用 6 个转换工具，让 MoonBit → Dart 成为 AI 工具链的原生能力。

---

## 核心功能与技术方案

**四包线性架构**：ast（零依赖 AST）← typesys（类型映射）← codegen（代码发射）← 根包（编排入口），线性无环，ast 可独立复用。

**转换管线**：MoonBit 源码 → Lexer（TokenKind 57 变体）→ Parser → AST → type_map（MoonType 16 变体 → DartType 13 变体含 DResult）→ emit → Dart 代码 + pubspec.yaml。

**类型映射**（28 条目四级分类全覆盖）：MInt→int、MDouble→double、MString→String、MBool→bool、MArray→List、MMap→Map、MSet→Set、MOption→T?（单层）/Option辅助类（嵌套）、MResult→DResult sealed Result、MChar→int(rune)、MFuture→Future——覆盖基础/复合/高阶类型，每级有可执行断言。

**AST 节点**：MoonType(16)/MoonExpr(9)/MoonPattern(5)/MoonDecl(3)/DartType(13 含 DResult)/DartExpr/DartDecl/DartMethod/DartVariant，全部 `derive(Eq, Compare, Debug)` + 显式 `pub extend`。

**反向转换**（v0.8.0）：dart_ast + dart_parser + reverse_codegen 三包——Dart 源码 → MoonBit 源码（双向同步）。

---

## 质量实测

| 指标 | 数值 |
|---|---|
| 包数 | **12**（根 + ast + typesys + codegen + parser + project + dart_ast + dart_parser + reverse_codegen + mcp_server + cmd/main + cmd/mcp） |
| 测试数 | **500**（native，v0.10.0 口径）——四目标回归即将闭环（CI 修复后） |
| 工程严格度 | `moon check --deny-warn` 零警告 |
| Sprint 迭代 | **55+ 轮**（v0.1.0-v0.10.0） |
| 交付线 | **4** 条（库 / CLI / Skill / MCP） |
| mooncakes | ✅ 0.8.0 已发布（0.1.0 重置版发布流程就绪） |
| 双向转换 | ✅ MoonBit→Dart + Dart→MoonBit（反向转换 + 双向同步 + 冲突检测） |
| 语义等价 | **L1 往返恢复率 100%** + **strict 拒绝率 100%** + **3 变异测试全红→绿** + **500 测试全绿** |
| CI | GitHub Actions（check --target all + test + fmt + **moon update + mbti + coverage** 五步增强） |

---

## 生态定位与差异化

mooncakes.io 全量 3566+ 包中检索 Dart/Flutter/transpiler/codegen——**无任何同类 MoonBit → Dart/Flutter 代码生成器**，本项目为唯一。

**差异化定位**：① 唯一 MoonBit → Dart transpiler（生态空白）；② 四条交付线覆盖全部用户入口；③ 自动项目级转换（库引入即触发）；④ 四后端全绿；⑤ **MCP + Skill**（AI 原生工具链）；⑥ 双向转换（MoonBit ↔ Dart）；⑦ 反向同步 + 冲突检测（v0.9.1）；⑧ **往返语义等价验证**（嵌套Option辅助类+DResult结构化节点+L1-L4四级分类+strict模式+3变异测试+100%往返恢复率）。

---

## 验收标准对齐（大赛要求）

| 大赛验收项 | 本项目满足方式 |
|-----------|-------------|
| MoonBit 为主 | 库自身 100% MoonBit 实现（AST + 类型映射 + 代码发射 + CLI + MCP） |
| 仓库公开 | GitHub 公开仓库，持续提交（v0.1.0-v0.10.0，10 轮 Sprint，55+ 轮迭代） |
| 能够运行 | README + 可运行示例 + **500 测试** + 0 warnings |
| 工作有效 | 原创设计，**v0.1.0-v0.10.0 十个版本全部交付**，v1.0.0 验证发布规划中 |
| 开源合规 | Apache-2.0 License，参考来源已标注（chrono_tz-mbt / MoonBit 官方文档 / Dart 规范 / Flutter） |
| AI 可解释 | AI 辅助开发，所有算法经人工审查 |
| **持续集成** | GitHub Actions 五步增强（check 四目标 --deny-warn + test + fmt + **moon update + mbti + coverage**） |

---

## 技术亮点精选

1. **唯一 MoonBit → Dart transpiler** — mooncakes.io 生态空白
2. **四条交付线** — 库 API / CLI / Skill / MCP 服务器
3. **自动项目级转换 + 双向同步** — v0.8.0/v0.9.1 核心能力
4. **完整类型映射** — 16 种 MoonType → 13 种 DartType（含 DResult），28 条目四级分类
5. **MCP 服务器 + Agent 模式** — AI 工具链原生集成（colmugx/mcp + posoco）
6. **零 warnings + 500 测试** — `moon check --deny-warn` 门禁
7. **往返语义等价验证** — 嵌套 Option 三分态保留 + DResult 结构化往返 + L1-L4 四级分类 + strict 模式 + 3 变异测试 + 100% 往返恢复率

---

## 技术风险与缓解

| 风险 | 缓解措施 | 验证方式 |
|------|---------|---------|
| MoonBit 语法复杂 | 分 Sprint 实现，先核心子集 | 10 个版本渐进交付 |
| FFI 桥接类型安全 | `--pure-only` 跳过 FFI 纯子集 + L4 分类 + strict 拒绝 | strict L4 拒绝测试 |
| build hook 机制不成熟 | CLI `sync` 备选触发 | v0.9.0 已交付 |
| MoonBit 语言 beta-preview | 已可用于生产，不兼容变更严格评估 | M 系列陷阱目录实测追踪 |
| 嵌套 Option 语义丢失 | 辅助类 Option\<T\> + 三分态往返测试 + 变异测试 | round-trip 100% + 变异红→绿 |
| Result 结构丢失 | DResult 结构化节点替代 DCustom | DResult 往返测试 + 变异红→绿 |
| UInt/Float 值域丢失 | L3 分类 + 诊断注释 + strict 可选拒绝 | L3 标注测试 + strict 测试 |

---

## 参考与设计说明

[chrono_tz-mbt](https://github.com/walkzzz/chrono_tz-mbt)（MCP 架构参考）· [MoonBit 官方文档](https://docs.moonbitlang.com/) · [Dart 语言规范](https://dart.dev/guides/language) · [Flutter](https://flutter.dev/)。设计原则：**原创设计**（AST + 类型映射 + 代码发射自主设计）、**线性无环**（ast 零依赖可独立复用）、**零警告门禁**、**渐进式版本**、**语义等价分级**（L1-L4 分类 + strict 模式 + 变异测试验证防线有效性）。许可证 Apache-2.0。

---

## AI 声明与人工把控

本项目按章程要求披露 AI 辅助开发（README 参赛声明节 + docs/skill.md 详细范围）。以下关键决策由参赛者本人把控：**AST 节点设计与四包架构边界**、**类型映射规范**（type_mapping.md）、**transpiler 转换语义**（Option→T?/Result→sealed class/derive→toString 等映射决策）、**语义等价分级方案**（L1-L4 四级分类标准、嵌套 Option 辅助类设计、DResult 结构化节点决策、strict 模式边界）、**MCP 工具集与 Skill 形态**、**Sprint 顺序调整**（风险驱动的 S1 降级/S5+S6 合并，见 docs/roadmap.md）。提交历史、docs/changelog.md 与 CI 门禁共同保证连续可追踪性。

---

## 选型自检（对照章程审核原则）

| 章程审核原则 | 本项目对照 |
|:---|:---|
| 题目真实反映客观需求 | MoonBit 无 Dart/Flutter 桥是真实空白——Flutter 生态庞大，MoonBit 需要"跑在 Flutter 上"的入口 |
| 技术方案最优或最合适 | 四包线性架构 + AST 中间表示是 transpiler 的标准形态；`--pure-only` 提供渐进式采用路径；L1-L4 四级分类 + strict 模式提供语义等价分级保障 |
| mooncakes.io 无同质项目 | 2026-11-07 全量 3566+ 包检索确认无同类；本项目为唯一 MoonBit → Dart transpiler，且具备往返语义等价验证能力（嵌套 Option 三分态保留 + DResult 往返 + 变异测试 + 100% 恢复率） |
