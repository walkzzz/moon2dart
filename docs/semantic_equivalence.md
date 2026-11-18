# moon2dart 语义等价性规范 | Semantic Equivalence Specification

> v0.11.0 · 2026-11-18 · 新增运行时语义保持体系（Int 32 位回绕模拟层 + 双语义模式 + golden 双端验证 14/14）· 已实现嵌套 Option 辅助类 + DResult 结构化节点
>
> 交叉参考：T 系列陷阱详见 [pitfall-catalog.md](pitfall-catalog.md)（T2 嵌套 Option 塌缩 / T3 Result 退化 / T4 UInt 值域 / T5 FFI 语义 / T6 并发原语 / T7 parse_expr_prec 终止 / T8 INT_MIN trap / T9 余数语义）；golden 双端实测报告详见 [golden_results.md](golden_results.md)

## 1. 核心定义 | Core Definitions

### 1.1 往返语义等价 | Round-Trip Semantic Equivalence

对于 MoonBit 源码 `S`，经过正向转换 `transpile` 和反向转换 `reverse_transpile` 后：

```
S → transpile → D → reverse_transpile → S'
```

若 `S'` 与 `S` 语义等价（行为一致），则称该构造具有**往返语义等价性**。

### 1.2 语义保留等级 | Semantic Preservation Levels

| 等级 | 标记 | 含义 |
|------|------|------|
| **L1 完全等价** | ✅ | 类型映射 + 运行时语义模拟（golden 双端 14/14 实测，见 §5.3） |
| **L2 结构等价** | ⚠️ | 数据结构可还原，但操作语义有差异 |
| **L3 受限等价** | 🔶 | 在特定约束下等价（需用户配合），默认模式含诊断注释 |
| **L4 不等价** | ❌ | 语义丢失，不可往返，--strict 模式拒绝 |

---

## 2. 可转换范围 | Translatable Range（28 条目全覆盖）

### 2.1 L1 完全等价的构造 | L1 Fully Equivalent（18 条目）

以下构造经过 MoonBit → Dart → MoonBit 往返后语义完全一致：

| # | MoonBit | Dart | 正向映射 | 反向映射 |
|---|---------|------|---------|---------|
| 1 | `Int` | `int` | `MInt → DInt`（+ mb32* 32 位回绕模拟层，Wrapping 模式默认） | `DInt → MInt` |
| 2 | `Int64` | `int` | `MInt64 → DInt64`（限 Dart VM——web 目标 int 退化为 JS number 值域 2^53） | `DDouble → MDouble` |
| 3 | `Double` | `double` | `MDouble → DDouble` | `DDouble → MDouble` |
| 4 | `Bool` | `bool` | `MBool → DBool` | `DBool → MBool` |
| 5 | `String` | `String` | `MString → DString` | `DString → MString` |
| 6 | `Unit` | `void` | `MUnit → DVoid` | `DVoid → MUnit` |
| 7 | `Array[T]` | `List<T>` | `MArray(T) → DList(T')` | `DList(T') → MArray(T)` |
| 8 | `Map[K,V]` | `Map<K,V>` | `MMap(K,V) → DMap(K',V')` | `DMap(K',V') → MMap(K,V)` |
| 9 | `Set[T]` | `Set<T>` | `MSet(T) → DSet(T')` | `DSet(T') → MSet(T)` |
| 10 | `Option[T]` (单层) | `T?` | `MOption(T) → DNullable(T')` | `DNullable(T') → MOption(T)` |
| 11 | `Option[Option[T]]` (嵌套) | `Option<T>` 辅助类 | `MOption(MOption(T)) → DNullable(DNullable(T'))` | `DNullable(DNullable(T')) → MOption(MOption(T))` |
| 12 | `Result[T,E]` | `Result<T,E>` sealed class | `MResult(ok,err) → DResult(ok',err')` | `DResult(ok',err') → MResult(ok,err)` |
| 13 | `Future[T]` | `Future<T>` | `MFuture(T) → DFuture(T')` | `DFuture(T') → MFuture(T)` |
| 14 | `fn(a:A) -> B` | `B name(A a)` | `DFn → DTopFn` | `DTopFn → DFn` |
| 15 | `struct Name { fields }` | `class Name { fields }` | `DStruct → DClass` | `DClass → DStruct` |
| 16 | `enum Name { variants }` | `sealed class Name` | `DEnum → DSealedClass` | `DSealedClass → DEnum` |
| 17 | `trait Name { methods }` | `abstract class Name` | `DTrait → DAbstractClass` | `DAbstractClass → DTrait` |
| 18 | `impl Trait for Type` | `class Type implements Trait` | `DImpl → 合并到DStruct` | `DClass(methods) → DImpl` |

