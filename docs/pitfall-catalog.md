# 陷阱目录 | Pitfall Catalog

> 准入标准（借鉴 flutter-ohos-expert-agent）：**只收"复现过并修好"的条目**，来源标【实测】并附编译器错误码 / 复现命令；报告不许写「预计可行」「理论上支持」。
> 编号分段：`M*` = MoonBit 语法演进（moon 0.1.20261104 实测，与 astrolabe/image 同源）· `T*` = moon2dart transpiler 特有（待积累）。
>
> 交叉参考：语义等价分级详见 [semantic_equivalence.md](semantic_equivalence.md)

---

## M 系列 · MoonBit 语法演进 | MoonBit Language Evolution（moon 0.1.20261104 实测）

### M1 `try?` 语法已移除

- **现象**：`match try? f() { ... }` 编译失败。
- **判别**：编译器直接提示 `try? has been removed. Replace 'try? expr' with 'try Ok(expr) catch { e => Err(e) }'`。
- **修法**：`let r : Result[T, E] = try { Ok(f()) } catch { e => Err(e) }`。
- **来源**：【实测】moon check 编译错误。
- **可自动化**：✅。

### M2 `inspect!` 宏已移除，且 `inspect` 的 Show 版本已弃用

- **现象**：`inspect!(expr, content=)` 解析错 `unexpected f!(..)`；`inspect` 对 `Result` 类型触发 `[0020] deprecated: Use Debug instead of Show for debugging purposes`（note 指向 `moonbitlang/core/builtin/show.mbt:357`）。
- **修法**：断言改 `to_string()` / 插值；或实现 `Debug` 后用 `debug_inspect`；README 展示性代码改 `match + println` 风格。
- **来源**：【实测】astrolabe/image 同源对照实验（3002 + 4018 双实锤）。
- **可自动化**：✅（CI --deny-warn 即红）。

### M3 命名参数传值语法是 `label=`，不是 `label~=`

- **现象**：`[3016] The syntax 'label~=..' is invalid, the correct syntax is 'label=..'`。
- **修法**：`label="value"`。
- **来源**：【实测】moon check 编译错误。
- **可自动化**：✅。

### M4 `not(expr)` 已弃用

- **现象**：`[0020] deprecated: Use !expr instead`（--deny-warn 下为错误）。
- **修法**：`!expr`。
- **来源**：【实测】moon check 警告。
- **可自动化**：✅。

### M5 `StringBuilder::new()` 已弃用

- **现象**：`[0020] deprecated: Use 'StringBuilder()' instead`。
- **修法**：`let buf : StringBuilder = StringBuilder()`。
- **来源**：【实测】moon check 警告。
- **可自动化**：✅。

### M6 MoonBit trait 不支持类型参数

- **现象**：`pub trait Name[A] { ... }` 编译错 `[3002] unexpected '['`；impl 处 `Name[T] for Type[T]` 同样拒绝。
- **根因**：MoonBit trait 无类型参数化能力。
- **修法**：函数式扩展点（裸函数作参数）或 Self 绑定。
- **来源**：【实测】astrolabe v0.5.0 ParserLike 类型类方案被编译器推翻（walkzzz/astrolabe 同作者）。
- **可自动化**：❌ 设计约束。

### M7 `Char` 的 Show 输出无引号

- **现象**：inspect 快照 `content="Ok('a')"` 失败，实际 `Ok(a)`。
- **修法**：快照断言以实测为准（`moon test --update` 自动对齐）。
- **来源**：【实测】astrolabe 侧快照 diff。
- **可自动化**：✅。

### M8 `impl Show` 的隐式方法提升已弃用（implicit promotion）

- **现象**：`[0079] implicit_impl_as_method`（--deny-warn 下为错误）。
- **修法**：显式 `pub extend X with Show::{output, to_string}`。
- **来源**：【实测】image core/types LoadError 实现 Show 时触发（0079）。
- **可自动化**：✅。

### M9 `Result` 的 Show 已弃用——failable API 推荐 `T raise E`

- **现象**：`[0078] result_error_return: Prefer 'T raise E' for failable APIs`；inspect（Show 版）同源弃用。
- **修法**：API 签名改 `-> T raise E`；测试断言改 `to_string()` / 插值。
- **来源**：【实测】CI --deny-warn 门禁（0078）。
- **可自动化**：✅。

### M10 `many` 零消耗死循环防护：mut 引用比较必须用运行前快照

