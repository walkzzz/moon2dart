# Package: bench

性能基准 | Performance benchmarks

## 概述 | Overview

衡量 moon2dart transpiler 各阶段的性能，覆盖 Lexer、Parser、Codegen、Flutter codegen、类型映射、反向转换和完整 transpile 管线。使用 moonbench 的 benchmark/measure 函数进行计时，并包含性能预算检查。

Benchmarks moon2dart transpiler performance across all stages: Lexer, Parser, Codegen, Flutter codegen, type mapping, reverse conversion, and full transpile pipeline. Uses moonbench's benchmark/measure functions for timing, and includes performance budget checks.

## 核心类型 | Core Types

（基准测试包，无额外 pub 类型 / Benchmark package, no additional pub types）

## 核心函数 | Core Functions

（内部辅助函数，无 pub 导出 / Internal helper functions, no pub exports）

| Function | Signature | Description |
|----------|-----------|-------------|
| `small_source` | `() -> String` | [CN] 小型 MoonBit 源码样本 / [EN] Small MoonBit source sample |
| `medium_source` | `() -> String` | [CN] 中型 MoonBit 源码样本 / [EN] Medium MoonBit source sample |
| `large_source` | `() -> String` | [CN] 大型 MoonBit 源码样本 / [EN] Large MoonBit source sample |
| `flutter_source` | `() -> String` | [CN] Flutter widget 源码样本 / [EN] Flutter widget source sample |
| `dart_source` | `() -> String` | [CN] Dart 源码样本（反向转换） / [EN] Dart source sample (for reverse conversion) |

## 依赖 | Dependencies

- `walkzzz/moon2dart` (@lib)
- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/parser`
- `walkzzz/moon2dart/codegen`
- `walkzzz/moon2dart/typesys`
- `walkzzz/moon2dart/reverse_codegen`
- `sa2360/moonbench`

## 测试 | Tests

- 基准测试 / Benchmark tests: 14
  - Lexer: 3 (small/medium/large)
  - Parser: 3 (small/medium/large)
  - Codegen: 3 (small/medium/large)
  - Transpile pipeline: 3 (small/medium/large)
  - Flutter: 2 (codegen + pipeline)
  - Type mapping: 1
  - Reverse transpile: 1
  - Budget check: 1

## 基准测试类别 | Benchmark Categories

| Category | Test Count | Description |
|----------|-----------|-------------|
| Lexer tokenize | 3 | [CN] 词法分析性能 / [EN] Lexing performance |
| Parser parse | 3 | [CN] 语法分析性能 / [EN] Parsing performance |
| Codegen emit | 3 | [CN] 代码生成性能 / [EN] Code generation performance |
| Transpile pipeline | 3 | [CN] 完整转换管线性能 / [EN] Full transpile pipeline performance |
| Flutter codegen | 2 | [CN] Flutter 代码生成性能 / [EN] Flutter code generation performance |
| Type mapping | 1 | [CN] 类型映射性能 / [EN] Type mapping performance |
| Reverse transpile | 1 | [CN] 反向转换性能 / [EN] Reverse transpilation performance |
| Budget check | 1 | [CN] 性能预算检查 / [EN] Performance budget check |
