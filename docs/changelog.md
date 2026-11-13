# Changelog

## v0.9.1 (2026-11-12) — 项目双向同步 + 冲突检测

### 新增
- **project/sync.mbt**：项目双向同步核心逻辑
  - `SyncDirection` 枚举：Forward / Reverse / Bidirectional
  - `SyncConflict` 结构：同步冲突信息（moonbit_path + dart_path + message）
  - `SyncResult` 结构：同步操作结果（direction + transpiled_files + conflicts）
  - `SyncResult::has_conflicts()` / `SyncResult::summary()` 方法
  - `reverse_sync_project(dart_dir, moonbit_output_dir, cache)` — Dart → MoonBit 反向同步
  - `sync_project_bidirectional(project, dart_dir, cache)` — 双向同步 + 冲突检测
  - `find_last_slash()` 辅助函数
- **CLI `sync --reverse`**：反向同步模式（Dart → MoonBit）
- **CLI `sync --bidirectional`**：双向同步模式（MoonBit ↔ Dart + 冲突检测）
- 10 白盒测试（SyncDirection / SyncConflict / SyncResult / summary / find_last_slash）
- project 包添加 reverse_codegen 依赖

### 改进
- 版本号 v0.9.0 → v0.9.1
- CLI sync 子命令帮助文本更新（添加 --reverse / --bidirectional 说明）
- 测试 373 → 383（native）

### 已知限制
- 反向同步使用 reverse_transpile_source，生成的 MoonBit 代码可能不完全等价于原始代码
- 冲突检测基于文件 hash 比较，无法检测语义级冲突

## v0.9.0 (2026-11-12) — MCP 服务器 + Agent 模式 + CLI serve/sync/watch 子命令

### 新增
- **mcp_server 包**：MCP 服务器核心逻辑（native target only）
  - 6 个 MCP 工具注册：moon2dart_convert / moon2dart_reverse / moon2dart_flutter / moon2dart_analyze / moon2dart_project / moon2dart_list_tools
  - 双模式架构：工具模式（MCPServer + STDIO/HTTP 传输）+ Agent 模式（posoco Agent 循环）
  - `serve_mcp(args)` 公共入口函数
  - JSON Schema 辅助函数（parse_json 构造只读 Json 值）
  - parse_port 端口解析、type_to_str 类型格式化
- **mcp_server/agent.mbt**：posoco Agent 模式集成
  - `RuleBasedModel` — 基于关键词的 ModelPort 实现（自动选择工具，不依赖 LLM API）
  - `InMemorySessionPort` — 内存会话存储（SessionPort 实现）
  - `Moon2DartExtension` — 组合 Model + Tools + Sessions 的 Extension
  - `register_moon2dart_tools` — 6 个工具注册到 ToolRegistry
  - `run_agent_mode_with_input(user_input)` — Agent 模式入口
  - 辅助函数：escape_json_string / make_json_args / json_get_string / select_tool / find_keyword_pos / make_tool_call / make_model_call_result / format_tool_outcome
- **cmd/mcp**：MCP 服务器独立入口（`moon run cmd/mcp --target native`）
  - 支持 `--http <port>` HTTP 模式
  - 支持 `--agent <text>` Agent 模式（posoco 驱动）
- **CLI `serve` 子命令**：`moon2dart serve [--http <port>] [--agent "<request>"]`
  - 集成 MCP 服务器到主 CLI，无需单独运行 cmd/mcp
  - `--agent` 参数接受用户自然语言请求，Agent 自动选择工具执行
- **IncrementalCache**：文件内容 hash 缓存，用于增量转换
  - `should_transpile` / `update` / `get_changed_files` / `mark_all_transpiled` / `cache_size` / `is_cached`
  - 9 白盒测试
- **sync_project API**：增量同步项目，只转换有变更的包
  - 基于 IncrementalCache 检测文件变更，避免重复转换
  - 首次运行时缓存为空，所有包都会被转换
- **CLI `sync` 子命令**：`moon2dart sync <dir> -o <output>`
  - 一次性增量同步，只转换变更的包
  - 无变更时输出 "No changes detected"
- **CLI `watch` 子命令**：`moon2dart watch <dir> -o <output> [--max-iterations <n>]`
  - 持续监听文件变更，自动增量同步
  - 使用 `@fs.Watcher` 文件系统监听器（非轮询，实时 FsEvent）
  - 支持 `--max-iterations` 参数限制迭代次数（默认 1000）
  - 首次运行执行完整 sync，后续仅转换变更包
