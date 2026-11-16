# Package: parser

MoonBit 词法+语法分析器 | MoonBit lexer and parser

## 概述 | Overview

将 MoonBit 源码字符串转换为 AST。Lexer 将源码 tokenize 为 Token 流（57 种 TokenKind），Parser 将 Token 流解析为 MoonDecl 数组。支持 fn/struct/enum/trait/impl/extern fn/async fn 声明，以及表达式、类型注解和模式匹配的解析。

Converts MoonBit source code strings to AST. The Lexer tokenizes source into a Token stream (57 TokenKind variants), and the Parser parses the Token stream into a MoonDecl array. Supports fn/struct/enum/trait/impl/extern fn/async fn declarations, plus expression, type annotation, and pattern matching parsing.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `TokenKind` | [CN] Token 种类枚举（57 变体：字面量/标识符/关键字/运算符/分隔符/特殊） / [EN] Token kind enum (57 variants) |
| `Token` | [CN] Token 结构（种类+文本+行列位置） / [EN] Token struct (kind + text + line/col position) |
| `Lexer` | [CN] 词法分析器 / [EN] Lexer |
| `Parser` | [CN] 语法分析器 / [EN] Parser |

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `Lexer::make` | `String -> Lexer` | [CN] 构造词法分析器 / [EN] Construct lexer |
| `Lexer::tokenize` | `Lexer -> Array[Token]` | [CN] 运行词法分析 / [EN] Run tokenization |
| `Parser::make` | `Array[Token] -> Parser` | [CN] 构造语法分析器 / [EN] Construct parser |
| `Parser::parse_program` | `Parser -> Array[MoonDecl]` | [CN] 解析整个程序 / [EN] Parse entire program |

## 依赖 | Dependencies

- `walkzzz/moon2dart/ast`

## 测试 | Tests

- 白盒测试 / Whitebox: 38
  - lexer_wbtest.mbt: 15 tests
  - parser_wbtest.mbt: 23 tests
- 黑盒测试 / Blackbox: 0
