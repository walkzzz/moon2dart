///|
/// lexer 白盒测试 — 验证词法分析器正确性。

///|
test "lexer: empty input" {
  let tokens = Lexer::make("").tokenize()
  assert_eq(tokens.length(), 1)
  assert_true(tokens[0].kind is TkEof)
}

///|
test "lexer: integers" {
  let tokens = Lexer::make("42 0 1000000").tokenize()
  assert_eq(tokens.length(), 4)
  assert_true(tokens[0].kind is TkInt)
  assert_eq(tokens[0].text, "42")
  assert_true(tokens[1].kind is TkInt)
  assert_eq(tokens[1].text, "0")
  assert_true(tokens[2].kind is TkInt)
  assert_eq(tokens[2].text, "1000000")
  assert_true(tokens[3].kind is TkEof)
}

///|
test "lexer: int64 suffix" {
  let tokens = Lexer::make("100L").tokenize()
  assert_eq(tokens.length(), 2)
  assert_true(tokens[0].kind is TkInt)
  assert_eq(tokens[0].text, "100L")
}

///|
test "lexer: double" {
  let tokens = Lexer::make("3.14 0.5").tokenize()
  assert_eq(tokens.length(), 3)
  assert_true(tokens[0].kind is TkDouble)
  assert_eq(tokens[0].text, "3.14")
  assert_true(tokens[1].kind is TkDouble)
  assert_eq(tokens[1].text, "0.5")
}

///|
test "lexer: string literal" {
  let tokens = Lexer::make("\"hello world\"").tokenize()
  assert_eq(tokens.length(), 2)
  assert_true(tokens[0].kind is TkString)
  assert_eq(tokens[0].text, "\"hello world\"")
}

///|
test "lexer: string with escape" {
  let tokens = Lexer::make("\"hello\\nworld\"").tokenize()
  assert_eq(tokens.length(), 2)
  assert_true(tokens[0].kind is TkString)
}

///|
test "lexer: identifiers" {
  let tokens = Lexer::make("foo bar_baz x1").tokenize()
  assert_eq(tokens.length(), 4)
  for i in 0..<3 {
    assert_true(tokens[i].kind is TkIdent)
  }
  assert_eq(tokens[0].text, "foo")
  assert_eq(tokens[1].text, "bar_baz")
  assert_eq(tokens[2].text, "x1")
}

///|
test "lexer: type identifiers" {
  let tokens = Lexer::make("Int String MyType").tokenize()
  assert_eq(tokens.length(), 4)
  for i in 0..<3 {
    assert_true(tokens[i].kind is TkUIdent)
  }
  assert_eq(tokens[0].text, "Int")
  assert_eq(tokens[1].text, "String")
  assert_eq(tokens[2].text, "MyType")
}

///|
test "lexer: keywords" {
  let src = "fn let mut struct enum trait pub if else match return true false"
  let tokens = Lexer::make(src).tokenize()
  let expected = [
    TkFn,
    TkLet,
    TkMut,
    TkStruct,
    TkEnum,
    TkTrait,
    TkPub,
    TkIf,
    TkElse,
    TkMatch,
    TkReturn,
    TkTrue,
    TkFalse,
  ]
  assert_eq(tokens.length(), expected.length() + 1)
  for i in 0..<expected.length() {
    assert_eq(tokens[i].kind, expected[i])
  }
}

///|
test "lexer: operators" {
  let src = "+ - * / % == != < > <= >= && || ! = -> => |> .. ..< ::"
  let tokens = Lexer::make(src).tokenize()
  let expected = [
    TkPlus,
    TkMinus,
    TkStar,
    TkSlash,
    TkPercent,
    TkEqEq,
    TkNotEq,
    TkLt,
    TkGt,
    TkLeEq,
    TkGrEq,
    TkAndAnd,
    TkOrOr,
    TkNot,
    TkAssign,
    TkArrow,
    TkFatArrow,
    TkPipe,
    TkDotDot,
    TkDotDotLt,
    TkColonColon,
  ]
  assert_eq(tokens.length(), expected.length() + 1)
  for i in 0..<expected.length() {
    assert_eq(tokens[i].kind, expected[i])
  }
}

///|
test "lexer: delimiters" {
  let src = "() [] {} , ; : ~ @"
  let tokens = Lexer::make(src).tokenize()
  let expected = [
    TkLParen,
    TkRParen,
    TkLBracket,
    TkRBracket,
    TkLBrace,
    TkRBrace,
    TkComma,
    TkSemi,
    TkColon,
    TkTilde,
    TkAt,
  ]
  assert_eq(tokens.length(), expected.length() + 1)
  for i in 0..<expected.length() {
    assert_eq(tokens[i].kind, expected[i])
  }
}

///|
test "lexer: comments skipped" {
  let src = "fn add() { // comment\n  1 + 2\n}"
  let tokens = Lexer::make(src).tokenize()
  assert_true(tokens[0].kind is TkFn)
  assert_true(tokens[1].kind is TkIdent)
  assert_eq(tokens[1].text, "add")
}

///|
test "lexer: doc comments skipped" {
  let src = "///|\n/// doc\nfn foo() { 1 }"
  let tokens = Lexer::make(src).tokenize()
  assert_true(tokens[0].kind is TkFn)
  assert_eq(tokens[0].text, "fn")
}

///|
test "lexer: simple fn declaration" {
  let src = "fn add(a : Int, b : Int) -> Int { a + b }"
  let tokens = Lexer::make(src).tokenize()
  assert_true(tokens[0].kind is TkFn)
  assert_true(tokens[1].kind is TkIdent)
  assert_eq(tokens[1].text, "add")
  assert_true(tokens[2].kind is TkLParen)
  assert_true(tokens[3].kind is TkIdent)
  assert_eq(tokens[3].text, "a")
  assert_true(tokens[4].kind is TkColon)
  assert_true(tokens[5].kind is TkUIdent)
  assert_eq(tokens[5].text, "Int")
}

///|
test "lexer: line and col tracking" {
  let src = "fn foo()\nfn bar()"
  let tokens = Lexer::make(src).tokenize()
  assert_eq(tokens[0].line, 1)
  assert_eq(tokens[4].line, 2)
  assert_eq(tokens[4].text, "fn")
}