- **Skill 描述符**：`skill/SKILL.md` + `skill/references/` 参考文档
  - 6 工具详细描述 + 参数定义 + 使用示例
  - 类型映射参考 + 7 个转换示例
- 依赖：colmugx/mcp@0.18.2（MCP SDK）+ colmugx/posoco@0.24.2（Agent 框架）

### 改进
- 版本号 v0.8.0 → v0.9.0
- CLI usage 更新：添加 serve/sync/watch 子命令说明 + --agent 参数示例
- MoonBit 工具链升级 0.1.20261020 → 0.1.20261111（支持 moonbitlang/core/async）
- moon.pkg 添加 allow-experimental-packages 选项
- 测试 364 → 373（native）

### 已知限制
- S5（项目双向同步）待后续迭代
- RuleBasedModel 为关键词匹配，后续可替换为真正的 LLM provider

## v0.8.0 (2026-11-11) — Dart → MoonBit 反向转换骨架

### 新增
- **dart_ast 包**：Dart AST 节点定义（零依赖）
  - DartType（14 变体）：DVoid/DInt/DDouble/DString/DBool/DList/DMap/DSet/DNullable/DFunction/DClass/DEnum/DSealedClass/DDynamic
  - DartExpr：DIntLit/DStringLit/DBoolLit/DVar/DCall/DBinOp/DIf/DLambda/DMatch/DCtor/DMethodCall/DListLit/DMapLit
  - DartPattern：DPVar/DPInt/DPString/DPWild/DPCtor
  - DartDecl：DFn/DClass/DEnum/DSealedClass/DAbstractClass/DField/DMethod/DVariant
- **dart_parser 包**：Dart 词法+语法分析
  - DartLexer（DartTokenKind 67 变体）
  - DartParser：fn/class/sealed/abstract/expr/type 解析
- **reverse_codegen 包**：Dart AST → MoonBit 代码发射
  - dart_type_to_moon：Dart 类型 → MoonBit 类型
  - emit_moon_expr/emit_moon_decl/emit_moon_program
- **根包反向转换 API**：
  - `reverse_transpile(decls)` — Dart AST → MoonBit 源码
  - `reverse_transpile_source(src)` — Dart 源码 → MoonBit 源码
  - `reverse_transpile_type(t)` — Dart 类型 → MoonBit 类型字符串
  - `reverse_transpile_expr(e)` — Dart 表达式 → MoonBit 表达式字符串
  - `reverse_transpile_decl(d)` — Dart 声明 → MoonBit 声明字符串
- **CLI `--reverse` 选项**：`moon2dart convert <file.dart> --reverse`
- 48 新测试（316 → 364 native）

### 改进
- 版本号 v0.7.0 → v0.8.0
- 双向转换能力：MoonBit → Dart + Dart → MoonBit
- mooncakes.io v0.8.0 已发布

## v0.7.0 (2026-11-07) — Flutter widget 转换

### 新增
- **Flutter widget 表达式识别**：`codegen/flutter_emitter.mbt` — 50+ Flutter widget 构造器名称识别
  - `Text("hello")` → `Text('hello')`
  - `Row(Text("A"), Text("B"))` → `Row(children: [Text('A'), Text('B')])`
  - `Column(...)` / `Stack(...)` → `children: [...]`
  - `Container(child)` → `Container(child: ...)`
  - `Padding(padding, child)` → `Padding(padding: ..., child: ...)`
  - `Expanded/Center/Flexible/Align` → `child: ...`
  - `SizedBox(width, height, child)` → `SizedBox(width: ..., height: ..., child: ...)`
- **布局 widget**：Stack/Padding/Expanded/Center/SizedBox/Positioned/AspectRatio/ConstrainedBox/
  LimitedBox/Opacity/Transform/DecoratedBox/ClipRRect/ClipOval/FittedBox/IntrinsicHeight/IntrinsicWidth/
  Offstage/Spacer/Divider/Card/ListTile/Icon/AppBar/Scaffold/MaterialApp
- **状态管理**：
  - `fn xxx() { Widget(...) }` → `class Xxx extends StatelessWidget { Widget build(BuildContext context) { return ...; } }`
  - `struct Counter { count : Int } impl Widget for Counter { fn build(...) { ... } }` → `class Counter extends StatelessWidget { final int count; const Counter({required this.count}); @override Widget build(BuildContext context) { return ...; } }`
  - `impl StatefulWidget for Type` → `class Type extends StatefulWidget { ... State<Type> createState() => _TypeState(); } class _TypeState extends State<Type> { ... }`
  - Widget impl + 其他 trait impl → `extends StatelessWidget implements OtherTrait`
