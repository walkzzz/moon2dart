///|
/// MoonBit 词法分析器 — 将源码字符串转换为 Token 流。
///
/// 支持：关键字 / 标识符 / 整数字面量 / 字符串字面量 / 运算符 / 分隔符。
/// 跳过：注释（// 和 ///）和空白字符。

///|
/// Token 种类枚举。
#derive(Eq, Debug)
pub(all) enum TokenKind {
  // 字面量
  TkInt
  TkDouble
  TkString
  TkChar
  // 标识符
  TkIdent
  TkUIdent
  // 关键字
  TkFn
  TkLet
  TkMut
  TkStruct
  TkEnum
  TkTrait
  TkImpl
  TkExtend
  TkPub
  TkIf
  TkElse
  TkMatch
  TkFor
  TkWhile
  TkReturn
  TkTrue
  TkFalse
  TkType
  TkDerive
  TkRaise
  TkTry
  TkCatch
  TkGuard
  TkDefer
  TkAsync
  TkAwait
  TkExtern
  TkTest
  TkInit
  TkMain
  TkAlias
  // 运算符
  TkPlus
  TkMinus
  TkStar
  TkSlash
  TkPercent
  TkEqEq
  TkNotEq
  TkLt
  TkGt
  TkLeEq
  TkGrEq
  TkAndAnd
  TkOrOr
  TkNot
  TkAssign
  TkArrow
  TkFatArrow
  TkPipe
  TkDot
  TkDotDot
  TkDotDotLt
  // 分隔符
  TkLParen
  TkRParen
  TkLBracket
  TkRBracket
  TkLBrace
  TkRBrace
  TkComma
  TkSemi
  TkColon
  TkColonColon
  TkTilde
  TkAt
  // 特殊
  TkEof
  TkError
}

///|
pub extend TokenKind with Eq::{not_equal, equal}

///|
pub extend TokenKind with Debug::{to_repr}

///|
/// Token 结构 — 包含种类、文本、位置信息。
#derive(Eq, Debug)
pub(all) struct Token {
  kind : TokenKind
  text : String
  line : Int32
  col : Int32
}

///|
pub extend Token with Eq::{not_equal, equal}

///|
pub extend Token with Debug::{to_repr}

///|
/// 词法分析器 — 逐字符扫描源码，生成 Token 流。
pub struct Lexer {
  chars : Array[Char]
  pos : Int32
  line : Int32
  col : Int32
  tokens : Array[Token]
}

///|
/// 构造词法分析器。
pub fn Lexer::make(src : String) -> Lexer {
  { chars: src.to_array(), pos: 0, line: 1, col: 1, tokens: [], }
}

///|
/// 运行词法分析，返回 Token 流。
pub fn Lexer::tokenize(self : Lexer) -> Array[Token] {
  let lexer : Lexer = { ..self, pos: 0, line: 1, col: 1, tokens: [], }
  let mut lexer = lexer
  let len = lexer.chars.length()
  while lexer.pos < len {
    lexer = lexer.skip_whitespace_and_comments()
    if lexer.pos >= len {
      break
    }
    lexer = lexer.scan_one()
  }
  lexer.tokens.push(Token::eof(lexer.line, lexer.col))
  lexer.tokens
}

///|
/// 跳过空白字符和注释。
fn Lexer::skip_whitespace_and_comments(self : Lexer) -> Lexer {
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
    } else {
      break
    }
  }
  lexer
}

///|
/// 扫描一个 Token。
fn Lexer::scan_one(self : Lexer) -> Lexer {
  let ch = self.chars[self.pos]
  if is_digit_char(ch) {
    return self.scan_number()
  }
  if ch == '_' || is_alpha(ch) {
    return self.scan_ident_or_keyword()
  }
  if ch == '"' {
    return self.scan_string()
  }
  if ch == '\'' {
    return self.scan_char()
  }
  self.scan_operator()
}

///|
/// 扫描数字字面量（整数或浮点数）。
fn Lexer::scan_number(self : Lexer) -> Lexer {
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
    } else if ch == 'L' || ch == 'U' || ch == 'F' || ch == 'N' {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      break
    } else if ch == '_' {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    } else {
      break
    }
  }
  let text = chars_to_string(lexer.chars, start, lexer.pos)
  let kind = if is_double { TokenKind::TkDouble } else { TokenKind::TkInt }
  lexer.tokens.push({ kind, text, line: lexer.line, col: start_col, })
  lexer
}

///|
/// 扫描标识符或关键字。
fn Lexer::scan_ident_or_keyword(self : Lexer) -> Lexer {
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
  let kind = keyword_or_ident(text)
  lexer.tokens.push({ kind, text, line: lexer.line, col: start_col, })
  lexer
}

