///|
/// moon2dart MCP 服务器核心逻辑 — MoonBit ↔ Dart 双向转换 MCP 工具。
///
/// 双模式架构：
///   工具模式（默认）: MCPServer + 6 工具注册，STDIO/HTTP 传输，兼容标准 MCP 客户端
///   Agent 模式（--agent）: posoco Agent 循环，LLM 理解意图 → 自动选择工具

// ============================================================
// 工具 Handler — 非 async，返回 ToolResult（消除 unused_async + result_error_return）
// ============================================================

///|
/// moon2dart_convert — 单文件 MoonBit → Dart 转换。
/// 参数: source (string, required), lib_name (string, optional)
fn handle_convert(
  _ctx : @mcpsdk.RequestContext,
  args : Json,
) -> @mcpsdk.ToolResult {
  let source = match @mcpsdk.get_string(args, "source") {
    Ok(s) => s
    Err(_) => return @mcpsdk.ToolResult::error("missing 'source' parameter")
  }
  let lib_name = match @mcpsdk.get_optional_string(args, "lib_name") {
    Ok(Some(name)) => name
    _ => "libnative.so"
  }
  let dart_code = try @lib.transpile_source_with_lib(source, lib_name) catch {
    @ast.Moon2DartError::ParseError(msg) => return @mcpsdk.ToolResult::error("Parse error: " + msg)
    @ast.Moon2DartError::TranspileError(msg) => return @mcpsdk.ToolResult::error("Transpile error: " + msg)
    _ => return @mcpsdk.ToolResult::error("Unexpected error during conversion")
  }
  @mcpsdk.ToolResult::text(dart_code)
}

///|
/// moon2dart_reverse — Dart → MoonBit 反向转换。
/// 参数: source (string, required)
fn handle_reverse(
  _ctx : @mcpsdk.RequestContext,
  args : Json,
) -> @mcpsdk.ToolResult {
  let source = match @mcpsdk.get_string(args, "source") {
    Ok(s) => s
    Err(_) => return @mcpsdk.ToolResult::error("missing 'source' parameter")
  }
  let moon_code = try @lib.reverse_transpile_source(source) catch {
    @ast.Moon2DartError::ReverseTranspileError(msg) => return @mcpsdk.ToolResult::error("Reverse transpile error: " + msg)
    _ => return @mcpsdk.ToolResult::error("Unexpected error during reverse conversion")
  }
  @mcpsdk.ToolResult::text(moon_code)
}

///|
/// moon2dart_flutter — MoonBit → Flutter widget 转换。
/// 参数: source (string, required)
fn handle_flutter(
  _ctx : @mcpsdk.RequestContext,
  args : Json,
) -> @mcpsdk.ToolResult {
  let source = match @mcpsdk.get_string(args, "source") {
    Ok(s) => s
    Err(_) => return @mcpsdk.ToolResult::error("missing 'source' parameter")
  }
  let flutter_code = try @lib.transpile_source_flutter(source) catch {
    @ast.Moon2DartError::ParseError(msg) => return @mcpsdk.ToolResult::error("Parse error: " + msg)
    @ast.Moon2DartError::TranspileError(msg) => return @mcpsdk.ToolResult::error("Transpile error: " + msg)
    _ => return @mcpsdk.ToolResult::error("Unexpected error during Flutter conversion")
  }
  @mcpsdk.ToolResult::text(flutter_code)
}

///|
/// moon2dart_analyze — 分析 MoonBit 代码结构，返回 AST 摘要。
/// 参数: source (string, required)
fn handle_analyze(
  _ctx : @mcpsdk.RequestContext,
  args : Json,
) -> @mcpsdk.ToolResult {
  let source = match @mcpsdk.get_string(args, "source") {
    Ok(s) => s
    Err(_) => return @mcpsdk.ToolResult::error("missing 'source' parameter")
  }
  @mcpsdk.ToolResult::text(analyze_source(source))
}

///|
/// moon2dart_project — 项目级 MoonBit 扫描与结构分析。
/// 参数: dir (string, required)
///
/// 注意：项目扫描需要 async I/O，在 ToolWrapper 的非 async 回调中无法执行。
/// 请使用 CLI 命令 `moon2dart project <dir>` 进行项目级扫描。
fn handle_project(
  _ctx : @mcpsdk.RequestContext,
  args : Json,
) -> @mcpsdk.ToolResult {
  let dir = match @mcpsdk.get_string(args, "dir") {
    Ok(s) => s
    Err(_) => return @mcpsdk.ToolResult::error("missing 'dir' parameter")
  }
  @mcpsdk.ToolResult::text(
    "Project scanning requires async I/O. Use 'moon2dart project " +
    dir +
    "' CLI command instead.",
  )
}

///|
/// moon2dart_list_tools — 列出所有可用工具及其参数。
fn handle_list_tools(
  _ctx : @mcpsdk.RequestContext,
  _args : Json,
) -> @mcpsdk.ToolResult {
  @mcpsdk.ToolResult::text(list_tools_info())
}

// ============================================================
// 工具构造辅助函数
// ============================================================

