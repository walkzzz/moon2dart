///|
/// Parser 白盒测试 — 表达式 / 类型 / 声明 / 程序。

///|
/// 辅助：从源码构造 Parser。
fn make_parser(src : String) -> Parser {
  let tokens = Lexer::make(src).tokenize()
  Parser::make(tokens)
}

///|
/// 测试解析整数字面量。
test "parse_expr_int" {
  let (expr, _) = make_parser("42").parse_expr()
  assert_true(expr is @ast.EInt(42))
}

///|
/// 测试解析字符串字面量。
test "parse_expr_string" {
  let (expr, _) = make_parser("\"hello\"").parse_expr()
  assert_true(expr is @ast.EString("hello"))
}

///|
/// 测试解析布尔字面量 true。
test "parse_expr_true" {
  let (expr, _) = make_parser("true").parse_expr()
  assert_true(expr is @ast.EBool(true))
}

///|
/// 测试解析布尔字面量 false。
test "parse_expr_false" {
  let (expr, _) = make_parser("false").parse_expr()
  assert_true(expr is @ast.EBool(false))
}

///|
/// 测试解析变量引用。
test "parse_expr_var" {
  let (expr, _) = make_parser("foo").parse_expr()
  assert_true(expr is @ast.EVar("foo"))
}

///|
/// 测试解析函数调用无参数。
test "parse_expr_call_no_args" {
  let (expr, _) = make_parser("foo()").parse_expr()
  assert_true(expr is @ast.ECall("foo", []))
}

///|
/// 测试解析函数调用带参数。
test "parse_expr_call_with_args" {
  let (expr, _) = make_parser("add(1, 2)").parse_expr()
  match expr {
    @ast.ECall(name, args) => {
      assert_eq(name, "add")
      assert_eq(args.length(), 2)
      assert_true(args[0] is @ast.EInt(1))
      assert_true(args[1] is @ast.EInt(2))
    }
    _ => abort("expected ECall")
  }
}

///|
/// 测试解析二元加法运算。
test "parse_expr_binop_add" {
  let (expr, _) = make_parser("1 + 2").parse_expr()
  assert_true(expr is @ast.EBinOp("+", @ast.EInt(1), @ast.EInt(2)))
}

///|
/// 测试解析二元乘法运算（优先级高于加法）。
test "parse_expr_binop_precedence" {
  let (expr, _) = make_parser("1 + 2 * 3").parse_expr()
  match expr {
    @ast.EBinOp("+", left, right) => {
      assert_true(left is @ast.EInt(1))
      assert_true(right is @ast.EBinOp("*", @ast.EInt(2), @ast.EInt(3)))
    }
    _ => abort("expected EBinOp +")
  }
}

///|
/// 测试解析比较运算。
test "parse_expr_binop_compare" {
  let (expr, _) = make_parser("a < b").parse_expr()
  assert_true(expr is @ast.EBinOp("<", @ast.EVar("a"), @ast.EVar("b")))
}

///|
/// 测试解析逻辑与运算。
test "parse_expr_binop_and" {
  let (expr, _) = make_parser("a && b").parse_expr()
  assert_true(expr is @ast.EBinOp("&&", @ast.EVar("a"), @ast.EVar("b")))
}

///|
/// 测试解析 if 表达式。
test "parse_expr_if" {
  let (expr, _) = make_parser("if x { 1 } else { 2 }").parse_expr()
  assert_true(expr is @ast.EIf(@ast.EVar("x"), @ast.EInt(1), @ast.EInt(2)))
}

///|
/// 测试解析 if 表达式无 else。
test "parse_expr_if_no_else" {
  let (expr, _) = make_parser("if x { 1 }").parse_expr()
  assert_true(expr is @ast.EIf(@ast.EVar("x"), @ast.EInt(1), @ast.EInt(0)))
}

///|
/// 测试解析嵌套表达式。
test "parse_expr_nested" {
  let (expr, _) = make_parser("foo(1 + 2, 3)").parse_expr()
  match expr {
    @ast.ECall(name, args) => {
      assert_eq(name, "foo")
      assert_eq(args.length(), 2)
      assert_true(args[0] is @ast.EBinOp("+", @ast.EInt(1), @ast.EInt(2)))
      assert_true(args[1] is @ast.EInt(3))
    }
    _ => abort("expected ECall")
  }
}

///|
/// 测试解析基本类型 Int。
test "parse_type_int" {
  let (ty, _) = make_parser("Int").parse_type()
  assert_true(ty is @ast.MInt)
}

///|
/// 测试解析基本类型 String。
test "parse_type_string" {
  let (ty, _) = make_parser("String").parse_type()
  assert_true(ty is @ast.MString)
}

///|
/// 测试解析数组类型。
test "parse_type_array" {
  let (ty, _) = make_parser("Array[Int]").parse_type()
  assert_true(ty is @ast.MArray(@ast.MInt))
}

///|
/// 测试解析 Map 类型。
test "parse_type_map" {
  let (ty, _) = make_parser("Map[String, Int]").parse_type()
  assert_true(ty is @ast.MMap(@ast.MString, @ast.MInt))
}

