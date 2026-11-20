# Changelog | moon2dart

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> **版本双轨说明**：功能迭代版本（v0.x.y）的完整记录见 [docs/changelog.md](docs/changelog.md)；mooncakes 包版本沿 0.1.x 线推进——包 0.1.0 = 功能 v0.1.0-v0.10.0 全量，包 0.1.1 = 功能 v0.11.0，包 0.1.2 = 功能 v0.12.0。

## [0.1.2] - 2026-11-20

对应功能版本 **v0.12.0**（第二轮初审整改：集合语义 + 安全边界 + 业务函数证据）。**未发布**（由维护者执行）。

### Changed — 语义定级修正
- **Array/Map/Set 从 L1 降为 L2-C（条件等价）**：`[1,2] == [1,2]` 在 MoonBit 为 `true`（逐元素）、Dart 为 `false`（引用）——类型映射不等于语义等价
- Wrapping 模式新增集合相等 shim `mbEquals`（递归 List/Map/Set），`==`/`!=` 发射 `mbEquals`/`!mbEquals`；Fast 模式裸发并在报告记录
- `semantic_level` 集合定级为 L2（内部 L3/L4 仍优先）；L1 条目 18 → 15，L2 2 → 5，总计 29

### Added — 安全边界（fail-closed）
- `UnresolvedPolicy`（ast 包）：`Error`（默认，拒绝）/ `Warn`（标注 + 报告）/ `Fast`（实验）
- `transpile_source_report` / `transpile_source_safe` / `report_to_json` / `report_to_markdown`
- CLI：`--on-unresolved error|warn|fast`、`--report <path>`（生成 `.json` + `.md`）；失败退出码非零
- 推断规则收紧：`EBinOp` 仅当两侧可推断且类型一致才定类型（一侧未知即 `UNRESOLVED`）
- lambda 参数并入子类型环境，闭包内回绕推断不再丢失

### Added — 业务函数子集（Array/List）
- AST/parser/emitter：数组字面量、索引、方法调用（`length`/`push`/`append`/`get`/`pop`）、`while`、`let [mut]`、赋值、括号分组
- 业务函数 golden：`golden_business` 包 + `scripts/golden_fixture/business.mbt`，双端 **13/13** 一致

### Added — 门禁与证据
- `scripts/safety_gate.mjs`：fail-closed / warn 标注 / 报告 JSON+MD / 未支持语法拒绝 / 幂等 / `mbEquals` / 回绕（8/8）
- CI `golden-dual-runtime` job：golden 27/27 + `dart analyze --fatal-infos` + safety gate + 工件上传；`.mbti` 漂移检查改为严格
- 文档：`docs/array_semantics.md`、`docs/safety_boundary.md`、`docs/ecosystem_practices.md`、`docs/review_anticipation.md`、`docs/golden_results_business.md`

### Added — 生态经验落地（v0.12.0 补丁）
- `docs/moonbit_ecosystem_lessons.md`：学习 mbt_rs / mizchi-ts / typify / 官方 parser / quickcheck 的做法（真实转化率、roundtrip、parity/fuzz、upstream-identical、幂等格式化）
- `moon2dart_prop_wbtest.mbt`：6 类固定种子属性测试（类型往返 / 幂等 / fail-closed / 集合相等 / 回绕 / L3）
- `scripts/acceptance_report.mjs` + `docs/acceptance_report.md`：真实文件接受率（fail-closed 子集，拒绝附原因）
- 属性测试发现并修复：`Int64` 往返丢失（新增 `dart_ast.DInt64`，同步 reverse/parser/emitter）；`Int32`/`UInt32` 规范别名支持
- CLI 失败退出码非零（`panic`），CI 可拦截；CI 增 `dart format` 可解析性与接受率报告

### Verified
- **579 测试** native 全绿；wasm / wasm-gc / js 各 529/529；四目标 `moon check --deny-warn` 零警告
- golden 双端 **27/27**（算术 14 + 业务函数 13）；`dart analyze` 0 issues；转换幂等
- 复现：`node scripts/golden_check.mjs && node scripts/safety_gate.mjs`

### Known gaps (documented)
- 位运算 / 复合赋值 / 一元负变量 / 切片 / `for-in` / `sort` 未实现：解析器直接拒绝（不静默近似）
- 数值格式化（`1.0`/`NaN`/`-0.0`）、字符串 Unicode、真实项目 corpus 接受率：0.13.0 待补

## [0.1.1] - 2026-11-18

对应功能版本 **v0.11.0**（运行时语义保持体系），详情见 [docs/changelog.md](docs/changelog.md)。已于 2026-11-18 发布 mooncakes.io（registry latest，build_status: success）。

### Added
- 语义双模式 `SemanticsMode`（ast 包）：Wrapping（默认）/ Fast；API `transpile_source_with_mode` / `transpile_source_with_options`，CLI `--semantics wrapping|fast`
- Int 32 位回绕模拟层（mb32* shim，按需生成）：`mb32Add/Sub/Mul/Div/Rem`，Div/Rem 含除零与 INT_MIN/-1 的 trap 模拟（throw StateError）
- mini 类型推断器（`typesys/infer.mbt`：TypeEnv + infer_expr_type + collect_int_arith_ops，推断失败保守裸发）
- golden 双端验证设施：golden 包 + `scripts/golden_check.mjs`，报告 `docs/golden_results.md`

### Fixed
- 整数除法原发射 `/`（Dart 浮点除法，类型与语义双重错误）→ `~/`（Fast）或 `mb32Div`（Wrapping）；`%` → `.remainder()`（截断余数，符号跟被除数）
- println → print 映射
- parser 类型表补 Int64/UInt/UInt64/Float（原 fallback MCustom 发射无效 Dart 类型 Int64）
- parser 新增 Double/负数字面量解析、多语句块（`EBlock`）、`fn main { ... }` 无括号零参语法
- `parse_expr_prec` 终止条件修复（非运算符 token 在 min_prec=0 时不终止）
- UInt64 语义定级漏判 L1 → 修正 L3

### Verified
- **541 测试** native 后端全通过（v0.10.0 口径 500 → 541）
- golden 双端 **14/14 行一致**：溢出回绕（`2147483647+1 = -2147483648`、`65536*65536 = 0`）、截断除余（`trunc_div(7,2) = 3`、`trunc_rem(-7,2) = -1`）、INT_MIN/-1 trap 边界两端行为类别一致（异常终止）
- 复现：`node scripts/golden_check.mjs`（前置：moon 工具链 + Dart SDK 3.x）
