# moon2dart 迭代路线图

> 已实现 v0.1.0-v0.8.0 · 2026-11-11 | 更新 v0.9.0-v1.0.0 规划

## 最终目标

开发者引入 moon2dart 后，**双向转换 MoonBit ↔ Dart/Flutter 项目**。

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
  ✅           ✅          ✅         ✅         ✅

v0.5.0 ──► v0.6.0 ──► v0.7.0 ──► v0.8.0 ──► v0.9.0 ──► v1.0.0
async      FFI       Flutter     Dart→MB    MCP+Skill   完整
Option     混合      widget      反向骨架    大模型消费   发布
  ✅           ✅          ✅         ✅
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

## v0.4.0 ✅ — 项目级扫描 + 包结构映射（已完成）

**目标**：扫描整个 MoonBit 项目目录，映射为 Dart 项目结构。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | 项目扫描器（ProjectInfo/PackageInfo/DependencyGraph + parse_moon_mod/pkg + scan_project） | ✅ |
| S2 | MoonBit 包结构 → Dart 包结构（pubspec.yaml + lib/ + emit_dart_project_files） | ✅ |
| S3 | 多文件项目转换（transpile_project + 拓扑排序 + write_dart_project） | ✅ |
| S4 | CLI `moon2dart project <dir> -o <output>` 子命令 | ✅ |
| S5 | 测试 + 文档 + 门禁 | ✅ |

**交付**：142 测试 × 4 后端，`transpile_project` API，CLI `project` 子命令。

---

## v0.5.0 ✅ — async + Option + Result + 泛型（已完成）

**目标**：支持异步、null safety、错误类型、泛型。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | async/await → Future/await | ✅ |
| S2 | Option[T] → T? null safety | ✅ |
| S3 | Result[T,E] → 自定义 Result class（sealed class + Ok/Err） | ✅ |
| S4 | 泛型类型参数支持（fn<T>、struct<T>） | ✅ |
| S5 | 闭包 → 箭头函数 | ✅ |
| S6 | 测试 + 文档 | ✅ |

**交付**：206 测试（native），async/Option/Result/泛型/闭包转换。

---

## v0.6.0 ✅ — FFI 混合模式（已完成）

**目标**：支持 FFI 转换（dart:ffi 桥接）。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | extern "C" → dart:ffi DynamicLibrary | ✅ |
| S2 | 类型转换桥接代码生成（String ↔ Pointer<Utf8>） | ✅ |
| S3 | 原生库加载代码（emit_dart_program_with_lib） | ✅ |
| S4 | CLI `--pure-only` 只转换纯子集（跳过 FFI） | ✅ |
| S5 | 测试 + 文档 | ✅ |

**交付**：240 测试（native），extern "c" → dart:ffi + String 桥接 + --pure-only/--lib 选项。

---

## v0.7.0 ✅ — Flutter widget 转换（已完成）

**目标**：支持 MoonBit UI 抽象 → Flutter widget 树。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | MoonBit UI 抽象 → Flutter widget（Text/Container/Row/Column） | ✅ |
| S2 | 布局（Row/Column/Stack/Padding/Container/Expanded/Center/SizedBox） | ✅ |
| S3 | 状态管理（StatelessWidget/StatefulWidget + setState） | ✅ |
| S4 | 事件处理（onTap/onPressed/onChanged + TextField/Switch/Checkbox/Slider） | ✅ |
| S5 | main 入口 → runApp(My?App()) | ✅ |
| S6 | 测试 + 文档 | ✅ |

**交付**：316 测试（native），50+ Flutter widget 转换 + StatelessWidget/StatefulWidget + 事件处理 + Flutter 辅助类。

---

## v0.8.0 ✅ — Dart → MoonBit 反向转换骨架（已完成）

**目标**：建立反向转换管线，支持 Dart 源码 → MoonBit 源码。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | dart_ast 包：DartType/DartExpr/DartPattern/DartDecl/DartMethod/DartVariant（14 白盒测试） | ✅ |
| S2 | dart_parser 包：DartLexer（DartTokenKind 67 变体）+ DartParser（fn/class/sealed/abstract/expr） | ✅ |
| S3 | reverse_codegen 包：dart_type_to_moon/emit_moon_expr/emit_moon_decl/emit_moon_program | ✅ |
| S4 | 根包 reverse_transpile/reverse_transpile_source API | ✅ |
| S5 | CLI `--reverse` 选项（convert <file.dart> --reverse） | ✅ |
| S6 | 测试 + 文档 | ✅ |

