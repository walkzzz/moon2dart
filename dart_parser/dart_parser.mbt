///|
/// Dart 语法分析器 — 将 Dart Token 流转换为 Dart AST。
///
/// 支持：顶层函数 / async 函数 / class / sealed class / abstract class / 基础表达式。

///|
/// Dart 语法分析器。
pub struct DartParser {
  tokens : Array[DartToken]
  pos : Int32
}

///|
/// 构造 Dart 语法分析器。
pub fn DartParser::make(tokens : Array[DartToken]) -> DartParser {
  { tokens, pos: 0, }
}

///|
/// 解析整个 Dart 程序（多个声明）。
pub fn DartParser::parse_program(
  self : DartParser,
) -> Array[@dart_ast.DartDecl] {
  let mut parser = self
  let decls : Array[@dart_ast.DartDecl] = []
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
/// 尝试解析一个 Dart 声明。
fn DartParser::try_parse_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl?, DartParser) {
  let kind = self.peek().kind
  match kind {
    DtSealed => {
      let (decl, p) = self.parse_sealed_class_decl()
      (Some(decl), p)
    }
    DtAbstract => {
      let (decl, p) = self.parse_abstract_class_decl()
      (Some(decl), p)
    }
    DtClass => {
      let (decl, p) = self.parse_class_decl()
      (Some(decl), p)
    }
    DtFutureType => {
      let (decl, p) = self.parse_async_fn_decl()
      (Some(decl), p)
    }
    DtVoid => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtIntType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtDoubleType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtStringType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtBoolType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtListType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtMapType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtSetType => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    DtUIdent => {
      let (decl, p) = self.parse_fn_decl()
      (Some(decl), p)
    }
    _ => (None, self)
  }
}

///|
/// 解析 Dart 类型。
fn DartParser::parse_type(
  self : DartParser,
) -> (@dart_ast.DartType, DartParser) {
  let token = self.peek()
  match token.kind {
    DtVoid => (@dart_ast.DVoid, self.advance())
    DtIntType => (@dart_ast.DInt, self.advance())
    DtDoubleType => (@dart_ast.DDouble, self.advance())
    DtStringType => (@dart_ast.DString, self.advance())
    DtBoolType => (@dart_ast.DBool, self.advance())
    DtUIdent => {
      let name = token.text
      let parser = self.advance()
      if parser.peek().kind is DtLt {
        let p1 = parser.advance()
        let (inner, p2) = p1.parse_type()
        let p3 = p2.expect(DtGt)
        let inner_str = dart_debug_type(inner)
        (@dart_ast.DCustom("\{name}<\{inner_str}>"), p3)
      } else {
        (@dart_ast.DCustom(name), parser)
      }
    }
    DtListType => {
      let parser = self.advance()
      let p1 = parser.expect(DtLt)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(DtGt)
      (@dart_ast.DList(inner), p3)
    }
    DtMapType => {
      let parser = self.advance()
      let p1 = parser.expect(DtLt)
      let (k, p2) = p1.parse_type()
      let p3 = p2.expect(DtComma)
      let (v, p4) = p3.parse_type()
      let p5 = p4.expect(DtGt)
      (@dart_ast.DMap(k, v), p5)
    }
    DtSetType => {
      let parser = self.advance()
      let p1 = parser.expect(DtLt)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(DtGt)
      (@dart_ast.DSet(inner), p3)
    }
    DtFutureType => {
      let parser = self.advance()
      let p1 = parser.expect(DtLt)
      let (inner, p2) = p1.parse_type()
      let p3 = p2.expect(DtGt)
      (@dart_ast.DFuture(inner), p3)
    }
    DtIdent => {
      let name = token.text
      let parser = self.advance()
      (@dart_ast.DCustom(name), parser)
    }
    _ => (@dart_ast.DCustom(token.text), self.advance())
  }
}

