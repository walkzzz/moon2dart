# moon2dart 项目申报书

> 2026 MoonBit 国产基础软件开源大赛 · 方向 1（新项目）· walkzzz（蒋本雄）· Apache-2.0

---

## ⚡ 组委会关切回应

### 一、可转换范围 | Convertible Scope

**问题**：哪些 MoonBit 构造可安全转 Dart？边界在哪？

29 个映射条目四级分类全覆盖（16 MoonType → 13 DartType），每条有 `assert_round_trip()` 可执行断言：

| 等级 | 含义 | 数量 | 代表构造 | 往返 |
|------|------|:----:|---------|:----:|
| L1 运行时验证等价 | 类型映射 + 运行时语义模拟（golden 双端实测） | 15 | Int→int(32位回绕模拟层), Bool→bool, String→String, Double→double, 单层Option[T]→T?, enum→sealed class, struct→class, trait→abstract class, fn→function, async fn→Future, 泛型[T]→\<T\>, 闭包→箭头函数, Result[T,E]→sealed class, 嵌套Option→辅助类, Tuple→Record | ✅ |
| L2 结构等价 | 结构可还原，操作有约束 | 5 | **Array→List（L2-C：`mbEquals` 逐元素相等 + 操作子集）**, **Map→Map（L2-C）**, **Set→Set（L2-C）**, Char→int(rune), Int64→int(64位值域约束，限 Dart VM) | ⚠️ |
| L3 受限等价 | 约束下等价，需用户配合 | 4 | UInt→int(丢unsigned), UInt64→int(丢unsigned), Float→double(精度提升), Char运算→int运算 | 🔶 |
| L4 不等价 | 语义丢失，不可往返 | 5 | ForeignFunction, Channel, Spawn, FFI内联, wasm intrinsics | ❌ |

**边界逻辑**：L1/L2 分界在"运行语义能否完全模拟"——MoonBit `Int` 是 32 位回绕（wasm i32）而 Dart `int` 是 64 位，类型映射不保证运算一致，因此 L1 的 Int 依赖生成的**回绕模拟层**（wrapping shim）而非裸映射；**集合（Array/Map/Set）的相等语义不兼容：MoonBit 逐元素、Dart 引用**，故降为 L2-C，Wrapping 模式发射 `mbEquals` 还原；L3/L4 分界在"约束下能否等价"（UInt 加运行时检查可部分等价，Channel 无 Dart 对应物）。`--strict` 拒绝 L4，只放行 L1-L3。

**验证**：15 个 L1 往返测试全绿→恢复率 100%；5 个 L4 strict 拒绝测试全绿→拒绝率 100%；**同一输入双端运行对比 27/27 一致**（算术 14 + 业务函数 13；MoonBit 端 `moon run` 原生求值 vs Dart 端转换后 Dart SDK 3.12 实跑，含溢出回绕、截断除法/余数、Array 求和/相等/空数组等组委会关切反例，完整对比表见 docs/golden_results.md 与 docs/golden_results_business.md）。

### 二、语义保留方法 | Semantic Preservation

**问题**：类型往返只证明**结构**可还原——**运行语义**（运算行为）如何保证？32 位整数溢出怎么办？

**回答**：类型 × 运算双层建模 + 三道防线 + 双端运行实证。

**类型层**：29 条映射四级分类（见关切一），每条有 `assert_round_trip()` 可执行断言；集合（Array/Map/Set）为 L2-C，需 `mbEquals` + 操作约束。

**前端架构（v0.12.0 技术债修复）**：默认使用 MoonBit 官方 `moonbitlang/parser`（LL(k) + LR(1) 双 parser）解析源码，经 `official_parser` 适配层转为 moon2dart AST；子集外节点**显式拒绝**（fail-closed），语法层失败时才回落内置 parser（`--official-only` 可强制官方直连，用于技术债度量）。官方直连对业务/算术 fixture 全部接受；真实文件 4/9 直连、拒绝项均给出具体原因（`docs/acceptance_report.md`）。

**运算层**（v0.11.0 新增）——MoonBit `Int` 是 32 位回绕（wasm i32），Dart `int` 是 64 位，`2147483647 + 1` 两端结果必然不同。mini 类型推断器（变量环境 + 函数签名表）在发射期判定算术操作数类型，**Wrapping 模式（默认）**为 Int 算术生成回绕模拟层：

```dart
int mb32Add(int a, int b) => (a + b).toSigned(32); // 回绕
int mb32Div(int a, int b) => (a == -2147483648 && b == -1 || b == 0)
    ? (throw StateError('integer overflow trap')) // INT_MIN/-1 与除零：trap 模拟
    : ((a ~/ b).toSigned(32)); // 截断除法
```

MoonBit `%` 是截断余数（符号跟被除数）而 Dart `%` 是欧几里得余数——发射 `.remainder()`；整数除法发射 `~/` 而非 `/`（Dart 浮点除法）。**Fast 模式**（`--semantics fast`）裸发地道 Dart，Int 自动降级 L2 并插入 `[L2-SEMANTICS]` 诊断注释；UInt/UInt64/Float/Char 保持 `[L3-CONSTRAINED]` 标注；嵌套 Option 三分态辅助类与 DResult 结构化节点不变（见关切三）。

