# golden 双端运行对比（业务函数 · Array→List） | Golden Dual-Runtime Comparison

> 生成：scripts/golden_check.mjs · 转换模式：wrapping + fail-closed（--on-unresolved error）· 真值端：MoonBit native · 执行端：`dart run`（Dart SDK 3.12.2, Dart VM）

> 同一份 MoonBit 源码（`scripts/golden_fixture/business.mbt`），两端各自**实际执行**。逐行输出对比：

| # | 输入表达式 | 说明 | MoonBit 输出 | Dart 输出 | 一致 |
|---|-----------|------|-------------|-----------|:----:|
| 1 | `sum([])` | 空数组：循环 0 次 → 0 | `0` | `0` | ✅ |
| 2 | `sum([1, 2, 3, 4])` | Array 求和（索引 + 累加）→ 10 | `10` | `10` | ✅ |
| 3 | `sum([2147483647, 1])` | 数组元素参与 32 位回绕 → -2147483648 | `-2147483648` | `-2147483648` | ✅ |
| 4 | `count_positive([-2, 0, 5, 7])` | 条件计数（if 表达式）→ 2 | `2` | `2` | ✅ |
| 5 | `max_or([3, 9, 2], -1)` | while 求最大值 → 9 | `9` | `9` | ✅ |
| 6 | `max_or([], -1)` | 空数组走默认分支 → -1 | `-1` | `-1` | ✅ |
| 7 | `build_squares(4).length()` | push 构建数组，长度 → 4 | `4` | `4` | ✅ |
| 8 | `build_squares(4)[3]` | 构建后索引 → 9 | `9` | `9` | ✅ |
| 9 | `first_or([42, 7], -1)` | 首元素索引 → 42 | `42` | `42` | ✅ |
| 10 | `first_or([], -1)` | 空数组索引保护 → -1 | `-1` | `-1` | ✅ |
| 11 | `same([1, 2], [1, 2])` | 集合相等：逐元素比较（Dart == 默认引用比较）→ true | `true` | `true` | ✅ |
| 12 | `same([1, 2], [2, 1])` | 集合相等：顺序不同 → false | `false` | `false` | ✅ |
| 13 | `same([], [])` | 空集合相等 → true | `true` | `true` | ✅ |

**结论**：13/13 行一致
