# Package: cmd/main

CLI 入口 | CLI entry point

## 概述 | Overview

moon2dart 命令行工具入口，提供 7 个子命令：convert（单文件转换）、project（项目级转换）、sync（增量同步）、watch（文件监听）、serve（MCP 服务器）、demo（演示模式）、help（帮助信息）。支持 --reverse、--pure-only、--strict、--lib、--bidirectional 等选项。

moon2dart CLI tool entry point, providing 7 subcommands: convert (single-file conversion), project (project-level conversion), sync (incremental sync), watch (file watching), serve (MCP server), demo (demo mode), help (help info). Supports --reverse, --pure-only, --strict, --lib, --bidirectional options.

## 核心类型 | Core Types

（CLI 入口，无 pub 类型 / CLI entry point, no pub types）

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `main` | `async fn` | [CN] CLI 主入口（解析子命令，分发到对应 handler） / [EN] CLI main entry (parse subcommand, dispatch to handler) |
| `cmd_convert` | `Array[String] -> Unit` (async) | [CN] convert 子命令 / [EN] convert subcommand |
| `cmd_project` | `Array[String] -> Unit` (async) | [CN] project 子命令 / [EN] project subcommand |
| `cmd_sync` | `Array[String] -> Unit` (async) | [CN] sync 子命令 / [EN] sync subcommand |
| `cmd_watch` | `Array[String] -> Unit` (async) | [CN] watch 子命令 / [EN] watch subcommand |
| `cmd_serve` | `Array[String] -> Unit` (async) | [CN] serve 子命令 / [EN] serve subcommand |
| `cmd_demo` | `() -> Unit` | [CN] demo 子命令（内置示例转换） / [EN] demo subcommand (built-in example conversion) |
| `cmd_help` | `() -> Unit` | [CN] help 子命令 / [EN] help subcommand |

## 依赖 | Dependencies

- `walkzzz/moon2dart` (@lib)
- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/project`
- `walkzzz/moon2dart/mcp_server`
- `moonbitlang/core/env`
- `moonbitlang/async`
- `moonbitlang/async/fs`

## 测试 | Tests

- 白盒测试 / Whitebox: 0
- 黑盒测试 / Blackbox: 5

## 平台限制 | Platform Restriction

- 仅 native 后端 / Native backend only (`pkgtype: executable`, `supported_targets = "-all+native"`)
- 需要 `moonbitlang/core/async` 实验包

## 用法 | Usage

```bash
moon run cmd/main --target native -- convert <file.mbt>
moon run cmd/main --target native -- convert <file.dart> --reverse
moon run cmd/main --target native -- convert <file.mbt> --pure-only
moon run cmd/main --target native -- convert <file.mbt> --strict
moon run cmd/main --target native -- project <dir> -o <output>
moon run cmd/main --target native -- sync <dir> -o <output>
moon run cmd/main --target native -- sync <dir> -o <output> --reverse
moon run cmd/main --target native -- sync <dir> -o <output> --bidirectional
moon run cmd/main --target native -- watch <dir> -o <output>
moon run cmd/main --target native -- serve [--http <port>]
moon run cmd/main --target native -- demo
moon run cmd/main --target native -- help
```
