///|
/// 语义保持发射测试 — Wrapping/Fast 双模式（v0.11.0） | Semantics emission tests — Wrapping/Fast dual modes (v0.11.0)
///
/// 覆盖：Int 算术 mb32* shim / 整除与取余修正 / Int64 与 Double 裸发 / shim 按需生成 / Fast 模式 L2 诊断。

///|
test "emit_dart_program_with_mode wrapping int add" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("return mb32Add(a, b);"))
  assert_true(
    result.contains("int mb32Add(int a, int b) => (a + b).toSigned(32);"),
  )
}

///|
test "emit_dart_program_with_mode wrapping div and rem" {
  let decls = [
    @ast.DFn(
      "q",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("/", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "r",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("%", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("return mb32Div(a, b);"))
  assert_true(result.contains("return mb32Rem(a, b);"))
  assert_true(
    result.contains("int mb32Div(int a, int b) => (a ~/ b).toSigned(32);"),
  )
  assert_true(
    result.contains("int mb32Rem(int a, int b) => a.remainder(b).toSigned(32);"),
  )
}

///|
test "emit_dart_program_with_mode fast raw with L2 annotation" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Fast)
  assert_true(result.contains("return a + b;"))
  assert_true(result.contains("[L2-SEMANTICS] Int: MoonBit 32-bit wrapping arithmetic vs Dart 64-bit int; overflow behavior differs"))
  assert_true(!result.contains("mb32Add"))
}

///|
test "emit_dart_program_with_mode fast div rem fixes" {
  let decls = [
    @ast.DFn(
      "q",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("/", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "r",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("%", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Fast)
  assert_true(result.contains("return a ~/ b;"))
  assert_true(result.contains("return a.remainder(b);"))
}

///|
test "emit_dart_program_with_mode double division stays raw" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MDouble), ("b", @ast.MDouble)],
      @ast.MDouble,
      @ast.EBinOp("/", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("return a / b;"))
  assert_true(!result.contains("mb32"))
}

///|
test "emit_dart_program_with_mode int64 raw arithmetic" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt64), ("b", @ast.MInt64)],
      @ast.MInt64,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "g",
      [],
      [("a", @ast.MInt64), ("b", @ast.MInt64)],
      @ast.MInt64,
      @ast.EBinOp("/", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("return a + b;"))
  assert_true(result.contains("return a ~/ b;"))
  assert_true(!result.contains("mb32"))
}

///|
test "wrapping shim generated on demand only" {
  let decls = [
    @ast.DFn(
      "f",
      [],
      [("a", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EInt(1)),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("int mb32Add"))
  assert_true(!result.contains("mb32Mul"))
  assert_true(!result.contains("mb32Div"))
}

///|
test "wrapping shim absent without int arithmetic" {
  let decls = [
    @ast.DFn("f", [], [], @ast.MString, @ast.EString("hello")),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(!result.contains("mb32"))
}

///|
test "wrapping shim covers int comparison raw emission" {
  let decls = [
    @ast.DFn(
      "lt",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MBool,
      @ast.EBinOp("<", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_dart_program_with_mode(decls, @ast.Wrapping)
  assert_true(result.contains("return a < b;"))
  assert_true(!result.contains("mb32"))
}
