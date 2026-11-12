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

## v0.9.0 — 自动触发 + 项目同步 + MCP/Skill

**目标**：引入库后自动触发项目转换，支持增量同步；MCP 服务器和 Skill 让大模型 Agent 能调用 moon2dart。

| Sprint | 内容 |
|--------|------|
| S1 | 引入库自动触发机制（moon.pkg hook / build script） |
| S2 | 文件变更检测（增量更新，只转换变更文件） |
| S3 | 项目同步（MoonBit ↔ Dart 保持双向同步） |
| S4 | CLI `moon2dart sync` / `moon2dart watch` 子命令 |
| S5 | MCP 服务器骨架（JSON-RPC + stdio） |
| S6 | MCP 工具定义（convert/project/sync/analyze/reverse） |
| S7 | Skill 描述符（mooncakes.io/skills 发布格式） |
| S8 | 测试 + 文档 |

**交付线**：库 API（auto_transpile）、CLI（`sync`/`watch`/`serve` 子命令）、Skill、MCP 服务器

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
| v0.9.0 | �🔴 高 | 自动触发依赖 MoonBit build hook（机制不成熟）+ MCP/Skill 规范待确认 |
| v1.0.0 | 🟡 中 | 整体质量保障 + 发布流程 |

## 技术参考

| 参考 | 用途 |
|------|------|
| `chrono_tz-mbt/cmd/mcp/main.mbt` | MCP 服务器架构（JSON-RPC + stdio + 工具分发，623 行） |
| `chrono_tz-mbt/cmd/cli/main.mbt` | CLI 子命令解析模式 |
| `moonbit_learning/advanced_basics` | MoonBit 语言特性（Json/defer/管道/is 表达式） |
| `docs/type_mapping.md` | 类型映射规范 |
| `docs/architecture.md` | 架构设计 |