- **现象**：`many(p)` 中 `p` 零消耗成功 → 尾递归同位置无限循环挂起；防护比较 `st.offset == state.offset` 因 `State` 为 mut 引用（run 原地推进）恒为 true，反而误伤全部正常匹配。
- **修法**：`p.run` 前取 `let before = state.offset` 快照，运行后比较 `st.offset == before`。
- **来源**：【实测】astrolabe 侧同类实现（walkzzz/astrolabe v0.5.2，M 系列同源）。
- **可自动化**：✅ 正反向测试。

### M11 `#warnings("...")` 属性触发 E3002 假 EOF（moonc v0.10.20 实测）

- **现象**：`.mbt` 文件使用 `#warnings("...")` 属性时，moonc 报 `[E3002] Parse error ... unexpected EOF`——错误位置指向文件尾的"假 EOF"。
- **根因**：moonc v0.10.20（moon 0.1.20261104 系）不支持该属性语法；CRLF 行尾的 `.mbt` 文件同样触发假 EOF。
- **修法**：禁用 `#warnings(...)` 属性，警告治理走修根因（--deny-warn 门禁逐条消除）；行尾统一 LF（仓库已加 `.gitattributes` 强制 `eol=lf`）。
- **来源**：【实测】moon2dart 仓库 moon check（2026-11-18，v0.11.0 Sprint）。
- **可自动化**：✅（`.gitattributes` eol=lf + CI --deny-warn）。

---

## T 系列 · moon2dart transpiler 特有 | Transpiler-Specific

> 准入规则同上；本段随项目演进积累（transpiler 管线 / 双向同步 / MCP 工具链特有陷阱）。

### T1 `MCustom`/`MTypeVar` 的 name 未校验直接插入 Dart 代码（注入向量）

- **现象**：`transpile_type(@ast.MCustom("a; class Injected"))` 返回 `"a; class Injected"`——name 原样插入生成的 Dart 代码，恶意 name 可注入任意 Dart 声明。
- **复现**：moon2dart_test.mbt 的 `transpile_type records DCustom name passthrough boundary` 测试（实测 name 原样通过）。
- **根因**：`map_type` 的 `MCustom(name) => DCustom(name)` 与 `to_dart_string` 的 `DCustom(name) => name` 均未校验 name 是否为合法 Dart identifier。
- **修法（roadmap 0.1.x 迭代）**：parser 解析 TypeVar/Custom name 时加 identifier 校验（字母/数字/下划线白名单），非法即报 `Moon2DartError`。
- **来源**：【实测】moon2dart_test.mbt 注入边界测试（2026-11-13）。
- **可自动化**：✅（注入测试已入册，校验后断言反转）。

### T2 嵌套 Option 塌缩——`Option[Option[T]]` 三分态丢失

- **现象**：`Option[Option[Int]]` 直接映射为 `int??`（Dart 不支持嵌套可空），导致 `Some(None)` 和 `None` 不可区分。
- **根因**：Dart `T?` 的 `?` 后缀不可嵌套——`T??` 等价于 `T?`，丢失了三分态（Some(Some(v)) / Some(None) / None）。
- **修法**：检测嵌套 Option → 自动生成 `Option<T>` 辅助类（含 `some`/`none` 工厂 + `isSome`/`isNone` 属性），`DNullable(DNullable(inner))` 表示嵌套。
- **来源**：【实测】v0.10.0 嵌套 Option 往返测试（assert_round_trip + 变异测试证明塌缩可检出）。
- **可自动化**：✅（变异测试：临时塌缩 → round-trip 变红；撤回 → 变绿）。

### T3 Result 退化为 DCustom——结构信息丢失

- **现象**：`Result[Int, String]` 映射为 `DCustom("Result<int, String>")`，反向恢复为 `MCustom` 而非 `MResult`，类型结构完全丢失。
- **根因**：旧版 `map_type` 将 `MResult` 拼接为字符串存入 `DCustom`，无结构化节点。
- **修法**：新增 `DResult(DartType, DartType)` 结构化节点，替代 `DCustom` 退化映射；反向 `dart_type_to_moon_ast` 精确恢复 `MResult`。
- **来源**：【实测】v0.10.0 DResult 往返测试 + 变异测试（退化为 DCustom → round-trip 变红）。
- **可自动化**：✅（变异测试：临时改回 DCustom → round-trip 变红；撤回 → 变绿）。

### T4 UInt/Float 值域丢失——语义等价不可达