///|
/// make_tool — 构造 ToolWrapper，提供参数定义和执行回调。
fn make_tool(
  name : String,
  description : String,
  params : Array[@tool.ParamDef],
  handler : (@mcpsdk.RequestContext, Json) -> @mcpsdk.ToolResult,
) -> @core.ToolWrapper {
  @core.ToolWrapper::{
    name_impl: fn() { name },
    description_impl: fn() { description },
    params_impl: fn() { params },
    execute_impl: handler,
  }
}

// ============================================================
// 端口解析
// ============================================================

///|
fn parse_port(s : String) -> Int32 {
  let mut result : Int32 = 0
  for c in s {
    let digit = c.to_int() - 48
    if digit >= 0 && digit <= 9 {
      result = result * 10 + digit
    } else {
      return 8080
    }
  }
  if result > 0 && result < 65536 {
    result
  } else {
    8080
  }
}

// ============================================================
// 服务器启动
// ============================================================

///|
/// 工具模式 — MCPServer + 6 工具注册，兼容标准 MCP 客户端。
async fn run_tool_mode(use_http : Bool, http_port : Int32) -> Unit {
  let server = @mcpsdk.MCPServer::MCPServer("moon2dart", "0.9.1")
    .with_description(
      "MoonBit <-> Dart/Flutter transpiler — convert code between MoonBit and Dart",
    )
    .with_instructions(
      "This server provides tools to convert MoonBit code to Dart/Flutter and vice versa. Use moon2dart_convert for MoonBit to Dart, moon2dart_reverse for Dart to MoonBit, moon2dart_flutter for Flutter widget generation, moon2dart_analyze for code structure analysis, moon2dart_project for project-level conversion.",
    )
    .with_tools(enabled=true)
  let server = server
    .with_tool(
      make_tool(
        "moon2dart_convert",
        "Convert MoonBit source code to Dart",
        [
          @tool.ParamDef::{
            name: "source",
            description: "MoonBit source code to convert",
            type_: "string",
            required: true,
          },
          @tool.ParamDef::{
            name: "lib_name",
            description: "Native library name for FFI (default: libnative.so)",
            type_: "string",
            required: false,
          },
        ],
        handle_convert,
      ),
    )
    .with_tool(
      make_tool(
        "moon2dart_reverse",
        "Convert Dart source code to MoonBit (reverse transpile)",
        [
          @tool.ParamDef::{
            name: "source",
            description: "Dart source code to convert to MoonBit",
            type_: "string",
            required: true,
          },
        ],
        handle_reverse,
      ),
    )
    .with_tool(
      make_tool(
        "moon2dart_flutter",
        "Convert MoonBit source to Flutter widget Dart code",
        [
          @tool.ParamDef::{
            name: "source",
            description: "MoonBit source code with Flutter widget definitions",
            type_: "string",
            required: true,
          },
        ],
        handle_flutter,
      ),
    )
    .with_tool(
      make_tool(
        "moon2dart_analyze",
        "Analyze MoonBit code structure and return AST summary",
        [
          @tool.ParamDef::{
            name: "source",
            description: "MoonBit source code to analyze",
            type_: "string",
            required: true,
          },
        ],
        handle_analyze,
      ),
    )
    .with_tool(
      make_tool(
        "moon2dart_project",
        "Scan and convert a MoonBit project directory to Dart",
        [
          @tool.ParamDef::{
            name: "dir",
            description: "MoonBit project directory path to scan and convert",
            type_: "string",
            required: true,
          },
        ],
        handle_project,
      ),
    )
    .with_tool(
      make_tool(
        "moon2dart_list_tools",
        "List all available moon2dart MCP tools and their parameters",
        [],
        handle_list_tools,
      ),
    )
  if use_http {
    server.run_http(port=http_port) catch {
      _ => println("Error: failed to start HTTP server on port \{http_port}")
    }
  } else {
    server.run_stdio() catch {
      _ => println("Error: failed to start STDIO server")
    }
  }
}

///|
/// Agent 模式 — posoco Agent 循环，LLM 理解意图 → 自动选择工具。
async fn run_agent_mode(user_input : String?) -> Unit {
  run_agent_mode_with_input(user_input)
}

// ============================================================
// 公共入口
// ============================================================

///|
/// serve_mcp — MCP 服务器公共入口。
///
/// 参数列表（与命令行参数格式一致）：
///   [] 或 ["--http"] 或 ["--http", "8080"] 或 ["--agent"]
pub async fn serve_mcp(args : Array[String]) -> Unit {
  let mut use_http = false
  let mut http_port : Int32 = 8080
  let mut use_agent = false
  let mut agent_input : String? = None
  let mut i = 0
  while i < args.length() {
    if args[i] == "--http" {
      use_http = true
      if i + 1 < args.length() {
        http_port = parse_port(args[i + 1])
        i = i + 2
      } else {
        i = i + 1
      }
    } else if args[i] == "--agent" {
      use_agent = true
      if i + 1 < args.length() {
        agent_input = Some(args[i + 1])
        i = i + 2
      } else {
        i = i + 1
      }
    } else {
      i = i + 1
    }
  }
  if use_agent {
    run_agent_mode(agent_input)
  } else {
    run_tool_mode(use_http, http_port)
  }
}
