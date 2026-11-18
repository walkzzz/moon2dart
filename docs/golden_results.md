# golden 双端运行对比报告 | Golden Dual-Runtime Comparison

> 生成：scripts/golden_check.mjs · 转换模式：wrapping · 真值端：`moon run golden`（native）· 执行端：`dart run`（Dart SDK 3.x, Dart VM）

> 同一份 MoonBit 源码（`scripts/golden_fixture/fixture.mbt`），两端各自**实际执行**：
> MoonBit 端由 moon 工具链原生求值；Dart 端由 moon2dart（wrapping 模式）转换后经 Dart SDK 编译运行。逐行输出对比：

| # | 输入表达式 | 说明 | MoonBit 输出 | Dart 输出 | 一致 |
|---|-----------|------|-------------|-----------|:----:|
| 1 | `wrap_add(2147483647, 1)` | 组委会反例：上界溢出回绕 → INT_MIN | `-2147483648` | `-2147483648` | ✅ |
| 2 | `wrap_add(-2147483647, -1)` | 下界回绕 → INT_MIN | `-2147483648` | `-2147483648` | ✅ |
| 3 | `wrap_sub(-2147483647, 2)` | 下界回绕 → INT_MAX | `2147483647` | `2147483647` | ✅ |
| 4 | `wrap_mul(65536, 65536)` | 2^32 回绕 → 0 | `0` | `0` | ✅ |
| 5 | `wrap_mul(100000, 100000)` | 10^10 回绕 → 1410065408 | `1410065408` | `1410065408` | ✅ |
| 6 | `trunc_div(7, 2)` | 正数整除（~/，非浮点除法） | `3` | `3` | ✅ |
| 7 | `trunc_div(-7, 2)` | 负被除数向零截断 → -3 | `-3` | `-3` | ✅ |
| 8 | `trunc_div(7, -2)` | 负除数向零截断 → -3 | `-3` | `-3` | ✅ |
| 9 | `trunc_rem(-7, 2)` | 截断余数符号跟被除数 → -1（Dart % 会得 1） | `-1` | `-1` | ✅ |
| 10 | `trunc_rem(7, -2)` | 截断余数符号跟被除数 → 1 | `1` | `1` | ✅ |
| 11 | `add64(1073741824, 1073741824)` | Int64 64 位加法不溢出 → 2147483648（限 Dart VM） | `2147483648` | `2147483648` | ✅ |
| 12 | `ratio(7.0, 2.0)` | Double IEEE 754 除法 → 3.5 | `3.5` | `3.5` | ✅ |
| 13 | `lt(2147483647, -2147483647)` | 回绕语义下比较一致 → false | `false` | `false` | ✅ |
| 14 | `join_str("moon", "bit")` | 字符串拼接 → moonbit | `moonbit` | `moonbit` | ✅ |

**结论**：14/14 行一致

## 边界行为（拒绝或人工处理边界）| Boundary behaviors

| 输入 | MoonBit 行为 | Dart（wrapping 模式）行为 | 类别 |
|------|-------------|--------------------------|------|
| `INT_MIN / -1` | **trap**（native 硬件异常终止，0xC0000095；wasm i32.div_s 规范 trap） | mb32Div 显式 `throw StateError`（本报告实测：TRAP） | 两端一致：异常终止 |
| `x / 0`、`x % 0` | **trap**（wasm i32.div_s / rem_s 除零 trap） | mb32Div/mb32Rem 显式 `throw StateError`（实测：TRAP） | 两端一致：异常终止 |
| `UInt` / `UInt64` / `Float` / `Char` | L3 值域有损 | 默认模式生成 + `// [L3-CONSTRAINED]` 诊断注释 | 人工处理（标注） |
| FFI / Channel / Spawn / wasm intrinsics | L4 无 Dart 对应 | `--strict` raise TypeError 拒绝；默认模式生成 + `[L4-INEQUIVALENT]` 注释 | 拒绝（strict）/ 人工处理 |
| `Int64` 算术 | 64 位回绕 | L1，**限 Dart VM**；编译到 web 时 int 退化为 JS number（值域 2^53），降级 L2 | 适用约束（VM only） |
| 字面量外的一元负号 / 无类型上下文的算术 | — | 类型推断失败时保守裸发（fast 语义），见推断边界说明 | 人工处理（标注） |

关键行为（回应 32 位整数溢出关切）：

- 行 1/2/3/4/5：MoonBit `Int` 为 32 位回绕（wasm i32），wrapping 模式生成的 `mb32*` 模拟层（`.toSigned(32)`）在 Dart 64 位 int 上逐运算还原同一结果
- 行 9/10：MoonBit `%` 为截断余数（符号跟被除数），Dart `%` 是非负欧几里得余数——转换器发射 `.remainder()` 而非 `%`
- 行 6/7/8：整除为 `~/`（截断向零），修复了原发射 `/`（浮点除法）的类型与语义双重错误
- 行 12：`Double` 两端均为 IEEE 754 64 位，直接裸发
- 类型往返断言只证明**结构**可还原；本报告的逐行输出对比证明的是**运行时语义**等价——两级证据互补
