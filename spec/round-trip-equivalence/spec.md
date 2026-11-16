# Feature Specification: 往返语义等价性验证体系

**Created**: 2026-11-16  
**Status**: Draft  
**Input**: 黑客松组委会驳回理由——"目前的转换与验证方案尚不能支持所承诺的往返语义等价。请明确可转换范围及语义保留方法，并以嵌套可选值等案例说明。"

## Overview

为 moon2dart 建立一套**可验证的往返语义等价性体系**：明确定义哪些 MoonBit 构造可以往返转换且语义等价、哪些有损、哪些不支持；为每个映射提供可执行断言证明；以嵌套可选值（`Option[Option[T]]`）为关键案例，展示语义保留方法。借鉴 flutter-ohos-expert-agent 的"没跑过 ≠ 通过"原则和四态判定协议，确保所有语义声称都有自动测试背书。

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 嵌套可选值语义保留 (Priority: P1)

作为 moon2dart 用户，我转换包含 `Option[Option[Int]]` 的 MoonBit 代码时，生成的 Dart 代码能保留三分态语义（`Some(Some(42))` / `Some(None)` / `None`），反向转换后语义完全恢复。

**Why this priority**: 组委会点名要求的案例，是驳回的核心原因。

**Independent Test**: 可通过构造 `Option[Option[Int]]` 的三种值、正向转 Dart、反向转回 MoonBit、对比值域是否完整来独立验证。

**Acceptance Scenarios**:

1. **Given** MoonBit 源码 `let x : Option[Option[Int]] = Some(Some(42))`, **When** transpile → Dart → reverse_transpile, **Then** 恢复为 `Some(Some(42))`
2. **Given** MoonBit 源码 `let x : Option[Option[Int]] = Some(None)`, **When** transpile → Dart, **Then** 生成的 Dart 代码能区分 `Some(None)` 与 `None`
3. **Given** MoonBit 源码 `let x : Option[Option[Int]] = None`, **When** transpile → Dart → reverse_transpile, **Then** 恢复为 `None`
4. **Given** `Option[Option[Option[Int]]]`（三层嵌套）, **When** transpile, **Then** 生成的 Dart 代码递归保留多分态语义

---

### User Story 2 - Result 类型往返语义保留 (Priority: P1)

作为 moon2dart 用户，我转换包含 `Result[T, E]` 的 MoonBit 代码时，类型结构在往返中不退化为不透明自定义类型，反向转换后能恢复 `MResult` 节点。

**Why this priority**: Result 是 MoonBit 核心错误处理类型，`DCustom` 退化是往返中最大的结构性缺陷。

**Independent Test**: 构造 `Result[Int, String]` 的声明，正向转 Dart 后检查 Dart AST 中类型节点是否为 `DResult` 而非 `DCustom`，反向转回后检查是否恢复为 `MResult(MInt, MString)`。

**Acceptance Scenarios**:

1. **Given** MoonBit 类型 `Result[Int, String]`, **When** map_type, **Then** 产生 `DResult(DInt, DString)` 而非 `DCustom("Result<int, String>")`
2. **Given** Dart 类型 `Result<int, String>`（从 moon2dart 生成）, **When** dart_type_to_moon_ast, **Then** 恢复为 `MResult(MInt, MString)`
3. **Given** MoonBit `fn divide(a:Int, b:Int) -> Result[Int, String]`, **When** 正向转 Dart → 反向转回, **Then** 返回类型仍为 `Result[Int, String]`

---

### User Story 3 - 可转换范围分类与文档 (Priority: P1)

作为评委/审核者，我能查看一份明确的可转换范围文档，了解哪些构造承诺往返等价、哪些有损、哪些不支持，以及每个映射的语义保留方法和限制。

**Why this priority**: 组委会明确要求"明确可转换范围及语义保留方法"。

**Independent Test**: 文档中每个映射等级（L1/L2/L3/L4）都有对应的自动测试覆盖；文档声称的 L1 映射全部通过往返测试。

**Acceptance Scenarios**:

1. **Given** 可转换范围文档, **When** 检查 L1 映射列表, **Then** 每个映射都有对应的往返等价自动测试
2. **Given** 可转换范围文档, **When** 检查 L4 映射列表, **Then** 每个映射都有明确的语义丢失说明和替代建议
3. **Given** 新增的 MoonBit 构造, **When** 尝试转换, **Then** 若属于 L4 范围，生成诊断信息而非静默降级

