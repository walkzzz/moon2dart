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
/// 安全边界感知的转换管线（fail-closed）| Safety-boundary aware pipeline (fail-closed)
///
/// 默认 `UnresolvedPolicy::Error`：任何"算术操作数类型不可推断"都拒绝生成，
/// 不静默降级；`Warn` 生成 `[L2-UNRESOLVED]` 诊断注释；`Fast` 仅用于实验。
/// 返回（Dart 代码, 可审计报告）。
pub fn transpile_source_report(
  src : String,
  lib_name : String,
  mode : @ast.SemanticsMode,
  policy : @ast.UnresolvedPolicy,
) -> (String, @ast.TranspileReport) raise @ast.Moon2DartError {
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
  let unresolved = @typesys.collect_unresolved_arith(decls)
  let degraded = @typesys.collect_degraded_types(decls)
  let report : @ast.TranspileReport = { policy, unresolved, degraded, }
  if policy is @ast.Error && unresolved.length() > 0 {
    let first = unresolved[0]
    raise @ast.Moon2DartError::TypeError(
      "UNRESOLVED (fail-closed, policy=error): \{report.summary()}; first \{first.code} at \{first.site}: \{first.detail}",
    )
  }
  let mut result = @codegen.emit_dart_program_full(decls, lib_name, mode)
  if policy is @ast.Warn && unresolved.length() > 0 {
    let notes = unresolved
      .map(fn(d) { "// [L2-UNRESOLVED] \{d.site}: \{d.detail}" })
      .join("\n")
    result = "// === moon2dart safety report (policy=warn) ===\n\{notes}\n\n\{result}"
  }
  (result, report)
}

///|
/// 安全默认转换：Wrapping + fail-closed（推荐库调用入口）| Safe default: Wrapping + fail-closed (recommended library entry)
pub fn transpile_source_safe(src : String) -> String raise @ast.Moon2DartError {
  let (code, _report) = transpile_source_report(
    src,
    "libnative.so",
    @ast.Wrapping,
    @ast.Error,
  )
  code
}

///|
/// 报告 JSON 序列化（CI / 工具链消费）| Report JSON serialization (for CI / tooling)
pub fn report_to_json(r : @ast.TranspileReport) -> String {
  let policy = match r.policy {
    @ast.Error => "error"
    @ast.Warn => "warn"
    @ast.Fast => "fast"
  }
  let unresolved = r.unresolved
    .map(fn(d) {
      "{\"code\":\"\{json_escape(d.code)}\",\"site\":\"\{json_escape(d.site)}\",\"detail\":\"\{json_escape(d.detail)}\"}"
    })
    .join(",")
  let degraded = r.degraded
    .map(fn(d) {
      "{\"code\":\"\{json_escape(d.code)}\",\"site\":\"\{json_escape(d.site)}\",\"detail\":\"\{json_escape(d.detail)}\"}"
    })
    .join(",")
  "{\"policy\":\"\{policy}\",\"ok\":\{r.is_ok()},\"unresolved\":[\{unresolved}],\"degraded\":[\{degraded}]}"
}

///|
/// 报告 Markdown 序列化（人类可审计）| Report Markdown serialization (human-auditable)
pub fn report_to_markdown(r : @ast.TranspileReport) -> String {
  let policy = match r.policy {
    @ast.Error => "error"
    @ast.Warn => "warn"
    @ast.Fast => "fast"
  }
  let sb = StringBuilder()
  sb <+ "# moon2dart 安全报告 | Safety Report\n\n"
  sb <+ "- policy: `\{policy}`\n"
  sb <+ "- passing: `\{r.is_ok()}`\n"
  sb <+ "- unresolved: \{r.unresolved.length()}\n"
  sb <+ "- degraded: \{r.degraded.length()}\n\n"
  sb <+ "## Unresolved（拒绝或标注项）| Unresolved items\n\n"
  if r.unresolved.length() == 0 {
    sb <+ "（无 / none）\n\n"
  } else {
    sb <+ "| code | site | detail |\n|---|---|---|\n"
    for d in r.unresolved {
      sb <+ "| `\{d.code}` | `\{d.site}` | \{d.detail} |\n"
    }
    sb <+ "\n"
  }
  sb <+ "## Degraded（定级降级项）| Degraded items\n\n"
  if r.degraded.length() == 0 {
    sb <+ "（无 / none）\n"
  } else {
    sb <+ "| code | site | detail |\n|---|---|---|\n"
    for d in r.degraded {
      sb <+ "| `\{d.code}` | `\{d.site}` | \{d.detail} |\n"
    }
  }
  sb.to_string()
}

///|
/// JSON 字符串转义（最小实现：反斜杠、双引号、换行）| Minimal JSON string escaping
fn json_escape(s : String) -> String {
  let sb = StringBuilder()
  for ch in s {
    if ch == '\\' {
      sb.write_string("\\\\")
    } else if ch == '"' {
      sb.write_string("\\\"")
    } else if ch == '\n' {
      sb.write_string("\\n")
    } else if ch == '\r' {
      sb.write_string("\\r")
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
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
