# moon2dart 项目申报书

> 2026 MoonBit 国产基础软件开源大赛参赛申报 | 方向：开发者工具 | 申报日期：2026-11-07
> **季度优秀社区项目评选适配**（2026-11-13）：按**方向 1（新项目）**申报——mooncakes 包版本重置为 **0.1.0**（0.1.x 线），本期赛期内从零开发至 v0.9.1（**383 测试 native**），CI 修复后四目标回归即将闭环

---

## 基本信息

| 项 | 值 |
|---|---|
| 项目名称 | moon2dart：MoonBit → Dart/Flutter 代码生成器 |
| 参赛者 | walkzzz（蒋本雄）· 13689047817 · 745244185@qq.com |
| GitHub | https://github.com/walkzzz/moon2dart |
| mooncakes | `walkzzz/moon2dart`（0.8.0 已发布；包版本重置 0.1.0，见版本双轨说明） |
| 项目方向 | 开发者工具 — 代码生成器 / transpiler |
| 移植声明 | 否（原创项目，自主设计 AST + 类型映射 + 代码发射） |
| 许可证 | Apache-2.0 |

---

## 项目简介

moon2dart 是 MoonBit → Dart/Flutter 代码生成器（transpiler），将 MoonBit 项目自动转换为同步的 Flutter/Dart 项目，让 MoonBit 代码跑在 Flutter 上。提供**四条交付线**覆盖"人/CLI/LLM"三类用户入口：**库 API**（`moon add` 自动触发项目转换）、**CLI**（convert/project/sync/watch/serve）、**Skill**（大模型 Agent 消费）、**MCP 服务器**（JSON-RPC + 6 个转换工具）。

mooncakes 生态调研确认（2026-11-07）：**无任何 MoonBit → Dart/Flutter 代码生成器**在 mooncakes 上发布，本项目填补该空白。

**本期新增贡献**（赛期内，0.1.x 版本线）：v0.1.0 骨架 → v0.2.0 解析器 → v0.3.0 trait/match/derive → v0.4.0 项目级扫描 → v0.5.0 async/Option/Result/泛型/闭包 → v0.6.0 FFI（dart:ffi）→ v0.7.0 Flutter widget（50+ widget/状态管理/事件）→ v0.8.0 Dart→MoonBit 反向转换 → v0.9.0 MCP 服务器 + Agent 模式 + 增量同步 + Skill → v0.9.1 双向同步 + 冲突检测——**9 个版本、48+ 轮 Sprint 全部交付**，mooncakes 0.8.0 已发布。

---

## 预期使用场景

