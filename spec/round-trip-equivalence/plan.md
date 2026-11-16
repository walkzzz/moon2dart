# Implementation Plan: 往返语义等价性验证体系

**Input**: Feature specification from `spec/round-trip-equivalence/spec.md`

## Summary

为 moon2dart 建立可验证的往返语义等价性体系。核心技术方案：(1) 在 `DartType` 中新增 `DResult` 结构化节点替代 `DCustom` 退化；(2) 检测嵌套 `Option[Option[T]]` 自动生成 Dart 辅助类 `Option<T>` 保留三分态语义；(3) 建立四级映射分类体系 + 可执行语义断言 + 变异测试。借鉴 flutter-ohos-expert-agent 的"没跑过 ≠ 通过"原则和 StudyDart-Skills 的 Dart 类型系统知识锚点。

## Technical Context

**Language/Version**: MoonBit (moon 0.1.20261104+) + Dart 3 (Sound Null Safety, sealed class, pattern matching)  
**Primary Dependencies**: @ast / @typesys / @codegen / @reverse_codegen / @dart_ast / @dart_parser  
**State Management**: N/A（编译期类型映射，无运行时状态）  
**Storage**: N/A  
**Testing**: moon test（白盒测试 .mbt 文件），目标 ≥ 430 测试（现有 383 + 新增 ≥ 47）  
**Target Platform**: MoonBit 四后端（wasm/wasm-gc/js/native），native 为主要验证后端  
**Project Type**: 编译器/transpiler 库 + CLI  
**Performance Goals**: 类型映射零运行时开销（单层 Option 保持 T?），辅助类仅嵌套场景生成  
**Constraints**: 向后兼容——现有 383 测试全部继续通过；生成的 Dart 代码必须通过 dart analyze  
**Scale/Scope**: 28 个映射条目（18 L1 + 2 L2 + 3 L3 + 5 L4），≥ 47 新测试

## Project Structure

### Documentation (this feature)

```text
spec/round-trip-equivalence/
├── spec.md              # 需求规格
├── plan.md              # 本文件（实施计划）
└── tasks.md             # 任务分解（Phase 3 产出）
```

### Source Code (repository root) — 改动范围

```text
moon2dart/
├── ast/ast.mbt                         # 新增 is_nested_option() 辅助函数
├── typesys/mapping.mbt                 # 【核心改动】DResult 节点 + 嵌套 Option 检测
├── codegen/emitter.mbt                 # 【核心改动】辅助类生成 + DResult 发射 + 诊断注释
├── codegen/flutter_emitter.mbt         # 适配 DResult（如有 Flutter Result 使用）
├── reverse_codegen/reverse_emitter.mbt # 【核心改动】DResult→MResult + Option辅助类→MOption(MOption)
├── dart_ast/                           # 新增 DResult 节点（如需 Dart 侧识别）
├── moon2dart.mbt                       # 新增 --strict 模式 API
├── cmd/main/main.mbt                   # 新增 --strict CLI 选项
├── docs/
│   ├── semantic_equivalence.md         # 【已有初稿】补充完善
│   ├── type_mapping.md                 # 更新映射表
│   ├── architecture.md                 # 修正"单向转换"过时描述
│   ├── pitfall-catalog.md              # 补充 T 系列（语义等价陷阱）
│   └── assessment.md                   # 更新验收记分卡
└── AGENTS.md                           # 更新 Sprint 状态
```

**Structure Decision**: 遵循现有 moon2dart 包结构，改动集中在 typesys/codegen/reverse_codegen 三个核心包，新增文档在 docs/。不引入新的包或目录层级。

## Research & Decisions

### RD-1: 嵌套 Option 映射策略

**Decision**: 检测嵌套时自动生成辅助类 `Option<T>`；单层 Option 保持 `T?` 零开销映射

**Rationale**: Dart 的 `T??` 自动塌缩为 `T?`（Dart 语言规范 §Null Safety），无法表达 MoonBit `Option[Option[T]]` 的三分态。辅助类是唯一能在 Dart 中保留三分态语义的方案。仅嵌套场景生成辅助类，避免影响 95%+ 的单层 Option 用例。

**Alternatives considered**:
- 方案 B：编译期拒绝嵌套 Option → 过于保守，不满足组委会"说明语义保留方法"的要求
- 方案 C：所有 Option 都用辅助类 → 零开销映射的优势完全丧失，生成的 Dart 代码不地道
- 方案 D：用 `Tuple2<bool, T?>` 模拟 → 语义不清晰，Dart 社区不接受

### RD-2: Result 类型结构化映射

**Decision**: 在 `DartType` 枚举中新增 `DResult(DartType, DartType)` 节点

**Rationale**: 当前 `MResult(ok, err) → DCustom("Result<...>")` 导致反向映射时类型结构信息完全丢失（DCustom → MCustom）。`DResult` 节点保留 ok/err 类型结构，使反向映射 `DResult → MResult` 成为可能。

**Alternatives considered**:
- 保持 DCustom + 在 DCustom name 中编码结构 → 脆弱，解析 name 字符串不可靠
- 新增 DartType 子系统 → 过度设计，增加一个枚举变体足够

### RD-3: Dart 侧辅助类设计

**Decision**: 辅助类 `Option<T>` 使用 `_value` 内部字段 + `some`/`none` 工厂构造函数

**Rationale**: Dart 3 的 sealed class + pattern matching 要求辅助类有明确的构造器。`some`/`none` 工厂构造函数与 MoonBit 的 `Some`/`None` 构造器语义对应，便于生成和反解析。

