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

- **S1 ast 包** ✅ — MoonType(16)/MoonExpr(9)/MoonPattern(5)/MoonDecl(3) + derive(Eq, Compare, Debug)
- **S2 typesys 包** ✅ — DartType(12) + map_type + emit_dart + moon_to_dart_type + is_pure + needs_result_type
- **S3 codegen 包** ✅ — emit_dart_expr + emit_dart_pattern + emit_dart_decl + emit_dart_program
- **S4 根包 transpile 入口** ✅ — transpile / transpile_decl / transpile_expr / transpile_type
- **S5 CLI 演示模式** ✅ — `moon run cmd/main` 输出 Dart 代码
- **S6 工程配置** ✅ — moon.mod + AGENTS.md + CI (github actions)
- **S7 门禁验证** ✅ — moon check --deny-warn ✓ + moon test 33/33 × 4 后端 ✓ + moon info ✓ + moon fmt ✓
- **S8 文档完善 + 发布准备** ✅ — README.md + README.mbt.md + docs/ 全部更新 + 黑盒测试 + "退化"措辞清除

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
