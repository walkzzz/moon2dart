# Package: dart_ast

Dart AST 节点定义（零依赖） | Dart AST node definitions (zero dependencies)

## 概述 | Overview

定义 Dart 源码的抽象语法树（AST）节点类型，包括 Dart 类型、表达式、模式、声明、方法和变体。作为反向转换（Dart → MoonBit）的基础数据模型，同时提供 DartType → MoonBit 类型的反向映射。

Defines abstract syntax tree (AST) node types for Dart source code, including Dart types, expressions, patterns, declarations, methods, and variants. Serves as the foundational data model for reverse conversion (Dart → MoonBit), and provides DartType → MoonBit type reverse mapping.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `DartType` | [CN] Dart 类型节点（13 变体：基础类型 + 容器 + Nullable + Future + Result + Custom） / [EN] Dart type node (13 variants) |
| `DartExpr` | [CN] Dart 表达式节点（12 变体：字面量/变量/方法调用/函数调用/二元/条件/switch/await/箭头/null） / [EN] Dart expression node (12 variants) |
| `DartPattern` | [CN] Dart 模式节点（7 变体：变量/整数/字符串/通配/null/构造器） / [EN] Dart pattern node (7 variants) |
| `DartDecl` | [CN] Dart 声明节点（5 变体：顶层函数/async 函数/class/sealed class/abstract class） / [EN] Dart declaration node (5 variants) |
| `DartMethod` | [CN] Dart 方法定义 / [EN] Dart method definition |
| `DartVariant` | [CN] Dart sealed class 变体 / [EN] Dart sealed class variant |

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `DartType::to_moon_string` | `DartType -> String` | [CN] Dart 类型 → MoonBit 类型字符串（aliased as `dart_type_to_moon`） / [EN] Dart type to MoonBit type string |

## 依赖 | Dependencies

- （零依赖 / Zero dependencies）

## 测试 | Tests

- 白盒测试 / Whitebox: 14
- 黑盒测试 / Blackbox: 0
