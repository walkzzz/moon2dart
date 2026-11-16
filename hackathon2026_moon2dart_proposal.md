# moon2dart 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 · 方向 1（新项目）· walkzzz（蒋本雄）· Apache-2.0

---

## ⚡ 组委会关切回应

### 一、可转换范围 | Convertible Scope

28 个映射条目四级分类全覆盖，每条有可执行断言：

| 等级 | 含义 | 数量 | 代表 | 往返可恢复 |
|------|------|:----:|------|:---------:|
| L1 完全等价 | 往返语义完全一致 | 18 | Int→int, Bool→bool, Option[T]→T?, enum→sealed class | ✅ 100% |
| L2 结构等价 | 结构可还原，操作有差异 | 2 | Char→int(rune), Int64→int(值域约束) | ⚠️ 部分 |
| L3 受限等价 | 约束下等价，需用户配合 | 3 | UInt→int(丢unsigned), Float→double(精度提升) | 🔶 受限 |
| L4 不等价 | 语义丢失，不可往返 | 5 | FFI/Channel/Spawn/wasm intrinsics | ❌ 不可 |

**边界清晰**：`--strict` CLI 拒绝 L4，只放行 L1-L3。**验证**：18 个 L1 往返测试全绿→恢复率 100%；5 个 L4 strict 拒绝测试全绿→拒绝率 100%。

### 二、语义保留方法 | Semantic Preservation

三级策略 + 两重防线：

- **L1 同构映射**：直接映射，零语义损失（Int→int, Option[T]→T?）
- **L2/L3 辅助结构**：嵌套 Option→辅助类（三分态保留），Result→DResult 结构化节点，L3 生成 `// [L3-CONSTRAINED]` 诊断注释
- **L4 拒绝/标注**：strict 模式 raise TypeError；默认模式生成 `// [L4-INEQUIVALENT]` 注释

**防线一**（编译期）：`is_nested_option()` 自动切换辅助类 → `DResult` 保留 ok/err 结构 → `semantic_level()` 自动分级 → `emit_semantic_diagnostic()` 生成诊断注释

**防线二**（变异测试）：注入缺陷→断言变红→撤回→变绿——嵌套 Option 塌缩变红、Result 退化变红、UInt 诊断缺失变红，证明防线检错能力

### 三、嵌套可选值 | Nested Option

Dart `T??` 塌缩为 `T?`，`Some(None)` 与 `None` 不可区分。v0.10.0 辅助类完整解决：

```dart
class Option<T> {
  final T? _value; final bool _isSome;
  Option._internal(this._value, this._isSome);
  factory Option.some(T v) => Option._internal(v, true);   // Some(v)
  factory Option.none() => Option._internal(null, false);   // None
  bool get isSome => _isSome; bool get isNone => !_isSome;
}
```

三分态往返：`None`↔`Option.none()` ✅ · `Some(None)`↔`Option.some(null)` ✅ · `Some(Some(42))`↔`Option.some(42)` ✅

单层保持 `T?` 零开销；仅嵌套场景生成辅助类。8 个专项测试全绿。

---

## 基本信息

| 项 | 值 |
|---|---|
| 项目 | moon2dart：MoonBit → Dart/Flutter 代码生成器 |
| 参赛者 | walkzzz（蒋本雄）· 13689047817 · 745244185@qq.com |
| GitHub | https://github.com/walkzzz/moon2dart |
| mooncakes | `walkzzz/moon2dart`（0.8.0 已发布；包版本重置 0.1.0） |
| 方向 | 开发者工具 — transpiler（原创，非移植） |
| 许可证 | Apache-2.0 |

---

## 预期使用场景