---

### User Story 4 - 语义等价自动断言与变异测试 (Priority: P2)

作为 moon2dart 开发者，我有一套自动测试框架，能验证每个映射的往返语义等价性，且通过变异测试确保断言有效性。

**Why this priority**: 借鉴 flutter-ohos-expert 的核心方法论——断言必须可执行且通过变异测试验证，否则声称的等价性不可信。

**Independent Test**: 运行 `moon test`，所有语义等价测试通过；注入已知缺陷（如把 `DResult` 降级回 `DCustom`），对应断言变红。

**Acceptance Scenarios**:

1. **Given** 语义等价测试套件, **When** 运行测试, **Then** 所有 L1 映射的往返测试通过
2. **Given** 语义等价测试套件, **When** 注入"嵌套 Option 塌缩为 T?"的缺陷, **Then** 嵌套 Option 测试变红
3. **Given** 语义等价测试套件, **When** 注入"Result 退化为 DCustom"的缺陷, **Then** Result 往返测试变红

---

### User Story 5 - 有损映射的诊断与标注 (Priority: P2)

作为 moon2dart 用户，当我的代码包含 `UInt`/`Float` 等有损映射类型时，转换结果包含明确的诊断注释，且 `--strict` 模式下拒绝转换。

**Why this priority**: 诚实标注有损映射是语义等价性的基本要求，且是 pitfall 目录的自然扩展。

**Independent Test**: 包含 `UInt` 的 MoonBit 源码转换后生成的 Dart 代码包含 `// WARNING: unsigned semantics lost` 注释；`--strict` 模式下抛出错误。

**Acceptance Scenarios**:

1. **Given** MoonBit 源码含 `UInt` 类型, **When** transpile（默认模式）, **Then** 生成的 Dart 代码含语义丢失警告注释
2. **Given** MoonBit 源码含 `UInt` 类型, **When** transpile（`--strict` 模式）, **Then** 抛出 `Moon2DartError::TypeError`
3. **Given** MoonBit 源码含 `Float` 类型, **When** transpile（默认模式）, **Then** 生成的 Dart 代码含精度提升警告注释

---

### User Story 6 - 验收记分卡 (Priority: P2)

作为项目维护者/评委，我有一份可计算的验收记分卡，三个口径可被第三方重跑验证。

**Why this priority**: 借鉴 flutter-ohos-expert 的验收记分卡模式——用数字说话，不用自我声称。

**Independent Test**: 记分卡中的每个检查点都有对应的可执行命令（`moon test`/`moon check`），数字可由第三方复算。

**Acceptance Scenarios**:

1. **Given** 验收记分卡, **When** 检查"往返类型恢复率", **Then** 数字 = L1 映射往返测试通过数 / L1 映射总数，可由 `moon test` 复算
2. **Given** 验收记分卡, **When** 检查"语义等价测试通过率", **Then** 数字 = 通过的语义断言数 / 总语义断言数
3. **Given** 验收记分卡, **When** 检查"人工修复数", **Then** 数字 = 0（全流程无人工干预）

---

### Edge Cases

