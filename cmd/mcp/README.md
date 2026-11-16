# Package: cmd/mcp

MCP 服务器独立入口 | Standalone MCP server entry point

## 概述 | Overview

moon2dart MCP 服务器的独立可执行入口，委托给 mcp_server 包的 serve_mcp 函数。支持工具模式（STDIO/HTTP）和 Agent 模式。与 cmd/main 的 serve 子命令功能相同，但作为独立二进制便于部署。

Standalone executable entry point for moon2dart MCP server, delegating to the mcp_server package's serve_mcp function. Supports tool mode (STDIO/HTTP) and agent mode. Functionally identical to cmd/main's serve subcommand, but provided as a standalone binary for easier deployment.

## 核心类型 | Core Types

（委托入口，无 pub 类型 / Delegation entry, no pub types）

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `main` | `async fn` | [CN] MCP 入口（解析参数 → serve_mcp） / [EN] MCP entry (parse args → serve_mcp) |

## 依赖 | Dependencies

- `walkzzz/moon2dart/mcp_server`
- `moonbitlang/core/env`
- `moonbitlang/async`

## 测试 | Tests

- 白盒测试 / Whitebox: 0
- 黑盒测试 / Blackbox: 0

## 平台限制 | Platform Restriction

- 仅 native 后端 / Native backend only (`pkgtype: executable`, `supported_targets = "-all+native"`)
- 需要 `moonbitlang/core/async` 实验包

## 用法 | Usage

```bash
moon run cmd/mcp --target native                  # 工具模式 (STDIO)
moon run cmd/mcp --target native -- --http 8080   # 工具模式 (HTTP)
moon run cmd/mcp --target native -- --agent       # Agent 模式
```
