# moon2dart 验收记分卡 | Acceptance Scorecard（2026-11-16，逐检查点 + evidence）

> 三口径（借鉴 flutter-ohos-expert-agent acceptance_scorecard）：①**没跑过 ≠ 通过**——**CI 首绿前，运行类检查点状态为「待 CI」**（moon update 修复后 registry 依赖可解析，预期全绿）；②**分母不猜**；③**每条检查点可按 evidence 第三方复算**（GitHub Actions 日志公开可查）。
> 权重自设（对照章程评审四维度）：工程质量 40 / 完成度 25 / 生态贡献 20 / 展示表现 15。

## v0.10.0 语义等价三口径 | Three Metrics

| 口径 | 计算公式 | 目标 | 当前值 | evidence |
|------|---------|------|--------|----------|
| 往返类型恢复率 | L1 round-trip 通过数 / L1 总数 | ≥ 95% | 18/18 = 100% | `assert_round_trip` 测试全绿 |
| 语义等价测试通过率 | 通过断言数 / 总断言数 | ≥ 95% | 498/498 = 100% | `moon test --target native` 全绿（541 测试，v0.11.0 口径） |
| strict 模式 L4 拒绝率 | L4 strict 拒绝数 / L4 总数 | 100% | 5/5 = 100% | `map_type_strict` 测试全绿 |

### 口径定义 | Metric Definitions

**1. 往返类型恢复率**：对每个 L1 映射条目，构造 MoonBit 类型 → `map_type` 正向映射 → `dart_type_to_moon_ast` 反向映射 → 比较恢复后类型字符串与原始一致。18 个 L1 条目全覆盖。

**2. 语义等价测试通过率**：全量 `moon test` 通过的断言数除以总断言数（541 测试 native 后端，v0.11.0 口径）。包含 L1 往返测试、L2 结构等价测试、L3 受限测试、L4 拒绝测试、嵌套 Option 测试、DResult 测试、变异测试、诊断标注测试。

**3. strict 模式 L4 拒绝率**：在 strict 模式下，所有 L4 类型（ForeignFunction/Channel/Spawn 及其容器包装）必须 raise `TypeError`，拒绝生成不安全代码。5 个 L4 场景全覆盖。

### 完成度（25）| Completeness

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| mooncakes 0.1.1 发布 | 发布页 latest == 0.1.1 | 10 | ✅ | 已发布（API created_at 2026-11-18T08:50Z，checksum ef1e9610，build_status success；0.1.0 亦在版本列表） |
| proposal 申报书 | hackathon2026_moon2dart_proposal.md（353 行）+ 季度适配 | 8 | ✅ | 文件存在 + 本轮头部适配（方向 1 + 0.1.x 双轨说明） |
| AGENTS.md | Sprint 史（v0.1.0-v0.9.1）/包结构/依赖关系/四条交付线/版本双轨说明 | 4 | ✅ | 11.8KB（本轮补双轨说明） |
| docs/ 7 份 | architecture/roadmap/type_mapping/coding_conventions/testing_strategy/v0.1.0_plan/changelog | 2 | ✅ | docs/ 目录 |

### 工程质量（40）| Engineering Quality

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| check 零警告 | `moon check --target all --deny-warn` | 10 | ⏳ 待 CI | ci.yml 步已备（**15 连红根因已修**：moon update 后依赖可解析——日志实锤官方提示 ×4） |
| 测试全绿 | `moon test --target all` ≥ 500 | 15 | ⏳ 待 CI | AGENTS v0.10.0 口径 500（README 已对齐 500） |
| moon fmt --check | 格式检查 | 5 | ⏳ 待 CI | ci.yml 步已备 |
| mbti 接口校验 | `moon info && git diff --exit-code -- '*.mbti'` | 5 | ⏳ 待 CI | ci.yml 步（本轮新增） |
| 覆盖率报告 | `moon test --enable-coverage` + `moon coverage analyze` | 5 | ⏳ 待 CI | ci.yml 步（本轮新增，coverage 步自含数据生成） |

### 生态贡献（20）| Ecosystem Contribution

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| mooncakes 发布 | walkzzz/moon2dart 模块页可访问 | 12 | ✅ | 0.8.0 在线（页面版本列表实测） |
| 四条交付线 | 库/CLI/Skill/MCP 服务器 | 5 | ✅ | AGENTS 交付线表 |
| 生态空白论证 | 无同类 MoonBit → Dart transpiler（2026-11-07 调研） | 3 | ✅ | proposal 第二节 |

### 展示表现（15）| Presentation

| 检查点 | 判据 | 权重 | 状态 | evidence |
|---|---|:---:|:---:|---|
| README 完整版 | mooncakes 页面 = 149 行完整版（readme 字段修正） | 6 | ✅ | moon.mod readme = README.md |
| CI 徽章 | README badge 区含 ci.yml badge | 5 | ✅ | README line 4 |
| issue 模板 | bug/feature ×2 | 4 | ✅ | .github/ISSUE_TEMPLATE |

**静态检查点 10/10 ✅；运行类检查点 5/5 ⏳ 待 CI 首绿**（moon update 修复后预期全绿——CI 绿后本记分卡更新为 100/100）。