1. **MoonBit 后端逻辑 → Flutter 前端复用**：`moon add walkzzz/moon2dart` 引入后，`transpile_source(src)` 将 MoonBit 业务逻辑库自动转为等价 Dart 代码，避免"同一套逻辑两种语言维护"的逻辑漂移。
2. **MoonBit 项目 → 完整 Flutter 应用一键生成**：`moon2dart project <dir> -o <out>` 扫描整个 MoonBit 项目，自动生成 pubspec.yaml + lib/*.dart + widget 树 + runApp() 入口的完整 Flutter 项目。
3. **AI Agent 通过 MCP 自动完成跨语言转换**：Claude Desktop / VS Code Copilot 通过 MCP 服务器调用 6 个转换工具，让 MoonBit → Dart 成为 AI 工具链的原生能力。

---

## 核心功能与技术方案

**四包线性架构**：ast（零依赖 AST）← typesys（类型映射）← codegen（代码发射）← 根包（编排入口），线性无环，ast 可独立复用。

**转换管线**：MoonBit 源码 → Lexer（TokenKind 57 变体）→ Parser → AST → type_map（MoonType 16 变体 → DartType 12 变体）→ emit → Dart 代码 + pubspec.yaml。

**类型映射**（12 种核心映射）：MInt→int、MDouble→double、MString→String、MBool→bool、MArray→List、MMap→Map、MSet→Set、MOption→T?、MResult→sealed Result、MChar→int(rune)、MFuture→Future、MTuple→Record——覆盖基础/复合/高阶类型。

**AST 节点**：MoonType(16)/MoonExpr(9)/MoonPattern(5)/MoonDecl(3)/DartType(12)/DartExpr/DartDecl/DartMethod/DartVariant，全部 `derive(Eq, Compare, Debug)` + 显式 `pub extend`。

**反向转换**（v0.8.0）：dart_ast + dart_parser + reverse_codegen 三包——Dart 源码 → MoonBit 源码（双向同步）。

---

## 质量实测

| 指标 | 数值 |
|---|---|
| 包数 | **12**（根 + ast + typesys + codegen + parser + project + dart_ast + dart_parser + reverse_codegen + mcp_server + cmd/main + cmd/mcp） |
| 测试数 | **383**（native，v0.9.1 口径）——四目标回归即将闭环（CI 修复后） |
| 工程严格度 | `moon check --deny-warn` 零警告 |
| Sprint 迭代 | **48+ 轮**（v0.1.0-v0.9.1） |
| 交付线 | **4** 条（库 / CLI / Skill / MCP） |
| mooncakes | ✅ 0.8.0 已发布（0.1.0 重置版发布流程就绪） |
| 双向转换 | ✅ MoonBit→Dart + Dart→MoonBit（反向转换 + 双向同步 + 冲突检测） |
| CI | GitHub Actions（check --target all + test + fmt + **moon update + mbti + coverage** 五步增强） |

---

## 生态定位与差异化

mooncakes.io 全量 3566+ 包中检索 Dart/Flutter/transpiler/codegen——**无任何同类 MoonBit → Dart/Flutter 代码生成器**，本项目为唯一。

**差异化定位**：① 唯一 MoonBit → Dart transpiler（生态空白）；② 四条交付线覆盖全部用户入口；③ 自动项目级转换（库引入即触发）；④ 四后端全绿；⑤ **MCP + Skill**（AI 原生工具链）；⑥ 双向转换（MoonBit ↔ Dart）；⑦ 反向同步 + 冲突检测（v0.9.1）。

---

## 验收标准对齐（大赛要求）

| 大赛验收项 | 本项目满足方式 |
|-----------|-------------|
| MoonBit 为主 | 库自身 100% MoonBit 实现（AST + 类型映射 + 代码发射 + CLI + MCP） |
| 仓库公开 | GitHub 公开仓库，持续提交（v0.1.0-v0.9.1，9 轮 Sprint，48+ 轮迭代） |
| 能够运行 | README + 可运行示例 + **383 测试** + 0 warnings |
| 工作有效 | 原创设计，**v0.1.0-v0.9.1 九个版本全部交付**，v1.0.0 验证发布规划中 |
| 开源合规 | Apache-2.0 License，参考来源已标注（chrono_tz-mbt / MoonBit 官方文档 / Dart 规范 / Flutter） |
| AI 可解释 | AI 辅助开发，所有算法经人工审查 |
| **持续集成** | GitHub Actions 五步增强（check 四目标 --deny-warn + test + fmt + **moon update + mbti + coverage**） |

---

## 技术亮点精选

1. **唯一 MoonBit → Dart transpiler** — mooncakes.io 生态空白
2. **四条交付线** — 库 API / CLI / Skill / MCP 服务器
3. **自动项目级转换 + 双向同步** — v0.8.0/v0.9.1 核心能力
4. **完整类型映射** — 16 种 MoonType → 12 种 DartType
5. **MCP 服务器 + Agent 模式** — AI 工具链原生集成（colmugx/mcp + posoco）
6. **零 warnings + 383 测试** — `moon check --deny-warn` 门禁

---

## 技术风险与缓解

| 风险 | 缓解措施 |
|------|---------|
| MoonBit 语法复杂 | 分 Sprint 实现，先核心子集 |
| FFI 桥接类型安全 | `--pure-only` 跳过 FFI 纯子集 |
| build hook 机制不成熟 | CLI `sync` 备选触发 |
| MoonBit 语言 beta-preview | 已可用于生产，不兼容变更严格评估 |

---

## 参考与设计说明

[chrono_tz-mbt](https://github.com/walkzzz/chrono_tz-mbt)（MCP 架构参考）· [MoonBit 官方文档](https://docs.moonbitlang.com/) · [Dart 语言规范](https://dart.dev/guides/language) · [Flutter](https://flutter.dev/)。设计原则：**原创设计**（AST + 类型映射 + 代码发射自主设计）、**线性无环**（ast 零依赖可独立复用）、**零警告门禁**、**渐进式版本**。许可证 Apache-2.0。

---

## AI 声明与人工把控

本项目按章程要求披露 AI 辅助开发（README 参赛声明节 + docs/skill.md 详细范围）。以下关键决策由参赛者本人把控：**AST 节点设计与四包架构边界**、**类型映射规范**（type_mapping.md）、**transpiler 转换语义**（Option→T?/Result→sealed class/derive→toString 等映射决策）、**MCP 工具集与 Skill 形态**、**Sprint 顺序调整**（风险驱动的 S1 降级/S5+S6 合并，见 docs/roadmap.md）。提交历史、docs/changelog.md 与 CI 门禁共同保证连续可追踪性。

---

## 选型自检（对照章程审核原则）

| 章程审核原则 | 本项目对照 |
|:---|:---|
| 题目真实反映客观需求 | MoonBit 无 Dart/Flutter 桥是真实空白——Flutter 生态庞大，MoonBit 需要"跑在 Flutter 上"的入口 |
| 技术方案最优或最合适 | 四包线性架构 + AST 中间表示是 transpiler 的标准形态；`--pure-only` 提供渐进式采用路径 |
| mooncakes.io 无同质项目 | 2026-11-07 全量 3566+ 包检索确认无同类；本项目为唯一 MoonBit → Dart transpiler |
