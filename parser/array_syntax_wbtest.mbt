///|
/// 数组/索引/方法调用/while/let 语法白盒测试（v0.12.0 业务函数子集）
/// White-box tests for array literals, indexing, method calls, while and let.

///|
test "parse array literal and empty array" {
  let (e, _) = make_parser("[1, 2, 3]").parse_expr()
  match e {
    @ast.EArrayLit(items) => assert_eq(items.length(), 3)
    _ => abort("expected EArrayLit")
  }
  let (empty, _) = make_parser("[]").parse_expr()
  match empty {
    @ast.EArrayLit(items) => assert_eq(items.length(), 0)
    _ => abort("expected empty EArrayLit")
  }
}

///|
test "parse index access" {
  let (e, _) = make_parser("xs[0]").parse_expr()
  match e {
    @ast.EIndex(@ast.EVar("xs"), @ast.EInt(0)) => ()
    _ => abort("expected EIndex(EVar(xs), EInt(0))")
  }
}

///|
test "parse method call length and push" {
  let (e, _) = make_parser("xs.length()").parse_expr()
  match e {
    @ast.EMethodCall(@ast.EVar("xs"), mname, args) => {
      assert_eq(mname, "length")
      assert_eq(args.length(), 0)
    }
    _ => abort("expected EMethodCall length")
  }
  let (p, _) = make_parser("out.push(i * i)").parse_expr()
  match p {
    @ast.EMethodCall(@ast.EVar("out"), mname, args) => {
      assert_eq(mname, "push")
      assert_eq(args.length(), 1)
    }
    _ => abort("expected EMethodCall push")
  }
}

///|
test "parse while let assign block" {
  let src = "fn sum(xs : Array[Int]) -> Int { let mut i = 0\n let mut acc = 0\n while i < xs.length() { acc = acc + xs[i]\n i = i + 1 }\n acc }"
  let decls = make_parser(src).parse_program()
  match decls[0] {
    @ast.DFn(name, _, params, ret, body) => {
      assert_eq(name, "sum")
      assert_eq(params.length(), 1)
      assert_true(ret is @ast.MInt)
      match body {
        @ast.EBlock(stmts) => {
          assert_eq(stmts.length(), 4)
          assert_true(stmts[0] is @ast.ELet("i", true, _, _))
          assert_true(stmts[1] is @ast.ELet("acc", true, _, _))
          assert_true(stmts[2] is @ast.EWhile(_, _))
          assert_true(stmts[3] is @ast.EVar("acc"))
        }
        _ => abort("expected EBlock")
      }
    }
    _ => abort("expected DFn")
  }
}

///|
test "parse let with type annotation" {
  let (e, _) = make_parser("let out : Array[Int] = []").parse_statement()
  match e {
    @ast.ELet(name, is_mut, ty, _) => {
      assert_eq(name, "out")
      assert_false(is_mut)
      assert_true(ty is Some(@ast.MArray(@ast.MInt)))
    }
    _ => abort("expected ELet")
  }
}

///|
test "parse parenthesized if expression" {
  let (e, _) = make_parser("(if x > 0 { 1 } else { 0 })").parse_expr()
  assert_true(e is @ast.EIf(_, _, _))
}

///|
test "parse Int32 / UInt32 canonical aliases" {
  let (arr, _) = make_parser("Array[Int32]").parse_type()
  assert_true(arr is @ast.MArray(@ast.MInt))
  let (uint, _) = make_parser("UInt32").parse_type()
  assert_true(uint is @ast.MUInt)
  let (nested, _) = make_parser("Map[Int32, Array[UInt32]]").parse_type()
  assert_true(nested is @ast.MMap(@ast.MInt, @ast.MArray(@ast.MUInt)))
}
