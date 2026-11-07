///|
/// MoonBit 语法分析器 — 将 Token 流转换为 AST。
///
/// 支持：fn 声明 / struct 声明 / enum 声明 / 基础表达式 / 类型注解。

///|
/// 语法分析器。
pub struct Parser {
  tokens : Array[Token]
  pos : Int32
}

///|
/// 构造语法分析器。
pub fn Parser::make(tokens : Array[Token]) -> Parser {
  { tokens, pos: 0, }
}

///|
/// 解析整个程序（多个声明）。
pub fn Parser::parse_program(self : Parser) -> Array[@ast.MoonDecl] {
  let mut parser = self
  let decls : Array[@ast.MoonDecl] = []
  while !parser.at_eof() {
    let (result, p) = parser.try_parse_decl()
    match result {
      Some(decl) => {
        decls.push(decl)
        parser = p
      }
      None => parser = parser.advance()
    }
  }
  decls
}

///|
/// 尝试解析一个声明，返回声明与新 Parser 状态。
fn Parser::try_parse_decl(self : Parser) -> (@ast.MoonDecl?, Parser) {
  let kind = self.peek().kind
  match kind {
    TkFn => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    TkStruct => {
      let (decl, p) = self.parse_struct_decl()
      (Some(decl), p)
    }
    TkEnum => {
      let (decl, p) = self.parse_enum_decl()
      (Some(decl), p)
    }
    TkTrait => {
      let (decl, p) = self.parse_trait_decl()
      (Some(decl), p)
    }
    TkImpl => {
      let (decl, p) = self.parse_impl_decl()
      (Some(decl), p)
    }
    _ => (None, self)
  }
}

///|
/// 解析 fn 声明：fn name(params) -> ret_type { body }
fn Parser::parse_fn_decl(self : Parser) -> (@ast.MoonDecl, Parser) {
  let parser = self.expect(TkFn)
  let (name, parser) = parser.expect_ident()
  let (params, parser2) = parser.parse_params()
  let (ret_type, parser3) = parser2.parse_return_type()
  let (body, p4) = parser3.parse_block_expr()
  (@ast.DFn(name, params, ret_type, body), p4)
}

///|
/// 解析参数列表：(name : Type, name : Type, ...)
fn Parser::parse_params(
  self : Parser,
) -> (Array[(String, @ast.MoonType)], Parser) {
  let parser = self.expect(TkLParen)
  let mut p = parser
  let params : Array[(String, @ast.MoonType)] = []
  if !(p.peek().kind is TkRParen) {
    while true {
      let (name, p1) = p.expect_ident()
      let p2 = p1.expect(TkColon)
      let (ty, p3) = p2.parse_type()
      p = p3
      params.push((name, ty))
      if p.peek().kind is TkComma {
        p = p.advance()
      } else {
        break
      }
    }
  }
  let p_final = p.expect(TkRParen)
  (params, p_final)
}

///|
/// 解析返回类型：-> Type 或无返回类型（默认 Unit）。
fn Parser::parse_return_type(self : Parser) -> (@ast.MoonType, Parser) {
  if self.peek().kind is TkArrow {
    let parser = self.advance()
    parser.parse_type()
  } else {
    (@ast.MUnit, self)
  }
}

///|
/// 解析 struct 声明：struct Name [derive(...)] { field : Type, ... }
fn Parser::parse_struct_decl(self : Parser) -> (@ast.MoonDecl, Parser) {
  let parser = self.expect(TkStruct)
  let (name, parser) = parser.expect_ident()
  let mut p = parser
  let derives : Array[String] = []
  if p.peek().kind is TkDerive {
    p = p.advance()
    p = p.expect(TkLParen)
    while true {
      let (dname, p1) = p.expect_ident()
      p = p1
      derives.push(dname)
      if p.peek().kind is TkComma {
        p = p.advance()
      } else {
        break
      }
    }
    p = p.expect(TkRParen)
  }
  p = p.expect(TkLBrace)
  let fields : Array[(String, @ast.MoonType)] = []
  if !(p.peek().kind is TkRBrace) {
    while true {
      let (field_name, p1) = p.expect_ident()
      let p2 = p1.expect(TkColon)
      let (field_type, p3) = p2.parse_type()
      p = p3
      fields.push((field_name, field_type))
      if p.peek().kind is TkComma {
        p = p.advance()
      } else {
        break
      }
    }
  }
  let p_final = p.expect(TkRBrace)
  (@ast.DStruct(name, fields, derives), p_final)
}

