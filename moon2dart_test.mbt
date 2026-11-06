///|
/// 黑盒测试 — 通过公开 API 验证 transpile 行为。

///|
test "blackbox: transpile fn" {
  let prog = [
    @ast.DFn(
      "square",
      [("x", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("*", @ast.EVar("x"), @ast.EVar("x")),
    ),
  ]
  let result = @moon2dart.transpile(prog)
  assert_true(result.contains("int square(int x)"))
  assert_true(result.contains("return x * x;"))
}

///|
test "blackbox: transpile struct" {
  let prog = [@ast.DStruct("Point", [("x", @ast.MDouble), ("y", @ast.MDouble)])]
  let result = @moon2dart.transpile(prog)
  assert_true(result.contains("class Point"))
  assert_true(result.contains("double x;"))
  assert_true(result.contains("double y;"))
}

///|
test "blackbox: transpile enum" {
  let prog = [@ast.DEnum("Color", ["Red", "Green", "Blue"])]
  let result = @moon2dart.transpile(prog)
  assert_true(result.contains("sealed class Color"))
  assert_true(result.contains("class Red extends Color"))
}

///|
test "blackbox: transpile_type mappings" {
  assert_eq(@moon2dart.transpile_type(@ast.MInt), "int")
  assert_eq(@moon2dart.transpile_type(@ast.MDouble), "double")
  assert_eq(@moon2dart.transpile_type(@ast.MString), "String")
  assert_eq(@moon2dart.transpile_type(@ast.MBool), "bool")
  assert_eq(@moon2dart.transpile_type(@ast.MArray(@ast.MInt)), "List<int>")
  assert_eq(@moon2dart.transpile_type(@ast.MOption(@ast.MString)), "String?")
}

///|
test "blackbox: transpile_expr binop" {
  let expr = @ast.EBinOp("+", @ast.EInt(1), @ast.EInt(2))
  assert_eq(@moon2dart.transpile_expr(expr), "1 + 2")
}
