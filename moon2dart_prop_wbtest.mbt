///|
/// 属性测试（property-based，固定种子可复现）——借鉴 MoonBit 生态（moonbitlang/quickcheck、
/// mizchi/mbt_rs roundtrip 测试、typify upstream-identical 思路）的随机化验证做法。
/// Property tests with fixed seeds, following ecosystem practice: quickcheck-style
/// randomization, mbt_rs-style roundtrip assertions, typify-style structural identity.

///|
/// 固定种子（32 字节，chacha8）保证可复现 | Fixed seed (32 bytes) for reproducibility
fn prop_seed() -> Bytes {
  b"\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f\x40"
}

///|
/// 随机生成 MoonType（递归深度受控）| Random MoonType generator (bounded depth)
fn gen_type(r : @random.Rand, depth : Int32) -> @ast.MoonType {
  // 仅生成 L1/L2 无损标量：UInt/UInt64/Float 属 L3（DartType 不保留无符号/精度），
  // 不参与 round-trip 性质，单列值域断言。
  // Only lossless L1/L2 scalars: UInt/UInt64/Float are L3 (DartType drops unsignedness),
  // excluded from the round-trip property and covered by a separate value-domain test.
  let scalars : Array[@ast.MoonType] = [
    @ast.MInt,
    @ast.MInt64,
    @ast.MDouble,
    @ast.MBool,
    @ast.MString,
    @ast.MChar,
    @ast.MUnit,
  ]
  if depth <= 0 {
    scalars[r.int(limit=scalars.length())]
  } else {
    match r.int(limit=7) {
      0 => @ast.MArray(gen_type(r, depth - 1))
      1 => @ast.MMap(gen_type(r, depth - 1), gen_type(r, depth - 1))
      2 => @ast.MSet(gen_type(r, depth - 1))
      3 => @ast.MOption(gen_type(r, depth - 1))
      4 => @ast.MResult(gen_type(r, depth - 1), gen_type(r, depth - 1))
      5 => @ast.MFuture(gen_type(r, depth - 1))
      _ => scalars[r.int(limit=scalars.length())]
    }
  }
}

///|
test "property: type mapping round-trip (random, 300 cases)" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let mut i = 0
  while i < 300 {
    let t = gen_type(r, 3)
    assert_true(
      @typesys.assert_round_trip(t),
      msg="round-trip failed for \{t.to_moon_string()}",
    )
    i = i + 1
  }
}

///|
test "property: L3 types are mapped but not round-trip guaranteed (100 cases)" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let l3 : Array[@ast.MoonType] = [
    @ast.MUInt,
    @ast.MUInt64,
    @ast.MFloat,
    @ast.MArray(@ast.MUInt),
    @ast.MMap(@ast.MString, @ast.MFloat),
  ]
  let mut i = 0
  while i < 100 {
    let t = l3[r.int(limit=l3.length())]
    assert_true(@typesys.semantic_level(t) is @typesys.L3)
    assert_true(@typesys.moon_to_dart_type(t).length() > 0)
    i = i + 1
  }
}

///|
test "property: transpile idempotent (random literals, 200 cases)" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let mut i = 0
  while i < 200 {
    let a = r.int(limit=1000000)
    let src = "fn f(x : Int) -> Int { x + \{a} }"
    let first = transpile_source_with_mode(src, @ast.Wrapping)
    let second = transpile_source_with_mode(src, @ast.Wrapping)
    assert_eq(first, second)
    i = i + 1
  }
}

///|
test "property: fail-closed always rejects undeclared arithmetic (100 cases)" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let mut i = 0
  while i < 100 {
    let n = r.int(limit=10000)
    let src = "fn f() -> Int { g\{n}() + h\{n}() }"
    let mut rejected = false
    try {
      let _ = transpile_source_report(
        src,
        "libnative.so",
        @ast.Wrapping,
        @ast.Error,
      )
    } catch {
      @ast.Moon2DartError::TypeError(_) => rejected = true
      _ => ()
    }
    assert_true(rejected)
    i = i + 1
  }
}

///|
test "property: collection equality always emits mbEquals (100 cases)" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let mut i = 0
  while i < 100 {
    let n = r.int(limit=10000)
    let src = "fn same\{n}(xs : Array[Int], ys : Array[Int]) -> Bool { xs == ys }"
    let code = transpile_source_safe(src)
    assert_true(code.contains("bool mbEquals(dynamic a, dynamic b)"))
    assert_true(code.contains("mbEquals(xs, ys)"))
    i = i + 1
  }
}

///|
test "property: wrapping shim always present for annotated Int arithmetic" {
  let r : @random.Rand = @random.Rand::chacha8(seed=prop_seed())
  let mut i = 0
  while i < 100 {
    let a = r.int(limit=100000)
    let src = "fn add\{a}(x : Int, y : Int) -> Int { x * y + \{a} }"
    let code = transpile_source_safe(src)
    assert_true(code.contains("mb32Add"))
    assert_true(code.contains("mb32Mul"))
    i = i + 1
  }
}
