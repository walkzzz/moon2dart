///|
/// moon2dart MCP 服务器入口 — 委托给 mcp_server 包。
///
/// 运行：
///   moon run cmd/mcp --target native                  # 工具模式 (STDIO)
///   moon run cmd/mcp --target native -- --http 8080   # 工具模式 (HTTP)
///   moon run cmd/mcp --target native -- --agent       # Agent 模式

///|
async fn main {
  let args = @env.args()
  let rest : Array[String] = []
  for j in 1..<args.length() {
    rest.push(args[j])
  }
  @mcp_server.serve_mcp(rest) catch {
    _ => println("Error: MCP server failed to start")
  }
}