///|
/// 解析 enum 声明：enum Name { Variant1, Variant2, ... }
fn Parser::parse_enum_decl(self : Parser) -> (@ast.MoonDecl, Parser) {
  let parser = self.expect(TkEnum)
  let (name, parser) = parser.expect_ident()
  let p = parser.expect(TkLBrace)
  let mut p = p
  let variants : Array[String] = []
  if !(p.peek().kind is TkRBrace) {
    while true {
      let (variant_name, p1) = p.expect_ident()
      p = p1
      variants.push(variant_name)
      if p.peek().kind is TkComma {
        p = p.advance()
      } else {
        break
      }
    }
  }
  let p_final = p.expect(TkRBrace)
  (@ast.DEnum(name, variants), p_final)
}

///|
/// 解析 trait 声明：trait Name { fn method(params) -> ret_type; ... }
fn Parser::parse_trait_decl(self : Parser) -> (@ast.MoonDecl, Parser) {
  let parser = self.expect(TkTrait)
  let (name, parser) = parser.expect_ident()
  let p = parser.expect(TkLBrace)
  let mut p = p
  let methods : Array[@ast.TraitMethod] = []
  while !(p.peek().kind is TkRBrace) {
    if p.peek().kind is TkFn {
      let p1 = p.expect(TkFn)
      let (mname, p2) = p1.expect_ident()
      let (params, p3) = p2.parse_params()
      let (ret_type, p4) = p3.parse_return_type()
      p = p4
      if p.peek().kind is TkSemi {
        p = p.advance()
      }
      methods.push({ name: mname, params, ret_type, })
    } else {
      p = p.advance()
    }
  }
  let p_final = p.expect(TkRBrace)
  (@ast.DTrait(name, methods), p_final)
}

///|
/// 解析 impl 声明：impl Trait for Type { fn method(params) -> ret_type { body } ... }
fn Parser::parse_impl_decl(self : Parser) -> (@ast.MoonDecl, Parser) {
  let parser = self.expect(TkImpl)
  let (trait_name, parser) = parser.expect_ident()
  let parser = parser.expect(TkFor)
  let (type_name, parser) = parser.expect_ident()
  let parser = parser.expect(TkLBrace)
  let mut p = parser
  let methods : Array[@ast.ImplMethod] = []
  while !(p.peek().kind is TkRBrace) {
    if p.peek().kind is TkFn {
      let p1 = p.expect(TkFn)
      let (mname, p2) = p1.expect_ident()
      let (params, p3) = p2.parse_params()
      let (ret_type, p4) = p3.parse_return_type()
      let (body, p5) = p4.parse_block_expr()
      p = p5
      methods.push({ name: mname, params, ret_type, body, })
    } else {
      p = p.advance()
    }
  }
  let p_final = p.expect(TkRBrace)
  (@ast.DImpl(trait_name, type_name, methods), p_final)
}

///|
/// 解析类型注解。
fn Parser::parse_type(self : Parser) -> (@ast.MoonType, Parser) {
  let (name, parser) = self.expect_ident()
  let (ty, p) = match name {
    "Int" => (@ast.MInt, parser)
    "Double" => (@ast.MDouble, parser)
    "String" => (@ast.MString, parser)
    "Bool" => (@ast.MBool, parser)
    "Unit" => (@ast.MUnit, parser)
    "Char" => (@ast.MChar, parser)
    "Array" => {
      let p1 = parser.expect(TkLBracket)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(TkRBracket)
      (@ast.MArray(inner), p3)
    }
    "Map" => {
      let p1 = parser.expect(TkLBracket)
      let (k, p2) = p1.parse_type()
      let p3 = p2.expect(TkComma)
      let (v, p4) = p3.parse_type()
      let p5 = p4.expect(TkRBracket)
      (@ast.MMap(k, v), p5)
    }
    "Set" => {
      let p1 = parser.expect(TkLBracket)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(TkRBracket)
      (@ast.MSet(inner), p3)
    }
    "Option" => {
      let p1 = parser.expect(TkLBracket)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(TkRBracket)
      (@ast.MOption(inner), p3)
    }
    "Result" => {
      let p1 = parser.expect(TkLBracket)
      let (t, p2) = p1.parse_type()
      let p3 = p2.expect(TkComma)
      let (e, p4) = p3.parse_type()
      let p5 = p4.expect(TkRBracket)
      (@ast.MResult(t, e), p5)
    }
    _ => (@ast.MCustom(name), parser)
  }
  (ty, p)
}

