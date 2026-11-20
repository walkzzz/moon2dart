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

///|
/// v0.10.0 DResult + 嵌套 Option + strict 模式测试。

///|
test "map_type DResult" {
  let result = map_type(@ast.MResult(@ast.MInt, @ast.MString))
  assert_eq(result, DResult(DInt, DString))
}

///|
test "emit_dart DResult" {
  let result = emit_dart(DResult(DInt, DString))
  assert_eq(result, "Result<int, String>")
}

///|
test "map_type nested Option double nullable" {
  let nested = @ast.MOption(@ast.MOption(@ast.MInt))
  let result = map_type(nested)
  assert_eq(result, DNullable(DNullable(DInt)))
}

///|
test "emit_dart double nullable" {
  let result = emit_dart(DNullable(DNullable(DInt)))
  assert_eq(result, "int??")
}

///|
test "moon_to_dart_type Result" {
  let result = moon_to_dart_type(@ast.MResult(@ast.MInt, @ast.MString))
  assert_eq(result, "Result<int, String>")
}

///|
test "needs_option_class with nested Option" {
  let decls = [
    @ast.DFn(
      "nested_opt",
      [],
      [],
      @ast.MOption(@ast.MOption(@ast.MInt)),
      @ast.ECall("Some", [@ast.ECall("Some", [@ast.EInt(42)])]),
    ),
  ]
  assert_true(needs_option_class(decls))
}

///|
test "needs_option_class without nested Option" {
  let decls = [
    @ast.DFn(
      "simple_opt",
      [],
      [],
      @ast.MOption(@ast.MInt),
      @ast.ECall("Some", [@ast.EInt(42)]),
    ),
  ]
  assert_true(!needs_option_class(decls))
}

///|
test "semantic_level L1 basic types" {
  assert_eq(semantic_level(@ast.MInt), L1)
  assert_eq(semantic_level(@ast.MBool), L1)
  assert_eq(semantic_level(@ast.MString), L1)
  assert_eq(semantic_level(@ast.MOption(@ast.MInt)), L1)
  assert_eq(semantic_level(@ast.MResult(@ast.MInt, @ast.MString)), L1)
}

///|
test "semantic_level L2 collections (Array/Map/Set)" {
  assert_eq(semantic_level(@ast.MArray(@ast.MInt)), L2)
  assert_eq(semantic_level(@ast.MMap(@ast.MString, @ast.MInt)), L2)
  assert_eq(semantic_level(@ast.MSet(@ast.MInt)), L2)
  assert_eq(semantic_level(@ast.MOption(@ast.MArray(@ast.MInt))), L2)
}

///|
test "semantic_level L3 constrained types" {
  assert_eq(semantic_level(@ast.MUInt), L3)
  assert_eq(semantic_level(@ast.MFloat), L3)
  assert_eq(semantic_level(@ast.MChar), L3)
}

///|
test "map_type_strict L1 types pass" {
  let result = map_type_strict(@ast.MInt)
  assert_eq(result, DInt)
  let result2 = map_type_strict(@ast.MResult(@ast.MInt, @ast.MString))
  assert_eq(result2, DResult(DInt, DString))
}

///|
test "map_type_strict L3 types pass with mapping" {
  let result = map_type_strict(@ast.MUInt)
  assert_eq(result, DInt)
  let result2 = map_type_strict(@ast.MFloat)
  assert_eq(result2, DDouble)
}

