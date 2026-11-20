# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies.

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`.

- `pub(all) enum` 供外部包构造；`pub enum` 仅允许 match。

- `derive(Eq, Compare, Debug)` 后需显式 `pub extend T with Trait::{method}`。

- snake_case 函数/变量，PascalCase 类型，UPPER_SNAKE 常量。

## Tooling

- `moon fmt` — 格式化
- `moon info` — 更新 .mbti 接口
- `moon test` — 运行测试
- `moon check --target all` — 四后端编译检查
- `moon run cmd/main` — 运行 CLI

## Project: moon2dart

MoonBit → Dart transpiler，让 MoonBit 代码跑在 Flutter 上。

### 包结构

```
moon2dart/            # 根包 — transpile 编排入口
├── moon2dart.mbt         # transpile / transpile_decl / transpile_expr / transpile_type
├── ast/                  # AST 类型定义（零依赖）
│   └── ast.mbt           # MoonType / MoonExpr / MoonPattern / MoonDecl
├── official_parser/      # 官方 parser 适配层（moonbitlang/parser → moon2dart AST）
│   └── official_parser.mbt # parse_source + conv_type/expr/pattern/decl（fail-closed）
├── typesys/              # 类型映射
│   └── mapping.mbt       # DartType + map_type + emit_dart + is_pure
├── codegen/              # Dart 代码发射
│   ├── emitter.mbt       # emit_dart_expr / emit_dart_pattern / emit_dart_decl / emit_dart_program
│   └── flutter_emitter.mbt # emit_flutter_expr / emit_flutter_program / emit_flutter_widget_struct
├── mcp_server/           # MCP 服务器核心逻辑（native only）
│   └── server.mbt        # serve_mcp / 6 工具 handler / run_tool_mode / run_agent_mode
├── project/              # 项目级扫描与转换（native only）
│   ├── project_info.mbt  # ProjectInfo / PackageInfo / DependencyGraph
│   ├── scanner.mbt       # scan_project / parse_moon_mod / parse_moon_pkg
│   ├── structure.mbt     # emit_pubspec_yaml / map_package_to_dart_path / emit_dart_imports
│   ├── transpile.mbt     # transpile_project / sync_project / write_dart_project
│   └── incremental.mbt   # IncrementalCache（hash 对比增量检测）
├── cmd/main/             # CLI 入口
│   └── main.mbt          # convert / project / sync / watch / serve / demo / help
└── cmd/mcp/              # MCP 服务器独立入口
    └── main.mbt          # 委托 mcp_server.serve_mcp
```

### 依赖关系

```
cmd/main ──> 根包 + mcp_server + ast + project
cmd/mcp  ──> mcp_server
mcp_server ──> 根包 + ast + parser + project + colmugx/mcp
根包 ──> official_parser（官方前端）+ parser（语法兜底）
official_parser ──> ast + moonbitlang/parser + parser/syntax
codegen ──> ast + typesys
typesys ──> ast
ast ──> (零依赖)
```

### 依赖关系

```
cmd/main ──> 根包 ──> ast + typesys + codegen
codegen ──> ast + typesys
typesys ──> ast
ast ──> (零依赖)
```

### 多后端支持

- `supported_targets = "+wasm+wasm-gc+js+native"`

### 凭据与 Token 安全（强制）

1. **禁止明文 token**：任何平台（GitHub / GitCode）的 access token 一律不得出现在
   命令行参数、remote URL（`https://user:token@` 形式）、脚本、文档、提交信息、
   聊天对话或任何持久化文件中。
2. **GitHub 操作统一用 gh CLI**：`gh`（GitHub CLI）凭据存于系统凭据管理器；
   查仓库 / 查 CI / 建 release 用 `gh repo view`、`gh run list` 等命令；
   git 推送走 SSH（origin = `git@github.com:...`）。
3. **GitCode 推送走 SSH**：SSH 公钥在 gitcode.com 个人设置中绑定后，
   `git push gitcode main`；remote URL 保持无凭据裸地址
   （当前：`git@gitcode.com:LOOYIABC/moon2dart.git`）。
