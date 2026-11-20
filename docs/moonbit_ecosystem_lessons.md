# MoonBit 生态同类库经验（Rust↔MoonBit 转换与代码生成）

> v0.12.0+ · 2026-11-20 · 调研范围：MoonBit 生态索引快照（2026-11-09，3641 模块）+ `moon search` + `moon fetch` 实源码 + 本仓库依赖缓存
> 目的：从"同类库/同生态工具"学习工程做法，校准 moon2dart 的承诺、边界与证据链

## 1. 调研对象（与"Rust 语言转换"直接相关）

| 模块 | 方向 | 关键事实（来自 README/源码） |
| --- | --- | --- |
| **mizchi/mbt_rs** | **MoonBit ↔ Rust 双向** | `mbt2rs`（MoonBit 库）+ `rs2mbt`（Rust CLI，syn/ra_ap）；**明确声明不追求完美转换**，未支持处输出 WARNING 注释人工修复；`--report` 给出真实项目转化率（calculator.rs 100%、linear_map 96%、hex 96%，`cargo expand` 后 99%）；行为等价测试 Rust 159 + MoonBit 161；roundtrip 测试断言产物片段 |
| **mizchi/ts** | TypeScript ↔ MoonBit bridge 生成 | `mtsc` 单二进制 + verb（`mtsc bridge` / `mtsc pkg npm`）；**生成物视为可再生成 output**；docs 分 14 篇（`rule-equivalence.md`、`terser-parity.md`、`mangle-fuzzing.md`、`mangle-safety.md`、`checker-priority.md`、`real-world-minify.md`），`corpus/` + `bench/` + `scripts/` |
| **bobzhang/typify** | JSON Schema → Rust / MoonBit 类型生成（Rust typify 端口） | 生成 **upstream-identical Rust token streams**；`/rust` 子包分离 token 构造/quote/渲染；正则语义对齐 Rust `regress` 0.12；CLI + 库双形态 |
| **moonbitlang/parser** | MoonBit 官方解析器 | 手写 LL(k) + moonyacc LR(1) 双 parser；AST/属性解析/JSON 序列化；`fmt` 子包**幂等格式化**（`format`/`format_mbtx`） |
| **moonbitlang/quickcheck** | 属性测试 | `quickcheck_fn` + `Arbitrary`/`Shrink` + 修饰器（non-empty/positive/sorted/ASCII/printable/Unicode）；FEAT 枚举 |
| **moonbit-community/tree-sitter-rust** / **tonyfettes/tree_sitter_rust** | Rust 语法 | 直接复用 tree-sitter 语法，不自研 |
| **starAndHonor/fst** / **comemoon** | Rust→MoonBit 移植 | 版本化 codec（v1/2/3 + CRC32C + `CodecError`）；**Rust-compatible MurmurHash3 128-bit** 哈希 |
| **Rust→MoonBit 移植群** | 语义复刻 | `aurasuisui/indexmap`、`marianoguerra/uri`、`taffy`、`geo`、`moonrfb`（Sans-I/O）等，普遍**声明上游版本 + 显式差异** |
| **walkzzz/chrono_tz-mbt**（作者自建） | 时区库移植 | 597 时区 + DST 三分支 + RFC3339；声明移植自 chrono-tz 0.11.0 |

索引场景：`lang/parser` 推荐 `moonbitlang/yacc`、`cogna-dev/parkit`；相关 `moonbitlang/parser`、`bobzhang/lexer`、`krueger`、`graphviz`；`lang/test` 推荐 `quickcheck`、`moonspec`、`moonitest`、`moon-proof`；`lang/compiler` 相关 `MoonLLVM`、`moonast`、`mizchi/codegen`。

## 2. 十二条可迁移经验

### E1 先声明"不承诺完美转换"，再给出人工修复路径
mbt_rs 首页第一段即写明"converts as much as possible and leaves the rest as WARNING comments for manual fixing"。
→ moon2dart 的 fail-closed（拒绝 + 报告 + 人工清单）方向更严格，但缺少 mbt_rs 的**逐处 WARNING + 人工修复说明**体验；本轮已有 `--on-unresolved warn` 标注与 MD/JSON 报告，后续可在报告里附"建议改写"（如补类型注解的具体位置）。

