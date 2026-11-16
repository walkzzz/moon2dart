# Package: mcp_server

MCP 服务器核心逻辑（native only） | MCP server core logic (native only)

## 概述 | Overview

实现 moon2dart 的 MCP（Model Context Protocol）服务器，提供 6 个工具（convert/reverse/flutter/analyze/project/list_tools）供 LLM Agent 调用。支持两种模式：工具模式（标准 MCP 客户端通过 STDIO/HTTP 调用）和 Agent 模式（基于 posoco 的规则引擎自动选择工具）。

Implements moon2dart's MCP (Model Context Protocol) server, providing 6 tools (convert/reverse/flutter/analyze/project/list_tools) for LLM Agent invocation. Supports two modes: tool mode (standard MCP client via STDIO/HTTP) and agent mode (posoco-based rule engine for automatic tool selection).

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `RuleBasedModel` | [CN] 基于关键词的 ModelPort 实现 / [EN] Keyword-based ModelPort implementation |
| `InMemorySessionPort` | [CN] 内存会话存储 / [EN] In-memory session storage |
| `Moon2DartExtension` | [CN] 组合 Model+ToolRegistry+Session 的 Extension / [EN] Extension combining Model + ToolRegistry + Session |

## 核心函数 | Core Functions

### MCP 工具 Handler | MCP Tool Handlers (server.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `handle_convert` | `(RequestContext, Json) -> ToolResult` | [CN] MoonBit → Dart 单文件转换 / [EN] MoonBit to Dart single-file conversion |
| `handle_reverse` | `(RequestContext, Json) -> ToolResult` | [CN] Dart → MoonBit 反向转换 / [EN] Dart to MoonBit reverse conversion |
| `handle_flutter` | `(RequestContext, Json) -> ToolResult` | [CN] MoonBit → Flutter widget 转换 / [EN] MoonBit to Flutter widget conversion |
| `handle_analyze` | `(RequestContext, Json) -> ToolResult` | [CN] 分析 MoonBit 源码结构 / [EN] Analyze MoonBit source structure |
| `handle_project` | `(RequestContext, Json) -> ToolResult` | [CN] 项目级扫描和转换 / [EN] Project-level scan and conversion |
| `handle_list_tools` | `(RequestContext, Json) -> ToolResult` | [CN] 列出所有可用工具 / [EN] List all available tools |

### 模式入口 | Mode Entry Points

| Function | Signature | Description |
|----------|-----------|-------------|
| `serve_mcp` | `Array[String] -> Unit` (async) | [CN] MCP 服务器入口（解析参数，选择工具/Agent 模式） / [EN] MCP server entry (parse args, select tool/agent mode) |
| `run_tool_mode` | `(Bool, Int32) -> Unit` (async) | [CN] 工具模式运行 / [EN] Tool mode execution |
| `run_agent_mode` | `String? -> Unit` (async) | [CN] Agent 模式运行 / [EN] Agent mode execution |

### 辅助函数 | Helper Functions (tools.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `analyze_source` | `String -> String` | [CN] 解析源码并返回 AST 摘要 / [EN] Parse source and return AST summary |
| `list_tools_info` | `() -> String` | [CN] 列出工具及参数描述 / [EN] List tools with parameter descriptions |

## 依赖 | Dependencies

- `colmugx/mcp` (@mcpsdk)
- `colmugx/mcp/protocol/core`
- `colmugx/mcp/protocol/tool`
- `colmugx/posoco`
- `walkzzz/moon2dart` (@lib)
- `walkzzz/moon2dart/parser`
- `walkzzz/moon2dart/ast`

## 测试 | Tests

- 白盒测试 / Whitebox: 0（通过 CLI 集成测试验证 / Verified via CLI integration tests）
- 黑盒测试 / Blackbox: 0

## 平台限制 | Platform Restriction

- 仅 native 后端 / Native backend only (`supported_targets = "-all+native"`)
- 需要 `moonbitlang/core/async` 实验包
