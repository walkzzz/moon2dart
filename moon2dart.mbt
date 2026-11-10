///|
/// transpile 编排入口 — 将 MoonBit AST 声明数组转为 Dart 代码字符串。
pub fn transpile(decls : Array[@ast.MoonDecl]) -> String {
  @codegen.emit_dart_program(decls)
}

///|
/// transpile 编排入口（可指定 FFI 库名）。
pub fn transpile_with_lib(
  decls : Array[@ast.MoonDecl],
  lib_name : String,
) -> String {
  @codegen.emit_dart_program_with_lib(decls, lib_name)
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
/// 单文件转换管线（可指定 FFI 库名）。
pub fn transpile_source_with_lib(src : String, lib_name : String) -> String {
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  @codegen.emit_dart_program_with_lib(decls, lib_name)
}

///|
/// 单文件转换管线（纯子集模式，跳过 FFI 声明）。
pub fn transpile_source_pure(src : String) -> String {
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  let pure_decls = @codegen.filter_pure(decls)
  @codegen.emit_dart_program(pure_decls)
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

///|
/// Flutter 转换入口 — 将 MoonBit AST 声明数组转为完整 Flutter 应用代码。
pub fn transpile_flutter(decls : Array[@ast.MoonDecl]) -> String {
  @codegen.emit_flutter_program(decls)
}

///|
/// 单文件 Flutter 转换管线 — MoonBit 源码字符串 → Flutter 应用代码字符串。
pub fn transpile_source_flutter(src : String) -> String {
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  @codegen.emit_flutter_program(decls)
}

///|
// === 反向转换 API（Dart → MoonBit）===

///|
/// 反向转换 — Dart AST 声明数组 → MoonBit 源码字符串。
pub fn reverse_transpile(decls : Array[@dart_ast.DartDecl]) -> String {
  @reverse_codegen.emit_moon_program(decls)
}

///|
/// 反向转换管线 — Dart 源码字符串 → MoonBit 源码字符串。
pub fn reverse_transpile_source(src : String) -> String {
  @reverse_codegen.reverse_transpile_source(src)
}

///|
/// 便捷：Dart 类型 → MoonBit 类型字符串。
pub fn reverse_transpile_type(t : @dart_ast.DartType) -> String {
  @reverse_codegen.dart_type_to_moon(t)
}

///|
/// 便捷：Dart 表达式 → MoonBit 表达式字符串。
pub fn reverse_transpile_expr(e : @dart_ast.DartExpr) -> String {
  @reverse_codegen.emit_moon_expr(e)
}

///|
/// 便捷：Dart 声明 → MoonBit 声明字符串。
pub fn reverse_transpile_decl(d : @dart_ast.DartDecl) -> String {
  @reverse_codegen.emit_moon_decl(d)
}
