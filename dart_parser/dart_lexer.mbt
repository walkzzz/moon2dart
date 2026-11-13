///|
/// Dart 词法分析器 — 将 Dart 源码字符串转换为 Token 流。
///
/// 支持：Dart 关键字 / 标识符 / 整数和浮点字面量 / 字符串字面量 / 运算符 / 分隔符。
/// 跳过：注释（// 和 /* */）和空白字符。

///|
/// Dart Token 种类枚举。
#derive(Eq, Debug)
pub(all) enum DartTokenKind {
  // 字面量
  DtInt
  DtDouble
  DtString
  // 标识符
  DtIdent
  DtUIdent
  // Dart 关键字
  DtClass
  DtSealed
  DtAbstract
  DtExtends
  DtImplements
  DtReturn
  DtIf
  DtElse
  DtSwitch
  DtAwait
  DtAsync
  DtNull
  DtTrue
  DtFalse
  DtFinal
  DtVar
  DtConst
  DtRequired
  DtThis
  DtOverride
  DtStatic
  DtEnum
  DtMixin
  DtWith
  DtOn
  DtIs
  DtAs
  DtTry
  DtCatch
  DtFinally
  DtThrow
  DtNew
  DtGet
  DtSet
  DtFactory
  DtOperator
  DtTypedef
  DtDynamic
  DtLate
  DtExternal
  DtFor
  DtWhile
  DtDo
  DtIn
  DtYield
  DtImport
  DtExport
  DtPart
  DtShow
  DtHide
  DtDeferred
  // Dart 内置类型
  DtVoid
  DtIntType
  DtDoubleType
  DtStringType
  DtBoolType
  DtListType
  DtMapType
  DtSetType
  DtFutureType
  // 运算符
  DtPlus
  DtMinus
  DtStar
  DtSlash
  DtPercent
  DtEqEq
  DtNotEq
  DtLt
  DtGt
  DtLeEq
  DtGrEq
  DtAndAnd
  DtOrOr
  DtNot
  DtAssign
  DtArrow
  DtNullAware
  DtNullCoalesce
  DtCascade
  DtQuestion
  // 分隔符
  DtLParen
  DtRParen
  DtLBracket
  DtRBracket
  DtLBrace
  DtRBrace
  DtComma
  DtSemi
  DtColon
  DtDot
  DtAt
  // 特殊
  DtEof
  DtError
}

///|
pub extend DartTokenKind with Eq::{not_equal, equal}

///|
pub extend DartTokenKind with Debug::{to_repr}

///|
/// Dart Token 结构。
#derive(Eq, Debug)
pub(all) struct DartToken {
  kind : DartTokenKind
  text : String
  line : Int32
  col : Int32
}

///|
pub extend DartToken with Eq::{not_equal, equal}

///|
pub extend DartToken with Debug::{to_repr}

///|
/// Dart 词法分析器。
pub struct DartLexer {
  chars : Array[Char]
  pos : Int32
  line : Int32
  col : Int32
  tokens : Array[DartToken]
}

///|
/// 构造 Dart 词法分析器。
pub fn DartLexer::make(src : String) -> DartLexer {
  { chars: src.to_array(), pos: 0, line: 1, col: 1, tokens: [], }
}

///|
/// 运行词法分析，返回 Token 流。
pub fn DartLexer::tokenize(self : DartLexer) -> Array[DartToken] {
  let lexer : DartLexer = { ..self, pos: 0, line: 1, col: 1, tokens: [], }
  let mut lexer = lexer
  let len = lexer.chars.length()
  while lexer.pos < len {
    lexer = lexer.skip_whitespace_and_comments()
    if lexer.pos >= len {
      break
    }
    lexer = lexer.scan_one()
  }
  lexer.tokens.push(DartToken::eof(lexer.line, lexer.col))
  lexer.tokens
}

///|
/// 跳过空白字符和注释（// 单行，/* */ 多行）。
fn DartLexer::skip_whitespace_and_comments(self : DartLexer) -> DartLexer {
  let len = self.chars.length()
  let mut lexer = self
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if ch == ' ' || ch == '\t' || ch == '\r' {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    } else if ch == '\n' {
      lexer = { ..lexer, pos: lexer.pos + 1, line: lexer.line + 1, col: 1, }
    } else if ch == '/' &&
      lexer.pos + 1 < len &&
      lexer.chars[lexer.pos + 1] == '/' {
      while lexer.pos < len && lexer.chars[lexer.pos] != '\n' {
        lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      }
    } else if ch == '/' &&
      lexer.pos + 1 < len &&
      lexer.chars[lexer.pos + 1] == '*' {
      lexer = { ..lexer, pos: lexer.pos + 2, col: lexer.col + 2, }
      while lexer.pos < len {
        if lexer.chars[lexer.pos] == '*' &&
          lexer.pos + 1 < len &&
          lexer.chars[lexer.pos + 1] == '/' {
          lexer = { ..lexer, pos: lexer.pos + 2, col: lexer.col + 2, }
          break
        }
        if lexer.chars[lexer.pos] == '\n' {
          lexer = { ..lexer, pos: lexer.pos + 1, line: lexer.line + 1, col: 1, }
        } else {
          lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
        }
      }
    } else {
      break
    }
  }
  lexer
}

