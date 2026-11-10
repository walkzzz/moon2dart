///|
test "DartType: basic construction" {
  assert_true(DInt is DInt)
  assert_true(DDouble is DDouble)
  assert_true(DBool is DBool)
  assert_true(DString is DString)
  assert_true(DRune is DRune)
  assert_true(DVoid is DVoid)
}

///|
test "DartType: composite construction" {
  assert_true(DList(DInt) is DList(_))
  assert_true(DMap(DString, DInt) is DMap(_, _))
  assert_true(DSet(DDouble) is DSet(_))
  assert_true(DNullable(DInt) is DNullable(_))
  assert_true(DFuture(DInt) is DFuture(_))
  assert_true(DCustom("MyType") is DCustom(_))
}

///|
test "DartExpr: literals" {
  assert_true(DIntLit(42) is DIntLit(_))
  assert_true(DDoubleLit(3.14) is DDoubleLit(_))
  assert_true(DBoolLit(true) is DBoolLit(_))
  assert_true(DStringLit("hello") is DStringLit(_))
  assert_true(DNullLit is DNullLit)
}

///|
test "DartExpr: references and calls" {
  assert_true(DVarRef("x") is DVarRef(_))
  assert_true(
    DFunctionCall("add", [DIntLit(1), DIntLit(2)]) is DFunctionCall(_, _),
  )
  assert_true(DMethodCall("obj", "toString", []) is DMethodCall(_, _, _))
}

///|
test "DartExpr: binary op and if" {
  assert_true(DBinOp("+", DIntLit(1), DIntLit(2)) is DBinOp(_, _, _))
  assert_true(
    DIfExpr(DBoolLit(true), DIntLit(1), DIntLit(0)) is DIfExpr(_, _, _),
  )
}

///|
test "DartExpr: switch and await" {
  assert_true(
    DSwitchExpr(DVarRef("x"), [(DPWild, DIntLit(0))]) is DSwitchExpr(_, _),
  )
  assert_true(DAwaitExpr(DVarRef("future")) is DAwaitExpr(_))
}

///|
test "DartExpr: arrow function" {
  assert_true(DArrowFn(["x"], DVarRef("x")) is DArrowFn(_, _))
}

///|
test "DartPattern: variants" {
  assert_true(DPVar("x") is DPVar(_))
  assert_true(DPInt(42) is DPInt(_))
  assert_true(DPString("hello") is DPString(_))
  assert_true(DPWild is DPWild)
  assert_true(DPNull is DPNull)
  assert_true(DPCtor("Ok", [DPVar("value")]) is DPCtor(_, _))
}

///|
test "DartDecl: top-level function" {
  let decl = DTopFn(
    "add",
    [],
    [("a", DInt), ("b", DInt)],
    DInt,
    DBinOp("+", DVarRef("a"), DVarRef("b")),
  )
  assert_true(decl is DTopFn(_, _, _, _, _))
}

///|
test "DartDecl: async function" {
  let decl = DAsyncTopFn("fetch", [], [], DInt, DIntLit(42))
  assert_true(decl is DAsyncTopFn(_, _, _, _, _))
}

///|
test "DartDecl: class" {
  let m = DartMethod::{
    name: "toString",
    params: [],
    ret_type: DString,
    body: DStringLit("Point"),
    is_async: false,
  }
  let decl = DClass("Point", [], [("x", DInt), ("y", DInt)], [m])
  assert_true(decl is DClass(_, _, _, _))
}

///|
test "DartDecl: sealed class" {
  let v = DartVariant::{ name: "Red", fields: [], }
  let decl = DSealedClass("Color", [v])
  assert_true(decl is DSealedClass(_, _))
}

///|
test "DartDecl: abstract class" {
  let m = DartMethod::{
    name: "name",
    params: [],
    ret_type: DString,
    body: DStringLit(" unnamed"),
    is_async: false,
  }
  let decl = DAbstractClass("Named", [m])
  assert_true(decl is DAbstractClass(_, _))
}

///|
test "DartMethod: construction" {
  let m = DartMethod::{
    name: "add",
    params: [("a", DInt), ("b", DInt)],
    ret_type: DInt,
    body: DBinOp("+", DVarRef("a"), DVarRef("b")),
    is_async: false,
  }
  assert_eq(m.name, "add")
  assert_false(m.is_async)
}

///|
test "DartVariant: construction" {
  let v = DartVariant::{ name: "Circle", fields: [("radius", DDouble)], }
  assert_eq(v.name, "Circle")
  assert_true(v.fields.length() == 1)
}
