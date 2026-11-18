///|
fn wrap_add(a : Int32, b : Int32) -> Int32 {
  a + b
}

///|
fn wrap_sub(a : Int32, b : Int32) -> Int32 {
  a - b
}

///|
fn wrap_mul(a : Int32, b : Int32) -> Int32 {
  a * b
}

///|
fn trunc_div(a : Int32, b : Int32) -> Int32 {
  a / b
}

///|
fn trunc_rem(a : Int32, b : Int32) -> Int32 {
  a % b
}

///|
fn add64(a : Int64, b : Int64) -> Int64 {
  a + b
}

///|
fn ratio(a : Double, b : Double) -> Double {
  a / b
}

///|
fn lt(a : Int32, b : Int32) -> Bool {
  a < b
}

///|
fn join_str(a : String, b : String) -> String {
  a + b
}

///|
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
  println(add64(1073741824, 1073741824))
  println(ratio(7.0, 2.0))
  println(lt(2147483647, -2147483647))
  println(join_str("moon", "bit"))
}