- **现象**：MoonBit `UInt` 映射为 Dart `int`（丢失 unsigned 语义）；`Float` 映射为 `double`（精度提升）。正向映射可用但反向恢复时值域不保证一致。
- **根因**：Dart 无 `unsigned int` 和 `float` 类型，无法精确表达。
- **修法**：语义等价分级为 L3（受限），代码生成时添加 `// [L3-CONSTRAINED]` 诊断注释；strict 模式下允许但标注。
- **来源**：【实测】v0.10.0 L3 诊断标注测试 + semantic_level 分类测试。
- **可自动化**：✅（L3 标注测试 + strict 模式测试）。

### T5 FFI 语义不可验证——`extern "c"` 跨越语言边界

- **现象**：`extern "c"` 声明生成的 `dart:ffi` 代码无法在编译时验证语义等价——C 侧函数签名可能与 Dart typedef 不匹配。
- **根因**：FFI 跨语言调用，编译器无法在 Dart 侧验证 C 函数的实际行为。
- **修法**：L4 分类（语义不等价），strict 模式下拒绝（除非在已知安全白名单中）；非 strict 模式下添加 `// [L4-INEQUIVALENT]` 诊断注释。
- **来源**：【实测】v0.10.0 L4 拒绝测试 + 诊断标注测试。
- **可自动化**：✅（strict 模式 L4 全拒绝测试）。

### T6 spawn/Channel 无 Dart 对应——并发原语不可映射

- **现象**：MoonBit 的 `spawn` 和 `Channel` 并发原语在 Dart 中无直接对应（Dart 使用 `Isolate` + `SendPort`/`ReceivePort` 模型，语义完全不同）。
- **根因**：两语言并发模型根本不同，无法建立语义等价映射。
- **修法**：L4 分类，strict 模式下拒绝；映射为 `DCustom` 并添加 `[L4-INEQUIVALENT]` 诊断注释。用户需手动实现 Dart 侧并发逻辑。
- **来源**：【实测】v0.10.0 L4 拒绝测试（Channel/Spawn strict raise）。
- **可自动化**：✅（strict 模式 L4 全拒绝测试）。

### T7 parse_expr_prec 终止条件——非运算符 token 不终止

- **现象**：表达式解析在 `min_prec=0` 时遇到非运算符 token（precedence=0）不终止，继续走运算符处理，`op_to_string` 抛 `"unknown operator token"`。
- **根因**：终止条件 `prec < min_prec` 对 precedence=0 的 token 在 `min_prec=0` 时不成立（0 < 0 为 false），非运算符被误当运算符。
- **修法**：终止条件改 `prec <= 0 || prec < min_prec`。
- **来源**：【实测】v0.11.0 parser 测试红绿（golden fixture 多语句块触发）。
- **可自动化**：✅（parser 白盒测试 + golden 双端对比）。

### T8 INT_MIN/-1 是硬件 trap 而非回绕

- **现象**：MoonBit native 端 `(-2147483648) / (-1)` 触发硬件 trap（0xC0000095），不产生回绕值 2147483647；测试断言若假设回绕值则失败。
- **根因**：除法溢出在 wasm（i32.div_s 规范 trap）与 native（CPU 除法异常）上都是 trap，语义上"无值"而非"回绕"。
- **修法**：测试断言不得假设回绕值；Dart 端 `mb32Div` 用 `throw StateError` 模拟 trap，保持两端行为类别一致（异常终止）。
- **来源**：【实测】golden 双端 trap 边界用例（[golden_results.md](golden_results.md)）。
- **可自动化**：✅（golden trap 用例）。

### T9 Dart `%` 与 MoonBit `%` 余数语义不同

- **现象**：`-7 % 2` MoonBit 得 -1（截断余数，符号跟被除数），Dart 裸 `%` 得 1（欧几里得余数，结果非负）。
- **根因**：两语言对 `%` 的语义定义不同——Dart `%` 结果非负，MoonBit `%` 符号跟被除数。
- **修法**：发射 `.remainder()`（Dart `num.remainder` 为截断余数）；Wrapping 模式下经 `mb32Rem`（含除零 trap 模拟）。
- **来源**：【实测】golden 双端 `trunc_rem(-7,2)` 用例（裸 `%` 得 1，`.remainder()` 得 -1）。
- **可自动化**：✅（golden 双端对比）。

---

## 维护规则 | Maintenance Rules（照 flutter-ohos-expert 准入流程）

1. 新条目只收"复现过并修好"的，附编译器错误码或测试红绿证据，标【实测】。
2. 编号从各段最大号往后接（M* / T*），不跨段复用。
3. M 系列与 astrolabe / image 的 docs/pitfall-catalog.md 同源（两项目各自收录，条目同步）。
