# Changelog | moon2dart

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

> **版本双轨说明**：功能迭代版本（v0.x.y）的完整记录见 [docs/changelog.md](docs/changelog.md)；mooncakes 包版本沿 0.1.x 线推进——包 0.1.0 = 功能 v0.1.0-v0.10.0 全量，包 0.1.1 = 功能 v0.11.0。

## [0.1.1] - 2026-11-18

对应功能版本 **v0.11.0**（运行时语义保持体系），详情见 [docs/changelog.md](docs/changelog.md)。

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
