# Package: reverse_codegen

Dart AST → MoonBit 代码发射 | Dart AST to MoonBit code emitter

## 概述 | Overview

将 Dart AST 节点转换为 MoonBit 源码字符串，实现反向转换管线（Dart → MoonBit）。包括 Dart 类型到 MoonBit AST 节点的映射、表达式/模式/声明的反向发射，以及完整的反向转换管线。

Converts Dart AST nodes to MoonBit source code strings, implementing the reverse conversion pipeline (Dart → MoonBit). Includes Dart type to MoonBit AST node mapping, reverse expression/pattern/declaration emission, and the complete reverse transpile pipeline.

## 核心类型 | Core Types

（本包以函数为主，无额外 pub 类型 / This package is primarily function-based with no additional pub types）

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `dart_type_to_moon_ast` | `DartType -> MoonType` | [CN] Dart 类型 → MoonBit AST 类型节点 / [EN] Dart type to MoonBit AST type node |
| `emit_moon_expr` | `DartExpr -> String` | [CN] Dart 表达式 → MoonBit 代码 / [EN] Dart expression to MoonBit code |
| `emit_moon_pattern` | `DartPattern -> String` | [CN] Dart 模式 → MoonBit 模式 / [EN] Dart pattern to MoonBit pattern |
| `emit_moon_decl` | `DartDecl -> String` | [CN] Dart 声明 → MoonBit 代码 / [EN] Dart declaration to MoonBit code |
| `emit_moon_program` | `Array[DartDecl] -> String` | [CN] 完整程序发射（Dart AST → MoonBit 源码） / [EN] Full program emission (Dart AST → MoonBit source) |
| `reverse_transpile_source` | `String -> String` | [CN] 反向转换管线（Dart 源码 → MoonBit 源码） / [EN] Reverse transpile pipeline (Dart source → MoonBit source) |

## 依赖 | Dependencies

- `walkzzz/moon2dart/dart_ast`
- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/dart_parser`

## 测试 | Tests

- 白盒测试 / Whitebox: 20
- 黑盒测试 / Blackbox: 0

## 语义等价 | Semantic Equivalence

本包实现反向映射，与 typesys 正向映射形成往返验证闭环：
- `DNullable(DNullable(T))` → `MOption(MOption(T))` — 嵌套 Option 反向映射
- `sealed class` → `enum` — 结构保留但 derive 注解为推断生成
- `abstract class` → `trait` — Dart abstract class 反向映射为 MoonBit trait
