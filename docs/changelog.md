# Changelog

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