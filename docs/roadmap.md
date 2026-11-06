# moon2dart 迭代路线图

> 已实现 v0.1.0 · 2026-11-06

## 路线总览

```
v0.1.0 ──► v0.2.0 ──► v0.3.0 ──► v0.4.0 ──► v0.5.0 ──► v1.0.0
类型映射    trait     async     FFI      Flutter    完整
纯逻辑      模式匹配   Option    混合     widget     验证
```

## v0.1.0 — 类型映射 + 纯逻辑转换

**目标**：建立 transpiler 骨架，支持纯逻辑子集转换。

| 项 | 内容 |
|----|------|
| 类型映射 | 基础类型 + Array/Map/Set/Option/Result |
| AST | 简化 AST（MoonType/MoonExpr/MoonDecl） |
| codegen | Dart 类型/表达式/声明发射 |
| 支持 | fn（无 trait 方法）/ struct / enum / 基础表达式 |
| 不支持 | trait / 模式匹配 / async / FFI |
| CLI | `moon2dart input -o output` 基本用法 |
| 测试 | 类型映射 + codegen 单元测试 |

**验收**：`moon check` + `moon test` 通过，能转换简单 fn/struct/enum 到 Dart。

## v0.2.0 — trait → mixin + 模式匹配

**目标**：支持 trait 转换和模式匹配。

| 项 | 内容 |
|----|------|
| trait | 单 trait → abstract class，多 trait → mixin 链 |
| 模式匹配 | match → switch expression (Dart 3) |
| derive | Debug→toString, Eq→operator== |
| parser | MoonBit 源码 → AST（简化解析器） |
| 不支持 | async / FFI |

## v0.3.0 — async + Option + verifier

**目标**：支持异步和 null safety，引入 dart analyze 验证。

| 项 | 内容 |
|----|------|
| async | async fn → Future, await → await |
| Option | T? null safety 语义 |
| verifier | 调用 `dart analyze` 验证生成代码 |
| CLI | `--verify` 选项 |

## v0.4.0 — FFI 混合模式

**目标**：支持 FFI 转换（dart:ffi 桥接）。

| 项 | 内容 |
|----|------|
| FFI | extern "C" → dart:ffi DynamicLibrary |
| 桥接 | 生成 native 库加载 + 类型转换代码 |
| 限制 | 不支持内联汇编/wasm intrinsics |
| CLI | `--pure-only` 只转换纯子集 |

## v0.5.0 — Flutter widget 转换

**目标**：支持 MoonBit UI 抽象 → Flutter widget 树。

| 项 | 内容 |
|----|------|
| widget | MoonBit UI 抽象 → Flutter widget |
| 布局 | Row/Column/Stack → Flutter 对应 |
| 状态 | MoonBit 状态 → StatefulWidget |

## v1.0.0 — 完整 transpiler

**目标**：生产可用。

| 项 | 内容 |
|----|------|
| 完整 | 所有可转换构造支持 |
| 验证 | dart analyze + flutter test 集成 |
| 文档 | 用户文档 + 示例 |
| 发布 | mooncakes.io 发布 |

## 里程碑与风险

| 版本 | 风险 | 缓解 |
|------|------|------|
| v0.1.0 | 🟢 低 | 纯骨架，无外部依赖 |
| v0.2.0 | 🟡 中 | trait→mixin 映射不完整 |
| v0.3.0 | 🟢 低 | async 语义近似 |
| v0.4.0 | 🔴 高 | FFI 桥接复杂 |
| v0.5.0 | 🟡 中 | widget 映射主观 |
| v1.0.0 | 🟡 中 | 整体质量保障 |