**交付**：347 测试（native），Dart→MoonBit 反向转换管线，CLI `--reverse` 选项。

**新增 API**：
- `reverse_transpile(decls)` — Dart AST → MoonBit 源码
- `reverse_transpile_source(src)` — Dart 源码 → MoonBit 源码
- `reverse_transpile_type(t)` — Dart 类型 → MoonBit 类型字符串
- `reverse_transpile_expr(e)` — Dart 表达式 → MoonBit 表达式字符串
- `reverse_transpile_decl(d)` — Dart 声明 → MoonBit 声明字符串

**新增包**：
- `dart_ast/` — Dart AST 节点定义（零依赖）
- `dart_parser/` — Dart 词法+语法分析（依赖 dart_ast）
- `reverse_codegen/` — Dart AST → MoonBit 代码发射（依赖 dart_ast + ast + dart_parser）

---

## v0.8.0 ✅ — Dart → MoonBit 反向转换骨架（已完成）

**目标**：建立反向转换管线，支持 Dart 源码 → MoonBit 源码。

| Sprint | 内容 | 状态 |
|--------|------|------|
| S1 | dart_ast 包：DartType/DartExpr/DartPattern/DartDecl/DartMethod/DartVariant（14 白盒测试） | ✅ |
| S2 | dart_parser 包：DartLexer（DartTokenKind 67 变体）+ DartParser（fn/class/sealed/abstract/expr） | ✅ |
| S3 | reverse_codegen 包：dart_type_to_moon/emit_moon_expr/emit_moon_decl/emit_moon_program | ✅ |
| S4 | 根包 reverse_transpile/reverse_transpile_source API | ✅ |
| S5 | CLI `--reverse` 选项（convert <file.dart> --reverse） | ✅ |
| S6 | 测试 + 文档 | ✅ |

**交付**：364 测试（native），Dart→MoonBit 反向转换管线，CLI `--reverse` 选项。

**新增 API**：
- `reverse_transpile(decls)` — Dart AST → MoonBit 源码
- `reverse_transpile_source(src)` — Dart 源码 → MoonBit 源码
- `reverse_transpile_type(t)` — Dart 类型 → MoonBit 类型字符串
- `reverse_transpile_expr(e)` — Dart 表达式 → MoonBit 表达式字符串
- `reverse_transpile_decl(d)` — Dart 声明 → MoonBit 声明字符串

**新增包**：
- `dart_ast/` — Dart AST 节点定义（零依赖）
- `dart_parser/` — Dart 词法+语法分析（依赖 dart_ast）
- `reverse_codegen/` — Dart AST → MoonBit 代码发射（依赖 dart_ast + ast + dart_parser）

---

## v0.9.0 — MCP 服务器 + 项目同步 + Skill

**目标**：基于 colmugx/mcp 构建 MCP 服务器，让大模型 Agent 能调用 moon2dart；支持增量同步和文件监听；发布 Skill 描述符。

**关键依赖**：`colmugx/mcp@0.18.2`（类型安全 MCP SDK，服务端+客户端，STDIO+HTTP）

**Sprint 顺序调整说明**：原 S1（自动触发）风险最高（MoonBit build hook 机制不成熟），降级为可选；原 S5+S6（MCP 服务器）因 colmugx/mcp 可用而合并简化，提升为 S1。

| Sprint | 内容 | 风险 | 交付物 |
|--------|------|------|--------|
| S1 | MCP 服务器骨架 + 6 工具注册（`cmd/mcp/main.mbt`，基于 colmugx/mcp） | 🟢 低 | MCPServer + STDIO 传输 |
| S2 | CLI `serve` 子命令（启动 MCP 服务器） | 🟢 低 | `moon2dart serve` 命令 |
| S3 | 文件变更检测 + 增量更新（hash 对比，只转换变更文件） | 🟡 中 | FileWatcher + incremental transpile |
| S4 | CLI `sync` / `watch` 子命令 | 🟡 中 | `moon2dart sync` / `moon2dart watch` |
| S5 | 项目双向同步（MoonBit ↔ Dart 保持同步） | 🟡 中 | bidirectional sync |
| S6 | Skill 描述符（mooncakes.io/skills 发布格式） | 🟡 中 | SKILL.md + references |
| S7 | 自动触发机制（moon.pkg hook，可选） | 🔴 高 | build script hook |
| S8 | 测试 + 文档 + 版本号 + 门禁 | 🟢 低 | 全量测试 + docs 更新 |

### S1: MCP 服务器骨架 + 6 工具注册

**依赖**：`colmugx/mcp@0.18.2`（已安装）

**实现**：`cmd/mcp/main.mbt`

