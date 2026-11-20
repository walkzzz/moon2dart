///|
/// 数组/循环/绑定语句发射白盒测试（v0.12.0 业务函数子集）
/// White-box tests for array, loop and binding-statement emission.

///|
test "emit array literal / index / length / push" {
  assert_eq(
    emit_dart_expr(@ast.EArrayLit([@ast.EInt(1), @ast.EInt(2)])),
    "[1, 2]",
  )
  assert_eq(emit_dart_expr(@ast.EIndex(@ast.EVar("xs"), @ast.EInt(0))), "xs[0]")
  assert_eq(
    emit_dart_expr(@ast.EMethodCall(@ast.EVar("xs"), "length", [])),
    "xs.length",
  )
  assert_eq(
    emit_dart_expr(@ast.EMethodCall(@ast.EVar("out"), "push", [@ast.EInt(9)])),
    "out.add(9)",
  )
}

///|
test "emit while / let / assign statements" {
  let body = @ast.EBlock([
    @ast.ELet("i", true, None, @ast.EInt(0)),
    @ast.EWhile(
      @ast.EBinOp("<", @ast.EVar("i"), @ast.EInt(2)),
      @ast.EBlock([
        @ast.EAssign("i", @ast.EBinOp("+", @ast.EVar("i"), @ast.EInt(1))),
      ]),
    ),
  ])
  let out = emit_dart_decl(@ast.DFn("f", [], [], @ast.MUnit, body))
  assert_true(out.contains("var i = 0;"))
  assert_true(out.contains("while (i < 2) {"))
  assert_true(out.contains("i = i + 1;"))
}

///|
test "emit typed let uses final/type annotation" {
  let body = @ast.EBlock([
    @ast.ELet("out", false, Some(@ast.MArray(@ast.MInt)), @ast.EArrayLit([])),
    @ast.EVar("out"),
  ])
  let out = emit_dart_decl(@ast.DFn("f", [], [], @ast.MArray(@ast.MInt), body))
  assert_true(out.contains("final List<int> out = [];"))
  assert_true(out.contains("return out;"))
}

///|
test "emit get produces bounds-checked nullable" {
  let out = emit_dart_expr(
    @ast.EMethodCall(@ast.EVar("xs"), "get", [@ast.EInt(1)]),
  )
  assert_true(out.contains("xs).length"))
  assert_true(out.contains(": null"))
}

///|
test "emit collection equality uses structural helper" {
  let env = @typesys.TypeEnv::for_function([], [
    ("a", @ast.MArray(@ast.MInt)),
    ("b", @ast.MArray(@ast.MInt)),
  ])
  let ctx : EmitCtx = {
    env: Some(env),
    mode: @ast.Wrapping,
    nested_option_context: false,
  }
  assert_eq(
    emit_dart_expr_inner(@ast.EBinOp("==", @ast.EVar("a"), @ast.EVar("b")), ctx),
    "mbEquals(a, b)",
  )
  assert_eq(
    emit_dart_expr_inner(@ast.EBinOp("!=", @ast.EVar("a"), @ast.EVar("b")), ctx),
    "!mbEquals(a, b)",
  )
}

///|
test "emit collection equality raw in fast mode" {
  let env = @typesys.TypeEnv::for_function([], [
    ("a", @ast.MArray(@ast.MInt)),
    ("b", @ast.MArray(@ast.MInt)),
  ])
  let ctx : EmitCtx = {
    env: Some(env),
    mode: @ast.Fast,
    nested_option_context: false,
  }
  assert_eq(
    emit_dart_expr_inner(@ast.EBinOp("==", @ast.EVar("a"), @ast.EVar("b")), ctx),
    "a == b",
  )
}