**三道防线**：
1. **编译期检查**：嵌套 Option 检测 / `semantic_level()` 模式感知定级（Wrapping 下 MInt=L1、Fast 下 MInt=L2）/ 诊断注释自动插入
2. **运行时模拟层**：mb32* shim 按需生成（仅程序实际用到的运算）；INT_MIN/-1 与除零按 wasm i32.div_s 规范抛异常模拟 trap，两端行为类别一致（异常终止）
3. **变异测试**：3 组注入缺陷→变红→撤回→变绿（嵌套 Option 塌缩 / Result 结构退化 / UInt 标注缺失）

**实证——同一输入双端运行对比**（直接回应"32 位整数溢出即可使转换前后结果不同"）：golden 用例库 27 组确定性输入（算术 14 + 业务函数 13），MoonBit 端 `moon run` 原生求值 vs Dart 端（wrapping 转换产物）Dart SDK 3.12 实跑，**逐行对比 27/27 一致**：

| 输入 | MoonBit 输出 | Dart 输出 | 一致 |
|------|------------|-----------|:----:|
| `2147483647 + 1`（溢出回绕） | -2147483648 | -2147483648 | ✅ |
| `65536 * 65536`（2^32 回绕） | 0 | 0 | ✅ |
| `7 / 2`（截断除法） | 3 | 3 | ✅ |
| `-7 % 2`（截断余数） | -1 | -1（Dart 裸 `%` 会得 1） | ✅ |
| `INT_MIN / -1`（trap 边界） | 异常终止（native 硬件 trap） | 异常终止（throw 模拟） | ✅ 类别一致 |
| `sum([2147483647, 1])`（数组 + 回绕） | -2147483648 | -2147483648 | ✅ |
| `same([1,2],[1,2])`（集合相等） | true | true（`mbEquals`；Dart 原生 `==` 为 false） | ✅ |
| `sum([])` / `max_or([],-1)`（空数组） | 0 / -1 | 0 / -1 | ✅ |

完整 27 行对比表 + **安全边界表**（fail-closed 拒绝 / L3 标注 / Int64 限 Dart VM）见 `docs/golden_results.md`、`docs/golden_results_business.md`、`docs/safety_boundary.md`。

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
| GitHub 主仓 | https://github.com/walkzzz/moon2dart（origin，SSH，CI/CD 全绿） |
| GitCode 镜像 | https://gitcode.com/LOOYIABC/moon2dart（跟随同步，与主仓 HEAD 一致） |
| mooncakes | `walkzzz/moon2dart`（旧功能线 0.8.0 已发布；包版本重置 0.1.x：0.1.0 已发布，0.1.1 = v0.11.0 已发布，**0.1.2 = 功能 v0.12.0 待发布**） |
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

包 **13** · 测试 **590**(native)· 四目标全绿 · `moon check --target all --deny-warn` 零警告 · Sprint 56+轮(12版本全交付) · L1 往返100% · strict 拒绝100% · 变异红→绿 · **golden 双端 27/27** · **安全边界门禁 8/8** · CI 六步（含 dart analyze）

---

## 生态与差异化

mooncakes 3566+ 包：**唯一 MoonBit→Dart transpiler**。①生态空白填补 ②四交付线 ③双向同步+冲突检测 ④MCP+Skill ⑤L1-L4+strict+变异测试 ⑥四后端全绿

---

## 验收对齐

| 大赛要求 | 满足方式 |
|---------|---------|
| MoonBit 为主 | 100% MoonBit 实现 |
| 公开仓库 | GitHub 主仓 + GitCode 镜像（双仓 HEAD 一致），v0.1.0-v0.12.0 |
| 能够运行 | 590 测试+0 warnings+示例+golden 双端 27/27 + 安全边界门禁（`node scripts/golden_check.mjs` / `node scripts/safety_gate.mjs` 一键复现） |
| 工作有效 | 11 版本全交付，原创 |
| 开源合规 | Apache-2.0 |
| AI 可解释 | AI 辅助，决策人工把控 |
| 持续集成 | GitHub Actions 九步：deny-warn 全目标 / 四后端测试 / fmt gate / mbti 契约校验 / coverage（最近 run 全绿） |

---

## 风险与缓解

| 风险 | 缓解 | 验证 |
|------|------|------|
| 嵌套Option语义丢失 | 辅助类+三分态往返+变异 | 100% |
| Result结构丢失 | DResult结构化节点 | 往返+变异 |
| FFI安全 | --pure-only+L4+strict | strict拒绝 |
| UInt/UInt64/Float/Char值域 | L3标注+诊断注释 | L3+strict |
| **Int 32位溢出语义差异** | **mb32* 回绕模拟层 + --semantics 双模式** | **golden 双端 27/27** |
| **集合相等语义差异（MoonBit 逐元素 / Dart 引用）** | **L2-C 定级 + `mbEquals` 相等 shim（Wrapping）** | **业务函数 `same(...)` 双端一致** |
| **推断失败静默降级** | **fail-closed 默认拒绝 + 三策略 + JSON/MD 报告 + 非零退出** | **safety_gate 8/8** |
| INT_MIN/-1 与除零 trap | mb32Div/mb32Rem 抛异常模拟（两端行为类别一致） | trap 边界验证 |

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
