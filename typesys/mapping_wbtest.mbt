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
  assert_true(@ast.MInt.is_pure())
  assert_true(@ast.MArray(@ast.MInt).is_pure())
  assert_true(@ast.MOption(@ast.MString).is_pure())
  assert_true(!@ast.MResult(@ast.MInt, @ast.MString).is_pure())
  assert_true(!@ast.MCustom("MyType").is_pure())
}

///|
test "needs_result_type" {
  assert_true(@ast.MResult(@ast.MInt, @ast.MString).needs_result_type())
  assert_true(!@ast.MInt.needs_result_type())
  assert_true(!@ast.MArray(@ast.MInt).needs_result_type())
}

///|
/// v0.6.0 FFI 类型映射测试。

///|
test "ffi_native_type basic" {
  assert_eq(ffi_native_type(@ast.MInt), "Int32")
  assert_eq(ffi_native_type(@ast.MUInt), "Uint32")
  assert_eq(ffi_native_type(@ast.MInt64), "Int64")
  assert_eq(ffi_native_type(@ast.MUInt64), "Uint64")
  assert_eq(ffi_native_type(@ast.MDouble), "Double")
  assert_eq(ffi_native_type(@ast.MFloat), "Float")
  assert_eq(ffi_native_type(@ast.MBool), "Bool")
  assert_eq(ffi_native_type(@ast.MString), "Pointer<Utf8>")
  assert_eq(ffi_native_type(@ast.MChar), "Uint8")
  assert_eq(ffi_native_type(@ast.MUnit), "Void")
}

///|
test "ffi_native_type composite" {
  assert_eq(ffi_native_type(@ast.MArray(@ast.MInt)), "Pointer<Opaque>")
  assert_eq(ffi_native_type(@ast.MCustom("Handle")), "Pointer<Opaque>")
  assert_eq(ffi_native_type(@ast.MOption(@ast.MInt)), "Pointer<Opaque>")
}

///|
test "ffi_dart_type basic" {
  assert_eq(ffi_dart_type(@ast.MInt), "int")
  assert_eq(ffi_dart_type(@ast.MUInt), "int")
  assert_eq(ffi_dart_type(@ast.MInt64), "int")
  assert_eq(ffi_dart_type(@ast.MDouble), "double")
  assert_eq(ffi_dart_type(@ast.MBool), "bool")
  assert_eq(ffi_dart_type(@ast.MString), "Pointer<Utf8>")
  assert_eq(ffi_dart_type(@ast.MChar), "int")
  assert_eq(ffi_dart_type(@ast.MUnit), "void")
}

///|
test "ffi_dart_type composite" {
  assert_eq(ffi_dart_type(@ast.MArray(@ast.MInt)), "Pointer<Opaque>")
  assert_eq(ffi_dart_type(@ast.MCustom("Handle")), "Pointer<Opaque>")
  assert_eq(ffi_dart_type(@ast.MOption(@ast.MInt)), "Pointer<Opaque>?")
}
