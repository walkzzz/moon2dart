# Changelog

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