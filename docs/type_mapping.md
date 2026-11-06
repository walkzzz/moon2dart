# MoonBit → Dart 类型与构造映射规范

> 已实现 v0.1.0 · 2026-11-06 · 完整映射表

## 1. 基础类型映射

| MoonBit | Dart | 可纯转换 | 备注 |
|---------|------|---------|------|
| `Int` | `int` | ✅ | 64-bit |
| `UInt` | `int` | ✅ | Dart 无 unsigned，转换有符号 |
| `Int64` | `int` | ✅ | |
| `UInt64` | `int` | ✅ | 同上 |
| `Double` | `double` | ✅ | |
| `Float` | `double` | ✅ | Dart 无 float，转换 double |
| `Bool` | `bool` | ✅ | |
| `String` | `String` | ✅ | |
| `Char` | `int` | ✅ | Dart 无 char，转换为 rune (int) |
| `Unit` | `void` | ✅ | |

## 2. 复合类型映射

| MoonBit | Dart | 可纯转换 | 备注 |
|---------|------|---------|------|
| `Array[T]` | `List<T>` | ✅ | |
| `Map[K,V]` | `Map<K,V>` | ✅ | |
| `Set[T]` | `Set<T>` | ✅ | |
| `Option[T]` | `T?` | ✅ | Dart null safety |
| `Result[T,E]` | `Result<T>` | ⚠️ | 需生成自定义 Result class |
| `T*` (引用) | `T` | ✅ | Dart 默认引用语义 |
| `(T1, T2)` | `(T1, T2)` | ✅ | Dart 3 record |
| `Bytes` | `Uint8List` | ⚠️ | 需 dart:typed_data |

## 3. 函数映射

| MoonBit | Dart | 备注 |
|---------|------|------|
| `fn add(a : Int, b : Int) -> Int` | `int add(int a, int b)` | 顶层函数 |
| `fn Type::meth(self : Type, ..)` | `T meth(..)` 作为 class 方法 | 方法 |
| 闭包 `fn(x) { x + 1 }` | `(x) => x + 1` | 箭头函数 |
| `fn(a, b)` 调用 | `a(b)` 或 `meth(b)` | |

## 4. struct 映射

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

## 5. enum 映射

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

## 6. trait 映射

| MoonBit | Dart | 可转换 | 备注 |
|---------|------|--------|------|
| `trait Named { name(Self) -> String }` | `abstract class Named { String get name; }` | ✅ | 单 trait |
| `pub(open) trait` 跨包实现 | `mixin` | ⚠️ | 多继承受限 |
| trait 多实现 | `implements` + `mixin` 链 | ⚠️ | 需拆分 |
| `derive(Debug, Eq)` | 生成 `toString()` + `operator ==` | ⚠️ | 样板代码 |

## 7. 模式匹配映射

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

## 8. async 映射

| MoonBit | Dart | 备注 |
|---------|------|------|
| `async fn` | `Future<T> fn() async` | |
| `await expr` | `await expr` | |
| `spawn` | `Future.microtask` / `Isolate.run` | ⚠️ 语义差异 |

## 9. FFI 映射（混合模式）

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

## 10. 不支持的构造（明确报错）

| MoonBit 构造 | 原因 |
|-------------|------|
| 内联汇编 | Dart 无对应 |
| wasm intrinsics | Dart 平台无关 |
| 编译期常量函数 | 转换为字面量，不执行 |
| `pub(open) trait` 跨包多继承 | Dart mixin 限制 |

## 11. 映射表维护

映射表集中在 `typesys/mapping.mbt`，版本跟随：
- MoonBit 工具链升级 → 更新 MoonType 枚举
- Dart 版本升级 → 更新 emit_dart_type
- 每次映射变更需更新本文档 + 测试