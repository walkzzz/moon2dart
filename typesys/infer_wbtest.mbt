///|
/// 类型推断器测试 — mini inferencer（v0.11.0 语义保持体系）| Type inference tests — mini inferencer (v0.11.0 semantic preservation)
///
/// 覆盖：字面量推断 / 环境查询 / EBinOp 合并 / 函数签名表 / shim 操作收集 / 模式感知定级。

///|
test "infer_expr_type literals" {
  let env = TypeEnv::make()
  assert_true(infer_expr_type(@ast.EInt(1), env) is Some(@ast.MInt))
  assert_true(infer_expr_type(@ast.EDouble(1.0), env) is Some(@ast.MDouble))
  assert_true(infer_expr_type(@ast.EBool(true), env) is Some(@ast.MBool))
  assert_true(infer_expr_type(@ast.EString("s"), env) is Some(@ast.MString))
}

///|
test "infer_expr_type env lookup" {
  let env = TypeEnv::for_function([], [("x", @ast.MInt)])
  assert_true(infer_expr_type(@ast.EVar("x"), env) is Some(@ast.MInt))
  assert_true(infer_expr_type(@ast.EVar("unknown"), env) is None)
}

///|
test "infer_expr_type binop merges operand type" {
  let env = TypeEnv::for_function([], [("a", @ast.MInt), ("b", @ast.MInt)])
  let e = @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b"))
  assert_true(infer_expr_type(e, env) is Some(@ast.MInt))
}

///|
test "infer_expr_type binop falls back to rhs literal" {
  let env = TypeEnv::for_function([], [("a", @ast.MInt)])
  let e = @ast.EBinOp("+", @ast.EVar("a"), @ast.EInt(1))
  assert_true(infer_expr_type(e, env) is Some(@ast.MInt))
}

///|
test "infer_expr_type call resolves via signature table" {
  let env = TypeEnv::from_decls([
    @ast.DFn("wrap", [], [("v", @ast.MInt)], @ast.MInt, @ast.EVar("v")),
  ])
  let e = @ast.ECall("wrap", [@ast.EInt(1)])
  assert_true(infer_expr_type(e, env) is Some(@ast.MInt))
}

///|
test "infer_expr_type await unwraps future" {
  let env = TypeEnv::for_function([], [("f", @ast.MFuture(@ast.MInt))])
  let e = @ast.EAwait(@ast.EVar("f"))
  assert_true(infer_expr_type(e, env) is Some(@ast.MInt))
}

///|
test "collect_int_arith_ops int arithmetic" {
  let decls = [
    @ast.DFn(
      "add",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "mul",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("*", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let ops = collect_int_arith_ops(decls)
  assert_eq(ops.length(), 2)
  assert_true(ops.contains("+"))
  assert_true(ops.contains("*"))
}

///|
test "collect_int_arith_ops double arithmetic excluded" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MDouble), ("b", @ast.MDouble)],
      @ast.MDouble,
      @ast.EBinOp("/", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  assert_eq(collect_int_arith_ops(decls).length(), 0)
}

///|
test "collect_int_arith_ops deduplicates operators" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp(
        "+",
        @ast.EVar("a"),
        @ast.EBinOp("+", @ast.EVar("a"), @ast.EInt(1)),
      ),
    ),
  ]
  assert_eq(collect_int_arith_ops(decls).length(), 1)
}

///|
test "collect_int_arith_ops empty for non-arithmetic program" {
  let decls = [@ast.DFn("f", [], [], @ast.MString, @ast.EString("hello"))]
  assert_eq(collect_int_arith_ops(decls).length(), 0)
}

///|
/// 模式感知定级 — Wrapping 下 MInt 保持 L1（shim 保证），Fast 下降级 L2 | Mode-aware level — MInt stays L1 under Wrapping, downgrades to L2 under Fast
test "semantic_level_in_mode MInt" {
  assert_true(semantic_level_in_mode(@ast.MInt, @ast.Wrapping) is L1)
  assert_true(semantic_level_in_mode(@ast.MInt, @ast.Fast) is L2)
}

///|
/// UInt64 漏判修复 — 无符号 64 位语义与 MUInt 同级 L3 | UInt64 mis-level fix — unsigned 64-bit is L3 like MUInt
test "semantic_level MUInt64 fixed to L3" {
  assert_true(semantic_level(@ast.MUInt64) is L3)
  assert_true(semantic_level(@ast.MInt64) is L1)
  assert_true(semantic_level(@ast.MUInt) is L3)
  assert_true(semantic_level(@ast.MInt) is L1)
}

///|
test "semantic_level_in_mode leaves other types unchanged" {
  assert_true(semantic_level_in_mode(@ast.MUInt, @ast.Fast) is L3)
  assert_true(semantic_level_in_mode(@ast.MDouble, @ast.Fast) is L1)
}