///|
/// 临时辅助：获取 DartType 的调试字符串（用于泛型嵌套）。
fn dart_debug_type(t : @dart_ast.DartType) -> String {
  match t {
    @dart_ast.DInt => "int"
    @dart_ast.DDouble => "double"
    @dart_ast.DBool => "bool"
    @dart_ast.DString => "String"
    @dart_ast.DVoid => "void"
    @dart_ast.DList(inner) => {
      let s = dart_debug_type(inner)
      "List<\{s}>"
    }
    @dart_ast.DMap(k, v) => {
      let ks = dart_debug_type(k)
      let vs = dart_debug_type(v)
      "Map<\{ks}, \{vs}>"
    }
    @dart_ast.DSet(inner) => {
      let s = dart_debug_type(inner)
      "Set<\{s}>"
    }
    @dart_ast.DNullable(inner) => {
      let s = dart_debug_type(inner)
      "\{s}?"
    }
    @dart_ast.DFuture(inner) => {
      let s = dart_debug_type(inner)
      "Future<\{s}>"
    }
    @dart_ast.DCustom(name) => name
    @dart_ast.DRune => "int"
  }
}

///|
/// 解析参数列表：(Type name, Type name, ...)
fn DartParser::parse_params(
  self : DartParser,
) -> (Array[(String, @dart_ast.DartType)], DartParser) {
  let parser = self.expect(DtLParen)
  let mut p = parser
  let params : Array[(String, @dart_ast.DartType)] = []
  if !(p.peek().kind is DtRParen) {
    while true {
      let (ty, p1) = p.parse_type()
      let (name, p2) = p1.expect_ident()
      p = p2
      params.push((name, ty))
      if p.peek().kind is DtComma {
        p = p.advance()
      } else {
        break
      }
    }
  }
  let p_final = p.expect(DtRParen)
  (params, p_final)
}

///|
/// 解析顶层函数声明：Type name(params) { return expr; }
fn DartParser::parse_fn_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl, DartParser) {
  let (ret_type, parser) = self.parse_type()
  let (name, parser) = parser.expect_ident()
  let (params, parser) = parser.parse_params()
  let parser = parser.expect(DtLBrace)
  let (body, p) = parser.parse_block_body()
  let p_final = p.expect(DtRBrace)
  (@dart_ast.DTopFn(name, [], params, ret_type, body), p_final)
}

///|
/// 解析 async 函数声明：Future<Type> name(params) async { return expr; }
fn DartParser::parse_async_fn_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl, DartParser) {
  let (ret_type, parser) = self.parse_type()
  let (name, parser) = parser.expect_ident()
  let (params, parser) = parser.parse_params()
  let parser = if parser.peek().kind is DtAsync {
    parser.advance()
  } else {
    parser
  }
  let parser = parser.expect(DtLBrace)
  let (body, p) = parser.parse_block_body()
  let p_final = p.expect(DtRBrace)
  (@dart_ast.DAsyncTopFn(name, [], params, ret_type, body), p_final)
}

///|
/// 解析 class 声明：class Name { Type field; ... Type method(params) { ... } }
fn DartParser::parse_class_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl, DartParser) {
  let parser = self.expect(DtClass)
  let (name, parser) = parser.expect_ident()
  let parser = parser.expect(DtLBrace)
  let mut p = parser
  let fields : Array[(String, @dart_ast.DartType)] = []
  let methods : Array[@dart_ast.DartMethod] = []
  while !(p.peek().kind is DtRBrace) {
    let (result, p2) = p.parse_class_member()
    match result {
      Some(field) => {
        let (fname, ftype) = field
        fields.push((fname, ftype))
        p = p2
      }
      None => {
        let (m, p3) = p2.parse_method(name)
        methods.push(m)
        p = p3
      }
    }
  }
  let p_final = p.expect(DtRBrace)
  (@dart_ast.DClass(name, [], fields, methods), p_final)
}