///|
/// 判断是关键字还是标识符。
fn keyword_or_ident(text : String) -> TokenKind {
  match text {
    "fn" => TokenKind::TkFn
    "let" => TokenKind::TkLet
    "mut" => TokenKind::TkMut
    "struct" => TokenKind::TkStruct
    "enum" => TokenKind::TkEnum
    "trait" => TokenKind::TkTrait
    "impl" => TokenKind::TkImpl
    "extend" => TokenKind::TkExtend
    "pub" => TokenKind::TkPub
    "if" => TokenKind::TkIf
    "else" => TokenKind::TkElse
    "match" => TokenKind::TkMatch
    "for" => TokenKind::TkFor
    "while" => TokenKind::TkWhile
    "return" => TokenKind::TkReturn
    "true" => TokenKind::TkTrue
    "false" => TokenKind::TkFalse
    "type" => TokenKind::TkType
    "derive" => TokenKind::TkDerive
    "raise" => TokenKind::TkRaise
    "try" => TokenKind::TkTry
    "catch" => TokenKind::TkCatch
    "guard" => TokenKind::TkGuard
    "defer" => TokenKind::TkDefer
    "async" => TokenKind::TkAsync
    "await" => TokenKind::TkAwait
    "extern" => TokenKind::TkExtern
    "test" => TokenKind::TkTest
    "init" => TokenKind::TkInit
    "main" => TokenKind::TkMain
    "alias" => TokenKind::TkAlias
    _ => {
      let first = text.to_array()[0]
      if is_upper(first) {
        TokenKind::TkUIdent
      } else {
        TokenKind::TkIdent
      }
    }
  }
}

///|
/// 扫描字符串字面量。
fn Lexer::scan_string(self : Lexer) -> Lexer {
  let start = self.pos
  let start_col = self.col
  let len = self.chars.length()
  let mut lexer = { ..self, pos: self.pos + 1, col: self.col + 1, }
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if ch == '"' {
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
    kind: TokenKind::TkString,
    text,
    line: lexer.line,
    col: start_col,
  })
  lexer
}

///|
/// 扫描字符字面量。
fn Lexer::scan_char(self : Lexer) -> Lexer {
  let start = self.pos
  let start_col = self.col
  let len = self.chars.length()
  let mut lexer = { ..self, pos: self.pos + 1, col: self.col + 1, }
  while lexer.pos < len {
    let ch = lexer.chars[lexer.pos]
    if ch == '\'' {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
      break
    } else if ch == '\\' && lexer.pos + 1 < len {
      lexer = { ..lexer, pos: lexer.pos + 2, col: lexer.col + 2, }
    } else {
      lexer = { ..lexer, pos: lexer.pos + 1, col: lexer.col + 1, }
    }
  }
  let text = chars_to_string(lexer.chars, start, lexer.pos)
  lexer.tokens.push({
    kind: TokenKind::TkChar,
    text,
    line: lexer.line,
    col: start_col,
  })
  lexer
}

///|
/// 扫描运算符或分隔符。
fn Lexer::scan_operator(self : Lexer) -> Lexer {
  let ch = self.chars[self.pos]
  let len = self.chars.length()
  let next = if self.pos + 1 < len {
    Some(self.chars[self.pos + 1])
  } else {
    None
  }
  let next2 = if self.pos + 2 < len {
    Some(self.chars[self.pos + 2])
  } else {
    None
  }
  match (ch, next, next2) {
    ('.', Some('.'), Some('<')) => return self.emit(TokenKind::TkDotDotLt, 3)
    _ => ()
  }
  match (ch, next) {
    ('-', Some('>')) => return self.emit(TokenKind::TkArrow, 2)
    ('=', Some('=')) => return self.emit(TokenKind::TkEqEq, 2)
    ('=', Some('>')) => return self.emit(TokenKind::TkFatArrow, 2)
    ('!', Some('=')) => return self.emit(TokenKind::TkNotEq, 2)
    ('<', Some('=')) => return self.emit(TokenKind::TkLeEq, 2)
    ('>', Some('=')) => return self.emit(TokenKind::TkGrEq, 2)
    ('&', Some('&')) => return self.emit(TokenKind::TkAndAnd, 2)
    ('|', Some('|')) => return self.emit(TokenKind::TkOrOr, 2)
    ('|', Some('>')) => return self.emit(TokenKind::TkPipe, 2)
    ('.', Some('.')) => return self.emit(TokenKind::TkDotDot, 2)
    (':', Some(':')) => return self.emit(TokenKind::TkColonColon, 2)
    _ => ()
  }
  let kind = match ch {
    '+' => TokenKind::TkPlus
    '-' => TokenKind::TkMinus
    '*' => TokenKind::TkStar
    '/' => TokenKind::TkSlash
    '%' => TokenKind::TkPercent
    '<' => TokenKind::TkLt
    '>' => TokenKind::TkGt
    '!' => TokenKind::TkNot
    '=' => TokenKind::TkAssign
    '.' => TokenKind::TkDot
    '(' => TokenKind::TkLParen
    ')' => TokenKind::TkRParen
    '[' => TokenKind::TkLBracket
    ']' => TokenKind::TkRBracket
    '{' => TokenKind::TkLBrace
    '}' => TokenKind::TkRBrace
    ',' => TokenKind::TkComma
    ';' => TokenKind::TkSemi
    ':' => TokenKind::TkColon
    '~' => TokenKind::TkTilde
    '@' => TokenKind::TkAt
    _ => TokenKind::TkError
  }
  self.emit(kind, 1)
}

///|
/// 发射一个 Token 并前进。
fn Lexer::emit(self : Lexer, kind : TokenKind, n : Int32) -> Lexer {
  let text = chars_to_string(self.chars, self.pos, self.pos + n)
  let token : Token = { kind, text, line: self.line, col: self.col, }
  let lexer = { ..self, pos: self.pos + n, col: self.col + n, }
  lexer.tokens.push(token)
  lexer
}

///|
/// 构造 EOF Token。
fn Token::eof(line : Int32, col : Int32) -> Token {
  { kind: TokenKind::TkEof, text: "", line, col, }
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
