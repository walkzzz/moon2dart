# moon2dart 迭代路线图

> 已实现 v0.1.0-v0.2.0 · 2026-11-07 | 更新 v0.3.0-v1.0.0 规划

## 最终目标

开发者引入 moon2dart 后，**自动将整个 MoonBit 项目转换为同步的 Flutter/Dart 项目**。

### 四条交付线

| 交付线 | 发布渠道 | 消费者 | 覆盖版本 |
|--------|----------|--------|----------|
| 库 API | `moon add walkzzz/moon2dart` | MoonBit 开发者 | v0.1.0-v0.8.0 |
| CLI 工具 | `mooncakes.io/cli` | 命令行用户 | v0.2.0, v0.4.0, v0.8.0, v0.9.0 |
| Skill | `mooncakes.io/skills` | 大模型 Agent | v0.9.0 |
| MCP 服务器 | 随 CLI 分发 | AI 工具链 | v0.9.0 |

## 路线总览

```
v0.1.0 ──► v0.2.0 ──► v0.3.0 ──► v0.4.0 ──► v0.5.0
transpiler   parser     trait      项目级     async
骨架         源码→AST   模式匹配    扫描       Option
  ✅

v0.5.0 ──► v0.6.0 ──► v0.7.0 ──► v0.8.0 ──► v0.9.0 ──► v1.0.0
async      FFI       Flutter     自动       MCP+Skill   完整
Option     混合      widget      触发同步    大模型消费   发布
```

---

## v0.1.0 ✅ — transpiler 骨架（已完成）

**目标**：建立 transpiler 骨架，支持手动 AST → Dart 转换。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | ast 包：MoonType(16)/MoonExpr(9)/MoonPattern(5)/MoonDecl(3) | ✅ |
| S2 | typesys 包：DartType(12) + map_type + emit_dart | ✅ |
| S3 | codegen 包：emit_dart_expr/pattern/decl/program | ✅ |
| S4 | 根包 transpile 入口 | ✅ |
| S5 | CLI 演示模式 | ✅ |
| S6 | moon.mod + AGENTS.md + CI | ✅ |
| S7 | 门禁验证 + commit + push | ✅ |
| S8 | 文档完善 + 发布准备 | ✅ |

**交付**：33 测试 × 4 后端，0 warning，`transpile`/`transpile_decl`/`transpile_expr`/`transpile_type` API。

---

## v0.2.0 ✅ — 解析器：MoonBit 源码 → AST（已完成）

**目标**：实现 MoonBit 源码解析器，支持 `.mbt` 文件 → AST → Dart 单文件转换。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | lexer：词法分析（TokenKind 57 变体 + Lexer，15 白盒测试） | ✅ |
| S2 | parser：语法分析（fn/struct/enum/expr/type，27 白盒测试） | ✅ |
| S3 | 单文件转换管线 transpile_source（8 管线测试） | ✅ |
| S4 | CLI convert/demo/help 子命令 | ✅ |
| S5 | 测试 + 文档 + 门禁 + 提交推送 | ✅ |

**交付**：83 测试 × 4 后端，`transpile_source` API，CLI `convert <file>` 子命令。

---

## v0.3.0 ✅ — trait + 模式匹配 + derive 生成（已完成）

**目标**：支持 trait 转换、模式匹配、derive 自动派生。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | trait → abstract class（DTrait + TraitMethod AST，parser，codegen） | ✅ |
| S2 | match → switch expression（Dart 3 pattern matching） | ✅ |
| S3 | derive(Debug) → toString()，derive(Eq) → operator==，derive(Compare) → compareTo() | ✅ |
| S4 | pub(open) trait 跨包实现 → impl Trait for Type → class Type implements Trait | ✅ |
| S5 | 测试 + 文档 + 门禁 | ✅ |

**交付**：125 测试 × 4 后端，0 warning，trait/match/derive/impl 转换。

---

## v0.4.0 — 项目级扫描 + 包结构映射

**目标**：扫描整个 MoonBit 项目目录，映射为 Dart 项目结构。

| Sprint | 内容 |
|--------|------|
| S1 | 项目扫描器（遍历目录，读取 moon.mod/moon.pkg，构建依赖图） |
| S2 | MoonBit 包结构 → Dart 包结构（pubspec.yaml + lib/ + test/） |
| S3 | 多文件项目转换（依赖图 + 拓扑排序 + 批量转换） |
| S4 | CLI `moon2dart project <dir> -o <output>` 子命令 |
| S5 | 测试 + 文档 |

**交付线**：库 API（`transpile_project`）、CLI（`project` 子命令）

---

## v0.5.0 — async + Option + Result + 泛型

**目标**：支持异步、null safety、错误类型、泛型。

| Sprint | 内容 |
|--------|------|
| S1 | async/await → Future/await |
| S2 | Option[T] → T? null safety |
| S3 | Result[T,E] → 自定义 Result class（sealed class + Ok/Err） |
| S4 | 泛型类型参数支持（fn<T>、struct<T>、enum<T>） |
| S5 | 闭包 → 箭头函数 |
| S6 | 测试 + 文档 |

**交付线**：库 API（async/Option/Result/泛型转换）

---

## v0.6.0 — FFI 混合模式

**目标**：支持 FFI 转换（dart:ffi 桥接）。