4. **Agent 协作约定**：Agent 请求 token 仅限单次使用场景（如首次建仓推送），
   使用后不得写入任何持久化位置，且必须提醒用户在平台侧撤销该 token。
5. **token 泄露处置**：token 一旦出现在聊天、日志或文件中，立即在对应平台
   撤销并重新生成；平台绑定改用 SSH key（长期凭据），不再使用 token 日常推送。
6. **CI/CD 凭据**：GitHub Actions 如需跨平台 token，一律存 GitHub Secrets
   （仓库设置 → Secrets and variables），工作流中经 `${{ secrets.X }}` 引用，
   严禁写入 workflow YAML 明文。

### MoonBit 语法要点

- **derive 后必须显式 pub extend**：`derive(Eq, Compare, Debug)` 后需三条 `pub extend`
- **pub(all) enum**：外部包可构造（测试需 pub(all)）
- **import 别名**：`"walkzzz/moon2dart" @lib` 语法
- **字符串插值**：`"\{expr}"`

### Sprint 状态

> **版本双轨说明**（2026-11-13，2026-11-20 更新）：功能迭代版本（v0.1.0 → v0.12.0）为 Sprint 史；**mooncakes 包版本重置为 0.1.x 线**（季度评选「新项目」叙事，mooncakes 上 0.8.0 为旧包版本）——映射：包 0.1.0 = 功能 v0.1.0-v0.10.0 全量（已发布），包 0.1.1 = 功能 v0.11.0（已发布），包 0.1.2 = 功能 v0.12.0（**待发布**，由维护者执行）。

- **v0.1.0** ✅ 已完成 — transpiler 骨架（33 测试 × 4 后端）
  - S1 ast 包 ✅ / S2 typesys ✅ / S3 codegen ✅ / S4 根包入口 ✅
  - S5 CLI 演示 ✅ / S6 工程配置 ✅ / S7 门禁验证 ✅ / S8 文档发布 ✅
- **v0.2.0** ✅ 已完成 — 解析器（MoonBit 源码 → AST）
  - S1 lexer ✅（15 白盒测试，TokenKind 57 变体 + Lexer）
  - S2 parser ✅（27 白盒测试，fn/struct/enum/expr/type 解析，75 测试 × 4 后端）
  - S3 转换管线 ✅（transpile_source: src→lexer→parser→codegen→dart，8 管线测试，83 测试 × 4 后端）
  - S4 CLI convert ✅（convert/demo/help 子命令，@fs.read_file 文件读取，native target）
  - S5 测试+文档+门禁 ✅（版本 0.2.0，83 测试 × 4 后端，roadmap/changelog/README 更新）
- **v0.3.0** 🔄 进行中 — trait + 模式匹配 + derive 生成
  - S1 trait → abstract class ✅（DTrait + TraitMethod AST 节点，parser 解析 trait 声明，codegen 生成 abstract class，8 新测试，91 测试 × 4 后端）
  - S2 match → switch expression ✅（parser 解析 match + pattern，codegen 生成 Dart 3 switch expression，12 新测试，103 测试 × 4 后端）
  - S3 derive 生成 ✅（DStruct 添加 derive 列表参数，parser 解析 `derive(Debug, Eq, Compare)` 语法，codegen 生成 toString/operator==/compareTo，11 新测试，114 测试 × 4 后端）
  - S4 pub(open) trait 跨包实现 ✅（DImpl + ImplMethod AST 节点，parser 解析 `impl Trait for Type`，codegen 合并 DImpl 到 DStruct 生成 `implements`，11 新测试，125 测试 × 4 后端）
  - S5 测试+文档+门禁 ✅（版本 0.3.0，125 测试 × 4 后端，roadmap/changelog/README 更新）
