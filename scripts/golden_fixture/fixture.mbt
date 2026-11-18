// golden 转换素材 — 供 moon2dart CLI（wrapping 模式）转换为 Dart 后由 Dart SDK 实跑。
// 业务函数与 golden/golden.mbt 保持文本一致；MoonBit 端真值见 golden 包（moon run golden）。
// 注：本文件位于 scripts/ 下，不属于任何 moon 包，不会被 MoonBit 编译。

fn wrap_add(a : Int, b : Int) -> Int { a + b }

fn wrap_sub(a : Int, b : Int) -> Int { a - b }

fn wrap_mul(a : Int, b : Int) -> Int { a * b }

fn trunc_div(a : Int, b : Int) -> Int { a / b }

fn trunc_rem(a : Int, b : Int) -> Int { a % b }

fn add64(a : Int64, b : Int64) -> Int64 { a + b }

fn ratio(a : Double, b : Double) -> Double { a / b }

fn lt(a : Int, b : Int) -> Bool { a < b }

fn join_str(a : String, b : String) -> String { a + b }

fn main {
  println(wrap_add(2147483647, 1))
  println(wrap_add(-2147483647, -1))
  println(wrap_sub(-2147483647, 2))
  println(wrap_mul(65536, 65536))
  println(wrap_mul(100000, 100000))
  println(trunc_div(7, 2))
  println(trunc_div(-7, 2))
  println(trunc_div(7, -2))
  println(trunc_rem(-7, 2))
  println(trunc_rem(7, -2))
  println(trunc_div(wrap_add(-2147483647, -1), -1))
  println(add64(1073741824, 1073741824))
  println(ratio(7.0, 2.0))
  println(lt(2147483647, -2147483647))
  println(join_str("moon", "bit"))
}