///|
/// 解析表达式，返回表达式与新 Parser 状态。
pub fn Parser::parse_expr(self : Parser) -> (@ast.MoonExpr, Parser) {
  self.parse_expr_prec(0)
}

///|
/// 按优先级解析表达式。
fn Parser::parse_expr_prec(
  self : Parser,
  min_prec : Int32,
) -> (@ast.MoonExpr, Parser) {
  let (left0, parser0) = self.parse_primary()
  let mut left = left0
  let mut parser = parser0
  while true {
    let op = parser.peek().kind
    let prec = op_precedence(op)
    if prec < min_prec {
      break
    }
    if op is TkEof ||
      op is TkRBrace ||
      op is TkRParen ||
      op is TkRBracket ||
      op is TkSemi ||
      op is TkLBrace ||
      op is TkComma ||
      op is TkElse ||
      op is TkArrow ||
      op is TkFatArrow ||
      op is TkColon {
      break
    }
    let op_str = op_to_string(op)
    parser = parser.advance()
    let (right, p2) = parser.parse_expr_prec(prec + 1)
    parser = p2
    left = @ast.EBinOp(op_str, left, right)
  }
  (left, parser)
}

///|
/// 解析基本表达式。
fn Parser::parse_primary(self : Parser) -> (@ast.MoonExpr, Parser) {
  let token = self.peek()
  match token.kind {
    TkInt => {
      let parser = self.advance()
      let n = parse_int_safe(token.text)
      (@ast.EInt(n), parser)
    }
    TkString => {
      let parser = self.advance()
      let text = token.text
      let len = text.length()
      let content = if len >= 2 { text[1:len - 1].to_owned() } else { "" }
      (@ast.EString(content), parser)
    }
    TkTrue => {
      let parser = self.advance()
      (@ast.EBool(true), parser)
    }
    TkFalse => {
      let parser = self.advance()
      (@ast.EBool(false), parser)
    }
    TkIdent => {
      let name = token.text
      let parser = self.advance()
      if parser.peek().kind is TkLParen {
        let p1 = parser.advance()
        let mut p = p1
        let args : Array[@ast.MoonExpr] = []
        if !(p.peek().kind is TkRParen) {
          while true {
            let (arg, p2) = p.parse_expr()
            p = p2
            args.push(arg)
            if p.peek().kind is TkComma {
              p = p.advance()
            } else {
              break
            }
          }
        }
        let p_final = p.expect(TkRParen)
        (@ast.ECall(name, args), p_final)
      } else {
        (@ast.EVar(name), parser)
      }
    }
    TkIf => {
      let parser = self.advance()
      let (cond, p1) = parser.parse_expr()
      let (then_expr, p2) = p1.parse_block_expr()
      let (else_expr, p3) = if p2.peek().kind is TkElse {
        let p = p2.advance()
        p.parse_block_expr()
      } else {
        (@ast.EInt(0), p2)
      }
      (@ast.EIf(cond, then_expr, else_expr), p3)
    }
    TkMatch => {
      let parser = self.advance()
      let (scrutinee, p1) = parser.parse_expr()
      let (cases, p2) = p1.parse_match_arms()
      (@ast.EMatch(scrutinee, cases), p2)
    }
    _ => {
      let parser = self.advance()
      (@ast.EInt(0), parser)
    }
  }
}

///|
/// 解析块表达式 { expr }。
fn Parser::parse_block_expr(self : Parser) -> (@ast.MoonExpr, Parser) {
  let parser = self.expect(TkLBrace)
  let (expr, p) = parser.parse_expr()
  let p_final = p.expect(TkRBrace)
  (expr, p_final)
}

///|
/// 解析 match 分支列表 { Pattern => body, ... }
fn Parser::parse_match_arms(
  self : Parser,
) -> (Array[(@ast.MoonPattern, @ast.MoonExpr)], Parser) {
  let parser = self.expect(TkLBrace)
  let mut p = parser
  let cases : Array[(@ast.MoonPattern, @ast.MoonExpr)] = []
  while !(p.peek().kind is TkRBrace) {
    let (pat, p1) = p.parse_pattern()
    let p2 = p1.expect(TkFatArrow)
    let (body, p3) = p2.parse_expr()
    p = p3
    cases.push((pat, body))
    if p.peek().kind is TkComma {
      p = p.advance()
    }
  }
  let p_final = p.expect(TkRBrace)
  (cases, p_final)
}

