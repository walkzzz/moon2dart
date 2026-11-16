# MoonBit → Dart 类型与构造映射规范 | Type Mapping Specification

> v0.10.0 · 2026-11-16 · 完整映射表 + 语义等价分级

## 1. 基础类型映射 | Basic Type Mapping

| MoonBit | Dart | 可纯转换 | 语义等级 | 备注 |
|---------|------|---------|---------|------|
| `Int` | `int` | ✅ | L1 ✅ | 64-bit |
| `UInt` | `int` | ✅ | L3 🔶 | Dart 无 unsigned，转换有符号 |
| `Int64` | `int` | ✅ | L1 ✅ | |
| `UInt64` | `int` | ✅ | L3 🔶 | 同 UInt |
| `Double` | `double` | ✅ | L1 ✅ | |
| `Float` | `double` | ✅ | L3 🔶 | Dart 无 float，转换 double |
| `Bool` | `bool` | ✅ | L1 ✅ | |
| `String` | `String` | ✅ | L1 ✅ | |
| `Char` | `int` | ✅ | L2 ⚠️ | Dart 无 char，转换为 rune (int) |
| `Unit` | `void` | ✅ | L1 ✅ | |

## 2. 复合类型映射 | Composite Type Mapping

| MoonBit | Dart | 可纯转换 | 语义等级 | 备注 |
|---------|------|---------|---------|------|
| `Array[T]` | `List<T>` | ✅ | L1 ✅ | |
| `Map[K,V]` | `Map<K,V>` | ✅ | L1 ✅ | |
| `Set[T]` | `Set<T>` | ✅ | L1 ✅ | |
| `Option[T]` (单层) | `T?` | ✅ | L1 ✅ | Dart null safety |
| `Option[Option[T]]` (嵌套) | `Option<T>` 辅助类 | ✅ | L1 ✅ | 自动生成辅助类保留三分态 |
| `Result[T,E]` | `Result<T,E>` sealed class | ⚠️ | L1 ✅ | DResult 结构化节点 |
| `Future[T]` | `Future<T>` | ✅ | L1 ✅ | |

## 3. 函数映射 | Function Mapping

| MoonBit | Dart | 备注 |
|---------|------|------|
| `fn add(a : Int, b : Int) -> Int` | `int add(int a, int b)` | 顶层函数 |
| `fn Type::meth(self : Type, ..)` | `T meth(..)` 作为 class 方法 | 方法 |
| 闭包 `fn(x) { x + 1 }` | `(x) => x + 1` | 箭头函数 |
| `fn(a, b)` 调用 | `a(b)` 或 `meth(b)` | |

## 4. struct 映射 | Struct Mapping

MoonBit:
```moonbit
struct Point {
  x : Int
  y : Int
}
```
Dart:
```dart
class Point {
  int x;
  int y;
  Point({required this.x, required this.y});
}
```

## 5. enum 映射 | Enum Mapping

MoonBit:
```moonbit
enum Color {
  Red
  Green
  Blue
}
```
Dart (sealed class, Dart 3):
```dart
sealed class Color {}
class Red extends Color {}
class Green extends Color {}
class Blue extends Color {}
```

带数据的 enum:
```moonbit
enum Shape {
  Circle(Double)
  Rect(Double, Double)
}
```
Dart:
```dart
sealed class Shape {}
class Circle extends Shape { final double radius; Circle(this.radius); }
class Rect extends Shape { final double w; final double h; Rect(this.w, this.h); }
```

## 6. trait 映射 | Trait Mapping

| MoonBit | Dart | 可转换 | 备注 |
|---------|------|--------|------|
| `trait Named { name(Self) -> String }` | `abstract class Named { String get name; }` | ✅ | 单 trait |
| `pub(open) trait` 跨包实现 | `mixin` | ⚠️ | 多继承受限 |
| trait 多实现 | `implements` + `mixin` 链 | ⚠️ | 需拆分 |
| `derive(Debug, Eq)` | 生成 `toString()` + `operator ==` | ⚠️ | 样板代码 |

## 7. 模式匹配映射 | Pattern Matching Mapping

MoonBit:
```moonbit
match shape {
  Circle(r) => 3.14 * r * r
  Rect(w, h) => w * h
}
```
Dart (switch expression, Dart 3):
```dart
switch (shape) {
  Circle(:var r) => 3.14 * r * r,
  Rect(:var w, :var h) => w * h,
}
```

## 8. async 映射 | Async Mapping

| MoonBit | Dart | 备注 |
|---------|------|------|
| `async fn` | `Future<T> fn() async` | |
| `await expr` | `await expr` | |
| `spawn` | `Future.microtask` / `Isolate.run` | ⚠️ 语义差异 |

## 9. FFI 映射 | FFI Mapping（混合模式）

MoonBit:
```moonbit
extern "C" fn c_sqrt(x : Double) -> Double
```
Dart (dart:ffi):
```dart
import 'dart:ffi';
final lib = DynamicLibrary.open('libm.so');
final cSqrt = lib.lookupFunction<Double Function(Double), double Function(double)>('sqrt');
```

## 10. 不支持的构造 | Unsupported Constructs

| MoonBit 构造 | 原因 |
|-------------|------|
| 内联汇编 | Dart 无对应 |
| wasm intrinsics | Dart 平台无关 |
| 编译期常量函数 | 转换为字面量，不执行 |
| `pub(open) trait` 跨包多继承 | Dart mixin 限制 |

## 11. 语义等级说明 | Semantic Level Explanation

| 等级 | 标记 | 含义 | 条目数 | strict 模式行为 |
|------|------|------|:------:|----------------|
| L1 完全等价 | ✅ | 往返转换后语义完全一致 | 18 | 正常生成 |
| L2 结构等价 | ⚠️ | 数据结构可还原，操作语义有差异 | 2 | 正常生成 |
| L3 受限等价 | 🔶 | 特定约束下等价，生成 `// [L3-CONSTRAINED]` 注释 | 3 | 允许，标注注释 |
| L4 不等价 | ❌ | 语义丢失，不可往返 | 5 | raise TypeError |

### 11.1 DResult 到 DartType 映射表（v0.10.0 新增）

| MoonBit AST | DartType | 语义等级 | 说明 |
|-------------|----------|---------|------|
| `MResult(ok, err)` | `DResult(map_type(ok), map_type(err))` | L1 ✅ | 结构化节点，反向精确恢复 |
| 旧版 `MResult` | `DCustom("Result<...>")` | — | 已弃用，反向丢失结构 |

### 11.2 嵌套 Option 映射规则

| 层级 | MoonBit | DartType | 语义等级 | 辅助类 |
|------|---------|----------|---------|--------|
| 单层 | `Option[T]` | `DNullable(T')` | L1 ✅ | 不需要 |
| 嵌套 | `Option[Option[T]]` | `DNullable(DNullable(T'))` | L1 ✅ | 自动生成 `Option<T>` |
| 三层+ | `Option[Option[Option[T]]]` | 递归嵌套 | L1 ✅ | 递归包装 |

## 12. 映射表维护 | Mapping Table Maintenance

映射表集中在 `typesys/mapping.mbt`，版本跟随：
- MoonBit 工具链升级 → 更新 MoonType 枚举
- Dart 版本升级 → 更新 emit_dart_type
- 每次映射变更需更新本文档 + 测试