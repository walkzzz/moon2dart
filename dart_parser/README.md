# Package: dart_parser

Dart 词法+语法分析器 | Dart lexer and parser

## 概述 | Overview

将 Dart 源码字符串转换为 Dart AST。DartLexer 将源码 tokenize 为 DartToken 流（67 种 DartTokenKind），DartParser 将 DartToken 流解析为 DartDecl 数组。支持顶层函数、async 函数、class、sealed class、abstract class、表达式和类型的解析。

Converts Dart source code strings to Dart AST. DartLexer tokenizes source into a DartToken stream (67 DartTokenKind variants), and DartParser parses the DartToken stream into a DartDecl array. Supports top-level functions, async functions, classes, sealed classes, abstract classes, expressions, and type parsing.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `DartTokenKind` | [CN] Dart Token 种类枚举（67 变体：字面量/标识符/关键字/内置类型/运算符/分隔符） / [EN] Dart Token kind enum (67 variants) |
| `DartToken` | [CN] Dart Token 结构（种类+文本+行列位置） / [EN] Dart Token struct (kind + text + line/col position) |
| `DartLexer` | [CN] Dart 词法分析器 / [EN] Dart lexer |
| `DartParser` | [CN] Dart 语法分析器 / [EN] Dart parser |

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `DartLexer::make` | `String -> DartLexer` | [CN] 构造 Dart 词法分析器 / [EN] Construct Dart lexer |
| `DartLexer::tokenize` | `DartLexer -> Array[DartToken]` | [CN] 运行 Dart 词法分析 / [EN] Run Dart tokenization |
| `DartParser::make` | `Array[DartToken] -> DartParser` | [CN] 构造 Dart 语法分析器 / [EN] Construct Dart parser |
| `DartParser::parse_program` | `DartParser -> Array[DartDecl]` | [CN] 解析整个 Dart 程序 / [EN] Parse entire Dart program |

## 依赖 | Dependencies

- `walkzzz/moon2dart/dart_ast`

## 测试 | Tests

- 白盒测试 / Whitebox: 20
  - dart_lexer_wbtest.mbt: 8 tests
  - dart_parser_wbtest.mbt: 12 tests
- 黑盒测试 / Blackbox: 0