- **事件处理**：
  - `ElevatedButton(onPressed_lambda, child)` → `ElevatedButton(onPressed: () { ... }, child: ...)`
  - `GestureDetector(onTap_lambda, child)` → `GestureDetector(onTap: () { ... }, child: ...)`
  - `FloatingActionButton(onPressed_lambda, child)` → `FloatingActionButton(onPressed: () { ... }, child: ...)`
  - `TextField(onChanged_lambda, decoration?)` → `TextField(onChanged: (value) { ... }, decoration: ...)`
  - `Switch/Checkbox/Radio/Slider/DropdownButton/InkWell/PopupMenuButton` — value + onChanged/onTap 参数映射
- **main 入口**：`fn main() { MaterialApp(...) }` → `void main() { runApp(MaterialApp(...)); }`
- **Flutter 辅助类**：EdgeInsets.all/symmetric/only、BorderRadius.circular、TextStyle、BoxDecoration、Matrix4.identity
- **完整 Flutter 程序生成**：`emit_flutter_program` — 生成含 `import 'package:flutter/material.dart'`、`void main() { runApp(...); }`、StatelessWidget 类的完整 Flutter 应用
- 根包新增 API：`transpile_flutter(decls)` / `transpile_source_flutter(src)`
- 76 新测试（240 → 316 native）

### 改进
- 版本号 v0.6.0 → v0.7.0
- emit_dart_program 版本号更新
- 测试 240 → 316（native）

## v0.6.0 (2026-11-07) — FFI 混合模式（extern "c" → dart:ffi）

### 新增
- **extern "c" → dart:ffi**：DExternFn AST 节点 + TkExtern 关键字 + parse_extern_fn_decl
  - `extern "c" fn c_add(a : Int, b : Int) -> Int = "c_add"` → typedef + lookupFunction + wrapper
  - 生成 `typedef _CAddNative = Int32 Function(Int32 a, Int32 b);` + `typedef _CAddDart = int Function(int a, int b);`
  - 生成 `final _c_add = _dylib.lookupFunction<_CAddNative, _CAddDart>('c_add');`
  - 生成 `int c_add(int a, int b) { return _c_add(a, b); }`
- **String ↔ Pointer<Utf8> 桥接**：String 参数自动转 Pointer<Utf8>，String 返回值自动 toDartString()
  - String 参数：`using((arena) { ... param.toUtf8(allocator: arena) ... })`
  - String 返回值：`return _func().toDartString();`
  - 自动检测是否需要 `import 'dart:ffi'` 和 `import 'package:ffi/ffi.dart'`
- **原生库加载配置**：emit_dart_program_with_lib + transpile_source_with_lib
  - 可指定 DynamicLibrary.open() 的库名（默认 `libnative.so`）
- **CLI --pure-only / --lib 选项**：
  - `--pure-only`：跳过 FFI 声明，只转换纯 MoonBit 子集
  - `--lib <name>`：指定原生库名
- ffi_native_type / ffi_dart_type 类型映射函数（MoonBit → Dart FFI Native/Dart 类型）
- filter_pure 函数：过滤 DExternFn 声明
- to_pascal 辅助函数：snake_case → PascalCase（用于 typedef 命名）
- 34 新测试（206 → 240 native）

### 改进
- 版本号 v0.5.0 → v0.6.0
- emit_dart_program 版本号更新
- 测试 206 → 240（native）

## v0.5.0 (2026-11-07) — async + Option + Result + 泛型 + 闭包

### 新增
- **async/await → Future/await**：DAsyncFn 声明 + EAwait 表达式 + MFuture 类型 + DFuture DartType
  - `async fn name() -> T { body }` → `Future<T> name() async { return body; }`
  - `await expr` → `await expr`
- **Option[T] → T? null safety**：Some(x) → x，None → null，match 中 None → null case 排序
  - `Some(x)` → `x`（直接解包）
  - `None` → `null`
  - `match opt { None => 0, Some(x) => x }` → `switch (opt) { null => 0, var x => x }`
- **Result[T,E] → sealed class Ok/Err**：自动检测 Result 类型使用，生成 sealed class 定义
  - `Result[T, E]` → `Result<T, E>`（自动生成 `sealed class Result<T,E>` + `Ok` + `Err`）
  - `Ok(value)` / `Err(error)` 保持构造器调用
- **泛型类型参数**：DFn/DAsyncFn/DStruct 添加 type_params 字段，parser 支持 `[T]` 语法
  - `fn identity[T](x : T) -> T { x }` → `T identity<T>(T x) { return x; }`
  - `struct Container[T] { value : T }` → `class Container<T> { T value; ... }`