### 2.2 L2 结构等价的构造 | L2 Structurally Equivalent（2 条目）

| # | MoonBit | Dart | 差异说明 | 影响 |
|---|---------|------|---------|------|
| 1 | `Char` | `int` (rune) | 字符 vs Unicode码点 | 字符串操作需注意 |
| 2 | `T*` (引用) | `T` | MoonBit 值类型 vs Dart 引用语义 | struct 行为差异 |

### 2.3 L3 受限等价的构造 | L3 Constrained Equivalence（4 条目）

| # | MoonBit | Dart | 约束条件 | 诊断注释 |
|---|---------|------|---------|---------|
| 1 | `UInt` | `int` | Dart 无 unsigned | `// [L3-CONSTRAINED] UInt: unsigned semantics lost, mapped to signed int` |
| 2 | `UInt64` | `int` | Dart 无 unsigned（v0.11.0 修正：原 semantic_level 漏判 L1） | `// [L3-CONSTRAINED] UInt64: unsigned semantics lost, mapped to signed int` |
| 3 | `Float` | `double` | 32→64位精度提升 | `// [L3-CONSTRAINED] Float: 32-bit float promoted to 64-bit double` |
| 4 | `Char` | `int` | 字符→码点 | `// [L3-CONSTRAINED] Char: character mapped to Unicode code point (int)` |

### 2.4 L4 不等价的构造 | L4 Inequivalent（5 条目）

| # | MoonBit | Dart | 语义丢失原因 | --strict 行为 |
|---|---------|------|------------|-------------|
| 1 | `ForeignFunction` | 无对应 | FFI 回调不可跨语言 | raise Moon2DartError::TypeError |
| 2 | `Channel` | 无对应 | CSP 并发模型不同 | raise Moon2DartError::TypeError |
| 3 | `Spawn` | `Future.microtask` | 并发原语语义不同 | raise Moon2DartError::TypeError |
| 4 | `extern "C"` FFI | `dart:ffi` | 跨语言调用语义不同 | --pure-only 排除 |
| 5 | 内联汇编/wasm intrinsics | 无对应 | 平台特定 | 不支持 |

---

## 3. 嵌套可选值 | Nested Option 详解

### 3.1 问题本质 | The Problem

MoonBit 的 `Option[T]` 是真正的代数数据类型（ADT），可以嵌套：

```moonbit
// MoonBit: 三种不同的值
let a : Option[Option[Int]] = Some(Some(42))   // 有值中的有值
let b : Option[Option[Int]] = Some(None)        // 有值中的空
let c : Option[Option[Int]] = None               // 空
```

Dart 的 `T?` 是 nullable 语法糖，**嵌套 nullable 自动塌缩**：

```dart
// Dart: int?? 等价于 int?，只有两种值
int? a = 42;     // 有值
int? b = null;   // 空 — 无法区分 "有值中的空" 和 "空"
```

**值域对比**：

| 值 | `Option[Option[Int]]` 语义 | `int?` 语义 | 可区分 |
|----|---------------------------|------------|--------|
| `Some(Some(42))` | 有值（内层有值） | `42` | ✅ |
| `Some(None)` | 有值（内层空） | `null` | ❌ 与 None 合并 |
| `None` | 空 | `null` | ❌ 与 Some(None) 合并 |

### 3.2 解决方案 | Solution：辅助 Option 包装类（v0.10.0 已实现）

当检测到嵌套 Option 时，自动生成 Dart 辅助类 `Option<T>`：

#### 实际生成的辅助类

```dart
class Option<T> {
  final T? _value;
  final bool _isSome;

  Option._internal(this._value, this._isSome);

  factory Option.some(T value) => Option._internal(value, true);
  factory Option.none() => Option._internal(null, false);

  bool get isSome => _isSome;
  bool get isNone => !_isSome;
  T get value => _value!;
}
```

#### 类型映射规则（v0.10.0 实际实现）

```
map_type(MOption(inner)):
  if is_nested_option(MOption(inner)):  // 嵌套检测
    match inner:
      MOption(inner_inner) => DNullable(DNullable(map_type(inner_inner)))
  else:
    DNullable(map_type(inner))  // 单层，保持现有行为
```

#### 嵌套 Option 完整案例

**MoonBit 源码**：

```moonbit
fn parse_config(raw : String) -> Option[Option[Int]] {
  if raw == "" {
    None                    // 配置项不存在
  } else if raw == "null" {
    Some(None)              // 配置项存在但值为空
  } else {
    Some(Some(raw.to_int())) // 配置项存在且有值
  }
}

fn use_config(config : Option[Option[Int]]) -> String {
  match config {
    None => "config missing"
    Some(None) => "config present but empty"
    Some(Some(v)) => "config value: \{v}"
  }
}
```

