# Array → List 语义规范（L2-C 条件等价）| Array → List Semantics (L2-C Conditional Equivalence)

> v0.12.0 · 2026-11-20 · 直接回应第二轮初审："Array 到 List 的 L1 定级未解释集合相等语义差异"
> 交叉参考：[safety_boundary.md](safety_boundary.md)（推断失败与人工介入）、[golden_results_business.md](golden_results_business.md)（双端业务函数实证）

## 1. 结论先行 | Bottom Line

| 项 | 旧口径（v0.11.0） | 新口径（v0.12.0） |
| --- | --- | --- |
| Array→List 定级 | **L1 完全等价** | **L2-C 条件等价（结构等价 + 约束子集）** |
| 相等语义 | 未说明 | **MoonBit 逐元素 vs Dart 引用** —— 已实测并修复（`mbEquals`） |
| 越界语义 | 未说明 | 异常类别一致（trap / RangeError），类型与消息不同 |
| 证据 | 仅类型映射断言 | **业务函数双端实跑 13/13**（`docs/golden_results_business.md`） |

**为什么不是 L1**：`[1,2] == [1,2]` 在 MoonBit 求值为 `true`（逐元素结构相等），
在 Dart 默认求值为 `false`（`List` 的 `==` 是引用相等）。若只做 `Array[T] → List<T>`
类型映射而不处理相等运算，"自动转等价 Dart"的承诺不成立。本版将其降级为 L2-C，
并在 Wrapping 模式发射 `mbEquals` 还原逐元素语义。

## 2. "等价"的可操作定义 | Operational Definition of Equivalence

本项目中的"等价"是**观测等价**，不是内存/实现等价：

1. 同一组输入下，两端进程的 **stdout 逐行一致**（golden 双端实跑）；
2. 返回值的可观测结构一致（标量值、集合元素与顺序）；
3. 异常场景下**终止类别一致**（正常 / 异常终止），不承诺异常类型名与消息文本一致；
4. 不承诺：内存布局、引用身份、迭代实现的内部顺序（当语言未定义时）、性能。

不满足以上 1-3 的构造不得标 L1，必须降级、加约束或拒绝。

## 3. 实测差异（可用命令复现）| Measured Differences

### 3.1 相等语义（关键）

```moonbit
// MoonBit：逐元素
let a : Array[Int] = [1, 2]
let b : Array[Int] = [1, 2]
println(a == b) // true
```

```dart
// Dart：引用（identity）
final a = [1, 2];
final b = [1, 2];
print(a == b); // false —— 与 MoonBit 不同
```

**修复**：Wrapping 模式对推断为集合的 `==` / `!=` 发射 `mbEquals(lhs, rhs)` /
`!mbEquals(lhs, rhs)`；`mbEquals` 递归处理 `List` / `Map` / `Set`，标量回落 `==`。
业务函数 `same(xs, ys) = xs == ys` 双端结果：`[1,2] vs [1,2] → true`、
`[1,2] vs [2,1] → false`、`[] vs [] → true`（golden 第 11-13 行）。

### 3.2 越界

| 场景 | MoonBit | Dart（生成代码） | 定级 |
| --- | --- | --- | --- |
| `xs[i]` 越界 | trap（native 异常终止 / wasm 规范 trap） | `RangeError`（异常终止） | L2：类别一致，类型/消息不同 |
| `xs.get(i)` 越界 | `None` | 生成 `(i >= 0 && i < xs.length ? xs[i] : null)` → `null` | L2：值域一致（null ↔ None） |
| `xs.pop()` 空数组 | `None` | 生成 `(xs.isEmpty ? null : xs.removeLast())` | L2：值域一致 |

### 3.3 32 位回绕 × 数组

`sum([2147483647, 1])` 两端均为 `-2147483648`（`mb32Add` 在数组累加路径生效，
golden 第 3 行、`scripts/safety_gate.mjs` 第 6 项）。

## 4. 操作映射矩阵 | Operation Matrix