### E2 质量报告必须带**真实项目转化率**，而不是只报测试数
mbt_rs `--report` 直接给出 211/114/181/606/525 行的真实文件转化率。
→ moon2dart 目前只有 27 行 golden；本轮新增 `scripts/acceptance_report.mjs`，对本仓库真实 `.mbt` 文件统计接受/拒绝与拒绝原因（见 `docs/acceptance_report.md`）。

### E3 行为等价测试是"两端跑同一断言"，不是只比类型
mbt_rs：Rust 159 + MoonBit 161 条相同断言；mizchi/ts：与 terser 的 parity 测试。
→ moon2dart 已有 golden 27/27（stdout 逐行），下一步把"同一份断言源码"生成两端测试（而不是两套 fixture 逻辑）。

### E4 roundtrip / rule-equivalence 要作为**独立文档 + 表驱动测试**
mbt_rs `roundtrip_test.mbt` 对 fn/struct/enum/generic/Option/if/let mut/while/derive/const/type alias/array 逐项断言产物片段；mizchi/ts 有 `rule-equivalence.md`。
→ moon2dart 有 `array_semantics.md`（操作矩阵）与 `semantic_equivalence.md`；建议再补 `rule-equivalence.md` 式"每条转换规则 → 两端行为 → 证据"总表。

### E5 生态工具**优先复用官方 parser**，自研 parser 是长期风险
mbt_rs 直接用 `moonbitlang/parser.parse_string`；mizchi/ts 用 TypeScript 官方 checker。
→ moon2dart 自研 Lexer/Parser（831 行）是最大技术债：语法覆盖受限、无法跟进 MoonBit 演进。建议评估迁移到 `moonbitlang/parser`（AST 适配层），至少建立**双 parser 一致性测试**（同一源码两边 AST 关键结构对齐）。

### E6 映射表显式化 + CallKind，而不是散落的 match
mbt_rs `mapping.mbt` 用 `RustCallKind`（Macro/Func/PrefixOp/Statement/None）+ 四张 lookup（call/method/derive/type）集中管理，可直接被文档与测试引用。
→ moon2dart 的集合方法映射仍在 `emit_dart_expr_inner` 内硬编码；建议抽 `codegen/mapping.mbt`（`CollectionOp` 枚举 + lookup），使 `array_semantics.md` 的矩阵可由代码生成/校验。

### E7 fixture 化：`input.*` + `expected.*` + 生成测试
mbt_rs `fixtures/input.mbt`、`expected.rs`、`generated_test.mbt`、`input.rs`。
→ moon2dart 的 `scripts/golden_fixture/{fixture,business}.mbt` 已有输入，但缺 `expected.dart` 基线；`golden_out/business.dart` 可固化为 expected（带 diff 审阅）。

### E8 用"宿主语言"实现该方向的转换
mbt_rs：Rust→MoonBit 用 Rust（syn/ra_ap 宏展开/类型信息），MoonBit→Rust 用 MoonBit（官方 parser）。
→ moon2dart 反向（Dart→MoonBit）自研 Dart parser；建议评估用 Dart analyzer/AST（`package:analyzer`）作为前端，降低解析风险（保持"不引入运行时依赖"的前提下可作为开发期工具）。

### E9 类型映射不得丢失语义维度（本轮属性测试的直接教训）
typify 追求 "upstream-identical"；fst 保留 codec 版本；comemoon 对齐 Rust hash。
→ 本轮属性测试（随机 300 类型）立刻发现 **`Int64 → DInt64 → DInt` 往返丢失**（`dart_ast.DartType` 无 64 位节点），已修：新增 `DInt64`，同步 reverse/parser/emitter。原则固化：**映射层必须信息完备，否则不得标 L1**。

### E10 fuzz / mangle 输入，验证"失败也不崩"
mizchi/ts 有 `mangle-fuzzing.md` / `mangle-safety.md`（随机变形输入 + 安全边界）。
→ moon2dart 属性测试目前覆盖类型/幂等/fail-closed/集合相等/回绕（6 类）；下一步对 Lexer/Parser 做随机字节 fuzz（只要求不 panic、返回 ParseError）。