**生成的 Dart 代码**：

```dart
// 自动生成的辅助类（仅当检测到嵌套 Option 时）
class Option<T> {
  final T? _value;
  final bool _isSome;
  Option._internal(this._value, this._isSome);
  factory Option.some(T value) => Option._internal(value, true);
  factory Option.none() => Option._internal(null, false);
  bool get isSome => _isSome;
  bool get isNone => !_isSome;
  T get value => _value!;
}

// 转换后的函数
Option<Option<int>> parseConfig(String raw) {
  if (raw == "") {
    return Option.none();                         // None → 配置项不存在
  } else if (raw == "null") {
    return Option.some(Option.none());            // Some(None) → 配置项存在但值为空
  } else {
    return Option.some(Option.some(int.parse(raw))); // Some(Some(v)) → 配置项存在且有值
  }
}
```

#### 反向映射规则（v0.10.0 已实现）

```
dart_type_to_moon_ast(DNullable(inner)):
  match inner:
    DNullable(inner_inner) => MOption(MOption(dart_type_to_moon_ast(inner_inner)))
    _ => MOption(dart_type_to_moon_ast(inner))

emit_moon_expr(Option.some/Option.none):
  Option.some(Option.some(v)) → Some(Some(v))
  Option.some(Option.none()) → Some(None)
  Option.none() → None
```

### 3.3 三层嵌套及更深场景 | Deeper Nesting

`Option[Option[Option[T]]]` → `Option<Option<T?>?>` —— 辅助类递归嵌套。

每增加一层嵌套，辅助类包装增加一层。实际使用中三层及以上嵌套极罕见，但方案可自动支持。

### 3.4 语义保留验证 | Semantic Preservation Verification

| MoonBit 值 | Dart 值 | 反向恢复 | 等价 |
|-----------|---------|---------|------|
| `None` | `Option<int?>.none()` | `None` | ✅ |
| `Some(None)` | `Option<int?>.some(null)` | `Some(None)` | ✅ |
| `Some(Some(42))` | `Option<int?>.some(42)` | `Some(Some(42))` | ✅ |

---

## 4. Result 类型语义保留 | Result Type Semantic Preservation（v0.10.0 已实现）

### 4.1 已实现的改进 | Improvement：DResult 结构化节点

```moonbit
// typesys/mapping.mbt — DartType 新增变体
pub enum DartType {
  // ... 现有节点 ...
  DResult(DartType, DartType)  // 结构化 Result — 保留 ok/err 类型信息
}
```

映射规则（已实现）：

```
正向：MResult(ok, err) → DResult(map_type(ok), map_type(err))
反向：DResult(ok, err) → MResult(dart_type_to_moon_ast(ok), dart_type_to_moon_ast(err))

to_dart_string(DResult(ok, err)) → "Result<" + ok.to_dart_string() + ", " + err.to_dart_string() + ">"
```

### 4.2 Result 往返验证 | Result Round-Trip Verification

```moonbit
// MoonBit
fn divide(a : Int, b : Int) -> Result[Int, String] {
  if b == 0 { Err("division by zero") } else { Ok(a / b) }
}
```

```dart
// Dart（改进后）
Result<int, String> divide(int a, int b) {
  if (b == 0) { return Err("division by zero"); } else { return Ok(a / b); }
}
```

反向恢复 → `fn divide(a : Int, b : Int) -> Result[Int, String]` ✅

---

## 5. 语义保留方法总结 | Semantic Preservation Methods Summary

### 5.1 三级语义保留策略 | Three-Level Strategy

```
┌──────────────────────────────────────────────────────┐
│ Level 1: 类型同构 — 类型映射 + 运算模拟           │
│   Int→int (mb32* 回绕模拟), Bool→bool, Array→List...  │
│   Option[T]→T? (单层), enum→sealed class            │
├──────────────────────────────────────────────────────┤
│ Level 2: 类型同态 — 映射需辅助结构，语义可还原      │
│   Option[Option[T]]→Option<T?> (辅助类)              │
│   Result[T,E]→Result<T,E> (sealed class + DResult)  │
│   trait→abstract class, struct→class                 │
├──────────────────────────────────────────────────────┤
│ Level 3: 类型限制 — 语义有损，需用户标注           │
│   UInt→int (无符号丢失), Float→double (精度提升)     │
│   FFI→dart:ffi (跨语言), spawn→Future (并发模型)    │
│   处理方式：--strict 模式报错 / 默认模式警告注释    │
└──────────────────────────────────────────────────────┘
```

