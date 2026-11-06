# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies.

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`.

- `pub(all) enum` 供外部包构造；`pub enum` 仅允许 match。

- `derive(Eq, Compare, Debug)` 后需显式 `pub extend T with Trait::{method}`。

- snake_case 函数/变量，PascalCase 类型，UPPER_SNAKE 常量。

## Tooling

- `moon fmt` — 格式化
- `moon info` — 更新 .mbti 接口
- `moon test` — 运行测试
- `moon check --target all` — 四后端编译检查
- `moon run cmd/main` — 运行 CLI

## Project: moon2dart

MoonBit → Dart transpiler，让 MoonBit 代码跑在 Flutter 上。

### 包结构

```
moon2dart/            # 根包 — transpile 编排入口
├── moon2dart.mbt         # transpile / transpile_decl / transpile_expr / transpile_type
├── ast/                  # AST 类型定义（零依赖）
│   └── ast.mbt           # MoonType / MoonExpr / MoonPattern / MoonDecl
├── typesys/              # 类型映射
│   └── mapping.mbt       # DartType + map_type + emit_dart + is_pure
├── codegen/              # Dart 代码发射
│   └── emitter.mbt       # emit_dart_expr / emit_dart_pattern / emit_dart_decl / emit_dart_program
└── cmd/main/             # CLI 入口
    └── main.mbt          # 演示模式
```

### 依赖关系

```
cmd/main ──> 根包 ──> ast + typesys + codegen
codegen ──> ast + typesys
typesys ──> ast
ast ──> (零依赖)
```

### 多后端支持

- `supported_targets = "+wasm+wasm-gc+js+native"`

### MoonBit 语法要点

- **derive 后必须显式 pub extend**：`derive(Eq, Compare, Debug)` 后需三条 `pub extend`
- **pub(all) enum**：外部包可构造（测试需 pub(all)）
- **import 别名**：`"walkzzz/moon2dart" @lib` 语法
- **字符串插值**：`"\{expr}"`

### Sprint 状态

- **v0.1.0** ✅ 已完成 — transpiler 骨架（33 测试 × 4 后端）
  - S1 ast 包 ✅ / S2 typesys ✅ / S3 codegen ✅ / S4 根包入口 ✅
  - S5 CLI 演示 ✅ / S6 工程配置 ✅ / S7 门禁验证 ✅ / S8 文档发布 ✅
- **v0.2.0** 🔄 进行中 — 解析器（MoonBit 源码 → AST）
  - S1 lexer ✅（15 白盒测试，TokenKind 57 变体 + Lexer）
  - S2 parser ✅（27 白盒测试，fn/struct/enum/expr/type 解析，75 测试 × 4 后端）
  - S3 单文件转换管线 📋 / S4 CLI convert 子命令 📋 / S5 测试+文档+门禁 📋
- **v0.3.0** 📋 计划 — trait + 模式匹配 + derive 生成
- **v0.4.0** 📋 计划 — 项目级扫描 + 包结构映射
- **v0.5.0** 📋 计划 — async + Option + Result + 泛型
- **v0.6.0** 📋 计划 — FFI 混合模式（dart:ffi）
- **v0.7.0** 📋 计划 — Flutter widget 转换
- **v0.8.0** 📋 计划 — 自动触发 + 项目同步（核心功能）
- **v0.9.0** 📋 计划 — MCP 服务器 + Skill（大模型消费）
- **v1.0.0** 📋 计划 — 验证 + 完整发布（mooncakes.io）

### 四条交付线

| 交付线 | 发布渠道 | 消费者 | 覆盖版本 |
|--------|----------|--------|----------|
| 库 API | `moon add walkzzz/moon2dart` | MoonBit 开发者 | v0.1.0-v0.8.0 |
| CLI 工具 | `mooncakes.io/cli` | 命令行用户 | v0.2.0-v0.9.0 |
| Skill | `mooncakes.io/skills` | 大模型 Agent | v0.9.0 |
| MCP 服务器 | 随 CLI 分发 | AI 工具链 | v0.9.0 |

### 技术参考

- MCP 服务器架构：参考 `chrono_tz-mbt/cmd/mcp/main.mbt`（JSON-RPC + stdio，623 行）
- MoonBit 语言特性：参考 `moonbit_learning/advanced_basics`（Json/defer/管道/is 表达式）
- 完整路线图：`docs/roadmap.md`

### 测试

33 个测试，四后端全通过（wasm / wasm-gc / js / native）：

| 包 | 白盒 | 黑盒 |
|----|------|------|
| ast | 7 | 0 |
| typesys | 7 | 0 |
| codegen | 9 | 0 |
| moon2dart (根) | 5 | 5 |

### 文档

开发文档在 `docs/`（7 份）：architecture / roadmap / v0.1.0_plan / type_mapping / coding_conventions / testing_strategy / changelog。