- **闭包 → 箭头函数**：ELambda AST 节点 + parser 解析 `fn(params) { body }`
  - `fn(x) { x + 1 }` → `(x) => x + 1`
- MTypeVar(String) 类型节点（类型参数引用）
- TkUIdent 在 parse_primary 中处理（大写标识符如 Some/None/Ok/Err）
- 64 新测试（155 → 206 native）

### 改进
- 版本号 v0.4.0 → v0.5.0
- emit_dart_program 版本号更新
- 测试 142 → 206（native）

## v0.4.0 (2026-11-07) — 项目级扫描 + 包结构映射

### 新增
- `project/` 包：项目级扫描与转换（native target only）
  - `project_info.mbt`：ProjectInfo / PackageInfo / DependencyGraph 数据模型 + 拓扑排序
  - `scanner.mbt`：parse_moon_mod / parse_moon_pkg / infer_package_name / scan_project（async）
  - `structure.mbt`：emit_pubspec_yaml / map_package_to_dart_path / emit_dart_project_files / emit_dart_imports
  - `transpile.mbt`：transpile_project（async）/ find_package_by_name / write_dart_project（async）
- CLI `project <dir> -o <output>` 子命令：扫描 MoonBit 项目 → 转换 → 写入 Dart 项目
- 17 新白盒测试（project 包）

### 改进
- 版本号 v0.3.0 → v0.4.0
- 测试 125 → 142（× 4 后端）

## v0.3.0 (2026-11-07) — trait + 模式匹配 + derive 生成

### 新增
- `ast/ast.mbt`：DTrait 声明节点 + TraitMethod struct（trait → abstract class）
- `ast/ast.mbt`：DImpl 声明节点 + ImplMethod struct（impl Trait for Type → implements）
- `parser/parser.mbt`：parse_trait_decl / parse_match_arms / parse_pattern / parse_impl_decl
- `codegen/emitter.mbt`：emit_derive_methods（Debug→toString, Eq→operator==, Compare→compareTo）
- `codegen/emitter.mbt`：emit_dart_program 合并 DImpl 到 DStruct（`class Type implements Trait`）
- DStruct 添加第三个参数 `Array[String]`（derive 列表），parser 支持 `struct Name derive(...) { }` 语法
- match 表达式 → Dart 3 switch expression（含 PVar/PInt/PString/PWild/PCtor 模式）
- parse_type 自定义类型 fallback 改为 MCustom(name)（之前错误返回 MInt）

### 改进
- 测试 83 → 125（× 4 后端）
- parse_pattern 中 `_` 标识符特殊处理为 PWild
- PCtor 空参数生成 `Name()`（Dart 3 语法）

## v0.2.0 (2026-11-07) — 解析器 + 单文件转换管线

### 新增
- `parser/lexer.mbt`：MoonBit 词法分析器（TokenKind 57 变体 + Lexer，15 白盒测试）
- `parser/parser.mbt`：MoonBit 语法分析器（fn/struct/enum/expr/type 解析，27 白盒测试）
- `transpile_source`：单文件转换管线（src → lexer → parser → codegen → dart，8 管线测试）
- CLI `convert <file>` 子命令：读取 .mbt 文件并转换为 Dart 代码
- CLI `demo` / `help` 子命令

### 改进
- 版本号 v0.1.0 → v0.2.0
- 测试 33 → 83（× 4 后端）
- 添加 `moonbitlang/async` 依赖（CLI 文件读取）

## v0.1.0 (2026-11-06) — transpiler 骨架

### 新增
- `typesys/`：MoonBit → Dart 类型映射（16 种 MoonType → 12 种 DartType）
- `ast/`：简化 AST（MoonType/MoonExpr/MoonDecl/MoonPattern）
- `codegen/`：Dart 代码发射器（类型/表达式/声明/程序）
- `moon2dart.mbt`：transpile 编排入口
- CLI：`moon2dart <input> -o <output>`（演示模式）

### 支持
- 基础类型：Int/UInt/Int64/UInt64/Double/Float/Bool/String/Char/Unit
- 复合类型：Array/Map/Set/Option/Result
- 声明：fn（无 trait 方法）/ struct / enum
- 表达式：字面量/变量/调用/二元运算/if/match

### 不支持（后续版本）
- trait → mixin（v0.2.0）
- 模式匹配 → switch expression（v0.2.0）
- async/await（v0.3.0）
- FFI → dart:ffi（v0.4.0）
- Flutter widget（v0.5.0）