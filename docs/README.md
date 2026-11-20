# moon2dart 开发文档总览 | Documentation Index

> MoonBit → Dart transpiler | 让 MoonBit 代码跑在 Flutter 上
>
> v0.11.0 · 2026-11-18 · 19 份文档

## 文档索引 | Document Index

| # | 文档 | 内容 | 状态 | 版本 |
|---|------|------|:----:|------|
| 1 | [architecture.md](architecture.md) | 架构设计：模块划分 + 数据流 + 双向转换 + 语义等价架构 | ✅ 已实现 | v0.11.0 |
| 2 | [type_mapping.md](type_mapping.md) | MoonBit → Dart 类型与构造映射规范（L1-L4 语义分级 + 双语义模式） | ✅ 已实现 | v0.11.0 |
| 3 | [semantic_equivalence.md](semantic_equivalence.md) | 往返语义等价性规范（四级分类 + 嵌套 Option + DResult + 运行时语义保持） | ✅ 已实现 | v0.11.0 |
| 4 | [assessment.md](assessment.md) | 验收记分卡（三口径 + evidence） | ✅ 已实现 | v0.10.0 |
| 5 | [pitfall-catalog.md](pitfall-catalog.md) | 陷阱目录（M 系列 MoonBit 语法 + T 系列 transpiler 特有） | ✅ 已实现 | v0.11.0 |
| 6 | [roadmap.md](roadmap.md) | 迭代路线图 v0.1.0 → v1.0.0 | ✅ 已实现 | v0.11.0 |
| 7 | [coding_conventions.md](coding_conventions.md) | 编码规范（MoonBit + 生成 Dart + 语义等价标注） | ✅ 已实现 | v0.11.0 |
| 8 | [testing_strategy.md](testing_strategy.md) | 测试策略（单元/快照/round-trip/语义等价/变异） | ✅ 已实现 | v0.11.0 |
| 9 | [changelog.md](changelog.md) | 变更日志 | ✅ 已实现 | v0.11.0 |
| 10 | [v0.1.0_plan.md](v0.1.0_plan.md) | v0.1.0 详细迭代计划（历史归档） | 📦 归档 | v0.1.0 |
| 11 | [golden_results.md](golden_results.md) | golden 双端验证报告（14/14 行一致 + trap 边界） | ✅ 已实现 | v0.11.0 |

## 项目定位 | Project Positioning

**moon2dart** 是 MoonBit ↔ Dart 的双向转换器（transpiler）。把 MoonBit 代码直接 transpile 为 Dart 代码，让 MoonBit 代码跑在 Flutter 上。

- **双向转换**：MoonBit → Dart（正向）+ Dart → MoonBit（反向），四级语义等价分类保障
- **混合模式**：不可转换部分（FFI/低层）直接走 `dart:ffi` 桥接
- **独立项目**：不依赖任何外部 native 库交付框架，自包含

## 技术可行性摘要 | Feasibility Summary

- **85% 构造可纯转换**：基础类型/struct/enum/模式匹配/Option/闭包/泛型/async/Array/Map/迭代器 → Dart 3 对应构造
- **15% 需混合模式**：FFI（→ dart:ffi）、`pub(open) trait` 跨包实现（→ mixin）、动态分派
- 依赖 Dart 3+（sealed class / switch expression / null safety）

## 语义等价分级 | Semantic Equivalence Levels

| 等级 | 标记 | 含义 | 条目数 |
|------|------|------|:------:|
| L1 完全等价 | ✅ | 往返转换后语义完全一致 | 18 |
| L2 结构等价 | ⚠️ | 数据结构可还原，操作语义有差异 | 2 |
| L3 受限等价 | 🔶 | 特定约束下等价，默认模式含诊断注释 | 4 |
| L4 不等价 | ❌ | 语义丢失，不可往返，--strict 拒绝 | 5 |

## 竞品 | Competition

蓝海。mooncakes.io（32,064 包）无 MoonBit→Dart transpiler，无直接竞品。

## 测试 | Tests

541 个测试，native 后端全通过（v0.11.0 口径）。
