# moon2dart 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 · 方向 1（新项目）· walkzzz（蒋本雄）· Apache-2.0

---

## ⚡ 组委会关切回应

### 一、可转换范围 | Convertible Scope

**问题**：哪些 MoonBit 构造可安全转 Dart？边界在哪？

28 个映射条目四级分类全覆盖（16 MoonType → 13 DartType），每条有 `assert_round_trip()` 可执行断言：

| 等级 | 含义 | 数量 | 代表构造 | 往返 |
|------|------|:----:|---------|:----:|
| L1 完全等价 | 往返后语义完全一致 | 18 | Int→int, Bool→bool, String→String, Double→double, Array→List, Map→Map, Set→Set, 单层Option[T]→T?, enum→sealed class, struct→class, trait→abstract class, fn→function, async fn→Future, 泛型[T]→\<T\>, 闭包→箭头函数, Result[T,E]→sealed class, 嵌套Option→辅助类, Tuple→Record | ✅ |
| L2 结构等价 | 结构可还原，操作有差异 | 2 | Char→int(rune), Int64→int(64位值域约束) | ⚠️ |
| L3 受限等价 | 约束下等价，需用户配合 | 3 | UInt→int(丢unsigned), Float→double(精度提升), Char运算→int运算 | 🔶 |
| L4 不等价 | 语义丢失，不可往返 | 5 | ForeignFunction, Channel, Spawn, FFI内联, wasm intrinsics | ❌ |

**边界逻辑**：L1/L2 分界在"值域是否完全对应"（Char 在 Dart 无独立类型）；L3/L4 分界在"约束下能否等价"（UInt 加运行时检查可部分等价，Channel 无 Dart 对应物）。`--strict` 拒绝 L4，只放行 L1-L3。

**验证**：18 个 L1 往返测试全绿→恢复率 100%；5 个 L4 strict 拒绝测试全绿→拒绝率 100%；L2/L3 各有语义边界断言确认行为与分级一致。

### 二、语义保留方法 | Semantic Preservation

**问题**：转换中如何保留语义？有损映射怎么处理？

**三级差异化策略**：

- **L1 同构映射**：直接映射，零语义损失。Int→int, Bool→bool, 单层Option→T?, enum→sealed class... 18 个类型双向往返完全恢复
- **L2/L3 辅助结构**：嵌套Option→Option\<T\>辅助类（三分态保留，见关切三）；Result→DResult(ok,err)结构化节点（保留ok/err类型结构）；UInt/Float→正常映射+`// [L3-CONSTRAINED]`诊断注释标注语义损失
- **L4 拒绝/标注**：`--strict`模式 raise TypeError 拒绝生成；默认模式生成代码+`// [L4-INEQUIVALENT] Channel: no Dart equivalent`诊断注释

**防线一——编译期自动检查**（4 个检查点串联）：①`is_nested_option()` 检测嵌套自动切换辅助类 ②`DResult(ok,err)` 结构化节点替代 DCustom 字符串退化 ③`semantic_level()` 每种 MoonType 自动获 L1-L4 标签 ④`emit_semantic_diagnostic()` L3/L4 自动插入诊断注释

**防线二——变异测试**（3 组，证明防线检错有效）：

| 变异操作 | 注入缺陷 | 检出结果 |
|---------|---------|---------|
| 嵌套Option塌缩 | 临时将辅助类改为 `T?` | round-trip 变红（Some(None)≠None不可区分）→撤回变绿 |
| Result结构退化 | 临时将 DResult 改回 DCustom | round-trip 变红（ok/err类型结构丢失）→撤回变绿 |
| UInt诊断缺失 | 临时移除 L3 标注 | strict 变红（L4拒绝范围错误）→撤回变绿 |

**结论**：每个保留方法有可执行断言，每个防线有变异测试证明检错能力。缺陷注入→变红→撤回→变绿，三组全通过。

### 三、嵌套可选值 | Nested Option

**问题**：`Option[Option[T]]` 在 Dart 中如何处理？三分态如何保留？

**问题本质**：transpiler 领域经典难题。MoonBit `Option[T]` 是真正 ADT 可嵌套，Dart `T??` 自动塌缩为 `T?`：

| MoonBit 值 | 语义 | Dart `int?` | 可区分 |
|-----------|------|------------|:------:|
| `Some(Some(42))` | 有值（内层有值） | `42` | ✅ |
| `Some(None)` | 有值（内层空） | `null` | ❌ 与 None 合并 |
| `None` | 空 | `null` | ❌ 与 Some(None) 合并 |

