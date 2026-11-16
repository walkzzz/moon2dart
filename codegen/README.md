# Package: codegen

Dart 代码发射器 | Dart code emitter

## 概述 | Overview

将 MoonBit AST 节点转换为 Dart 源码字符串，包括表达式、模式、声明和完整程序的发射，以及 Flutter widget 转换和 FFI extern 函数代码生成。支持语义诊断标注、derive 方法生成和 DImpl 合并。

Converts MoonBit AST nodes to Dart source code strings, including expression, pattern, declaration, and full program emission, plus Flutter widget conversion and FFI extern function code generation. Supports semantic diagnostic annotations, derive method generation, and DImpl merging.

## 核心类型 | Core Types

（本包以函数为主，无额外 pub 类型 / This package is primarily function-based with no additional pub types）

## 核心函数 | Core Functions

### 通用代码发射 | General Code Emission (emitter.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `emit_dart_expr` | `MoonExpr -> String` | [CN] 表达式 → Dart 代码 / [EN] Expression to Dart code |
| `emit_dart_expr_nested` | `MoonExpr -> String` | [CN] 嵌套 Option 感知表达式发射 / [EN] Nested-option-aware expression emission |
| `emit_dart_pattern` | `MoonPattern -> String` | [CN] 模式 → Dart 3 pattern / [EN] Pattern to Dart 3 pattern |
| `emit_dart_decl` | `MoonDecl -> String` | [CN] 声明 → Dart 代码 / [EN] Declaration to Dart code |
| `emit_dart_program` | `Array[MoonDecl] -> String` | [CN] 完整程序发射 / [EN] Full program emission |
| `emit_dart_program_with_lib` | `(Array[MoonDecl], String) -> String` | [CN] 可指定 FFI 库名的程序发射 / [EN] Program emission with custom FFI lib name |
| `filter_pure` | `Array[MoonDecl] -> Array[MoonDecl]` | [CN] 过滤掉 DExternFn 声明 / [EN] Filter out DExternFn declarations |
| `emit_option_class` | `() -> String` | [CN] 生成 Option 辅助类 / [EN] Generate Option helper class |

### Flutter 代码发射 | Flutter Code Emission (flutter_emitter.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `emit_flutter_expr` | `MoonExpr -> String` | [CN] Flutter widget 表达式发射 / [EN] Flutter widget expression emission |
| `emit_flutter_program` | `Array[MoonDecl] -> String` | [CN] 完整 Flutter 应用发射 / [EN] Full Flutter app emission |
| `needs_flutter` | `Array[MoonDecl] -> Bool` | [CN] 检测是否需要 Flutter import / [EN] Detect whether Flutter import is needed |

## 依赖 | Dependencies

- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/typesys`

## 测试 | Tests

- 白盒测试 / Whitebox: 140+
- 黑盒测试 / Blackbox: 0

## 语义等价 | Semantic Equivalence

本包在 `emit_dart_decl_in_program` 中自动为 L3/L4 类型生成诊断注释：
- `[L3-CONSTRAINED]` — 值域有损映射（UInt/Float/Char）
- `[L4-INEQUIVALENT]` — 无 Dart 对应（FFI/Channel 等自定义类型）