1. **MoonBit 后端逻辑 → Flutter 前端复用**：`moon add walkzzz/moon2dart` 引入后，`transpile_source(src)` 自动将 MoonBit 业务逻辑转为等价 Dart，避免双语言维护逻辑漂移
2. **MoonBit 项目 → 完整 Flutter 应用一键生成**：`moon2dart project <dir> -o <out>` 扫描整个项目，自动生成 pubspec.yaml + lib/*.dart + widget 树 + runApp() 入口
3. **AI Agent 通过 MCP 自动跨语言转换**：Claude Desktop / VS Code Copilot 通过 MCP 服务器调用 6 个转换工具，MoonBit→Dart 成为 AI 工具链原生能力

---

## 核心功能与技术方案

**四包线性架构**：ast（零依赖）← typesys（类型映射）← codegen（代码发射）← 根包（编排），线性无环，ast 可独立复用。

**转换管线**：MoonBit 源码 → Lexer（TokenKind 57 变体）→ Parser → AST → type_map（16 MoonType → 13 DartType，28 条目四级分类）→ emit → Dart + pubspec.yaml。

**四条交付线**：库 API（`moon add` 自动触发）· CLI（convert/project/sync/watch/serve）· Skill（大模型 Agent）· MCP 服务器（JSON-RPC 6 工具）。

**双向转换**（v0.8.0+）：dart_ast + dart_parser + reverse_codegen 三包反向转换 + 双向同步 + 冲突检测。

---

## 质量实测

| 指标 | 值 |
|------|-----|
| 包数 | 12 |
| 测试 | **500**（native）· 464（wasm/js/wasm-gc） |
| 门禁 | `moon check --target all --deny-warn` 零警告 |
| Sprint | 55+ 轮（v0.1.0→v0.10.0，10 版本全交付） |
| mooncakes | ✅ 0.8.0 已发布 |
| 语义等价 | L1 往返恢复 100% · strict 拒绝 100% · 变异测试全红→绿 |
| CI | GitHub Actions 五步（check+test+fmt+moon update+coverage） |

---

## 生态定位与差异化

mooncakes.io 全量 3566+ 包检索确认：**无任何同类 MoonBit→Dart transpiler**，本项目为唯一。

差异化：①唯一生态空白填补 ②四条交付线全覆盖 ③项目级自动转换 ④双向同步+冲突检测 ⑤MCP+Skill AI原生 ⑥**L1-L4四级语义等价+strict模式+变异测试** ⑦四后端全绿+零警告

---

## 验收标准对齐

| 大赛要求 | 满足方式 |
|---------|---------|
| MoonBit 为主 | 100% MoonBit 实现 |
| 公开仓库 | GitHub 持续提交 v0.1.0-v0.10.0 |
| 能够运行 | 500 测试 + 0 warnings + 可运行示例 |
| 工作有效 | 10 版本全交付，原创设计 |
| 开源合规 | Apache-2.0，参考来源已标注 |
| AI 可解释 | AI 辅助开发，关键决策人工把控 |
| 持续集成 | GitHub Actions 五步增强 |

---

## 技术风险与缓解

| 风险 | 缓解 | 验证 |
|------|------|------|
| 嵌套 Option 语义丢失 | 辅助类+三分态往返+变异测试 | round-trip 100%+变异红→绿 |
| Result 结构丢失 | DResult 结构化节点 | DResult 往返测试+变异红→绿 |
| FFI 桥接安全 | `--pure-only`+L4分类+strict拒绝 | strict L4 拒绝测试 |
| UInt/Float 值域丢失 | L3分类+诊断注释+strict可选拒绝 | L3 标注+strict 测试 |
| build hook 不成熟 | CLI `sync` 备选触发 | v0.9.0 已交付 |

---

## 参考与设计说明

[chrono_tz-mbt](https://github.com/walkzzz/chrono_tz-mbt)（MCP 架构参考）· [MoonBit 官方文档](https://docs.moonbitlang.com/) · [Dart 规范](https://dart.dev/guides/language) · [Flutter](https://flutter.dev/)。设计原则：**原创设计**·**线性无环**·**零警告门禁**·**渐进式版本**·**语义等价分级**（L1-L4+strict+变异测试）。Apache-2.0。

---

## AI 声明与人工把控

AI 辅助开发，关键决策人工把控：**AST 架构边界** · **类型映射规范** · **语义等价分级（L1-L4 标准+辅助类设计+strict 边界）** · **MCP/Skill 形态** · **Sprint 顺序调整**。提交历史+changelog+CI 门禁保证可追踪性。

---

## 选型自检

| 章程审核原则 | 本项目对照 |
|:---|:---|
| 题目真实反映客观需求 | MoonBit 无 Dart/Flutter 桥是真实空白——Flutter 生态庞大，MoonBit 需要"跑在 Flutter 上"的入口 |
| 技术方案最优或最合适 | 四包线性架构+AST 中间表示是 transpiler 标准形态；L1-L4 四级分类+strict 模式提供语义等价分级保障 |
| mooncakes.io 无同质项目 | 3566+ 包检索确认无同类；唯一 MoonBit→Dart transpiler 且具备往返语义等价验证能力 |