### E11 文档分层：quick-start / parity / safety / checker-triage
mizchi/ts docs 14 篇，把"怎么用"与"为什么不一致/怎么保证一致"分开。
→ moon2dart 已有 17 篇，但缺"parity（与上游 Rust emojis? 不适用；与 Dart 语义 parity）"与"rule-equivalence"两页；`review_anticipation.md` 是 safety 侧的补充。

### E12 CI 按"证据类型"分层
mbt_rs 三 job（MoonBit lint/test、Rust tests、behavioral equivalence）。
→ moon2dart 六步（check/四目标测试/golden/safety/analyze/契约）；建议新增 `acceptance`（真实文件接受率）与 `format`（生成物可被 `dart format` 解析）两个轻量步骤。

### E13 生成物要有来源与可再生成声明
mizchi/ts："生成物是再生成 output"；mbt_rs `just convert` 自动 `moon fmt`。
→ moon2dart 头注释已有 `Generated by moon2dart / DO NOT EDIT`；建议追加源文件与内容摘要（source mapping），并声明"重新生成是唯一编辑方式"。

### E14 移植库的"上游追踪"惯例
生态内移植库普遍在 README/包描述写"port of X vY"（fst 0.4.7、taffy 0.5.x、chrono-tz 0.11.0）。
→ moon2dart 对齐的是"语言语义"而非单一 crate；已在 README/示例声明语义目标，建议在 `semantic_equivalence.md` 顶部固定"对齐基准：MoonBit 0.1.20261117 / Dart 3.12.2"。

## 3. 对 moon2dart 的落地状态

| 经验 | 本轮落地 | 证据 |
| --- | --- | --- |
| E2 真实转化率 | `scripts/acceptance_report.mjs` + `docs/acceptance_report.md` | 见报告 |
| E3 行为等价 | golden 27/27（算术 14 + 业务 13） | `docs/golden_results*.md` |
| E6 映射显式化 | 列为 0.13.0（`codegen/mapping.mbt`） | `review_anticipation.md` |
| E8 宿主语言前端 | 列为 0.13.0 评估（Dart analyzer） | 同上 |
| E9 信息完备 | **已修 `DInt64`**（属性测试发现） | `dart_ast` / `reverse_codegen` / `dart_parser` |
| E10 fuzz | 属性测试 6 类（类型/幂等/fail-closed/集合/回绕/L3） | `moon2dart_prop_wbtest.mbt` |
| E11 文档分层 | `review_anticipation` / `array_semantics` / `safety_boundary` / 本篇 | `docs/` |
| E12 CI 分层 | golden job 增 `dart format` 可解析性 + acceptance | `.github/workflows/ci.yml` |
| E13 来源声明 | 列为 0.13.0（source digest） | 同上 |
| **E5 官方 parser** | **已落地 `official_parser` 适配层（默认前端，fail-closed；兼容兜底 + `--official-only` 度量）** | `official_parser/`、`docs/acceptance_report.md` |

## 4. 结论

MoonBit 生态里"语言转换"类项目的主流做法与 moon2dart 的整改方向一致：**划子集、补 shim、失败即诊断、双端实证、公开已知差异**。最值得补的三件事是：

1. **真实语料接受率**（E2）——已落地脚本，补齐"27 行样本太小"的质疑；
2. **复用官方 parser / 宿主语言前端**（E5/E8）——自研 parser 是最大长期风险；
3. **映射层信息完备性 + 显式映射表**（E6/E9）——属性测试已经在一天内抓到 Int64 丢失，说明随机化验证应成为常态。

## 5. 引用

- 生态索引：https://moonbit-ecosystem-index.pages.dev/（快照 2026-11-09）
- mizchi/mbt_rs：https://github.com/mizchi/mbt_rs（`mbt2rs/mapping.mbt`、`roundtrip_test.mbt`、`TODO.md`、`fixtures/`）
- mizchi/ts：https://github.com/mizchi/ts.mbt（`docs/rule-equivalence.md`、`mangle-fuzzing.md` 等）
- bobzhang/typify：https://github.com/bobzhang/typify.mbt
- moonbitlang/parser：https://github.com/moonbitlang/parser
- moonbitlang/quickcheck：https://github.com/moonbitlang/quickcheck
- 本仓库实源码：`.repos/mizchi/mbt_rs/0.3.0`、`.repos/mizchi/ts/0.6.0`（`moon fetch` 拉取）