```
MCPServer("moon2dart", "0.9.0")
  .with_description("MoonBit ↔ Dart/Flutter transpiler")
  .with_instructions("...")
  .tool("moon2dart_convert", ..., convert_handler)
  .tool("moon2dart_project", ..., project_handler)
  .tool("moon2dart_reverse", ..., reverse_handler)
  .tool("moon2dart_analyze", ..., analyze_handler)
  .tool("moon2dart_flutter", ..., flutter_handler)
  .tool("moon2dart_list_tools", ..., list_tools_handler)
  .run_stdio()
```

**6 个 MCP 工具定义**：

| 工具 | 参数 (JSON Schema) | 功能 | 复用 API |
|------|-------------------|------|----------|
| `moon2dart_convert` | `{file: string, output?: string}` | 单文件 MoonBit→Dart 转换 | `transpile_source(src)` |
| `moon2dart_project` | `{dir: string, output: string}` | 项目级转换 | `transpile_project(dir)` |
| `moon2dart_reverse` | `{file: string, output?: string}` | Dart→MoonBit 反向转换 | `reverse_transpile_source(src)` |
| `moon2dart_analyze` | `{file: string}` | 分析 MoonBit 代码结构 | `parse_source(src)` + AST 输出 |
| `moon2dart_flutter` | `{file: string, output?: string}` | MoonBit→Flutter widget 转换 | `transpile_source_with_flutter(src)` |
| `moon2dart_list_tools` | `{}` | 列出所有可用工具 | 静态 JSON 响应 |

**测试**：8-10 白盒测试（工具注册、请求处理、错误响应）

### S2: CLI `serve` 子命令

**实现**：扩展 `cmd/main/main.mbt`

```
moon2dart serve              # 启动 MCP 服务器（STDIO）
moon2dart serve --http 8080   # 启动 MCP 服务器（HTTP）
```

**测试**：3-5 白盒测试（子命令解析、服务器启动）

### S3: 文件变更检测 + 增量更新

**实现**：`project/watcher.mbt`

- 文件 hash 对比（SHA-256 或简化 hash）
- `.moon2dart_cache/` 目录存储上次转换的 hash
- 只重新转换变更文件

**测试**：5-8 白盒测试

### S4: CLI `sync` / `watch` 子命令

**实现**：扩展 `cmd/main/main.mbt`

```
moon2dart sync <dir> -o <output>    # 一次性同步
moon2dart watch <dir> -o <output>   # 持续监听变更
```

**测试**：3-5 白盒测试

### S5: 项目双向同步

**实现**：`project/sync.mbt`

- MoonBit → Dart 正向同步
- Dart → MoonBit 反向同步（基于 v0.8.0 reverse_codegen）
- 冲突检测和提示

**测试**：5-8 白盒测试

### S6: Skill 描述符

**实现**：`skill/` 目录

- `SKILL.md` — 入口与硬规则
- `references/` — 参考文档
- 遵循 moonbit-stack-selection 的 Skill 格式

**测试**：格式验证

### S7: 自动触发机制（可选）

**风险**：🔴 高 — MoonBit build hook 机制不成熟

**降级方案**：如无法实现 build hook，改为提供 `moon2dart init` 命令生成 `.moon2dart.json` 配置文件，配合 CI/CD 使用

### S8: 测试 + 文档 + 版本号 + 门禁

- 版本号 v0.8.0 → v0.9.0
- `moon check --target all --deny-warn`
- `moon test --target all`
- roadmap / changelog / README / AGENTS.md 更新
- mooncakes.io 发布

**交付线**：库 API（incremental transpile）、CLI（`serve`/`sync`/`watch` 子命令）、Skill、MCP 服务器

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
| v0.8.0 ✅ | � 中 | Dart 语法复杂，parser 工作量大 |
| v0.9.0 | 🟡 中 | MCP 服务器依赖 colmugx/mcp（已验证可用）；自动触发降级为可选 |
| v1.0.0 | 🟡 中 | 整体质量保障 + 发布流程 |

## 技术参考

| 参考 | 用途 |
|------|------|
| `chrono_tz-mbt/cmd/mcp/main.mbt` | MCP 服务器架构（JSON-RPC + stdio + 工具分发，623 行） |
| `chrono_tz-mbt/cmd/cli/main.mbt` | CLI 子命令解析模式 |
| `moonbit_learning/advanced_basics` | MoonBit 语言特性（Json/defer/管道/is 表达式） |
| `docs/type_mapping.md` | 类型映射规范 |
| `docs/architecture.md` | 架构设计 |