**解决方案**——辅助 Option 包装类，检测到嵌套时自动生成：

```dart
class Option<T> {
  final T? _value; final bool _isSome;
  Option._internal(this._value, this._isSome);
  factory Option.some(T v) => Option._internal(v, true);   // Some(v)
  factory Option.none() => Option._internal(null, false);   // None
  bool get isSome => _isSome; bool get isNone => !_isSome;
}
```

**三分态往返闭环**：`None`→`Option.none()`→`None` ✅ · `Some(None)`→`Option.some(null)`→`Some(None)` ✅ · `Some(Some(42))`→`Option.some(42)`→`Some(Some(42))` ✅

**设计权衡**：单层保持 `T?` 零开销（95%+ 用例）；仅嵌套场景由 `needs_option_class(decls)` 自动检测生成；更深层自动递归（`Option[Option[Option[T]]]` → `Option<Option<T?>?>`）。**测试**：8 个专项全绿（三分态正向+反向+四层嵌套+混合嵌套+生成条件+变异测试）

---

## 基本信息

| 项 | 值 |
|---|---|
| 项目 | moon2dart：MoonBit → Dart/Flutter 代码生成器 |
| 参赛者 | walkzzz（蒋本雄）· 13689047817 · 745244185@qq.com |
| GitHub | https://github.com/walkzzz/moon2dart |
| mooncakes | `walkzzz/moon2dart`（0.8.0 已发布；包版本重置 0.1.0） |
| 方向 | 开发者工具 — transpiler（原创，非移植）· Apache-2.0 |

---

## 使用场景

1. **后端逻辑→Flutter 前端复用**：`moon add walkzzz/moon2dart` → `transpile_source(src)` 自动转等价 Dart
2. **项目一键生成 Flutter 应用**：`moon2dart project <dir> -o <out>` → pubspec.yaml + lib/*.dart + widget 树
3. **AI Agent MCP 自动转换**：Claude/Copilot 通过 MCP 6 工具，MoonBit→Dart 成为 AI 工具链原生能力

---

## 技术方案

ast（零依赖）← typesys ← codegen ← 根包，线性无环。管线：源码→Lexer→Parser→AST→type_map→emit→Dart+pubspec.yaml。交付线：库API·CLI·Skill·MCP。双向：dart_ast+dart_parser+reverse_codegen 反向转换+双向同步+冲突检测。

---

## 质量实测

包 **12** · 测试 **500**(native)/**464**(wasm+js+wasm-gc) · `moon check --target all --deny-warn` 零警告 · Sprint 55+轮(10版本全交付) · L1 往返100% · strict 拒绝100% · 变异红→绿 · CI 五步

---

## 生态与差异化

mooncakes 3566+ 包：**唯一 MoonBit→Dart transpiler**。①生态空白填补 ②四交付线 ③双向同步+冲突检测 ④MCP+Skill ⑤L1-L4+strict+变异测试 ⑥四后端全绿

---

## 验收对齐

| 大赛要求 | 满足方式 |
|---------|---------|
| MoonBit 为主 | 100% MoonBit 实现 |
| 公开仓库 | GitHub v0.1.0-v0.10.0 |
| 能够运行 | 500 测试+0 warnings+示例 |
| 工作有效 | 10 版本全交付，原创 |
| 开源合规 | Apache-2.0 |
| AI 可解释 | AI 辅助，决策人工把控 |
| 持续集成 | GitHub Actions 五步 |

---

## 风险与缓解

| 风险 | 缓解 | 验证 |
|------|------|------|
| 嵌套Option语义丢失 | 辅助类+三分态往返+变异 | 100% |
| Result结构丢失 | DResult结构化节点 | 往返+变异 |
| FFI安全 | --pure-only+L4+strict | strict拒绝 |
| UInt/Float值域 | L3标注+诊断注释 | L3+strict |

---

## AI 声明

AI 辅助开发，关键决策人工把控：**AST 架构**·**类型映射**·**L1-L4 分级+辅助类+strict**·**MCP/Skill 形态**。提交历史+changelog+CI 保证可追踪性。

---

## 选型自检

| 章程原则 | 对照 |
|:---|:---|
| 真实需求 | Flutter 生态庞大，MoonBit 需要"跑在 Flutter 上"——真实空白 |
| 方案最优 | 四包线性+AST 是 transpiler 标准形态；L1-L4+strict 提供语义分级保障 |
| 无同质 | 3566+ 包确认唯一；往返语义等价（嵌套Option+DResult+变异+100%恢复率） |
