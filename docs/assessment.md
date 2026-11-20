# moon2dart 验收记分卡 | Acceptance Scorecard（2026-11-20，逐检查点 + evidence）

> 三口径（借鉴 flutter-ohos-expert-agent acceptance_scorecard）：①**没跑过 ≠ 通过**；②**分母不猜**；③**每条检查点可按 evidence 第三方复算**（本机命令 + CI 日志）。
> 权重自设（对照章程评审四维度）：工程质量 40 / 完成度 25 / 生态贡献 20 / 展示表现 15。

## v0.12.0 语义等价三口径 | Three Metrics

| 口径 | 计算公式 | 目标 | 当前值 | evidence |
|------|---------|------|--------|----------|
| 往返类型恢复率 | L1 round-trip 通过数 / L1 总数 | ≥ 95% | 15/15 = 100% | `assert_round_trip` 测试全绿（集合移出 L1，见 type_mapping） |
| 语义等价测试通过率 | 通过断言数 / 总断言数 | ≥ 95% | 590/590 = 100% | `moon test --target native` 全绿（v0.12.0 口径） |
| strict 模式 L4 拒绝率 | L4 strict 拒绝数 / L4 总数 | 100% | 5/5 = 100% | `map_type_strict` 测试全绿 |
| **双端观测等价率** | golden 一致行 / 总行 | 100% | **27/27 = 100%** | `node scripts/golden_check.mjs`（算术 14 + 业务 13） |
| **安全边界门禁** | 通过项 / 总项 | 100% | **8/8 = 100%** | `node scripts/safety_gate.mjs` |

### 口径定义 | Metric Definitions

**1. 往返类型恢复率**：对每个 L1 映射条目，构造 MoonBit 类型 → `map_type` 正向映射 → `dart_type_to_moon_ast` 反向映射 → 比较恢复后类型字符串与原始一致。15 个 L1 条目全覆盖（集合为 L2-C，由双端 golden 证明而非类型断言）。

**2. 语义等价测试通过率**：全量 `moon test` 通过的断言数除以总断言数（590 测试 native 后端，v0.12.0 口径）。包含 L1 往返测试、L2 结构/集合约束测试、L3 受限测试、L4 拒绝测试、嵌套 Option 测试、DResult 测试、安全边界测试、诊断标注测试。

**3. strict 模式 L4 拒绝率**：在 strict 模式下，所有 L4 类型（ForeignFunction/Channel/Spawn 及其容器包装）必须 raise `TypeError`，拒绝生成不安全代码。5 个 L4 场景全覆盖。

**4. 双端观测等价率**：同一输入在 MoonBit native 与 Dart VM 两端实跑，stdout 逐行一致的行数占比（`scripts/golden_check.mjs`，报告 `docs/golden_results*.md`）。

**5. 安全边界门禁**：fail-closed / warn 标注 / 报告可解析 / 未支持语法拒绝 / 幂等 / `mbEquals` / 回绕共 8 项（`scripts/safety_gate.mjs`）。

### 完成度（25）| Completeness

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| mooncakes 0.1.1 发布 | 发布页 latest == 0.1.1 | 10 | ✅ | 已发布（2026-11-18，build_status success） |
| mooncakes 0.1.2（v0.12.0） | 整改批次发布 | — | 🔶 待发布 | 由维护者执行；`moon publish --dry-run` 预检 |
| proposal 申报书 | hackathon2026_moon2dart_proposal.md（v0.12.0 口径） | 8 | ✅ | 文件存在 + 本轮更新（L1/L2 计数、27/27、安全边界） |
| AGENTS.md | Sprint 史 / 包结构 / 依赖关系 / 交付线 / 版本双轨 / 语义安全纪律 | 4 | ✅ | 本轮补 v0.12.0 与安全纪律 |
| docs/ 19 份 | architecture/…/array_semantics/safety_boundary/ecosystem_practices/moonbit_ecosystem_lessons/acceptance_report | 2 | ✅ | docs/ 目录 |

### 工程质量（40）| Engineering Quality

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| check 零警告 | `moon check --target all --deny-warn` | 10 | ✅ 本机通过 | 2026-11-20 实测（196 tasks, 0 warnings） |
| 测试全绿 | `moon test --target all` | 15 | ✅ 本机通过 | native 590；js/wasm/wasm-gc 各 540 |
| moon fmt --check | 格式检查 | 5 | ✅ | 本轮 `moon fmt` 后 git diff 已复核 |
| mbti 接口校验 | `moon info && git diff --exit-code -- '*.mbti'` | 5 | ✅ | CI 改为严格；本机 `moon info` 无漂移 |
| 覆盖率报告 | `moon test --enable-coverage` + `moon coverage analyze` | 5 | ✅ | CI 断言 `uncovered line` 存在 |
| **双端 golden** | 27/27 | 5 | ✅ | `node scripts/golden_check.mjs` |
| **安全边界** | 8/8 + `dart analyze --fatal-infos` 0 issues | 5 | ✅ | `node scripts/safety_gate.mjs` |
| **官方 parser 直连** | `--official-only` 接受真实文件 4/9（兼容 4/9） | 5 | ✅ | `node scripts/acceptance_report.mjs` |

### 生态贡献（20）| Ecosystem Contribution

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| mooncakes 发布 | walkzzz/moon2dart 模块页可访问 | 12 | ✅ | 0.1.1 在线；0.1.2 待发布 |
| 四条交付线 | 库/CLI/Skill/MCP 服务器 | 5 | ✅ | AGENTS 交付线表 |
| 生态空白论证 | 无同类 MoonBit → Dart transpiler | 3 | ✅ | proposal 第二节 |

### 展示表现（15）| Presentation

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| README 完整版 | mooncakes 页面 = 完整版 | 6 | ✅ | moon.mod readme = README.md（本轮 v0.12.0 更新） |
| CI 徽章 | README badge 区含 ci.yml badge | 5 | ✅ | README badge 区 |
| issue/PR 模板 | bug/feature + PR | 4 | ✅ | .github/ISSUE_TEMPLATE、PULL_REQUEST_TEMPLATE |

**本机实测：check / test / fmt / golden / safety / dart analyze 全部通过；CI 首绿以推送后的 Actions 日志为准**（本轮不虚报 CI 状态）。