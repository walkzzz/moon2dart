///|
/// transpile 编排入口 — 将 MoonBit AST 声明数组转为 Dart 代码字符串。
pub fn transpile(decls : Array[@ast.MoonDecl]) -> String {
  @codegen.emit_dart_program(decls)
}

///|
/// 单文件转换管线 — MoonBit 源码字符串 → Dart 代码字符串。
///
/// 管线：source → Lexer::tokenize → Parser::parse_program → emit_dart_program
pub fn transpile_source(src : String) -> String {
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  @codegen.emit_dart_program(decls)
}

///|
/// 便捷：转换单个声明为 Dart 代码字符串。
pub fn transpile_decl(decl : @ast.MoonDecl) -> String {
  @codegen.emit_dart_decl(decl)
}

///|
/// 便捷：转换表达式为 Dart 代码字符串。
pub fn transpile_expr(expr : @ast.MoonExpr) -> String {
  @codegen.emit_dart_expr(expr)
}

///|
/// 便捷：MoonBit 类型 → Dart 类型字符串。
pub fn transpile_type(t : @ast.MoonType) -> String {
  @typesys.moon_to_dart_type(t)
}