///|
/// 解析 sealed class 声明：sealed class Name { class Variant1 ... class Variant2(...) ... }
fn DartParser::parse_sealed_class_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl, DartParser) {
  let parser = self.expect(DtSealed)
  let parser = parser.expect(DtClass)
  let (name, parser) = parser.expect_ident()
  let parser = parser.expect(DtLBrace)
  let mut p = parser
  let variants : Array[@dart_ast.DartVariant] = []
  while !(p.peek().kind is DtRBrace) {
    if p.peek().kind is DtClass {
      let p1 = p.advance()
      let (vname, p2) = p1.expect_ident()
      let (vfields, p3) = p2.parse_variant_fields()
      variants.push(@dart_ast.DartVariant::{ name: vname, fields: vfields, })
      p = p3
    } else {
      p = p.advance()
    }
  }
  let p_final = p.expect(DtRBrace)
  (@dart_ast.DSealedClass(name, variants), p_final)
}

///|
/// 解析 abstract class 声明：abstract class Name { Type method(params); ... }
fn DartParser::parse_abstract_class_decl(
  self : DartParser,
) -> (@dart_ast.DartDecl, DartParser) {
  let parser = self.expect(DtAbstract)
  let parser = parser.expect(DtClass)
  let (name, parser) = parser.expect_ident()
  let parser = parser.expect(DtLBrace)
  let mut p = parser
  let methods : Array[@dart_ast.DartMethod] = []
  while !(p.peek().kind is DtRBrace) {
    let (m, p2) = p.parse_abstract_method()
    methods.push(m)
    p = p2
  }
  let p_final = p.expect(DtRBrace)
  (@dart_ast.DAbstractClass(name, methods), p_final)
}

///|
/// 解析 class 成员（字段或方法）。
fn DartParser::parse_class_member(
  self : DartParser,
) -> ((String, @dart_ast.DartType)?, DartParser) {
  let p = self
  let (ty, p1) = p.parse_type()
  let (name, p2) = p1.expect_ident()
  if p2.peek().kind is DtSemi {
    let p3 = p2.advance()
    (Some((name, ty)), p3)
  } else {
    (None, p)
  }
}

///|
/// 解析方法定义：Type method(params) { return expr; }
fn DartParser::parse_method(
  self : DartParser,
  _class_name : String,
) -> (@dart_ast.DartMethod, DartParser) {
  let (ret_type, parser) = self.parse_type()
  let (name, parser) = parser.expect_ident()
  let (params, parser) = parser.parse_params()
  let parser = parser.expect(DtLBrace)
  let (body, p) = parser.parse_block_body()
  let p_final = p.expect(DtRBrace)
  let m = @dart_ast.DartMethod::{
    name,
    params,
    ret_type,
    body,
    is_async: false,
  }
  (m, p_final)
}

///|
/// 解析抽象方法签名：Type method(params);
fn DartParser::parse_abstract_method(
  self : DartParser,
) -> (@dart_ast.DartMethod, DartParser) {
  let (ret_type, parser) = self.parse_type()
  let (name, parser) = parser.expect_ident()
  let (params, parser) = parser.parse_params()
  let p_final = parser.expect(DtSemi)
  let m = @dart_ast.DartMethod::{
    name,
    params,
    ret_type,
    body: @dart_ast.DNullLit,
    is_async: false,
  }
  (m, p_final)
}

///|
/// 解析变体字段：class Variant(Type field, ...) 或 class Variant
fn DartParser::parse_variant_fields(
  self : DartParser,
) -> (Array[(String, @dart_ast.DartType)], DartParser) {
  if !(self.peek().kind is DtLParen) {
    return ([], self)
  }
  let parser = self.expect(DtLParen)
  let mut p = parser
  let fields : Array[(String, @dart_ast.DartType)] = []
  if !(p.peek().kind is DtRParen) {
    while true {
      let (ty, p1) = p.parse_type()
      let (name, p2) = p1.expect_ident()
      p = p2
      fields.push((name, ty))
      if p.peek().kind is DtComma {
        p = p.advance()
      } else {
        break
      }
    }
  }
  let p_final = p.expect(DtRParen)
  let p_final = if p_final.peek().kind is DtSemi {
    p_final.advance()
  } else {
    p_final
  }
  (fields, p_final)
}