- `Option[Result[Int, String]]`（Option 内嵌 Result）的语义保留
- `Result[Option[Int], String]`（Result 内嵌 Option）的语义保留
- `Array[Option[Int]]` → `List<int?>` 的往返一致性
- 泛型类型参数 `struct Container[T] { value: Option[T] }` 中 T 为 Option 时的处理
- `Option[T]` 中 T 为 `MCustom("MyType")` 时的辅助类命名
- 空 `Some(None)` 与 `None` 在 match 模式中的区分

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 类型映射系统 MUST 支持 `DResult(DartType, DartType)` 结构化节点，替代当前 `DCustom("Result<...>")` 退化映射
- **FR-002**: 类型映射系统 MUST 检测嵌套 `Option[Option[T]]` 并生成 Dart 辅助类 `Option<T>` 以保留三分态语义
- **FR-003**: 反向映射系统 MUST 将 `DResult` 映射回 `MResult`，而非 `MCustom`
- **FR-004**: 反向映射系统 MUST 将 Dart `Option<T>` 辅助类映射回 `MOption(MOption(T))`
- **FR-005**: 可转换范围文档 MUST 按四级分类（L1 完全等价 / L2 结构等价 / L3 受限等价 / L4 不等价）列出所有映射
- **FR-006**: 每个映射等级 MUST 有对应的自动测试，且 L1 映射的往返测试全部通过
- **FR-007**: 有损映射（UInt/Float/Char）MUST 在生成代码中包含诊断注释
- **FR-008**: `--strict` 模式 MUST 拒绝所有 L4 映射的转换并抛出 `Moon2DartError`
- **FR-009**: 语义等价测试套件 MUST 包含变异测试——注入已知缺陷后对应断言变红
- **FR-010**: 验收记分卡 MUST 三个口径可被第三方重跑复算：往返类型恢复率、语义等价测试通过率、人工修复数
- **FR-011**: `emit_dart_program` MUST 在检测到嵌套 Option 时自动生成辅助类定义
- **FR-012**: `emit_dart_program` MUST 在检测到 Result 类型时生成 `DResult` 格式的 sealed class 而非 DCustom
- **FR-013**: Dart 代码生成中 `Some(None)` 与 `None` 的区分 MUST 通过辅助类实现，而非依赖 nullable 塌缩
- **FR-014**: 现有 383 个测试 MUST 全部继续通过（改进为严格向后兼容）

### Key Entities

- **SemanticMapping**: 一个 MoonBit → Dart 类型映射条目，包含等级（L1-L4）、正向规则、反向规则、值域证明、限制说明
- **RoundTripTest**: 一个往返测试用例，描述 MoonBit 构造 → Dart → MoonBit 的完整路径，验证语义恢复
- **DiagnosticAnnotation**: 生成 Dart 代码中的诊断注释，标注有损映射的语义丢失
- **OptionWrapper**: Dart 辅助类 `Option<T>`，仅在检测到嵌套 Option 时生成
- **AcceptanceScorecard**: 验收记分卡，三个口径的数字和 evidence

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 嵌套可选值 `Option[Option[Int]]` 的三种值在往返转换后 100% 语义恢复（可执行断言证明）
- **SC-002**: Result 类型 `Result[T, E]` 在往返转换后类型结构 100% 恢复（DResult → MResult 而非 DCustom → MCustom）
- **SC-003**: 可转换范围文档覆盖所有已实现的映射（18 种 L1 + 2 种 L2 + 3 种 L3 + 5 种 L4 = 28 个条目）
- **SC-004**: 往返类型恢复率 = L1 映射往返测试通过数 / L1 映射总数 ≥ 95%
- **SC-005**: 语义等价测试通过率 = 通过断言数 / 总断言数 ≥ 95%
- **SC-006**: 人工修复数 = 0（全流程无人工干预即可完成往返转换验证）
- **SC-007**: 变异测试：注入 3 个已知缺陷（嵌套 Option 塌缩 / Result 退化 / UInt 语义丢失），对应断言全部变红
- **SC-008**: 现有 383 个测试全部继续通过，零回归

## Assumptions

- MoonBit 语言核心语义在本次改进范围内不变（`Option[T]` 三分态、`Result[T,E]` 代数语义）
- Dart 3 空安全规则不变（`T??` 塌缩为 `T?`，sealed class 穷尽性检查）
- 嵌套 Option 在实际代码中出现频率低于 5%，但必须支持以保证语义完备
- `--strict` 模式默认不启用，保持现有行为的向后兼容
- 辅助类 `Option<T>` 仅在检测到嵌套 Option 时生成，单层 Option 保持 `T?` 的零开销映射
- Result 辅助 sealed class 的命名和结构与现有 `emit_result_class()` 保持一致
- 本期不涉及 Dart 真机运行验证（纯编译期/类型级语义等价证明），v1.0.0 再做运行时验证

## Open Questions

- 是否需要支持 `Option[T]` 中 T 为函数类型（如 `Option[fn(Int) -> Int]`）的辅助类生成？这会影响辅助类的泛型约束设计。
- `--strict` 模式的 CLI 参数设计是新增 `--strict` 还是复用现有 `--pure-only` 扩展语义？
- 验收记分卡是否纳入现有 `docs/assessment.md` 还是独立为新的 `docs/semantic_acceptance.md`？