///|
/// 扫描一个 Token。
fn DartLexer::scan_one(self : DartLexer) -> DartLexer {
  let ch = self.chars[self.pos]
  if is_digit_char(ch) {
    return self.scan_number()
  }
  if ch == '_' || is_alpha(ch) {
    return self.scan_ident_or_keyword()
  }
  if ch == '"' || ch == '\'' {
    return self.scan_string()
  }
  self.scan_operator()
}

///|
/// 扫描数字字面量。
fn DartLexer::scan_number(self : DartLexer) -> DartLexer {
  let start = self.pos
  let start_col = self.col
  let len = self.chars.length()
  let mut lexer = self
  let mut is_double = false
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if is_digit_char(ch) {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    } else if ch == '.' &&
      !is_double &&
      lexer.pos + 1 < len &&
      is_digit_char(lexer.chars[lexer.pos + 1]) {
      is_double = true
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    } else if ch == 'e' || ch == 'E' {
      is_double = true
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      if lexer.pos < len &&
        (lexer.chars[lexer.pos] == '+' || lexer.chars[lexer.pos] == '-') {
        lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      }
    } else {
      break
    }
  }
  let text = chars_to_string(lexer.chars, start, lexer.pos)
  let kind = if is_double {
    DartTokenKind::DtDouble
  } else {
    DartTokenKind::DtInt
  }
  lexer.tokens.push({ kind, text, line: lexer.line, col: start_col, })
  lexer
}

///|
/// 扫描标识符或关键字。
fn DartLexer::scan_ident_or_keyword(self : DartLexer) -> DartLexer {
  let start = self.pos
  let start_col = self.col
  let len = self.chars.length()
  let mut lexer = self
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if ch == '_' || is_alpha(ch) || is_digit_char(ch) {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    } else {
      break
    }
  }
  let text = chars_to_string(lexer.chars, start, lexer.pos)
  let kind = dart_keyword_or_ident(text)
  lexer.tokens.push({ kind, text, line: lexer.line, col: start_col, })
  lexer
}

///|
/// 判断是 Dart 关键字还是标识符。
fn dart_keyword_or_ident(text : String) -> DartTokenKind {
  match text {
    "class" => DartTokenKind::DtClass
    "sealed" => DartTokenKind::DtSealed
    "abstract" => DartTokenKind::DtAbstract
    "extends" => DartTokenKind::DtExtends
    "implements" => DartTokenKind::DtImplements
    "return" => DartTokenKind::DtReturn
    "if" => DartTokenKind::DtIf
    "else" => DartTokenKind::DtElse
    "switch" => DartTokenKind::DtSwitch
    "await" => DartTokenKind::DtAwait
    "async" => DartTokenKind::DtAsync
    "null" => DartTokenKind::DtNull
    "true" => DartTokenKind::DtTrue
    "false" => DartTokenKind::DtFalse
    "final" => DartTokenKind::DtFinal
    "var" => DartTokenKind::DtVar
    "const" => DartTokenKind::DtConst
    "required" => DartTokenKind::DtRequired
    "this" => DartTokenKind::DtThis
    "override" => DartTokenKind::DtOverride
    "static" => DartTokenKind::DtStatic
    "enum" => DartTokenKind::DtEnum
    "mixin" => DartTokenKind::DtMixin
    "with" => DartTokenKind::DtWith
    "on" => DartTokenKind::DtOn
    "is" => DartTokenKind::DtIs
    "as" => DartTokenKind::DtAs
    "try" => DartTokenKind::DtTry
    "catch" => DartTokenKind::DtCatch
    "finally" => DartTokenKind::DtFinally
    "throw" => DartTokenKind::DtThrow
    "new" => DartTokenKind::DtNew
    "get" => DartTokenKind::DtGet
    "set" => DartTokenKind::DtSet
    "factory" => DartTokenKind::DtFactory
    "operator" => DartTokenKind::DtOperator
    "typedef" => DartTokenKind::DtTypedef
    "dynamic" => DartTokenKind::DtDynamic
    "late" => DartTokenKind::DtLate
    "external" => DartTokenKind::DtExternal
    "for" => DartTokenKind::DtFor
    "while" => DartTokenKind::DtWhile
    "do" => DartTokenKind::DtDo
    "in" => DartTokenKind::DtIn
    "yield" => DartTokenKind::DtYield
    "import" => DartTokenKind::DtImport
    "export" => DartTokenKind::DtExport
    "part" => DartTokenKind::DtPart
    "show" => DartTokenKind::DtShow
    "hide" => DartTokenKind::DtHide
    "deferred" => DartTokenKind::DtDeferred
    "void" => DartTokenKind::DtVoid
    "int" => DartTokenKind::DtIntType
    "double" => DartTokenKind::DtDoubleType
    "String" => DartTokenKind::DtStringType
    "bool" => DartTokenKind::DtBoolType
    "List" => DartTokenKind::DtListType
    "Map" => DartTokenKind::DtMapType
    "Set" => DartTokenKind::DtSetType
    "Future" => DartTokenKind::DtFutureType
    _ => {
      let first = text.to_array()[0]
      if is_upper(first) {
        DartTokenKind::DtUIdent
      } else {
        DartTokenKind::DtIdent
      }
    }
  }
}