///|
/// 解析函数体中的表达式（支持 return expr; 和直接 expr;）。
fn DartParser::parse_block_body(
  self : DartParser,
) -> (@dart_ast.DartExpr, DartParser) {
  let p = self
  if p.peek().kind is DtReturn {
    let p1 = p.advance()
    let (expr, p2) = p1.parse_expr()
    let p3 = p2.expect(DtSemi)
    (expr, p3)
  } else {
    let (expr, p2) = p.parse_expr()
    let p3 = p2.expect(DtSemi)
    (expr, p3)
  }
}

///|
/// 解析表达式。
pub fn DartParser::parse_expr(
  self : DartParser,
) -> (@dart_ast.DartExpr, DartParser) {
  self.parse_expr_prec(0)
}

///|
/// 按优先级解析表达式。
fn DartParser::parse_expr_prec(
  self : DartParser,
  min_prec : Int32,
) -> (@dart_ast.DartExpr, DartParser) {
  let (left0, parser0) = self.parse_primary()
  let mut left = left0
  let mut parser = parser0
  while true {
    let op = parser.peek().kind
    let prec = dart_op_precedence(op)
    if prec < min_prec {
      break
    }
    if op is DtEof ||
      op is DtRBrace ||
      op is DtRParen ||
      op is DtRBracket ||
      op is DtSemi ||
      op is DtComma ||
      op is DtColon ||
      op is DtLBrace {
      break
    }
    let op_str = dart_op_to_string(op)
    parser = parser.advance()
    let (right, p2) = parser.parse_expr_prec(prec + 1)
    parser = p2
    left = @dart_ast.DBinOp(op_str, left, right)
  }
  (left, parser)
}

///|
/// 解析基本表达式。
fn DartParser::parse_primary(
  self : DartParser,
) -> (@dart_ast.DartExpr, DartParser) {
  let token = self.peek()
  match token.kind {
    DtInt => {
      let parser = self.advance()
      let n = parse_dart_int_safe(token.text)
      (@dart_ast.DIntLit(n), parser)
    }
    DtDouble => {
      let parser = self.advance()
      (@dart_ast.DDoubleLit(0.0), parser)
    }
    DtString => {
      let parser = self.advance()
      let content = extract_string_content(token.text)
      (@dart_ast.DStringLit(content), parser)
    }
    DtTrue => {
      let parser = self.advance()
      (@dart_ast.DBoolLit(true), parser)
    }
    DtFalse => {
      let parser = self.advance()
      (@dart_ast.DBoolLit(false), parser)
    }
    DtNull => {
      let parser = self.advance()
      (@dart_ast.DNullLit, parser)
    }
    DtIdent => {
      let name = token.text
      let parser = self.advance()
      if parser.peek().kind is DtLParen {
        let p1 = parser.advance()
        let mut p = p1
        let args : Array[@dart_ast.DartExpr] = []
        if !(p.peek().kind is DtRParen) {
          while true {
            let (arg, p2) = p.parse_expr()
            p = p2
            args.push(arg)
            if p.peek().kind is DtComma {
              p = p.advance()
            } else {
              break
            }
          }
        }
        let p_final = p.expect(DtRParen)
        (@dart_ast.DFunctionCall(name, args), p_final)
      } else if parser.peek().kind is DtDot {
        let p1 = parser.advance()
        let (method_name, p2) = p1.expect_ident()
        if p2.peek().kind is DtLParen {
          let p3 = p2.advance()
          let mut p = p3
          let args : Array[@dart_ast.DartExpr] = []
          if !(p.peek().kind is DtRParen) {
            while true {
              let (arg, p4) = p.parse_expr()
              p = p4
              args.push(arg)
              if p.peek().kind is DtComma {
                p = p.advance()
              } else {
                break
              }
            }
          }
          let p_final = p.expect(DtRParen)
          (@dart_ast.DMethodCall(name, method_name, args), p_final)
        } else {
          (@dart_ast.DVarRef(name), p1)
        }
      } else {
        (@dart_ast.DVarRef(name), parser)
      }
    }
    DtAwait => {
      let parser = self.advance()
      let (inner, p1) = parser.parse_primary()
      (@dart_ast.DAwaitExpr(inner), p1)
    }
    DtIf => {
      let parser = self.advance()
      let (cond, p1) = parser.parse_expr()
      let p2 = p1.expect(DtLBrace)
      let (then_expr, p3) = p2.parse_block_body()
      let p4 = p3.expect(DtRBrace)
      let (else_expr, p5) = if p4.peek().kind is DtElse {
        let p = p4.advance()
        if p.peek().kind is DtIf {
          let (e, p_next) = p.parse_primary()
          (e, p_next)
        } else {
          let p_brace = p.expect(DtLBrace)
          let (e, p_body) = p_brace.parse_block_body()
          let p_close = p_body.expect(DtRBrace)
          (e, p_close)
        }
      } else {
        (@dart_ast.DNullLit, p4)
      }
      (@dart_ast.DIfExpr(cond, then_expr, else_expr), p5)
    }
    _ => {
      let parser = self.advance()
      (@dart_ast.DNullLit, parser)
    }
  }
}

