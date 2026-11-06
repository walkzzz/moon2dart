# moon2dart 开发文档总览

> MoonBit → Dart transpiler | 让 MoonBit 代码跑在 Flutter 上

## 文档索引

| 文档 | 内容 | 状态 |
|------|------|------|
| [architecture.md](architecture.md) | 架构设计：模块划分 + 数据流 + 转换策略 | 已实现 |
| [type_mapping.md](type_mapping.md) | MoonBit → Dart 类型与构造映射规范（完整映射表） | 已实现 |
| [roadmap.md](roadmap.md) | 迭代路线图 v0.1.0 → v1.0.0 | 已实现 |
| [coding_conventions.md](coding_conventions.md) | 编码规范（MoonBit + 生成 Dart 风格） | 已实现 |
| [testing_strategy.md](testing_strategy.md) | 测试策略（单元/快照/round-trip） | 已实现 |
| [v0.1.0_plan.md](v0.1.0_plan.md) | v0.1.0 详细迭代计划 | 已实现 |
| [changelog.md](changelog.md) | 变更日志 | 已实现 |

## 项目定位

**moon2dart** 是 MoonBit → Dart 的转换器（transpiler）。把 MoonBit 代码直接 transpile 为 Dart 代码，让 MoonBit 代码跑在 Flutter 上。

- **转换**：MoonBit 完整能力特化为 Flutter/Dart 可表达子集
- **混合模式**：不可转换部分（FFI/低层）直接走 `dart:ffi` 桥接
- **独立项目**：不依赖任何外部 native 库交付框架，自包含

## 技术可行性摘要

- **85% 构造可纯转换**：基础类型/struct/enum/模式匹配/Option/闭包/泛型/async/Array/Map/迭代器 → Dart 3 对应构造
- **15% 需混合模式**：FFI（→ dart:ffi）、`pub(open) trait` 跨包实现（→ mixin）、动态分派
- 依赖 Dart 3+（sealed class / switch expression / null safety）

## 竞品

蓝海。mooncakes.io（32,064 包）无 MoonBit→Dart transpiler，无直接竞品。