- **v0.4.0** ✅ 已完成 — 项目级扫描 + 包结构映射
  - S1 项目扫描器 ✅（ProjectInfo/PackageInfo/DependencyGraph 数据模型 + parse_moon_mod/parse_moon_pkg + scan_project async + 拓扑排序，9 白盒测试）
  - S2 包结构映射 ✅（emit_pubspec_yaml + map_package_to_dart_path + emit_dart_project_files + emit_dart_imports，5 白盒测试）
  - S3 多文件项目转换 ✅（transpile_project async + find_package_by_name + write_dart_project，3 白盒测试）
  - S4 CLI project 子命令 ✅（`moon2dart project <dir> -o <output>`，scan+transpile+write 全管线）
  - S5 版本号+门禁+文档 ✅（版本 0.4.0，142 测试 × 4 后端）
- **v0.5.0** ✅ 已完成 — async + Option + Result + 泛型 + 闭包
  - S1 async/await → Future/await ✅（DAsyncFn + EAwait + MFuture/DFuture，`async fn` → `Future<T> name() async`，`await` → `await`，5 新测试）
  - S2 Option[T] → T? null safety ✅（Some(x) → x，None → null，Option match 中 null case 排序，TkUIdent parser 支持，8 新测试）
  - S3 Result[T,E] → sealed class Ok/Err ✅（自动检测 Result 类型使用，生成 sealed class Result<T,E> + Ok + Err，8 新测试）
  - S4 泛型类型参数支持 ✅（DFn/DAsyncFn/DStruct 添加 type_params，parser 支持 `[T]` 语法，MTypeVar 类型节点，10 新测试）
  - S5 闭包 → 箭头函数 ✅（ELambda AST 节点，parser 解析 `fn(params) { body }`，`(params) => expr`，8 新测试）
  - S6 版本号+门禁+文档 ✅（版本 0.5.0，206 测试 native）
- **v0.6.0** ✅ 已完成 — FFI 混合模式（extern "c" → dart:ffi）
  - S1 extern "c" → dart:ffi ✅（DExternFn AST 节点 + TkExtern 关键字 + parse_extern_fn_decl + ffi_native_type/ffi_dart_type + typedef/lookupFunction/wrapper 代码生成，20 新测试）
  - S2 String ↔ Pointer<Utf8> 桥接 ✅（String 参数自动 toUtf8(allocator: arena) + using arena 管理 + String 返回值 toDartString()，6 新测试）
  - S3 原生库加载配置 ✅（emit_dart_program_with_lib + transpile_source_with_lib，可指定 DynamicLibrary 库名，4 新测试）
  - S4 CLI --pure-only ✅（filter_pure 过滤 DExternFn + transpile_source_pure + CLI --pure-only/--lib 选项，4 新测试）
  - S5 版本号+门禁+文档 ✅（版本 0.6.0，240 测试 native）
- **v0.7.0** ✅ 已完成 — Flutter widget 转换（316 测试 native）
  - S1 Widget 表达式识别 ✅（`codegen/flutter_emitter.mbt` — 50+ Flutter widget 构造器名称识别 + 位置参数→命名参数映射，Text/Container/Row/Column，30 白盒测试）
  - S2 布局 widget ✅（Stack/Padding/Expanded/Center/SizedBox/Positioned/AspectRatio/ConstrainedBox/LimitedBox/Opacity/Transform/DecoratedBox/ClipRRect/Card/ListTile/Icon/AppBar/Scaffold/MaterialApp 等，20 白盒测试）
  - S3 状态管理 ✅（`fn xxx() { Widget(...) }` → `class Xxx extends StatelessWidget`；`struct + impl Widget` → StatelessWidget；`struct + impl StatefulWidget` → StatefulWidget + State 类；Widget impl + 其他 trait → `extends StatelessWidget implements OtherTrait`，10 白盒测试）
  - S4 事件处理 ✅（ElevatedButton/GestureDetector/FloatingActionButton/InkWell → onTap/onPressed lambda；TextField/TextFormField → onChanged + InputDecoration；Switch/Checkbox/Radio/Slider/DropdownButton → value + onChanged，10 白盒测试）
  - S5 main 入口 ✅（`fn main() { MaterialApp(...) }` → `void main() { runApp(...); }` + `import 'package:flutter/material.dart'`）
  - S6 版本号+门禁+文档 ✅（版本 0.7.0，316 测试 native，零警告，roadmap/changelog/README 更新）
