///|
/// transpile 编排入口 — 将 MoonBit AST 声明数组转为 Dart 代码字符串 | Transpile orchestration entry — convert MoonBit AST declarations to Dart code string
pub fn transpile(decls : Array[@ast.MoonDecl]) -> String {
  @codegen.emit_dart_program(decls)
}

///|
/// transpile 编排入口（可指定 FFI 库名）| Transpile orchestration entry (with configurable FFI library name)
pub fn transpile_with_lib(
  decls : Array[@ast.MoonDecl],
  lib_name : String,
) -> String {
  @codegen.emit_dart_program_with_lib(decls, lib_name)
}

///|
/// 单文件转换管线 — MoonBit 源码字符串 → Dart 代码字符串 | Single-file pipeline — MoonBit source string to Dart code string
/// 管线：source → Lexer::tokenize → Parser::parse_program → emit_dart_program | Pipeline: source → Lexer::tokenize → Parser::parse_program → emit_dart_program
pub fn transpile_source(src : String) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  let result = @codegen.emit_dart_program(decls)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError("codegen produced empty output")
  }
  result
}

///|
/// 单文件转换管线（可指定 FFI 库名）| Single-file pipeline (with configurable FFI library name)
pub fn transpile_source_with_lib(
  src : String,
  lib_name : String,
) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  let result = @codegen.emit_dart_program_with_lib(decls, lib_name)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError("codegen produced empty output")
  }
  result
}

///|
/// 单文件转换管线（纯子集模式，跳过 FFI 声明）| Single-file pipeline (pure subset mode, skips FFI declarations)
pub fn transpile_source_pure(src : String) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  let pure_decls = @codegen.filter_pure(decls)
  if pure_decls.length() == 0 {
    raise @ast.Moon2DartError::TranspileError(
      "no pure declarations after filtering",
    )
  }
  let result = @codegen.emit_dart_program(pure_decls)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError("codegen produced empty output")
  }
  result
}

///|
/// 单文件转换管线（完整选项：FFI 库名 + 语义模式）| Single-file pipeline (full options: FFI library name + semantics mode)
///
/// Wrapping（默认）：Int 算术生成 mb32* 回绕模拟层，两端运行结果一致（32 位 wasm i32 语义）。
/// Fast：裸发地道 Dart，Int 自动降级 L2 并追加 [L2-SEMANTICS] 诊断注释。
pub fn transpile_source_with_options(
  src : String,
  lib_name : String,
  mode : @ast.SemanticsMode,
) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  let result = @codegen.emit_dart_program_full(decls, lib_name, mode)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError("codegen produced empty output")
  }
  result
}

///|
/// 单文件转换管线（语义模式感知）| Single-file pipeline (semantics-mode aware)
pub fn transpile_source_with_mode(
  src : String,
  mode : @ast.SemanticsMode,
) -> String raise @ast.Moon2DartError {
  transpile_source_with_options(src, "libnative.so", mode)
}

///|
/// 严格模式转换管线 — L4 类型 raise 错误，L3 类型保留诊断注释 | Strict mode pipeline — L4 types raise error, L3 types keep diagnostic comments
pub fn transpile_source_strict(
  src : String,
) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  // 检查所有声明中的类型是否有 L4 类型 — map_type_strict 会 raise
  for d in decls {
    for t in @ast.collect_types_from_decl(d) {
      let _ = @typesys.map_type_strict(t)
    }
  }
  let result = @codegen.emit_dart_program(decls)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError("codegen produced empty output")
  }
  result
}

///|
/// 便捷：转换单个声明为 Dart 代码字符串 | Convenience: transpile a single declaration to Dart code string
pub fn transpile_decl(decl : @ast.MoonDecl) -> String {
  @codegen.emit_dart_decl(decl)
}

///|
/// 便捷：转换表达式为 Dart 代码字符串 | Convenience: transpile an expression to Dart code string
pub fn transpile_expr(expr : @ast.MoonExpr) -> String {
  @codegen.emit_dart_expr(expr)
}

///|
/// 便捷：MoonBit 类型 → Dart 类型字符串 | Convenience: MoonBit type to Dart type string
pub fn transpile_type(t : @ast.MoonType) -> String {
  @typesys.moon_to_dart_type(t)
}

///|
/// Flutter 转换入口 — 将 MoonBit AST 声明数组转为完整 Flutter 应用代码 | Flutter transpile entry — convert MoonBit AST declarations to full Flutter app code
pub fn transpile_flutter(decls : Array[@ast.MoonDecl]) -> String {
  @codegen.emit_flutter_program(decls)
}

///|
/// 单文件 Flutter 转换管线 — MoonBit 源码字符串 → Flutter 应用代码字符串 | Single-file Flutter pipeline — MoonBit source string to Flutter app code string
pub fn transpile_source_flutter(
  src : String,
) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ParseError("empty source code")
  }
  let tokens = @parser.Lexer::make(src).tokenize()
  if tokens.length() == 0 {
    raise @ast.Moon2DartError::ParseError("lexer produced no tokens")
  }
  let decls = @parser.Parser::make(tokens).parse_program()
  if decls.length() == 0 {
    raise @ast.Moon2DartError::ParseError("parser produced no declarations")
  }
  let result = @codegen.emit_flutter_program(decls)
  if result.length() == 0 {
    raise @ast.Moon2DartError::TranspileError(
      "flutter codegen produced empty output",
    )
  }
  result
}

///|
// === 反向转换 API（Dart → MoonBit）=== | === Reverse transpile API (Dart → MoonBit) ===

///|
/// 反向转换 — Dart AST 声明数组 → MoonBit 源码字符串 | Reverse transpile — Dart AST declarations to MoonBit source string
pub fn reverse_transpile(decls : Array[@dart_ast.DartDecl]) -> String {
  @reverse_codegen.emit_moon_program(decls)
}

///|
/// 反向转换管线 — Dart 源码字符串 → MoonBit 源码字符串 | Reverse pipeline — Dart source string to MoonBit source string
pub fn reverse_transpile_source(
  src : String,
) -> String raise @ast.Moon2DartError {
  if src.trim().length() == 0 {
    raise @ast.Moon2DartError::ReverseTranspileError("empty Dart source code")
  }
  let result = @reverse_codegen.reverse_transpile_source(src)
  if result.length() == 0 {
    raise @ast.Moon2DartError::ReverseTranspileError(
      "reverse transpile produced empty output",
    )
  }
  result
}

///|
/// 便捷：Dart 类型 → MoonBit 类型字符串 | Convenience: Dart type to MoonBit type string
pub fn reverse_transpile_type(t : @dart_ast.DartType) -> String {
  t.to_moon_string()
}

///|
/// 便捷：Dart 表达式 → MoonBit 表达式字符串 | Convenience: Dart expression to MoonBit expression string
pub fn reverse_transpile_expr(e : @dart_ast.DartExpr) -> String {
  @reverse_codegen.emit_moon_expr(e)
}

///|
/// 便捷：Dart 声明 → MoonBit 声明字符串 | Convenience: Dart declaration to MoonBit declaration string
pub fn reverse_transpile_decl(d : @dart_ast.DartDecl) -> String {
  @reverse_codegen.emit_moon_decl(d)
}