///|
/// 扫描字符串字面量（支持单引号和双引号）。
fn DartLexer::scan_string(self : DartLexer) -> DartLexer {
  let start = self.pos
  let start_col = self.col
  let quote = self.chars[self.pos]
  let len = self.chars.length()
  let mut lexer = { ..self, pos: self.pos + 1, col: self.col + 1, }
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if ch == quote {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      break
    } else if ch == '\\' && lexer.pos + 1 < len {
      lexer = { ..lexer, pos: lexer.pos + 2, col: lexer.col + 2, }
    } else if ch == '\n' {
      lexer = { ..lexer, pos: lexer.pos + 1, line: lexer.line + 1, col: 1, }
    } else {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    }
  }
  let text = chars_to_string(lexer.chars, start, lexer.pos)
  lexer.tokens.push({
    kind: DartTokenKind::DtString,
    text,
    line: lexer.line,
    col: start_col,
  })
  lexer
}

///|
/// 扫描运算符或分隔符。
fn DartLexer::scan_operator(self : DartLexer) -> DartLexer {
  let ch = self.chars[self.pos]
  let len = self.chars.length()
  let next = if self.pos + 1 < len {
    Some(self.chars[self.pos + 1])
  } else {
    None
  }
  match (ch, next) {
    ('=', Some('>')) => return self.dart_emit(DartTokenKind::DtArrow, 2)
    ('=', Some('=')) => return self.dart_emit(DartTokenKind::DtEqEq, 2)
    ('!', Some('=')) => return self.dart_emit(DartTokenKind::DtNotEq, 2)
    ('<', Some('=')) => return self.dart_emit(DartTokenKind::DtLeEq, 2)
    ('>', Some('=')) => return self.dart_emit(DartTokenKind::DtGrEq, 2)
    ('&', Some('&')) => return self.dart_emit(DartTokenKind::DtAndAnd, 2)
    ('|', Some('|')) => return self.dart_emit(DartTokenKind::DtOrOr, 2)
    ('?', Some('?')) => return self.dart_emit(DartTokenKind::DtNullCoalesce, 2)
    ('?', Some('.')) => return self.dart_emit(DartTokenKind::DtNullAware, 2)
    ('.', Some('.')) => return self.dart_emit(DartTokenKind::DtCascade, 2)
    _ => ()
  }
  let kind = match ch {
    '+' => DartTokenKind::DtPlus
    '-' => DartTokenKind::DtMinus
    '*' => DartTokenKind::DtStar
    '/' => DartTokenKind::DtSlash
    '%' => DartTokenKind::DtPercent
    '<' => DartTokenKind::DtLt
    '>' => DartTokenKind::DtGt
    '!' => DartTokenKind::DtNot
    '=' => DartTokenKind::DtAssign
    '?' => DartTokenKind::DtQuestion
    '.' => DartTokenKind::DtDot
    '(' => DartTokenKind::DtLParen
    ')' => DartTokenKind::DtRParen
    '[' => DartTokenKind::DtLBracket
    ']' => DartTokenKind::DtRBracket
    '{' => DartTokenKind::DtLBrace
    '}' => DartTokenKind::DtRBrace
    ',' => DartTokenKind::DtComma
    ';' => DartTokenKind::DtSemi
    ':' => DartTokenKind::DtColon
    '@' => DartTokenKind::DtAt
    _ => DartTokenKind::DtError
  }
  self.dart_emit(kind, 1)
}

///|
/// 发射一个 Dart Token 并前进。
fn DartLexer::dart_emit(
  self : DartLexer,
  kind : DartTokenKind,
  n : Int32,
) -> DartLexer {
  let text = chars_to_string(self.chars, self.pos, self.pos + n)
  let token : DartToken = { kind, text, line: self.line, col: self.col, }
  let lexer = { ..self, pos: self.pos + n, col: self.col + n, }
  lexer.tokens.push(token)
  lexer
}

///|
/// 构造 EOF Token。
fn DartToken::eof(line : Int32, col : Int32) -> DartToken {
  { kind: DartTokenKind::DtEof, text: "", line, col, }
}

///|
/// 将 chars[start:end] 转为 String。
fn chars_to_string(chars : Array[Char], start : Int32, end : Int32) -> String {
  let mut s = ""
  for i in start..<end {
    s = s + chars[i].to_string()
  }
  s
}

///|
/// 字符是否为数字。
fn is_digit_char(ch : Char) -> Bool {
  ch >= '0' && ch <= '9'
}

///|
/// 字符是否为字母。
fn is_alpha(ch : Char) -> Bool {
  (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')
}

///|
/// 字符是否为大写。
fn is_upper(ch : Char) -> Bool {
  ch >= 'A' && ch <= 'Z'
}
