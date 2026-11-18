///|
/// golden 真值断言 — 32 位回绕语义的 MoonBit 端真值（wasm i32 语义） | Golden ground-truth assertions — MoonBit-side truth of 32-bit wrapping semantics
///
/// 每条断言对应 scripts/golden_check.mjs 对比表的一行；Dart 端（wrapping 模式）必须产出相同值。

///|
test "golden wrap_add overflow wraps" {
  assert_eq(wrap_add(2147483647, 1), -2147483648)
}

///|
test "golden wrap_add lower bound wraps" {
  assert_eq(wrap_add(-2147483647, -1), -2147483648)
}

///|
test "golden wrap_sub wraps to max" {
  assert_eq(wrap_sub(-2147483647, 2), 2147483647)
}

///|
test "golden wrap_mul 2^32 wraps to zero" {
  assert_eq(wrap_mul(65536, 65536), 0)
}

///|
test "golden wrap_mul 10^10 wraps to 1410065408" {
  assert_eq(wrap_mul(100000, 100000), 1410065408)
}

///|
test "golden trunc_div positive" {
  assert_eq(trunc_div(7, 2), 3)
}

///|
test "golden trunc_div negative dividend truncates toward zero" {
  assert_eq(trunc_div(-7, 2), -3)
}

///|
test "golden trunc_div negative divisor truncates toward zero" {
  assert_eq(trunc_div(7, -2), -3)
}

///|
test "golden trunc_rem sign follows dividend" {
  assert_eq(trunc_rem(-7, 2), -1)
  assert_eq(trunc_rem(7, -2), 1)
}

///|
/// INT_MIN/-1 是 **trap 边界**：MoonBit native 硬件异常终止（0xc0000095），
/// Dart 端 mb32Div 显式抛 StateError 模拟 —— 两端行为类别一致（异常终止），
/// 不在本套件内取值断言（见 docs/golden_results.md 边界行为表）。
test "golden int_min computation and wrap-around" {
  let int_min = wrap_add(-2147483647, -1)
  assert_eq(int_min, -2147483648)
  assert_eq(wrap_sub(int_min, 1), 2147483647)
}

///|
test "golden int64 addition stays 64-bit" {
  assert_eq(add64(1073741824, 1073741824), 2147483648L)
}

///|
test "golden double division is ieee754" {
  assert_eq(ratio(7.0, 2.0), 3.5)
}

///|
test "golden int comparison unaffected by wrapping" {
  assert_true(!lt(2147483647, -2147483647))
  assert_true(lt(-2147483647, 2147483647))
}

///|
test "golden string concat semantics" {
  assert_eq(join_str("moon", "bit"), "moonbit")
}