///|
/// 解析模式匹配节点。
fn Parser::parse_pattern(self : Parser) -> (@ast.MoonPattern, Parser) {
  let token = self.peek()
  match token.kind {
    TkInt => {
      let parser = self.advance()
      let n = parse_int_safe(token.text)
      (@ast.PInt(n), parser)
    }
    TkString => {
      let parser = self.advance()
      let text = token.text
      let len = text.length()
      let content = if len >= 2 { text[1:len - 1].to_owned() } else { "" }
      (@ast.PString(content), parser)
    }
    TkIdent => {
      let name = token.text
      let parser = self.advance()
      if name == "_" {
        (@ast.PWild, parser)
      } else if parser.peek().kind is TkLParen {
        let p1 = parser.advance()
        let mut p = p1
        let args : Array[@ast.MoonPattern] = []
        if !(p.peek().kind is TkRParen) {
          while true {
            let (arg, p2) = p.parse_pattern()
            p = p2
            args.push(arg)
            if p.peek().kind is TkComma {
              p = p.advance()
            } else {
              break
            }
          }
        }
        let p_final = p.expect(TkRParen)
        (@ast.PCtor(name, args), p_final)
      } else {
        (@ast.PVar(name), parser)
      }
    }
    TkUIdent => {
      let name = token.text
      let parser = self.advance()
      if parser.peek().kind is TkLParen {
        let p1 = parser.advance()
        let mut p = p1
        let args : Array[@ast.MoonPattern] = []
        if !(p.peek().kind is TkRParen) {
          while true {
            let (arg, p2) = p.parse_pattern()
            p = p2
            args.push(arg)
            if p.peek().kind is TkComma {
              p = p.advance()
            } else {
              break
            }
          }
        }
        let p_final = p.expect(TkRParen)
        (@ast.PCtor(name, args), p_final)
      } else {
        (@ast.PCtor(name, []), parser)
      }
    }
    _ => {
      let parser = self.advance()
      (@ast.PWild, parser)
    }
  }
}

///|
/// 运算符优先级。
fn op_precedence(kind : TokenKind) -> Int32 {
  match kind {
    TkOrOr => 1
    TkAndAnd => 2
    TkEqEq => 3
    TkNotEq => 3
    TkLt => 4
    TkGt => 4
    TkLeEq => 4
    TkGrEq => 4
    TkPlus => 5
    TkMinus => 5
    TkStar => 6
    TkSlash => 6
    TkPercent => 6
    _ => 0
  }
}

///|
/// 运算符转字符串。
fn op_to_string(kind : TokenKind) -> String {
  match kind {
    TkPlus => "+"
    TkMinus => "-"
    TkStar => "*"
    TkSlash => "/"
    TkPercent => "%"
    TkEqEq => "=="
    TkNotEq => "!="
    TkLt => "<"
    TkGt => ">"
    TkLeEq => "<="
    TkGrEq => ">="
    TkAndAnd => "&&"
    TkOrOr => "||"
    _ => "+"
  }
}

///|
/// 查看当前 Token（不前进）。
fn Parser::peek(self : Parser) -> Token {
  self.tokens[self.pos]
}

///|
/// 前进一个 Token。
fn Parser::advance(self : Parser) -> Parser {
  { ..self, pos: self.pos + 1, }
}

///|
/// 是否到达文件末尾。
fn Parser::at_eof(self : Parser) -> Bool {
  self.peek().kind is TkEof
}

///|
/// 期望当前 Token 是指定种类，前进。
fn Parser::expect(self : Parser, _kind : TokenKind) -> Parser {
  self.advance()
}

///|
/// 期望当前 Token 是标识符，返回其文本并前进。
fn Parser::expect_ident(self : Parser) -> (String, Parser) {
  let token = self.peek()
  (token.text, self.advance())
}

///|
/// 安全解析整数字面量。
fn parse_int_safe(s : String) -> Int32 {
  let mut result = 0
  for ch in s.to_array() {
    if ch >= '0' && ch <= '9' {
      result = result * 10 + (ch.to_int() - '0'.to_int())
    } else {
      break
    }
  }
  result
}
