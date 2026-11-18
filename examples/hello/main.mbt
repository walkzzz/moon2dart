// 最小转换示例 — MoonBit 源码 | Minimal conversion example — MoonBit source
//
// 转换命令（wrapping 模式，Int 算术生成 mb32* 回绕模拟层）：
//   moon run cmd/main --target native -- convert examples/hello/main.mbt --semantics wrapping > examples/hello/main.dart
//
// 运行对比：MoonBit 端 `moon run golden` 同源码求值；Dart 端 `dart run examples/hello/main.dart` —— 两端输出一致（42）。

fn add(a : Int, b : Int) -> Int { a + b }

fn half(a : Int) -> Int { a / 2 }

fn main {
  println(add(40, 2))
  println(half(7))
}
