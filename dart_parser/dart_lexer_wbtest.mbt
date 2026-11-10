///|
test "DartLexer: basic tokens" {
  let tokens = DartLexer::make("int x = 42;").tokenize()
  assert_true(tokens[0].kind is DtIntType)
  assert_true(tokens[1].kind is DtIdent)
  assert_true(tokens[2].kind is DtAssign)
  assert_true(tokens[3].kind is DtInt)
  assert_true(tokens[4].kind is DtSemi)
  assert_true(tokens[5].kind is DtEof)
}

///|
test "DartLexer: keywords" {
  let tokens = DartLexer::make(
    "class sealed abstract return if else switch await async",
  ).tokenize()
  assert_true(tokens[0].kind is DtClass)
  assert_true(tokens[1].kind is DtSealed)
  assert_true(tokens[2].kind is DtAbstract)
  assert_true(tokens[3].kind is DtReturn)
  assert_true(tokens[4].kind is DtIf)
  assert_true(tokens[5].kind is DtElse)
  assert_true(tokens[6].kind is DtSwitch)
  assert_true(tokens[7].kind is DtAwait)
  assert_true(tokens[8].kind is DtAsync)
}

///|
test "DartLexer: built-in types" {
  let tokens = DartLexer::make(
    "void int double String bool List Map Set Future",
  ).tokenize()
  assert_true(tokens[0].kind is DtVoid)
  assert_true(tokens[1].kind is DtIntType)
  assert_true(tokens[2].kind is DtDoubleType)
  assert_true(tokens[3].kind is DtStringType)
  assert_true(tokens[4].kind is DtBoolType)
  assert_true(tokens[5].kind is DtListType)
  assert_true(tokens[6].kind is DtMapType)
  assert_true(tokens[7].kind is DtSetType)
  assert_true(tokens[8].kind is DtFutureType)
}

///|
test "DartLexer: operators" {
  let tokens = DartLexer::make("=> == != <= >= && || ?? ?.").tokenize()
  assert_true(tokens[0].kind is DtArrow)
  assert_true(tokens[1].kind is DtEqEq)
  assert_true(tokens[2].kind is DtNotEq)
  assert_true(tokens[3].kind is DtLeEq)
  assert_true(tokens[4].kind is DtGrEq)
  assert_true(tokens[5].kind is DtAndAnd)
  assert_true(tokens[6].kind is DtOrOr)
  assert_true(tokens[7].kind is DtNullCoalesce)
  assert_true(tokens[8].kind is DtNullAware)
}

///|
test "DartLexer: string literals" {
  let tokens = DartLexer::make("\"hello\" 'world'").tokenize()
  assert_true(tokens[0].kind is DtString)
  assert_true(tokens[1].kind is DtString)
}

///|
test "DartLexer: double literal" {
  let tokens = DartLexer::make("3.14").tokenize()
  assert_true(tokens[0].kind is DtDouble)
}

///|
test "DartLexer: comments" {
  let tokens = DartLexer::make("// comment\nint x; /* block */ int y;").tokenize()
  assert_true(tokens[0].kind is DtIntType)
  assert_true(tokens[1].kind is DtIdent)
  assert_true(tokens[2].kind is DtSemi)
  assert_true(tokens[3].kind is DtIntType)
  assert_true(tokens[4].kind is DtIdent)
  assert_true(tokens[5].kind is DtSemi)
}

///|
test "DartLexer: identifiers" {
  let tokens = DartLexer::make("myVar MyClass").tokenize()
  assert_true(tokens[0].kind is DtIdent)
  assert_true(tokens[1].kind is DtUIdent)
}
