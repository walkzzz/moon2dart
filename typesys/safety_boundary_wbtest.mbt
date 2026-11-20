///|
/// 安全边界白盒测试 — 未解析算术收集、集合定级、局部 let 绑定推断（v0.12.0）
/// White-box tests for the safety boundary: unresolved arithmetic, collection levels, local let inference.

///|
test "collect_unresolved_arith reports unknown operands" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [],
      @ast.MInt,
      @ast.EBinOp("+", @ast.ECall("g", []), @ast.ECall("h", [])),
    ),
  ]
  let ds = collect_unresolved_arith(decls)
  assert_eq(ds.length(), 1)
  assert_eq(ds[0].code, "UNRESOLVED_ARITH")
  assert_eq(ds[0].site, "f")
}

///|
test "collect_unresolved_arith accepts one-sided unknown? no — requires both" {
  // 只有一侧未知也不放过：安全边界要求操作数类型确认 | one unknown side is still unresolved
  let decls = [
    @ast.DFn(
      "f",
      [],
      [],
      @ast.MInt,
      @ast.EBinOp("+", @ast.ECall("g", []), @ast.EInt(1)),
    ),
  ]
  assert_eq(collect_unresolved_arith(decls).length(), 1)
}

///|
test "collect_unresolved_arith treats annotated local as resolved" {
  let body = @ast.EBlock([
    @ast.ELet("i", true, None, @ast.EInt(0)),
    @ast.EWhile(
      @ast.EBinOp("<", @ast.EVar("i"), @ast.EInt(3)),
      @ast.EBlock([
        @ast.EAssign("i", @ast.EBinOp("+", @ast.EVar("i"), @ast.EInt(1))),
      ]),
    ),
    @ast.EVar("i"),
  ])
  let decls = [@ast.DFn("f", [], [], @ast.MInt, body)]
  assert_eq(collect_unresolved_arith(decls).length(), 0)
}

///|
test "collect_unresolved_arith ignores annotated function params" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  assert_eq(collect_unresolved_arith(decls).length(), 0)
}

///|
test "semantic_level array/map/set are L2" {
  assert_true(semantic_level(@ast.MArray(@ast.MInt)) is L2)
  assert_true(semantic_level(@ast.MMap(@ast.MInt, @ast.MString)) is L2)
  assert_true(semantic_level(@ast.MSet(@ast.MString)) is L2)
  assert_true(semantic_level(@ast.MArray(@ast.MUInt)) is L3)
  assert_true(semantic_level(@ast.MArray(@ast.MCustom("Channel"))) is L4)
}

///|
test "collect_degraded_types records L3 collection" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("xs", @ast.MArray(@ast.MUInt))],
      @ast.MUnit,
      @ast.EVar("xs"),
    ),
  ]
  let ds = collect_degraded_types(decls)
  assert_true(ds.length() >= 1)
  assert_eq(ds[0].code, "L3_TYPE")
}

///|
test "bind_local_lets enables inference for later uses" {
  let env = TypeEnv::make()
  let body = @ast.EBlock([
    @ast.ELet("i", true, None, @ast.EInt(0)),
    @ast.EBinOp("+", @ast.EVar("i"), @ast.EInt(1)),
  ])
  bind_local_lets(body, env)
  assert_true(infer_expr_type(@ast.EVar("i"), env) is Some(@ast.MInt))
  assert_true(
    infer_expr_type(@ast.EBinOp("+", @ast.EVar("i"), @ast.EInt(1)), env)
    is Some(@ast.MInt),
  )
}

///|
test "infer array / index / method call" {
  let env = TypeEnv::for_function([], [("xs", @ast.MArray(@ast.MInt))])
  assert_true(
    infer_expr_type(@ast.EArrayLit([@ast.EInt(1)]), env)
    is Some(@ast.MArray(@ast.MInt)),
  )
  assert_true(
    infer_expr_type(@ast.EIndex(@ast.EVar("xs"), @ast.EInt(0)), env)
    is Some(@ast.MInt),
  )
  assert_true(
    infer_expr_type(@ast.EMethodCall(@ast.EVar("xs"), "length", []), env)
    is Some(@ast.MInt),
  )
  assert_true(
    infer_expr_type(
      @ast.EMethodCall(@ast.EVar("xs"), "get", [@ast.EInt(0)]),
      env,
    )
    is Some(@ast.MOption(@ast.MInt)),
  )
}