///|
/// 运算符优先级。
fn dart_op_precedence(kind : DartTokenKind) -> Int32 {
  match kind {
    DtOrOr => 1
    DtAndAnd => 2
    DtEqEq => 3
    DtNotEq => 3
    DtLt => 4
    DtGt => 4
    DtLeEq => 4
    DtGrEq => 4
    DtPlus => 5
    DtMinus => 5
    DtStar => 6
    DtSlash => 6
    DtPercent => 6
    _ => 0
  }
}

///|
/// 运算符转字符串。
fn dart_op_to_string(kind : DartTokenKind) -> String {
  match kind {
    DtPlus => "+"
    DtMinus => "-"
    DtStar => "*"
    DtSlash => "/"
    DtPercent => "%"
    DtEqEq => "=="
    DtNotEq => "!="
    DtLt => "<"
    DtGt => ">"
    DtLeEq => "<="
    DtGrEq => ">="
    DtAndAnd => "&&"
    DtOrOr => "||"
    _ => "+"
  }
}

///|
/// 查看当前 Token（不前进）。
fn DartParser::peek(self : DartParser) -> DartToken {
  self.tokens[self.pos]
}

///|
/// 前进一个 Token。
fn DartParser::advance(self : DartParser) -> DartParser {
  { ..self, pos: self.pos + 1, }
}

///|
/// 是否到达文件末尾。
fn DartParser::at_eof(self : DartParser) -> Bool {
  self.peek().kind is DtEof
}

///|
/// 期望当前 Token 是指定种类，前进。
fn DartParser::expect(self : DartParser, _kind : DartTokenKind) -> DartParser {
  self.advance()
}

///|
/// 期望当前 Token 是标识符，返回其文本并前进。
fn DartParser::expect_ident(self : DartParser) -> (String, DartParser) {
  let token = self.peek()
  (token.text, self.advance())
}

///|
/// 安全解析整数字面量。
fn parse_dart_int_safe(s : String) -> Int32 {
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

///|
/// 提取字符串字面量内容（去掉引号）。
fn extract_string_content(text : String) -> String {
  let len = text.length()
  if len >= 2 {
    text[1:len - 1].to_owned()
  } else {
    ""
  }
}
