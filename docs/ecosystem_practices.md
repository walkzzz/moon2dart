# 跨语言转换生态做法与本项目对照 | Ecosystem Practices for Cross-Language Transpilation

> v0.12.0 · 2026-11-20 · 为第二轮回应提供方法论依据：主流转换器如何处理"语义不等价、推断失败、集合差异"
> 说明：以下为各项目公开文档/实现中稳定的工程做法，不引用具体版本行号；对照结论为本项目判断。

## 1. 结论：主流生态不承诺"全语言自动等价"

没有任何成熟转换器承诺"任意源语言程序 → 目标语言完全等价"。它们的一致做法是：

1. **划定可转换子集**（语法/类型/运行时三类子集）；
2. **用运行时 shim 或库移植**弥合数值/集合语义；
3. **失败即诊断**（编译错误或显式拒绝），不静默近似；
4. **显式标注不安全/有损边界**，要求人工审阅；
5. **用差分执行（differential testing）**给出可复现证据，而不是只做类型断言。

## 2. 生态对照表 | Comparison

| 项目 | 语义策略 | 失败/不支持处理 | 集合与数值 | 人工边界 | moon2dart 对应 |
| --- | --- | --- | --- | --- | --- |
| **TypeScript (tsc)** | 类型擦除 + 固定 downlevel 目标；`strict` / `noImplicitAny` | 类型检查失败 = 编译错误；不支持语法 = 诊断 | 无运行时集合；类型层 only | 类型断言（`as`）由用户负责 | `Error` 默认策略（推断失败拒绝）；`UNRESOLVED` 报告 |
| **Babel** | 单语法插件变换 | 未支持的语法直接抛 `SyntaxError`，不静默跳过 | 插件级 | 插件边界 | 解析器 fail-closed（`for`/位运算/复合赋值直接报错） |
| **Scala.js** | 运行时保持：32 位 `Int` 运算、`Long` 用运行时类、标准库移植 | 编译错误；不支持的 API 明确排除 | 集合库整体移植；`==` 语义按 Scala 定义 | `@JSExport`/JS 互操作边界 | `mb32*` 回绕 shim；`mbEquals` 逐元素相等；L1-L4 分级 |
| **Kotlin/JS** | `Long` 包装类、stdlib 移植、IR 后端 | 编译错误；JS 互操作显式外部声明 | 集合 stdlib 移植 | `external` 声明 | 运行时 helper（`mbEquals`）+ 数值 shim |
| **GopherJS** | 移植 Go 运行时（slice/map/goroutine 语义） | 编译错误 | slice/map 用运行时结构模拟 | 反射/unsafe 边界 | 集合 helper；明确排除并发（Spawn=L4） |
| **c2rust** | 生成 `unsafe` Rust，不承诺安全性/完全等价 | 显式 `unsafe` 标注 + 人工审阅 | C 指针/内存模型差异显式暴露 | **强制人工审阅** | L3/L4 诊断 + `docs/safety_boundary.md` 人工清单 |
| **Emscripten** | 移植 libc/运行时（musl）+ JS 互操作 | 不支持的 API 明确报错 | 运行时库整体移植 | 文件/线程/网络 API 边界 | 集合/整数 shim；FFI 列为 L4 |
| **Haxe** | 多目标后端 + 目标特定语义 | 目标不支持则编译错误 | 各目标 stdlib 抽象 | 条件编译（`#if target`） | 本项目**禁止**目标条件编译，改为运行时 shim + 显式约束 |
| **Closure Compiler** | 类型检查 + 优化 | 警告可升级为 error（`--jscomp_error`） | JS 原生 | 外部类型声明 | CI 安全门禁把诊断升级为硬失败 |
| **Fable (F#→JS)** | 整数位运算包装、`Async` 映射、集合库移植 | 编译错误 | 数值/集合 shim | JS 互操作 | 数值 shim + 集合 helper |
| **ReScript / Reason** | 类型擦除；`external` / `%raw` 显式越界 | 编译错误 | 依赖 JS 原生 | 显式 unsafe | 无 `%raw` 级逃生口（更保守） |
| **dart2js / Dart web** | VM 与 web 的 `int` 值域差异明确文档（web 53 位） | 编译错误 | 数值语义差异文档化 | 平台约束 | `Int64` 标注"限 Dart VM"，web 降级 L2 |
| **SwiftWasm / Pyodide** | 运行时整体移植 | 不支持的 API 明确 | 标准库/解释器移植 | 宿主能力边界 | 本项目选择"最小 shim + 拒绝"，不移植整个运行时 |

## 3. 对本项目整改的直接映射

| 初审关切 | 生态做法 | v0.12.0 落地 |
| --- | --- | --- |
| Array→List 定级过高 | Scala.js/Kotlin 均移植集合语义或显式约束，不默认 `List ==` 等价 | 降为 **L2-C**；`mbEquals` 还原逐元素相等；操作矩阵与约束 |
| 推断失败无安全边界 | tsc `noImplicitAny` / Babel fail-fast / Closure 升级 error | **默认 Error**；拒绝生成 + 非零退出；`Warn` 留痕；JSON/MD 报告 |
| 只有类型断言、无行为证据 | 各项目用运行时测试/差分执行 | 算术 14 + 业务函数 13 双端实跑；`safety_gate` 8 项；`dart analyze` |
| 分级不能指导复用 | c2rust `unsafe` 边界 + 人工审阅 | L1-C/L2/L3/L4 + 人工介入清单 + 机器可读报告 |

## 4. 本项目不采纳的做法（说明理由）

- **目标条件编译（Haxe 式）**：会造成"同一源码不同目标不同语义"，与本项目"单一产物可审计"目标冲突；
- **移植完整运行时（GopherJS/Pyodide 式）**：MoonBit 集合/字符串与 Dart 的差异集中在少数原语，
  移植整套运行时成本高且难以审计，当前采用按需 shim；
- **生成 `unsafe` 逃生口（c2rust 式）**：Dart 无对应机制；本项目用"拒绝 + 人工清单"替代，
  避免把不等价隐藏在注释里。

## 5. 引用与复现

- 本文件为方法论对照，不作为具体版本行为断言；关键结论均可由本地门禁复现：
  ```bash
  node scripts/golden_check.mjs   # 27/27 行一致（14 算术 + 13 业务）
  node scripts/safety_gate.mjs    # 8/8 安全边界
  dart analyze golden_out --fatal-infos
  ```