| Sprint | 内容 |
|--------|------|
| S1 | extern "C" → dart:ffi DynamicLibrary |
| S2 | 类型转换桥接代码生成（C 类型 ↔ Dart 类型） |
| S3 | 原生库加载代码 |
| S4 | CLI `--pure-only` 只转换纯子集（跳过 FFI） |
| S5 | 测试 + 文档 |

**交付线**：库 API（FFI 转换）、CLI（`--pure-only` 选项）

---

## v0.7.0 — Flutter widget 转换

**目标**：支持 MoonBit UI 抽象 → Flutter widget 树。

| Sprint | 内容 |
|--------|------|
| S1 | MoonBit UI 抽象 → Flutter widget（Text/Container/Row/Column） |
| S2 | 布局（Row/Column/Stack/Padding/Container/Expanded） |
| S3 | 状态管理（StatelessWidget/StatefulWidget + setState） |
| S4 | 事件处理（onTap/onPressed/onChanged） |
| S5 | main 入口 → runApp(MyApp()) |
| S6 | 测试 + 文档 |

**交付线**：库 API（widget 转换）

---

## v0.8.0 — 自动触发 + 项目同步（核心功能）

**目标**：引入库后自动触发项目转换，支持增量同步。

| Sprint | 内容 |
|--------|------|
| S1 | 引入库自动触发机制（moon.pkg hook / build script） |
| S2 | 文件变更检测（增量更新，只转换变更文件） |
| S3 | 项目同步（MoonBit ↔ Dart 保持同步） |
| S4 | CLI `moon2dart sync` / `moon2dart watch` 子命令 |
| S5 | 配置文件（moon2dart.toml — 排除规则/映射规则/输出路径） |
| S6 | 测试 + 文档 |

**交付线**：库 API（auto_transpile）、CLI（`sync`/`watch` 子命令）

---

## v0.9.0 — MCP 服务器 + Skill（大模型消费）

**目标**：开发 MCP 服务器和 Skill，让大模型 Agent 能调用 moon2dart。

| Sprint | 内容 |
|--------|------|
| S1 | MCP 服务器骨架（JSON-RPC + stdio，参考 chrono_tz-mbt/cmd/mcp） |
| S2 | MCP 工具定义（convert/project/sync/analyze/format/list_tools） |
| S3 | Skill 描述符（mooncakes.io/skills 发布格式 — SKILL.md + 工具清单） |
| S4 | CLI `moon2dart serve` 启动 MCP 服务器 |
| S5 | 测试 + 文档 |

**MCP 工具清单**：

| 工具 | 参数 | 功能 |
|------|------|------|
| `moon2dart_convert` | `{file: string, output?: string}` | 单文件转换 |
| `moon2dart_project` | `{dir: string, output: string}` | 项目级转换 |
| `moon2dart_sync` | `{dir: string, watch?: bool}` | 项目同步 |
| `moon2dart_analyze` | `{file: string}` | 分析 MoonBit 代码结构 |
| `moon2dart_format` | `{code: string}` | 格式化生成的 Dart 代码 |
| `moon2dart_list_tools` | `{}` | 列出所有可用工具 |

**交付线**：CLI（`serve` 子命令）、Skill、MCP 服务器

---

## v1.0.0 — 验证 + 完整发布

**目标**：生产可用，完整发布到 mooncakes.io。

| Sprint | 内容 |
|--------|------|
| S1 | dart analyze 集成验证（生成的 Dart 代码零警告） |
| S2 | flutter test 集成（生成的 Flutter 项目可测试） |
| S3 | round-trip 测试（MoonBit → Dart → 语义对比） |
| S4 | 完整用户文档 + 示例项目（3 个：纯逻辑/UI/FFI） |
| S5 | mooncakes.io 发布（库 + CLI + skill 三渠道） |
| S6 | 最终验证 + 发布 |

**交付线**：全部四条交付线正式发布

---

## 里程碑与风险

| 版本 | 风险 | 缓解 |
|------|------|------|
| v0.1.0 ✅ | 🟢 低 | 纯骨架，无外部依赖 |
| v0.2.0 | 🟡 中 | MoonBit 语法复杂，parser 工作量大 |
| v0.3.0 | 🟡 中 | trait→mixin 映射不完整（多继承冲突） |
| v0.4.0 | 🟡 中 | 项目结构映射需处理依赖图 |
| v0.5.0 | 🟢 低 | async/Option 语义近似 |
| v0.6.0 | 🔴 高 | FFI 桥接复杂，类型安全难保证 |
| v0.7.0 | 🟡 中 | widget 映射主观，需定义 UI 抽象层 |
| v0.8.0 | 🔴 高 | 自动触发依赖 MoonBit build hook（机制不成熟） |
| v0.9.0 | 🟡 中 | MCP/Skill 规范待确认 |
| v1.0.0 | 🟡 中 | 整体质量保障 + 发布流程 |

## 技术参考

| 参考 | 用途 |
|------|------|
| `chrono_tz-mbt/cmd/mcp/main.mbt` | MCP 服务器架构（JSON-RPC + stdio + 工具分发，623 行） |
| `chrono_tz-mbt/cmd/cli/main.mbt` | CLI 子命令解析模式 |
| `moonbit_learning/advanced_basics` | MoonBit 语言特性（Json/defer/管道/is 表达式） |
| `docs/type_mapping.md` | 类型映射规范 |
| `docs/architecture.md` | 架构设计 |