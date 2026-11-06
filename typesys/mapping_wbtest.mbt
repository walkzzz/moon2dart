///|
/// typesys 白盒测试 — 类型映射正确性。

///|
test "map_type basic" {
  assert_eq(map_type(@ast.MInt), DInt)
  assert_eq(map_type(@ast.MUInt), DInt)
  assert_eq(map_type(@ast.MInt64), DInt64)
  assert_eq(map_type(@ast.MDouble), DDouble)
  assert_eq(map_type(@ast.MFloat), DDouble)
  assert_eq(map_type(@ast.MBool), DBool)
  assert_eq(map_type(@ast.MString), DString)
  assert_eq(map_type(@ast.MChar), DRune)
  assert_eq(map_type(@ast.MUnit), DVoid)
}

///|
test "map_type composite" {
  assert_eq(map_type(@ast.MArray(@ast.MInt)), DList(DInt))
  assert_eq(map_type(@ast.MMap(@ast.MString, @ast.MInt)), DMap(DString, DInt))
  assert_eq(map_type(@ast.MSet(@ast.MInt)), DSet(DInt))
  assert_eq(map_type(@ast.MOption(@ast.MInt)), DNullable(DInt))
}

///|
test "emit_dart basic" {
  assert_eq(emit_dart(DInt), "int")
  assert_eq(emit_dart(DInt64), "int")
  assert_eq(emit_dart(DDouble), "double")
  assert_eq(emit_dart(DBool), "bool")
  assert_eq(emit_dart(DString), "String")
  assert_eq(emit_dart(DRune), "int")
  assert_eq(emit_dart(DVoid), "void")
}

///|
test "emit_dart composite" {
  assert_eq(emit_dart(DList(DInt)), "List<int>")
  assert_eq(emit_dart(DMap(DString, DInt)), "Map<String, int>")
  assert_eq(emit_dart(DSet(DInt)), "Set<int>")
  assert_eq(emit_dart(DNullable(DInt)), "int?")
}

///|
test "moon_to_dart_type convenience" {
  assert_eq(moon_to_dart_type(@ast.MInt), "int")
  assert_eq(moon_to_dart_type(@ast.MArray(@ast.MString)), "List<String>")
  assert_eq(moon_to_dart_type(@ast.MOption(@ast.MInt)), "int?")
}

///|
test "is_pure" {
  assert_true(is_pure(@ast.MInt))
  assert_true(is_pure(@ast.MArray(@ast.MInt)))
  assert_true(is_pure(@ast.MOption(@ast.MString)))
  assert_true(!is_pure(@ast.MResult(@ast.MInt, @ast.MString)))
  assert_true(!is_pure(@ast.MCustom("MyType")))
}

///|
test "needs_result_type" {
  assert_true(needs_result_type(@ast.MResult(@ast.MInt, @ast.MString)))
  assert_true(!needs_result_type(@ast.MInt))
  assert_true(!needs_result_type(@ast.MArray(@ast.MInt)))
}
