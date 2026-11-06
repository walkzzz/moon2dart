///|
/// ast 黑盒测试 — 验证 AST 节点构造与 derive 正确性。

///|
test "MoonType basic construction" {
  assert_eq(MInt, MInt)
  assert_eq(MString, MString)
  assert_true(MInt != MString)
}

///|
test "MoonType composite construction" {
  let arr = MArray(MInt)
  let map = MMap(MString, MInt)
  let opt = MOption(MBool)
  assert_eq(arr, MArray(MInt))
  assert_eq(map, MMap(MString, MInt))
  assert_eq(opt, MOption(MBool))
}

///|
test "MoonExpr construction" {
  assert_eq(EInt(42), EInt(42))
  assert_eq(EString("hello"), EString("hello"))
  assert_eq(EVar("x"), EVar("x"))
  assert_true(EInt(1) != EInt(2))
}

///|
test "MoonExpr composite" {
  let call = ECall("add", [EInt(1), EInt(2)])
  let binop = EBinOp("+", EVar("a"), EVar("b"))
  let if_ = EIf(EBool(true), EInt(1), EInt(0))
  assert_eq(call, ECall("add", [EInt(1), EInt(2)]))
  assert_eq(binop, EBinOp("+", EVar("a"), EVar("b")))
  assert_eq(if_, EIf(EBool(true), EInt(1), EInt(0)))
}

///|
test "MoonPattern construction" {
  assert_eq(PVar("x"), PVar("x"))
  assert_eq(PInt(42), PInt(42))
  assert_eq(PWild, PWild)
  assert_eq(PCtor("Some", [PVar("x")]), PCtor("Some", [PVar("x")]))
}

///|
test "MoonDecl construction" {
  let fn_ = DFn(
    "add",
    [("a", MInt), ("b", MInt)],
    MInt,
    EBinOp("+", EVar("a"), EVar("b")),
  )
  let struct_ = DStruct("Point", [("x", MInt), ("y", MInt)])
  let enum_ = DEnum("Color", ["Red", "Green", "Blue"])
  assert_eq(
    fn_,
    DFn(
      "add",
      [("a", MInt), ("b", MInt)],
      MInt,
      EBinOp("+", EVar("a"), EVar("b")),
    ),
  )
  assert_eq(struct_, DStruct("Point", [("x", MInt), ("y", MInt)]))
  assert_eq(enum_, DEnum("Color", ["Red", "Green", "Blue"]))
}

///|
test "MoonType Compare ordering" {
  assert_true(MInt < MString)
  assert_true(MBool <= MBool)
  assert_true(MString >= MInt)
}