- **v0.8.0** ✅ 已完成 — Dart → MoonBit 反向转换骨架（364 测试 native）
  - S1 dart_ast 包 ✅（DartType/DartExpr/DartPattern/DartDecl/DartMethod/DartVariant，14 白盒测试）
  - S2 dart_parser 包 ✅（DartLexer DartTokenKind 67 变体 + DartParser fn/class/sealed/abstract/expr）
  - S3 reverse_codegen 包 ✅（dart_type_to_moon/emit_moon_expr/emit_moon_decl/emit_moon_program）
  - S4 根包 reverse_transpile/reverse_transpile_source API ✅
  - S5 CLI --reverse 选项 ✅（convert <file.dart> --reverse）
  - S6 测试+文档 ✅（364 测试 native，mooncakes.io v0.8.0 已发布）
- **v0.9.0** ✅ 已完成 — MCP 服务器 + Agent 模式 + CLI serve/sync/watch 子命令
  - S1 MCP 服务器骨架 ✅（mcp_server 包 + 6 工具注册 + MCPServer + STDIO/HTTP 传输）
  - S2 CLI serve 子命令 ✅（`moon2dart serve [--http <port>] [--agent "<request>"]`）
  - S3 文件变更检测 + 增量更新 ✅（IncrementalCache + sync_project，9 白盒测试）
  - S4 CLI sync/watch 子命令 ✅（`moon2dart sync` 增量同步 + `moon2dart watch` 文件系统 Watcher）
  - S5 项目双向同步 ✅（v0.9.1 — `project/sync.mbt` + reverse_sync_project + sync_project_bidirectional + 冲突检测 + CLI --reverse/--bidirectional，10 白盒测试）
  - S6 Skill 描述符 ✅（SKILL.md + references/）
  - S7 测试+文档+门禁 ✅（版本号 0.9.0，373 测试 native，roadmap/changelog 更新）
  - Agent posoco Agent 模式集成 ✅（`mcp_server/agent.mbt` — RuleBasedModel + InMemorySessionPort + Moon2DartExtension + 6 工具注册 + `run_agent_mode_with_input` + `--agent <text>` CLI 参数）
- **v0.9.1** ✅ 已完成 — 项目双向同步 + 冲突检测（383 测试 native）
- **v0.10.0** ✅ 已完成 — 往返语义等价性验证体系（500 测试 native）
  - S1 嵌套 Option 辅助类 ✅（is_nested_option + emit_option_class + emit_dart_expr_nested）
  - S2 DResult 结构化节点 ✅（DResult(DartType, DartType) 替代 DCustom 退化）
  - S3 语义等价四级分类 ✅（SemanticLevel 枚举 + semantic_level + map_type_strict）
  - S4 诊断标注 ✅（emit_semantic_diagnostic + [L3-CONSTRAINED]/[L4-INEQUIVALENT]）
  - S5 strict 模式 ✅（--strict CLI + transpile_source_strict + L4 拒绝）
  - S6 断言+变异+记分卡 ✅（assert_round_trip + assert_value_domain + 验收三口径）
  - S7 文档更新 ✅（semantic_equivalence + type_mapping + assessment + pitfall + architecture + roadmap）
- **v0.11.0** ✅ 已完成 — 运行时语义保持体系（541 测试 native）
  - S1 语义双模式 ✅（SemanticsMode：Wrapping 默认 / Fast + CLI --semantics + transpile_source_with_mode/transpile_source_with_options）
  - S2 mini 推断器 ✅（typesys/infer.mbt：TypeEnv + infer_expr_type + collect_int_arith_ops，推断失败保守裸发）
  - S3 parser 缺口修复 ✅（类型表补 Int64/UInt/UInt64/Float + Double/负数字面量 + EBlock 多语句块 + fn main {} 无括号语法 + parse_expr_prec 终止条件）
  - S4 golden 双端验证 ✅（golden 包 + scripts/golden_check.mjs，14/14 行一致，INT_MIN/-1 trap 行为类别一致）
  - S5 文档+回复组委会 ✅（6 份文档 + docs/golden_results.md + reply_to_committee.md）