| # | MoonBit | 生成 Dart | 观测等价 | 等级 | 约束 |
| --- | --- | --- | --- | --- | --- |
| 1 | `xs.length()` | `xs.length` | 元素计数一致 | L1-C | 仅长度语义 |
| 2 | `[a, b, c]` / `[]` | `[a, b, c]` / `[]` | 元素与顺序一致 | L1-C | 元素可转换 |
| 3 | `xs[i]` 读 | `xs[i]` | 命中一致；越界均异常终止 | L2 | 不依赖异常类型/消息 |
| 4 | `xs.get(i)` | 越界检查三元 → `null` | `Some(v)` ↔ `v`，越界 ↔ `null` | L2 | 需类型推断确认元素 |
| 5 | `xs.push(v)` | `xs.add(v)` | 追加位置一致 | L1-C | 返回 Unit |
| 6 | `xs.append(ys)` | `xs.addAll(ys)` | 顺序拼接一致 | L1-C | — |
| 7 | `xs.pop()` | `isEmpty ? null : removeLast()` | 尾部弹出/空数组一致 | L2 | — |
| 8 | `xs == ys` / `!=` | `mbEquals(xs, ys)` / `!mbEquals` | 逐元素一致（含嵌套 List/Map/Set） | L1-C（Wrapping）/ L2（Fast） | 需 Wrapping 模式 |
| 9 | 切片 `xs[a:b]` | **未支持（拒绝）** | — | L4（子集外） | 待实现（sublist） |
| 10 | `for x in xs` | **未支持（拒绝）** | — | L4（子集外） | 用 `while` + 索引 |
| 11 | `xs.sort()` | **未支持（拒绝）** | — | L4（子集外） | Dart sort 不稳定，需显式比较器 |
| 12 | 别名（两个变量指向同一数组） | 引用共享 | 修改可见性一致 | L1 | 不涉及并发 |
| 13 | 容量/扩容 | 动态长度 | 一致（均自动扩容） | L1 | — |

> L1-C = L1 条件等价：在矩阵给定的操作子集与约束内观测等价；超出子集即拒绝。

## 5. 安全转换范围（提升到 L1-C 的条件）| Safe Range

同时满足以下条件时，Array→List 可标 **L1-C**：

1. 仅使用矩阵第 1-8、12-13 项操作；
2. 集合相等依赖 `==` / `!=` 时，必须处于 **Wrapping** 模式（生成 `mbEquals`）；
3. 元素类型为标量、字符串或可递归比较的集合（`mbEquals` 递归支持）；
4. 不依赖越界异常的类型名或消息文本；
5. 不使用 `sort` / 切片 / `for-in` 等未实现操作（解析器直接拒绝）。

**必须人工介入**（不得宣称自动等价）：

- Fast 模式下任何集合 `==` / `!=`（发射裸 `==`，语义不同）；
- 依赖 `Set` / `Map` 迭代顺序（Dart 默认 LinkedHashSet/LinkedHashMap 为插入序，MoonBit 顺序不在本项目保证范围）；
- 元素为函数/闭包/自定义 trait 对象的相等比较；
- 跨函数返回的集合类型无法从签名确认；
- 并发/共享可变数组。

## 6. 证据链 | Evidence

| 证据 | 位置 | 结果 |
| --- | --- | --- |
| 业务函数双端实跑 | `scripts/golden_check.mjs` → `docs/golden_results_business.md` | **13/13 一致**（含相等、空数组、回绕、push、索引） |
| 安全边界门禁 | `scripts/safety_gate.mjs` | **8/8 PASS**（fail-closed / 报告 / 幂等 / mbEquals / 回绕） |
| 算术双端实跑 | `docs/golden_results.md` | 14/14 一致 + trap 边界一致 |
| 单元测试 | `codegen/array_emit_wbtest.mbt`、`moon2dart_safety_wbtest.mbt` | 集合发射与端到端断言 |

复现：

```bash
node scripts/golden_check.mjs    # 需 Dart SDK 3.12.2
node scripts/safety_gate.mjs     # 需 moon 工具链
```

## 7. 未覆盖与边界 | Gaps

- 切片、`for-in`、`sort`、位运算、复合赋值尚未实现：解析器/发射器直接拒绝（fail-closed），
  不做静默近似。
- 嵌套集合的 `mbEquals` 为递归 `dynamic` 实现，性能 O(n²)（Set 比较），正确性优先。
- Web 目标（dart2js）下 `int` 退化为 53 位值域：Array 元素为 `Int` 时同样受此约束，
  与 `Int64` 的 L2 约束一致（见 `type_mapping.md`）。