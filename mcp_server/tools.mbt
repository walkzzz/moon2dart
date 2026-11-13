///|
/// mcp_server 公共工具执行逻辑 — server.mbt 和 agent.mbt 共享的工具执行入口。

///|

///|
/// 分析 MoonBit 源码结构 — 解析源码并返回 AST 摘要。
fn analyze_source(source : String) -> String {
  let lexer = @parser.Lexer::make(source)
  let tokens = lexer.tokenize()
  let parser = @parser.Parser::make(tokens)
  let decls = parser.parse_program()
  let lines : Array[String] = []
  lines.push("Found \{decls.length()} declarations:")
  for decl in decls {
    match decl {
      @ast.DFn(name, _, params, ret_type, _) =>
        lines.push(
          "  - fn \{name}(\{params.map(fn(p) { p.0 }).join(", ")}) -> \{ret_type.to_moon_string()}",
        )
      @ast.DStruct(name, _, fields, _) =>
        lines.push(
          "  - struct \{name} { \{fields.map(fn(f) { f.0 }).join(", ")} }",
        )
      @ast.DEnum(name, variants) =>
        lines.push("  - enum \{name} { \{variants.join(", ")} }")
      @ast.DTrait(name, methods) =>
        lines.push("  - trait \{name} (\{methods.length()} methods)")
      @ast.DImpl(trait_name, type_name, _) =>
        lines.push("  - impl \{trait_name} for \{type_name}")
      @ast.DExternFn(name, _, ret_type, _) =>
        lines.push("  - extern fn \{name}(...) -> \{ret_type.to_moon_string()}")
      @ast.DAsyncFn(name, _, params, ret_type, _) =>
        lines.push(
          "  - async fn \{name}(\{params.map(fn(p) { p.0 }).join(", ")}) -> \{ret_type.to_moon_string()}",
        )
    }
  }
  lines.push("Token count: \{tokens.length()}")
  lines.join("\n")
}

///|
/// 列出所有可用工具及其参数描述。
fn list_tools_info() -> String {
  [
    "moon2dart_convert: Convert MoonBit source to Dart", "moon2dart_reverse: Convert Dart source to MoonBit",
    "moon2dart_flutter: Convert MoonBit to Flutter widget code", "moon2dart_analyze: Analyze MoonBit code structure",
    "moon2dart_project: Scan and convert a MoonBit project", "moon2dart_list_tools: List all available tools",
  ].join("\n")
}
