///|
/// 语义保持端到端测试 — 同一源码两种模式输出对照（v0.11.0） | End-to-end semantics tests — same source, both modes (v0.11.0)
///
/// 覆盖：transpile_source_with_mode Wrapping（溢出保护）/ Fast（L2 标注）/ SemanticsMode 解析。

///|
test "transpile_source_with_mode wrapping protects overflow site" {
  let src = "fn inc(a : Int) -> Int { a + 2147483647 }"
  let result = transpile_source_with_mode(src, @ast.Wrapping)
  assert_true(result.contains("return mb32Add(a, 2147483647);"))
  assert_true(
    result.contains("int mb32Add(int a, int b) => (a + b).toSigned(32);"),
  )
}

///|
test "transpile_source_with_mode fast keeps raw with annotation" {
  let src = "fn inc(a : Int) -> Int { a + 2147483647 }"
  let result = transpile_source_with_mode(src, @ast.Fast)
  assert_true(result.contains("return a + 2147483647;"))
  assert_true(
    result.contains(
      "[L2-SEMANTICS] Int: MoonBit 32-bit wrapping arithmetic vs Dart 64-bit int; overflow behavior differs",
    ),
  )
}

///|
test "transpile_source_with_mode truncating division both modes" {
  let src = "fn half(a : Int) -> Int { a / 2 }"
  let wrapping = transpile_source_with_mode(src, @ast.Wrapping)
  assert_true(wrapping.contains("return mb32Div(a, 2);"))
  let fast = transpile_source_with_mode(src, @ast.Fast)
  assert_true(fast.contains("return a ~/ 2;"))
}

///|
test "transpile_source wrapping double division untouched" {
  let src = "fn ratio(a : Double, b : Double) -> Double { a / b }"
  let result = transpile_source_with_mode(src, @ast.Wrapping)
  assert_true(result.contains("return a / b;"))
  assert_true(!result.contains("mb32"))
}

///|
test "semantics_mode_parse" {
  assert_true(@ast.SemanticsMode::parse("fast") is @ast.Fast)
  assert_true(@ast.SemanticsMode::parse("wrapping") is @ast.Wrapping)
  assert_true(@ast.SemanticsMode::parse("unknown") is @ast.Wrapping)
}