///|
test "map_type_strict L4 types raise error" {
  let mut raised = false
  try {
    let _ = map_type_strict(@ast.MCustom("ForeignFunction"))
  } catch {
    @ast.Moon2DartError::TypeError(msg) => {
      assert_true(msg.contains("L4-INEQUIVALENT"))
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
}

///|
test "is_nested_option from ast" {
  assert_true(@ast.is_nested_option(@ast.MOption(@ast.MOption(@ast.MInt))))
  assert_true(!@ast.is_nested_option(@ast.MOption(@ast.MInt)))
  assert_true(!@ast.is_nested_option(@ast.MInt))
}

///|
/// v0.10.0 US2 Result 往返测试（类型映射层面）。

///|
test "DResult map_type not DCustom" {
  let moon_type = @ast.MResult(@ast.MInt, @ast.MString)
  let dart_type = map_type(moon_type)
  assert_eq(dart_type, DResult(DInt, DString))
  // DResult should NOT be DCustom
  assert_true(!(dart_type is DCustom(_)))
  assert_true(dart_type is DResult(_, _))
}

///|
test "DResult nested Result" {
  let moon_type = @ast.MResult(
    @ast.MResult(@ast.MInt, @ast.MString),
    @ast.MBool,
  )
  let dart_type = map_type(moon_type)
  assert_eq(dart_type, DResult(DResult(DInt, DString), DBool))
  let dart_str = emit_dart(dart_type)
  assert_eq(dart_str, "Result<Result<int, String>, bool>")
}

///|
test "DResult with Option" {
  let moon_type = @ast.MResult(@ast.MOption(@ast.MInt), @ast.MString)
  let dart_type = map_type(moon_type)
  assert_eq(dart_type, DResult(DNullable(DInt), DString))
  let dart_str = emit_dart(dart_type)
  assert_eq(dart_str, "Result<int?, String>")
}

///|
test "DResult with nested Option" {
  let moon_type = @ast.MResult(
    @ast.MOption(@ast.MOption(@ast.MInt)),
    @ast.MString,
  )
  let dart_type = map_type(moon_type)
  assert_eq(dart_type, DResult(DNullable(DNullable(DInt)), DString))
}

///|
test "DResult with Array" {
  let moon_type = @ast.MResult(@ast.MArray(@ast.MInt), @ast.MString)
  let dart_type = map_type(moon_type)
  assert_eq(dart_type, DResult(DList(DInt), DString))
  let dart_str = emit_dart(dart_type)
  assert_eq(dart_str, "Result<List<int>, String>")
}

///|
test "DResult semantic level L2 when collection nested" {
  assert_eq(semantic_level(@ast.MResult(@ast.MInt, @ast.MString)), L1)
  assert_eq(
    semantic_level(@ast.MResult(@ast.MArray(@ast.MInt), @ast.MString)),
    L2,
  )
}

///|
test "semantic_level L4 composite" {
  assert_eq(semantic_level(@ast.MArray(@ast.MCustom("ForeignFunction"))), L4)
  assert_eq(semantic_level(@ast.MOption(@ast.MCustom("Channel"))), L4)
}

///|
test "semantic_level L3 composite" {
  assert_eq(semantic_level(@ast.MArray(@ast.MUInt)), L3)
  assert_eq(semantic_level(@ast.MOption(@ast.MFloat)), L3)
}

///|
/// v0.10.0 US3 映射分类测试 — L1 全自动往返测试。

///|
test "L1 round-trip: Int" {
  let t = @ast.MInt
  let dart = map_type(t)
  assert_eq(dart, DInt)
  let dart_str = emit_dart(dart)
  assert_eq(dart_str, "int")
}

///|
test "L1 round-trip: Int64" {
  let t = @ast.MInt64
  let dart = map_type(t)
  assert_eq(dart, DInt64)
}

///|
test "L1 round-trip: Double" {
  let t = @ast.MDouble
  let dart = map_type(t)
  assert_eq(dart, DDouble)
}

///|
test "L1 round-trip: Bool" {
  let t = @ast.MBool
  let dart = map_type(t)
  assert_eq(dart, DBool)
}

///|
test "L1 round-trip: String" {
  let t = @ast.MString
  let dart = map_type(t)
  assert_eq(dart, DString)
}

///|
test "L1 round-trip: Unit" {
  let t = @ast.MUnit
  let dart = map_type(t)
  assert_eq(dart, DVoid)
}

///|
test "L1 round-trip: Array[Int]" {
  let t = @ast.MArray(@ast.MInt)
  let dart = map_type(t)
  assert_eq(dart, DList(DInt))
  assert_eq(emit_dart(dart), "List<int>")
}

///|
test "L1 round-trip: Map[String,Int]" {
  let t = @ast.MMap(@ast.MString, @ast.MInt)
  let dart = map_type(t)
  assert_eq(dart, DMap(DString, DInt))
}

///|
test "L1 round-trip: Set[Int]" {
  let t = @ast.MSet(@ast.MInt)
  let dart = map_type(t)
  assert_eq(dart, DSet(DInt))
}

///|
test "L1 round-trip: Option[Int] single layer" {
  let t = @ast.MOption(@ast.MInt)
  let dart = map_type(t)
  assert_eq(dart, DNullable(DInt))
}

///|
test "L1 round-trip: Option[Option[Int]] nested" {
  let t = @ast.MOption(@ast.MOption(@ast.MInt))
  let dart = map_type(t)
  assert_eq(dart, DNullable(DNullable(DInt)))
}

///|
test "L1 round-trip: Result[Int,String]" {
  let t = @ast.MResult(@ast.MInt, @ast.MString)
  let dart = map_type(t)
  assert_eq(dart, DResult(DInt, DString))
}

///|
test "L1 round-trip: Future[Int]" {
  let t = @ast.MFuture(@ast.MInt)
  let dart = map_type(t)
  assert_eq(dart, DFuture(DInt))
}

///|
test "L1 round-trip: Array[Option[Int]]" {
  let t = @ast.MArray(@ast.MOption(@ast.MInt))
  let dart = map_type(t)
  assert_eq(dart, DList(DNullable(DInt)))
}

///|
test "L1 round-trip: Result[Array[Int],String]" {
  let t = @ast.MResult(@ast.MArray(@ast.MInt), @ast.MString)
  let dart = map_type(t)
  assert_eq(dart, DResult(DList(DInt), DString))
}

///|
test "L1 round-trip: Option[Result[Int,String]]" {
  let t = @ast.MOption(@ast.MResult(@ast.MInt, @ast.MString))
  let dart = map_type(t)
  assert_eq(dart, DNullable(DResult(DInt, DString)))
}

///|
test "L1 round-trip: Map[String,Result[Int,String]]" {
  let t = @ast.MMap(@ast.MString, @ast.MResult(@ast.MInt, @ast.MString))
  let dart = map_type(t)
  assert_eq(dart, DMap(DString, DResult(DInt, DString)))
}

///|
test "L1 round-trip: Result[Result[Int,String],Bool]" {
  let t = @ast.MResult(@ast.MResult(@ast.MInt, @ast.MString), @ast.MBool)
  let dart = map_type(t)
  assert_eq(dart, DResult(DResult(DInt, DString), DBool))
}

///|
/// L2 结构等价测试。

///|
test "L2 structural: Char→DRune" {
  let t = @ast.MChar
  let dart = map_type(t)
  assert_eq(dart, DRune)
  assert_eq(emit_dart(dart), "int")
}

///|
test "L2 structural: Int64→DInt64 maps to int" {
  let t = @ast.MInt64
  let dart = map_type(t)
  assert_eq(dart, DInt64)
  assert_eq(emit_dart(dart), "int")
}

///|
/// L3 受限测试。

///|
test "L3 constrained: UInt semantic loss" {
  let t = @ast.MUInt
  let level = semantic_level(t)
  assert_eq(level, L3)
  let dart = map_type(t)
  assert_eq(dart, DInt)
  // 映射可用但语义有损
}

///|
test "L3 constrained: Float precision promotion" {
  let t = @ast.MFloat
  let level = semantic_level(t)
  assert_eq(level, L3)
  let dart = map_type(t)
  assert_eq(dart, DDouble)
}

///|
test "L3 constrained: Char→int constrained" {
  let t = @ast.MChar
  let level = semantic_level(t)
  assert_eq(level, L3)
}

///|
/// L4 拒绝测试。

///|
test "L4 reject: ForeignFunction strict raises" {
  let mut raised = false
  try {
    let _ = map_type_strict(@ast.MCustom("ForeignFunction"))
  } catch {
    @ast.Moon2DartError::TypeError(msg) => {
      assert_true(msg.contains("L4-INEQUIVALENT"))
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
}

///|
test "L4 reject: Channel strict raises" {
  let mut raised = false
  try {
    let _ = map_type_strict(@ast.MCustom("Channel"))
  } catch {
    @ast.Moon2DartError::TypeError(msg) => {
      assert_true(msg.contains("L4-INEQUIVALENT"))
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
}

///|
test "L4 reject: Spawn strict raises" {
  let mut raised = false
  try {
    let _ = map_type_strict(@ast.MCustom("Spawn"))
  } catch {
    @ast.Moon2DartError::TypeError(msg) => {
      assert_true(msg.contains("L4-INEQUIVALENT"))
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
}

///|
test "L4 reject: Array[ForeignFunction] strict raises" {
  let mut raised = false
  try {
    let _ = map_type_strict(@ast.MArray(@ast.MCustom("ForeignFunction")))
  } catch {
    @ast.Moon2DartError::TypeError(msg) => {
      assert_true(msg.contains("L4-INEQUIVALENT"))
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
}

///|
test "L4 reject: non-strict mode allows L4 but maps" {
  // 非严格模式下 L4 类型正常映射为 DCustom
  let result = map_type(@ast.MCustom("ForeignFunction"))
  assert_eq(result, DCustom("ForeignFunction"))
}

///|
/// v0.10.0 US4 — assert_round_trip 测试。

///|
test "assert_round_trip: MInt" {
  assert_true(assert_round_trip(@ast.MInt))
}

///|
test "assert_round_trip: MBool" {
  assert_true(assert_round_trip(@ast.MBool))
}

///|
test "assert_round_trip: MString" {
  assert_true(assert_round_trip(@ast.MString))
}

///|
test "assert_round_trip: MDouble" {
  assert_true(assert_round_trip(@ast.MDouble))
}

///|
test "assert_round_trip: MArray[MInt]" {
  assert_true(assert_round_trip(@ast.MArray(@ast.MInt)))
}

///|
test "assert_round_trip: MMap[String,Int]" {
  assert_true(assert_round_trip(@ast.MMap(@ast.MString, @ast.MInt)))
}

///|
test "assert_round_trip: MSet[Int]" {
  assert_true(assert_round_trip(@ast.MSet(@ast.MInt)))
}

///|
test "assert_round_trip: MOption[MInt] single" {
  assert_true(assert_round_trip(@ast.MOption(@ast.MInt)))
}

///|
test "assert_round_trip: MOption[MOption[MInt]] nested" {
  assert_true(assert_round_trip(@ast.MOption(@ast.MOption(@ast.MInt))))
}

///|
test "assert_round_trip: MResult[Int,String]" {
  assert_true(assert_round_trip(@ast.MResult(@ast.MInt, @ast.MString)))
}

///|
test "assert_round_trip: MFuture[Int]" {
  assert_true(assert_round_trip(@ast.MFuture(@ast.MInt)))
}

///|
test "assert_round_trip: nested Result[Result[Int,String],Bool]" {
  assert_true(
    assert_round_trip(
      @ast.MResult(@ast.MResult(@ast.MInt, @ast.MString), @ast.MBool),
    ),
  )
}

///|
test "assert_round_trip: Array[Option[Int]]" {
  assert_true(assert_round_trip(@ast.MArray(@ast.MOption(@ast.MInt))))
}

///|
/// v0.10.0 US4 — assert_value_domain 测试。

///|
test "assert_value_domain: L1 Int" {
  assert_true(assert_value_domain(@ast.MInt, L1))
}

///|
test "assert_value_domain: L1 Option[Int]" {
  assert_true(assert_value_domain(@ast.MOption(@ast.MInt), L1))
}

///|
test "assert_value_domain: L1 Result[Int,String]" {
  assert_true(assert_value_domain(@ast.MResult(@ast.MInt, @ast.MString), L1))
}

///|
test "assert_value_domain: L3 UInt" {
  assert_true(assert_value_domain(@ast.MUInt, L3))
}

///|
test "assert_value_domain: L3 Float" {
  assert_true(assert_value_domain(@ast.MFloat, L3))
}

///|
test "assert_value_domain: L4 ForeignFunction" {
  assert_true(assert_value_domain(@ast.MCustom("ForeignFunction"), L4))
}

///|
test "assert_value_domain: L4 Channel" {
  assert_true(assert_value_domain(@ast.MCustom("Channel"), L4))
}

///|
/// v0.10.0 US4 — 变异测试（mutation tests）。
/// 这些测试验证断言能检测到已知缺陷。

///|
test "mutation: nested Option collapse detected by round-trip" {
  // 正确映射：MOption(MOption(Int)) → DNullable(DNullable(DInt))
  // 如果映射塌缩为 DNullable(DInt)，round-trip 将失败
  let correct = @ast.MOption(@ast.MOption(@ast.MInt))
  assert_true(assert_round_trip(correct))

  // 模拟塌缩：如果错误地映射为 DNullable(DInt)，
  // 反向恢复会得到 MOption(MInt) 而非 MOption(MOption(MInt))
  let collapsed_dart = DNullable(DInt)
  let collapsed_ast = convert_to_dart_ast_type(collapsed_dart)
  let recovered = collapsed_ast.to_moon_string()
  // 塌缩后恢复为 "Option[Int]" 而非 "Option[Option[Int]]"
  assert_true(recovered != correct.to_moon_string())
}

///|
test "mutation: Result degeneration to DCustom detected by round-trip" {
  // 正确映射：MResult(MInt, MString) → DResult(DInt, DString)
  let correct = @ast.MResult(@ast.MInt, @ast.MString)
  assert_true(assert_round_trip(correct))

  // 模拟退化为 DCustom：如果错误地映射为 DCustom("Result<int, String>")
  // 反向恢复会得到 MCustom 而非 MResult
  let degenerate_dart = DCustom("Result<int, String>")
  let degenerate_ast = convert_to_dart_ast_type(degenerate_dart)
  let recovered = degenerate_ast.to_moon_string()
  // 退化后恢复为自定义类型字符串，而非 "Result[Int, String]"
  assert_true(recovered != correct.to_moon_string())
}

///|
test "mutation: UInt L3 diagnosis cannot be bypassed in strict" {
  // UInt 在 strict 模式下不会被拒绝（它是 L3 不是 L4）
  // 但 semantic_level 应正确标识为 L3
  let level = semantic_level(@ast.MUInt)
  assert_eq(level, L3)

  // 如果错误地将 UInt 归为 L1，assert_value_domain 应该能检测
  // （因为 L1 断言要求 round-trip 一致，但 UInt→DInt 的语义有损）
  // 注意：由于 UInt round-trip 实际上恢复为 Int（字符串一致），
  // 所以 L1 断言会通过，但语义级别标注仍然正确
  assert_true(assert_value_domain(@ast.MUInt, L3))
}

///|
/// v0.10.0 US6 — 验收记分卡测试。

///|
test "assessment: L1 round-trip recovery rate >= 95%" {
  // 17 L1 类型全部验证（Int64 是 L2，不在 L1 列表中）
  let l1_types : Array[@ast.MoonType] = [
    @ast.MInt,
    @ast.MDouble,
    @ast.MBool,
    @ast.MString,
    @ast.MUnit,
    @ast.MArray(@ast.MInt),
    @ast.MMap(@ast.MString, @ast.MInt),
    @ast.MSet(@ast.MInt),
    @ast.MOption(@ast.MInt),
    @ast.MOption(@ast.MOption(@ast.MInt)),
    @ast.MResult(@ast.MInt, @ast.MString),
    @ast.MFuture(@ast.MInt),
    @ast.MArray(@ast.MOption(@ast.MInt)),
    @ast.MResult(@ast.MArray(@ast.MInt), @ast.MString),
    @ast.MOption(@ast.MResult(@ast.MInt, @ast.MString)),
    @ast.MMap(@ast.MString, @ast.MResult(@ast.MInt, @ast.MString)),
    @ast.MResult(@ast.MResult(@ast.MInt, @ast.MString), @ast.MBool),
  ]
  let mut passed = 0
  let total = l1_types.length()
  for t in l1_types {
    let moon_str = t.to_moon_string()
    let dart_type = map_type(t)
    let dart_ast_type = convert_to_dart_ast_type(dart_type)
    let recovered_str = dart_ast_type.to_moon_string()
    if moon_str == recovered_str {
      passed = passed + 1
    }
  }
  // L1 往返恢复率目标 ≥ 95%
  let rate = passed * 100 / total
  assert_true(rate >= 95)
}

///|
test "assessment: strict mode rejects all L4 types" {
  let l4_types : Array[@ast.MoonType] = [
    @ast.MCustom("ForeignFunction"),
    @ast.MCustom("Channel"),
    @ast.MCustom("Spawn"),
    @ast.MArray(@ast.MCustom("ForeignFunction")),
    @ast.MOption(@ast.MCustom("Channel")),
  ]
  let mut rejected = 0
  for t in l4_types {
    let mut raised = false
    try {
      let _ = map_type_strict(t)
    } catch {
      @ast.Moon2DartError::TypeError(_) => raised = true
      _ => ()
    }
    if raised {
      rejected = rejected + 1
    }
  }
  // 100% 拒绝率
  assert_eq(rejected, l4_types.length())
}