**Alternatives considered**:
- 使用 Dart 3 extension type → 不能参与 switch pattern matching，不满足需求
- 使用 `Union<A, B>` 库 → 引入外部依赖，违反零运行时依赖原则

### RD-4: --strict 模式设计

**Decision**: 新增独立 `--strict` CLI 选项，拒绝 L4 映射（UInt/Float/FFI/spawn 等），默认关闭

**Rationale**: `--pure-only` 已有语义（过滤 DExternFn），复用会导致语义混淆。`--strict` 专注于语义等价性把关，两个选项可组合使用。

**Alternatives considered**:
- 扩展 `--pure-only` 语义 → 破坏现有 CLI 兼容性
- 默认开启 strict → 破坏现有 383 测试

### RD-5: 验收记分卡口径

**Decision**: 三口径——往返类型恢复率 + 语义等价测试通过率 + 人工修复数

**Rationale**: 直接映射 flutter-ohos-expert 的"构建成功率 + 功能完备度 + 人工修复数"三口径。往返类型恢复率衡量类型级等价（编译期验证），语义等价测试通过率衡量行为级等价（断言验证），人工修复数衡量全流程自动化程度。

**Alternatives considered**:
- 仅用"测试通过率"一个口径 → 无法区分类型级和行为级问题
- 加入"代码覆盖率"口径 → moon test 覆盖率机制与语义等价性无直接关联

## Data Model

### SemanticMapping — 语义映射条目

```
SemanticMapping:
  moon_type: MoonType          # MoonBit 类型
  dart_type: DartType          # Dart 类型
  level: L1|L2|L3|L4           # 语义等价等级
  forward_rule: String         # 正向映射规则描述
  reverse_rule: String         # 反向映射规则描述
  value_domain_proof: String   # 值域等价证明（L1）或损失说明（L4）
  restrictions: Array[String]  # 限制条件
  diagnostic: String?          # 诊断注释（L3/L4）
```

### 嵌套 Option 检测模型

```
is_nested_option(t: MoonType) -> Bool:
  match t:
    MOption(inner) => inner is MOption(_)
    _ => false

needs_option_wrapper(t: MoonType) -> Bool:
  递归检查类型树中是否存在 MOption(MOption(_))
```

### DResult 节点

```
// DartType 枚举新增变体
DResult(DartType, DartType)   // 结构化 Result——保留 ok/err 类型信息

// 对应的 to_dart_string
DResult(ok, err) => "Result<" + ok.to_dart_string() + ", " + err.to_dart_string() + ">"

// 反向映射
DResult(ok, err) => MResult(dart_type_to_moon_ast(ok), dart_type_to_moon_ast(err))
```

### Option 辅助类生成条件

```
needs_option_class(decls: Array[MoonDecl]) -> Bool:
  遍历所有声明中的类型引用
  如果任何位置出现 MOption(MOption(_)) 则返回 true
```

## Contracts & Interfaces

### 类型映射接口变更

**现有接口**（typesys/mapping.mbt）：
- `map_type(MoonType) -> DartType` — 新增 DResult 分支、嵌套 Option 检测
- `to_dart_string(DartType) -> String` — 新增 DResult 发射
- `ffi_native_type(MoonType) -> String` — 新增 DResult → Pointer<Opaque>
- `ffi_dart_type(MoonType) -> String` — 新增 DResult → Pointer<Opaque>

**新增接口**（typesys/mapping.mbt）：
- `is_nested_option(MoonType) -> Bool` — 检测嵌套 Option
- `needs_option_class(Array[MoonDecl]) -> Bool` — 检测程序是否需要辅助类
- `map_type_strict(MoonType) -> DartType raise Moon2DartError` — strict 模式映射，L4 类型 raise

**反向映射接口变更**（reverse_codegen/reverse_emitter.mbt）：
- `dart_type_to_moon_ast(DartType) -> MoonType` — 新增 DResult → MResult 分支
- `DartType.to_moon_string() -> String` — 新增 DResult 发射

### 代码生成接口变更

**emitter.mbt 新增**：
- `emit_option_class() -> String` — 生成辅助 Option 类定义
- `emit_dart_program` 中条件性调用 `emit_option_class()`
- `emit_dart_decl` 中 DResult 相关诊断注释

**moon2dart.mbt 新增**：
- `transpile_source_strict(src) -> String raise Moon2DartError` — strict 模式管线

**CLI 新增**：
- `--strict` 选项，传递给 `transpile_source_strict`

### 测试接口

**新增白盒测试文件**：
- `typesys/mapping_wbtest.mbt` — DResult 映射 + 嵌套 Option 检测 + strict 模式
- `codegen/emitter_wbtest.mbt` — 辅助类生成 + DResult 发射 + 诊断注释
- `reverse_codegen/reverse_emitter_wbtest.mbt` — DResult 反向 + Option 辅助类反向

**新增变异测试**（在现有测试文件中追加）：
- 注入"嵌套 Option 塌缩"缺陷 → 断言变红
- 注入"Result 退化为 DCustom"缺陷 → 断言变红
- 注入"UInt 语义丢失未标注"缺陷 → 断言变红

### 验收记分卡接口

**docs/assessment.md 更新为三口径**：
1. 往返类型恢复率 = L1 映射往返测试通过数 / L1 映射总数
2. 语义等价测试通过率 = 通过的语义断言数 / 总语义断言数
3. 人工修复数 = 全流程人工改动行数（目标 0）

每个口径都有对应的 `moon test` 命令作为 evidence。
