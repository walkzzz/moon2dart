///|
/// 官方 parser 适配层测试（标准语法子集）| Official-parser adapter tests (standard syntax subset).

///|
test "official: function with arithmetic" {
  let decls = parse_source("fn add(x : Int32, y : Int32) -> Int32 { x + y }")
  assert_eq(decls.length(), 1)
  match decls[0] {
    @ast.DFn(name, params, ps, ret, body) => {
      assert_eq(name, "add")
      assert_eq(params.length(), 0)
      assert_eq(ps.length(), 2)
      assert_true(ret is @ast.MInt)
      assert_true(body is @ast.EBinOp("+", _, _))
    }
    _ => abort("expected DFn")
  }
}

///|
test "official: async fn and generic type params" {
  let decls = parse_source("async fn[T] fetch(x : T) -> Int { 1 }")
  match decls[0] {
    @ast.DAsyncFn(name, tps, ps, ret, _) => {
      assert_eq(name, "fetch")
      assert_eq(tps.length(), 1)
      assert_eq(tps[0], "T")
      assert_eq(ps.length(), 1)
      assert_true(ret is @ast.MInt)
    }
    _ => abort("expected DAsyncFn")
  }
}

///|
test "official: struct with semicolon fields" {
  let decls = parse_source("struct Point { x : Int; y : Int }")
  match decls[0] {
    @ast.DStruct(name, _, fields, _) => {
      assert_eq(name, "Point")
      assert_eq(fields.length(), 2)
      assert_eq(fields[0].0, "x")
      assert_true(fields[0].1 is @ast.MInt)
    }
    _ => abort("expected DStruct")
  }
}

///|
test "official: enum variants" {
  let decls = parse_source("enum Color { Red; Green; Blue }")
  match decls[0] {
    @ast.DEnum(name, variants) => {
      assert_eq(name, "Color")
      assert_eq(variants.length(), 3)
      assert_eq(variants[2], "Blue")
    }
    _ => abort("expected DEnum")
  }
}

///|
test "official: trait declaration" {
  let decls = parse_source("trait Show { to_string(Self) -> String }")
  match decls[0] {
    @ast.DTrait(name, methods) => {
      assert_eq(name, "Show")
      assert_eq(methods.length(), 1)
      assert_eq(methods[0].name, "to_string")
    }
    _ => abort("expected DTrait")
  }
}

///|
test "official: impl block aggregation" {
  let decls = parse_source(
    "impl Show for Point with to_string(self : Point) -> String { \"p\" }",
  )
  match decls[0] {
    @ast.DImpl(trait_name, type_name, methods) => {
      assert_eq(trait_name, "Show")
      assert_eq(type_name, "Point")
      assert_eq(methods.length(), 1)
      assert_eq(methods[0].name, "to_string")
    }
    _ => abort("expected DImpl")
  }
}

///|
test "official: array / index / method call / while" {
  let decls = parse_source(
    "fn sum(xs : Array[Int32]) -> Int32 { let mut i = 0; let mut acc = 0; while i < xs.length() { acc = acc + xs[i]; i = i + 1 }; acc }",
  )
  match decls[0] {
    @ast.DFn(_, _, ps, _, body) => {
      assert_eq(ps.length(), 1)
      assert_true(ps[0].1 is @ast.MArray(@ast.MInt))
      match body {
        @ast.EBlock(stmts) => assert_true(stmts.length() >= 4)
        _ => abort("expected block body")
      }
    }
    _ => abort("expected DFn")
  }
}

///|
test "official: match with option pattern" {
  let decls = parse_source(
    "fn unwrap_or(o : Int?, d : Int) -> Int { match o { Some(v) => v; None => d } }",
  )
  match decls[0] {
    @ast.DFn(_, _, _, _, @ast.EMatch(_, cases)) => assert_eq(cases.length(), 2)
    _ => abort("expected match body")
  }
}

///|
test "official: reject for-loop (fail-closed)" {
  let mut rejected = false
  try {
    let _ = parse_source("fn f() -> Int { for i in 0..<3 { i }; 0 }")
  } catch {
    @ast.Moon2DartError::ParseError(_) => rejected = true
    _ => ()
  }
  assert_true(rejected)
}

///|
test "official: reject top-level let (fail-closed)" {
  let mut rejected = false
  try {
    let _ = parse_source("let X : Int = 1")
  } catch {
    @ast.Moon2DartError::ParseError(_) => rejected = true
    _ => ()
  }
  assert_true(rejected)
}

///|
test "official: syntax error becomes ParseError" {
  let mut rejected = false
  try {
    let _ = parse_source("fn broken( -> Int { }")
  } catch {
    @ast.Moon2DartError::ParseError(_) => rejected = true
    _ => ()
  }
  assert_true(rejected)
}
