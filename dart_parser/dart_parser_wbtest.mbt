///|
test "DartParser: parse top-level function" {
  let src = "int add(int a, int b) { return a + b; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DTopFn(_, _, _, _, _))
}

///|
test "DartParser: parse void function" {
  let src = "void greet(String name) { return name; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DTopFn(_, _, _, _, _))
}

///|
test "DartParser: parse async function" {
  let src = "Future<int> fetch() async { return 42; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DAsyncTopFn(_, _, _, _, _))
}

///|
test "DartParser: parse class" {
  let src = "class Point { int x; int y; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DClass(_, _, _, _))
}

///|
test "DartParser: parse sealed class" {
  let src = "sealed class Color { class Red; class Blue; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DSealedClass(_, _))
}

///|
test "DartParser: parse abstract class" {
  let src = "abstract class Named { String name(); }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  assert_true(decls.length() == 1)
  assert_true(decls[0] is DAbstractClass(_, _))
}

///|
test "DartParser: parse expression - binary op" {
  let src = "int add(int a, int b) { return a + b; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DTopFn(_, _, _, _, body) => assert_true(body is DBinOp(_, _, _))
    _ => assert_true(false)
  }
}

///|
test "DartParser: parse expression - function call" {
  let src = "int call_it() { return add(1, 2); }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DTopFn(_, _, _, _, body) => assert_true(body is DFunctionCall(_, _))
    _ => assert_true(false)
  }
}

///|
test "DartParser: parse expression - method call" {
  let src = "String run() { return obj.toString(); }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DTopFn(_, _, _, _, body) => assert_true(body is DMethodCall(_, _, _))
    _ => assert_true(false)
  }
}

///|
test "DartParser: parse expression - await" {
  let src = "Future<int> fetch() async { return await future; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DAsyncTopFn(_, _, _, _, body) => assert_true(body is DAwaitExpr(_))
    _ => assert_true(false)
  }
}

///|
test "DartParser: parse type - List" {
  let src = "List<int> make_list() { return null; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DTopFn(_, _, _, ret, _) => assert_true(ret is DList(_))
    _ => assert_true(false)
  }
}

///|
test "DartParser: parse type - Map" {
  let src = "Map<String, int> make_map() { return null; }"
  let tokens = DartLexer::make(src).tokenize()
  let decls = DartParser::make(tokens).parse_program()
  match decls[0] {
    DTopFn(_, _, _, ret, _) => assert_true(ret is DMap(_, _))
    _ => assert_true(false)
  }
}
