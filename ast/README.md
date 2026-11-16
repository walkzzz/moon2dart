# Package: ast

MoonBit AST 节点定义（零依赖） | MoonBit AST node definitions (zero dependencies)

## 概述 | Overview

定义 MoonBit 源码的抽象语法树（AST）节点类型，包括类型、表达式、模式、声明等。作为整个 transpiler 的基础数据模型，所有其他包均依赖此包。

Defines abstract syntax tree (AST) node types for MoonBit source code, including types, expressions, patterns, and declarations. Serves as the foundational data model for the entire transpiler.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `MoonType` | [CN] MoonBit 类型节点（23 变体：基础类型 + 容器 + 泛型） / [EN] MoonBit type node (23 variants: primitives + containers + generics) |
| `MoonExpr` | [CN] MoonBit 表达式节点（9 变体：字面量/变量/调用/二元/条件/匹配/await/lambda） / [EN] MoonBit expression node (9 variants) |
| `MoonPattern` | [CN] MoonBit 模式匹配节点（5 变体：变量/整数/字符串/通配/构造器） / [EN] MoonBit pattern matching node (5 variants) |
| `MoonDecl` | [CN] MoonBit 声明节点（7 变体：fn/async fn/struct/enum/trait/impl/extern fn） / [EN] MoonBit declaration node (7 variants) |
| `TraitMethod` | [CN] trait 方法签名 / [EN] Trait method signature |
| `ImplMethod` | [CN] impl 方法实现（含方法体） / [EN] Impl method definition (with body) |
| `Moon2DartError` | [CN] 统一错误类型（8 子错误：Parse/Transpile/ReverseTranspile/Json/Schema/FileIO/Project/Type） / [EN] Unified error type (8 sub-errors) |
| `TypeDisplay` | [CN] 类型显示 trait / [EN] Type display trait |

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `MoonType::to_moon_string` | `MoonType -> String` | [CN] 类型转 MoonBit 字符串 / [EN] Type to MoonBit string |
| `MoonType::contains_result` | `MoonType -> Bool` | [CN] 递归检测是否包含 Result / [EN] Recursively check for Result type |
| `MoonType::is_pure` | `MoonType -> Bool` | [CN] 判断是否可纯转换 / [EN] Check if type is purely mappable |
| `MoonType::needs_result_type` | `MoonType -> Bool` | [CN] 是否需要自定义 Result 类型 / [EN] Whether custom Result type is needed |
| `is_nested_option` | `MoonType -> Bool` | [CN] 检测嵌套 Option / [EN] Detect nested Option |
| `has_nested_option_in_decls` | `Array[MoonDecl] -> Bool` | [CN] 声明列表中是否有嵌套 Option / [EN] Check for nested Option in declarations |
| `collect_types_from_decl` | `MoonDecl -> Array[MoonType]` | [CN] 收集声明中使用的所有类型 / [EN] Collect all types used in declaration |

## 依赖 | Dependencies

- （零依赖 / Zero dependencies）

## 测试 | Tests

- 白盒测试 / Whitebox: 11
- 黑盒测试 / Blackbox: 0