- **v0.12.0** ✅ 已完成 — 第二轮初审整改：集合语义 + 安全边界 + 业务函数证据（**590 测试 native**）
  - S1 集合定级修正 ✅（Array/Map/Set → **L2-C**；`mbEquals` 集合相等 shim；L1 15 / L2 5 / 总计 29）
  - S2 安全边界 ✅（`UnresolvedPolicy` Error 默认 / Warn / Fast；`transpile_source_report`；CLI `--on-unresolved` / `--report`；失败非零退出）
  - S3 业务函数子集 ✅（数组字面量/索引/方法调用/while/let/赋值/括号分组；`golden_business` 13/13）
  - S4 门禁与证据 ✅（`scripts/safety_gate.mjs` 8/8；CI golden 27/27 + `dart analyze --fatal-infos` + 工件上传）
  - S5 文档 ✅（array_semantics / safety_boundary / ecosystem_practices / review_anticipation / golden_results_business / reply 重写）
  - S6 生态经验学习 ✅（mbt_rs / mizchi-ts / typify / 官方 parser / quickcheck → `docs/moonbit_ecosystem_lessons.md`；属性测试 6 类；真实语料接受率；属性测试发现并修复 `Int64` 往返丢失 + `Int32/UInt32` 别名）
  - S7 官方 parser 迁移 ✅（新增 `official_parser` 包：`moonbitlang/parser` → moon2dart AST 适配层，fail-closed；根包默认官方 parser + 语法层兼容兜底；`--official-only` 用于技术债度量；11 项适配测试）
- **v1.0.0** 📋 计划 — 验证 + 完整发布（mooncakes.io）

### 四条交付线

| 交付线 | 发布渠道 | 消费者 | 覆盖版本 |
|--------|----------|--------|----------|
| 库 API | `moon add walkzzz/moon2dart` | MoonBit 开发者 | v0.1.0-v0.9.0 |
| CLI 工具 | `mooncakes.io/cli` | 命令行用户 | v0.2.0-v0.9.0 |
| Skill | `mooncakes.io/skills` | 大模型 Agent | v0.9.0 |
| MCP 服务器 | 随 CLI 分发 | AI 工具链 | v0.9.0 |

### 技术参考

- MCP 服务器架构：参考 `chrono_tz-mbt/cmd/mcp/main.mbt`（JSON-RPC + stdio，623 行）
- MoonBit 语言特性：参考 `moonbit_learning/advanced_basics`（Json/defer/管道/is 表达式）
- 完整路线图：`docs/roadmap.md`

### 测试

590 个测试，native 后端全通过（v0.12.0 口径；wasm/wasm-gc/js 各 540）：

| 包 | 白盒 | 黑盒 |
|----|------|------|
| ast | 11 | 0 |
| official_parser | 11 | 0 |
| typesys | 74+ | 0 |
| codegen | 167+ | 0 |
| parser | 38 | 0 |
| project | 17 | 0 |
| dart_ast | 14 | 0 |
| dart_parser | 0 | 0 |
| reverse_codegen | 7+ | 0 |
| mcp_server | 10+ | 0 |
| golden | 27 | 0 |
| moon2dart (根) | 45+ | 5 |

### 文档

开发文档在 `docs/`（19 份）：architecture / roadmap / v0.1.0_plan / type_mapping / coding_conventions / testing_strategy / semantic_equivalence / assessment / pitfall-catalog / changelog / golden_results / golden_results_business / array_semantics / safety_boundary / ecosystem_practices / moonbit_ecosystem_lessons / review_anticipation / acceptance_report / README。

### 语义安全纪律（v0.12.0 强制）

- **默认 fail-closed**：类型推断失败即拒绝生成（`UnresolvedPolicy::Error`），禁止恢复"静默裸发"默认行为；
- **集合不得标 L1**：Array/Map/Set 只能 L2-C，相等比较必须走 Wrapping 的 `mbEquals`；
- **未支持语法必须报错**：禁止在解析器/发射器里"跳过未知构造"或生成近似代码；
- **证据先行**：语义相关改动必须同时更新 `scripts/golden_check.mjs` / `safety_gate.mjs` 与对应 docs 数字。