///|
/// 测试解析 Option 类型。
test "parse_type_option" {
  let (ty, _) = make_parser("Option[Int]").parse_type()
  assert_true(ty is @ast.MOption(@ast.MInt))
}

///|
/// 测试解析 fn 声明。
test "parse_fn_decl" {
  let (decl, _) = make_parser("fn add(a : Int, b : Int) -> Int { a + b }").parse_fn_decl()
  match decl {
    @ast.DFn(name, params, ret, body) => {
      assert_eq(name, "add")
      assert_eq(params.length(), 2)
      let (p0n, p0t) = params[0]
      let (p1n, p1t) = params[1]
      assert_eq(p0n, "a")
      assert_true(p0t is @ast.MInt)
      assert_eq(p1n, "b")
      assert_true(p1t is @ast.MInt)
      assert_true(ret is @ast.MInt)
      assert_true(body is @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")))
    }
    _ => abort("expected DFn")
  }
}

///|
/// 测试解析无返回类型的 fn 声明。
test "parse_fn_decl_no_ret" {
  let (decl, _) = make_parser("fn foo(x : Int) { x }").parse_fn_decl()
  match decl {
    @ast.DFn(name, params, ret, body) => {
      assert_eq(name, "foo")
      assert_eq(params.length(), 1)
      assert_true(ret is @ast.MUnit)
      assert_true(body is @ast.EVar("x"))
    }
    _ => abort("expected DFn")
  }
}

///|
/// 测试解析 struct 声明。
test "parse_struct_decl" {
  let (decl, _) = make_parser("struct Point { x : Int, y : Int }").parse_struct_decl()
  match decl {
    @ast.DStruct(name, fields, _) => {
      assert_eq(name, "Point")
      assert_eq(fields.length(), 2)
      let (f0n, f0t) = fields[0]
      let (f1n, f1t) = fields[1]
      assert_eq(f0n, "x")
      assert_true(f0t is @ast.MInt)
      assert_eq(f1n, "y")
      assert_true(f1t is @ast.MInt)
    }
    _ => abort("expected DStruct")
  }
}

///|
/// 测试解析 enum 声明。
test "parse_enum_decl" {
  let (decl, _) = make_parser("enum Color { Red, Green, Blue }").parse_enum_decl()
  match decl {
    @ast.DEnum(name, variants) => {
      assert_eq(name, "Color")
      assert_eq(variants.length(), 3)
      assert_eq(variants[0], "Red")
      assert_eq(variants[1], "Green")
      assert_eq(variants[2], "Blue")
    }
    _ => abort("expected DEnum")
  }
}

///|
/// 测试解析完整程序（多个声明）。
test "parse_program" {
  let src = "fn id(x : Int) -> Int { x }\nstruct Foo { a : Int }\nenum Bar { A, B }"
  let decls = make_parser(src).parse_program()
  assert_eq(decls.length(), 3)
  assert_true(decls[0] is @ast.DFn("id", _, _, _))
  assert_true(decls[1] is @ast.DStruct("Foo", _, _))
  assert_true(decls[2] is @ast.DEnum("Bar", _))
}

///|
/// 测试解析空程序。
test "parse_program_empty" {
  let decls = make_parser("").parse_program()
  assert_eq(decls.length(), 0)
}

///|
/// 测试 Parser 前进与查看。
test "parser_advance_peek" {
  let parser = make_parser("1 2")
  assert_true(parser.peek().kind is TkInt)
  let parser2 = parser.advance()
  assert_true(parser2.peek().kind is TkInt)
  let parser3 = parser2.advance()
  assert_true(parser3.peek().kind is TkEof)
}

///|
/// 测试 expect_ident 返回文本并前进。
test "parser_expect_ident" {
  let (name, parser) = make_parser("foo bar").expect_ident()
  assert_eq(name, "foo")
  assert_true(parser.peek().kind is TkIdent)
  assert_eq(parser.peek().text, "bar")
}

///|
/// 测试解析 trait 声明。
test "parse_trait_decl" {
  let (decl, _) = make_parser(
    "trait Drawable { fn draw() -> Unit; fn area() -> Double; }",
  ).parse_trait_decl()
  match decl {
    @ast.DTrait(name, methods) => {
      assert_eq(name, "Drawable")
      assert_eq(methods.length(), 2)
      assert_eq(methods[0].name, "draw")
      assert_true(methods[0].ret_type is @ast.MUnit)
      assert_eq(methods[1].name, "area")
      assert_true(methods[1].ret_type is @ast.MDouble)
    }
    _ => abort("expected DTrait")
  }
}

///|
/// 测试解析带参数的 trait 声明。
test "parse_trait_decl_with_params" {
  let src = "trait Comparable { fn compare(other : Int) -> Int; }"
  let (decl, _) = make_parser(src).parse_trait_decl()
  match decl {
    @ast.DTrait(name, methods) => {
      assert_eq(name, "Comparable")
      assert_eq(methods.length(), 1)
      assert_eq(methods[0].name, "compare")
      assert_eq(methods[0].params.length(), 1)
      let (pname, ptype) = methods[0].params[0]
      assert_eq(pname, "other")
      assert_true(ptype is @ast.MInt)
      assert_true(methods[0].ret_type is @ast.MInt)
    }
    _ => abort("expected DTrait")
  }
}

///|
/// 测试解析包含 trait 的完整程序。
test "parse_program_with_trait" {
  let src = "trait Drawable { fn draw() -> Unit; }\nstruct Circle { r : Double }"
  let decls = make_parser(src).parse_program()
  assert_eq(decls.length(), 2)
  assert_true(decls[0] is @ast.DTrait("Drawable", _))
  assert_true(decls[1] is @ast.DStruct("Circle", _, _))
}

///|
/// 测试解析 match 表达式（基本）。
test "parse_expr_match_basic" {
  let src = "match x { 1 => a, _ => b }"
  let (expr, _) = make_parser(src).parse_expr()
  match expr {
    @ast.EMatch(scrutinee, cases) => {
      assert_true(scrutinee is @ast.EVar("x"))
      assert_eq(cases.length(), 2)
      let (p0, b0) = cases[0]
      let (p1, b1) = cases[1]
      assert_true(p0 is @ast.PInt(1))
      assert_true(b0 is @ast.EVar("a"))
      assert_true(p1 is @ast.PWild)
      assert_true(b1 is @ast.EVar("b"))
    }
    _ => abort("expected EMatch")
  }
}

///|
/// 测试解析 match 表达式（构造器模式）。
test "parse_expr_match_ctor" {
  let src = "match s { Red => 1, Green => 2, Blue => 3 }"
  let (expr, _) = make_parser(src).parse_expr()
  match expr {
    @ast.EMatch(_, cases) => {
      assert_eq(cases.length(), 3)
      let (p0, _) = cases[0]
      let (p1, _) = cases[1]
      let (p2, _) = cases[2]
      assert_true(p0 is @ast.PCtor("Red", []))
      assert_true(p1 is @ast.PCtor("Green", []))
      assert_true(p2 is @ast.PCtor("Blue", []))
    }
    _ => abort("expected EMatch")
  }
}

///|
/// 测试解析 match 表达式（带参数构造器模式）。
test "parse_expr_match_ctor_with_args" {
  let src = "match e { Point(x, y) => x, _ => 0 }"
  let (expr, _) = make_parser(src).parse_expr()
  match expr {
    @ast.EMatch(_, cases) => {
      assert_eq(cases.length(), 2)
      let (p0, _) = cases[0]
      let (p1, _) = cases[1]
      match p0 {
        @ast.PCtor(name, args) => {
          assert_eq(name, "Point")
          assert_eq(args.length(), 2)
          assert_true(args[0] is @ast.PVar("x"))
          assert_true(args[1] is @ast.PVar("y"))
        }
        _ => abort("expected PCtor")
      }
      assert_true(p1 is @ast.PWild)
    }
    _ => abort("expected EMatch")
  }
}

///|
/// 测试解析 match 表达式（字符串模式）。
test "parse_expr_match_string" {
  let src = "match s { \"hello\" => 1, _ => 0 }"
  let (expr, _) = make_parser(src).parse_expr()
  match expr {
    @ast.EMatch(_, cases) => {
      assert_eq(cases.length(), 2)
      let (p0, _) = cases[0]
      let (p1, _) = cases[1]
      assert_true(p0 is @ast.PString("hello"))
      assert_true(p1 is @ast.PWild)
    }
    _ => abort("expected EMatch")
  }
}

///|
/// 测试解析带 derive 的 struct 声明。
test "parse_struct_decl_derive" {
  let (decl, _) = make_parser("struct Point derive(Debug) { x : Int, y : Int }").parse_struct_decl()
  match decl {
    @ast.DStruct(name, fields, derives) => {
      assert_eq(name, "Point")
      assert_eq(fields.length(), 2)
      assert_eq(derives.length(), 1)
      assert_eq(derives[0], "Debug")
    }
    _ => abort("expected DStruct")
  }
}

///|
/// 测试解析带多个 derive 的 struct 声明。
test "parse_struct_decl_multi_derive" {
  let (decl, _) = make_parser(
    "struct Point derive(Debug, Eq, Compare) { x : Int, y : Int }",
  ).parse_struct_decl()
  match decl {
    @ast.DStruct(name, fields, derives) => {
      assert_eq(name, "Point")
      assert_eq(fields.length(), 2)
      assert_eq(derives.length(), 3)
      assert_eq(derives[0], "Debug")
      assert_eq(derives[1], "Eq")
      assert_eq(derives[2], "Compare")
    }
    _ => abort("expected DStruct")
  }
}

///|
/// 测试解析无 derive 的 struct 声明（默认空列表）。
test "parse_struct_decl_no_derive" {
  let (decl, _) = make_parser("struct Point { x : Int, y : Int }").parse_struct_decl()
  match decl {
    @ast.DStruct(name, fields, derives) => {
      assert_eq(name, "Point")
      assert_eq(fields.length(), 2)
      assert_eq(derives.length(), 0)
    }
    _ => abort("expected DStruct")
  }
}