**运算层（v0.11.0 新增）**：类型同构之上叠加运行时语义模拟——

- **mini 类型推断器**（`typesys/infer.mbt`）：`TypeEnv`（变量环境 + 函数签名表）+ `infer_expr_type` + `collect_int_arith_ops`，定位程序中实际发生的 Int 算术运算；推断失败时保守裸发（fast 语义，不阻塞转换）。
- **mb32\* 回绕 shim**（按需生成，仅程序用到的运算）：`mb32Add/Sub/Mul(a,b) => (a op b).toSigned(32)`；`mb32Div` 含 INT_MIN/-1 与除零的 throw StateError trap 模拟 + `(a ~/ b).toSigned(32)`；`mb32Rem` 含除零 trap 模拟 + `a.remainder(b).toSigned(32)`。
- **双模式**：`SemanticsMode` 枚举（Wrapping 默认 / Fast），API `transpile_source_with_mode(src, mode)` / `transpile_source_with_options(src, lib_name, mode)`，CLI `--semantics wrapping|fast`。双模式定级 `semantic_level_in_mode`：Wrapping 下 MInt=L1，Fast 下 MInt=L2；MUInt64 从漏判 L1 修正为 L3；MInt64 保持 L1 但限 Dart VM（web 目标 int 退化为 JS number 值域 2^53）。

### 5.2 编译期语义检查 | Compile-Time Semantic Checks

1. **嵌套 Option 检测**：`map_type` 递归时检测 `MOption(MOption(_))`，自动切换辅助类映射
2. **无符号类型警告**：`MUInt`/`MUInt64` 映射时生成 `// WARNING: unsigned semantics lost` 注释
3. **Result 结构化**：`MResult` 映射为 `DResult`（非 `DCustom`），保留类型结构
4. **is_pure 检查**：`--pure-only` 模式排除所有 L3/L4 构造

### 5.3 运行时语义验证 | Runtime Semantic Verification（v0.11.0 已实现）

```
golden_fixture/fixture.mbt (MoonBit)
    ├── moon run golden      → 真值端逐行输出（MoonBit native 语义）
    └── transpile → dart run → 转换端逐行输出（Dart SDK 3.x）
              └── scripts/golden_check.mjs 逐行对比 → docs/golden_results.md
```

- **结果**：14/14 行一致——含 `2147483647+1 = -2147483648`（溢出回绕）、`65536*65536 = 0`（乘法回绕）、`trunc_div(7,2) = 3`（截断除法）、`trunc_rem(-7,2) = -1`（Dart 裸 `%` 得 1，`.remainder()` 得 -1）。
- **trap 边界**：`INT_MIN / -1` 在 MoonBit native 是硬件 trap（0xC0000095）而非回绕（wasm i32.div_s 规范 trap）；`mb32Div` 抛 StateError 模拟，两端行为类别一致（异常终止）。
- **复现**：`node scripts/golden_check.mjs`（前置：moon 工具链 + Dart SDK 3.x）；报告见 [golden_results.md](golden_results.md)。
- **两级证据互补**：类型往返断言只证明结构可还原；运行时语义等价由 golden 双端逐行输出对比证明。

---

## 6. 不在可转换范围内的构造 | Excluded Constructs

| 构造 | 原因 | 替代建议 |
|------|------|---------|
| `extern "C"` 内联汇编 | Dart 无对应 | `--pure-only` 排除 |
| wasm intrinsics | Dart 平台无关 | `--pure-only` 排除 |
| 编译期常量函数 | 跨语言编译期差异 | 保留为字面量 |
| `spawn` 并发原语 | 并发模型不同 | 手动适配 `Isolate` |
| `ref`/`mut` 引用语义 | Dart 默认引用 | 文档标注差异 |

---

## 7. 实现路线 | Implementation Roadmap

| 阶段 | 内容 | 版本 |
|------|------|------|
| ✅ 已实现 | 单层 Option→T?, enum→sealed class, struct→class, trait→abstract class | v0.1.0-v0.5.0 |
| ✅ 已实现 | Result→自定义 sealed class (DCustom) | v0.5.0 |
| ✅ 已实现 | 反向转换管线 Dart→MoonBit | v0.8.0 |
| ✅ 已实现 | 双向同步 + 冲突检测 | v0.9.1 |
| ✅ 已实现 | 嵌套 Option 辅助类 + DResult 结构化节点 + 语义等价分级 + strict 模式 | v0.10.0 |
| ✅ 已实现 | Int 回绕模拟层 + mini 推断器 + 双模式 + golden 双端验证 | v0.11.0 |
| 📋 下一步 | 运行时等价覆盖扩展（更多构造 + CI 集成） | v1.0.0 |
