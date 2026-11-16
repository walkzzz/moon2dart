# Package: typesys

MoonBit → Dart 类型映射 | MoonBit to Dart type mapping

## 概述 | Overview

负责 MoonBit 类型到 Dart 类型的映射，包括语义等价等级分类（L1-L4）、FFI 类型映射、严格模式检查以及往返断言验证。是 transpiler 类型转换语义正确性的核心保障。

Handles MoonBit-to-Dart type mapping, including semantic equivalence level classification (L1-L4), FFI type mapping, strict mode checking, and round-trip assertion verification. Core guarantor of type conversion semantic correctness.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `DartType` | [CN] Dart 类型节点（13 变体：基础类型 + 容器 + Nullable + Future + Result + Custom） / [EN] Dart type node (13 variants) |
| `SemanticLevel` | [CN] 语义等价等级（L1 完全等价 / L2 结构等价 / L3 受限 / L4 不等价） / [EN] Semantic equivalence level (L1-L4) |

## 核心函数 | Core Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `map_type` | `MoonType -> DartType` | [CN] MoonBit 类型 → Dart 类型映射 / [EN] MoonBit to Dart type mapping |
| `DartType::to_dart_string` | `DartType -> String` | [CN] Dart 类型 → 代码字符串 / [EN] Dart type to code string (aliased as `emit_dart`) |
| `moon_to_dart_type` | `MoonType -> String` | [CN] 便捷：MoonBit 类型 → Dart 类型字符串 / [EN] Convenience: MoonBit type to Dart type string |
| `semantic_level` | `MoonType -> SemanticLevel` | [CN] 判断语义等价等级 / [EN] Determine semantic equivalence level |
| `map_type_strict` | `MoonType -> DartType raise Moon2DartError` | [CN] 严格模式映射（L4 类型 raise 错误） / [EN] Strict mode mapping (L4 types raise error) |
| `ffi_native_type` | `MoonType -> String` | [CN] FFI Native 侧类型字符串 / [EN] FFI Native-side type string |
| `ffi_dart_type` | `MoonType -> String` | [CN] FFI Dart 侧类型字符串 / [EN] FFI Dart-side type string |
| `needs_option_class` | `Array[MoonDecl] -> Bool` | [CN] 是否需要生成 Option 辅助类 / [EN] Whether Option helper class is needed |
| `assert_round_trip` | `MoonType -> Bool` | [CN] 往返断言验证 / [EN] Round-trip assertion verification |
| `assert_value_domain` | `(MoonType, SemanticLevel) -> Bool` | [CN] 值域断言验证 / [EN] Value domain assertion verification |

## 依赖 | Dependencies

- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/dart_ast`

## 测试 | Tests

- 白盒测试 / Whitebox: 50+
- 黑盒测试 / Blackbox: 0

## 语义等价 | Semantic Equivalence

本包实现完整的四级语义等价分类体系：

| Level | 含义 | 示例 |
|-------|------|------|
| L1 | 完全等价 | `Int → int`, `String → String`, `Bool → bool` |
| L2 | 结构等价 | `Option[T] → T?`（null safety 语义保留） |
| L3 | 受限等价 | `UInt → int`（无符号语义丢失）, `Float → double`, `Char → int` |
| L4 | 不等价 | `ForeignFunction`, `Channel`, `Spawn`（无 Dart 对应） |
