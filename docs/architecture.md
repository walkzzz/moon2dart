# moon2dart 架构设计 | Architecture Design

> v0.10.0 · 2026-11-16 · 双向转换 + 语义等价分级架构

## 1. 顶层架构 | Top-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                  moon2dart CLI                   │
│              (cmd/main/main.mbt)                 │
└──────────────────────┬──────────────────────────┘
                       │
              ┌────────▼────────┐
              │   transpile     │  编排入口
              │  (moon2dart.mbt)│
              └────────┬────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   ┌────▼────┐   ┌─────▼─────┐  ┌────▼────┐
   │ parser  │   │  typesys  │  │ codegen │
   │ MoonBit │   │ 类型映射  │  │  Dart   │
   │  → AST  │   │ Moon→Dart │  │  发射   │
   └────┬────┘   └─────┬─────┘  └────┬────┘
        │              │              │
        └──────────────┴──────────────┘
                       │
              ┌────────▼────────┐
              │    verifier     │  验证生成 Dart
              │  dart analyze   │
              └─────────────────┘
```

## 2. 模块划分 | Module Table

| 模块 | 职责 | 迭代 | 语义等价 |
|------|------|------|----------|
| `ast/` | MoonBit AST 类型定义（含 is_nested_option / SemanticLevel） | v0.1.0 | L1-L4 基础 |
| `parser/` | MoonBit 源码 → AST（lexer + parser） | v0.2.0 | — |
| `typesys/` | MoonBit 类型 → Dart 类型映射（含 semantic_level / map_type_strict / DResult） | v0.1.0 | L1-L4 分类 |
| `codegen/` | AST → Dart 代码字符串发射（含 emit_semantic_diagnostic / emit_option_class） | v0.1.0 | 诊断标注 |
| `codegen/` (flutter_emitter) | Flutter widget 转换（StatelessWidget/StatefulWidget） | v0.7.0 | — |
| `dart_ast/` | Dart AST 节点定义（含 DResult 变体） | v0.8.0 | 反向基础 |
| `dart_parser/` | Dart 词法+语法分析 | v0.8.0 | — |
| `reverse_codegen/` | Dart AST → MoonBit 代码发射（DResult → MResult 精确恢复） | v0.8.0 | 往返核心 |
| `project/` | 项目级扫描、转换、增量同步、双向同步 | v0.4.0 | 冲突检测 |
| `mcp_server/` | MCP 服务器 + Agent 模式（6 工具 + posoco 集成） | v0.9.0 | — |
| `cmd/main/` | CLI 入口（convert/project/sync/watch/serve） | v0.1.0 | — |
| `cmd/mcp/` | MCP 服务器独立入口 | v0.9.0 | — |

## 3. 数据流 | Data Flow

### 3.1 正向转换（MoonBit → Dart）

```
MoonBit 源码 (.mbt)
    │
    ▼  parser
MoonBit AST
    │
    ▼  typesys (类型映射 + 语义等价分级)
带 Dart 类型的 AST（SemanticLevel 标注）
    │
    ▼  codegen (emit + 诊断标注 + 辅助类生成)
Dart 源码字符串
    │
    ▼  verifier (可选, v0.3.0+)
dart analyze 通过?
    │
    ▼
.dart 文件
```

### 3.2 反向转换（Dart → MoonBit，v0.8.0+）

```
Dart 源码 (.dart)
    │
    ▼  dart_parser
Dart AST (dart_ast)
    │
    ▼  reverse_codegen (含 DResult → MResult 精确恢复)
MoonBit 源码字符串
    │
    ▼
.mbt 文件
```

### 3.3 双向同步（v0.9.1+）

```
MoonBit 项目 ──────► Dart 项目
     ▲                    │
     │                    │
     └──── 冲突检测 ◄─────┘
          (sync_project_bidirectional)
```

## 4. 转换策略 | Transpilation Strategy

### 4.1 纯转换（85%）| Pure Transpilation
MoonBit 构造直接映射为 Dart 构造，无运行时桥接：
- 基础类型：`Int`→`int`、`Double`→`double`、`Bool`→`bool`、`String`→`String`
- 复合类型：`Array[T]`→`List<T>`、`Map[K,V]`→`Map<K,V>`、`Option[T]`→`T?`
- 逻辑构造：`fn`→函数、`struct`→`class`、`enum`→`sealed class`、模式匹配→`switch expression`

### 4.2 混合模式（15%）| Hybrid Mode
不可纯转换，需生成桥接代码：
- **FFI**（`extern "C"`）：生成 `dart:ffi` 绑定 + 原生库加载代码
- **`pub(open) trait` 跨包实现**：转换为 `mixin`，限制多继承
- **动态分派（特征对象）**：转换为 `abstract class` 多态

### 4.3 不支持（明确排除）| Unsupported
- MoonBit 的 C FFI 内联汇编
- MoonBit 的 wasm 特定 intrinsics
- MoonBit 的编译期常量计算（保留为字面量）

## 5. AST 设计 | AST Design

### 5.1 MoonBit 类型节点（v0.10.0 完整）

```moonbit
pub enum MoonType {
  MInt | MUInt | MInt64 | MUInt64
  MDouble | MFloat | MBool | MString | MChar | MUnit
  MArray(MoonType)
  MMap(MoonType, MoonType)
  MSet(MoonType)
  MOption(MoonType)
  MResult(MoonType, MoonType)
  MFuture(MoonType)
  MTypeVar(String)
  MCustom(String)
}
```

### 5.2 Dart 类型节点（v0.10.0 完整，含 DResult + SemanticLevel）

```moonbit
pub enum DartType {
  DInt | DInt64 | DDouble | DBool | DString | DRune | DVoid | DDynamic
  DList(DartType)
  DMap(DartType, DartType)
  DSet(DartType)
  DNullable(DartType)
  DResult(DartType, DartType)  // v0.10.0 结构化节点
  DFuture(DartType)
  DFunction(DartType, Array[DartType])
  DClass(String, Array[DartType])
  DEnum(String, Array[DartType])
  DSealedClass(String, Array[DartType])
  DAbstractClass(String, Array[DartType])
  DCustom(String)
}

pub enum SemanticLevel {
  L1  // 完全等价
  L2  // 结构等价
  L3  // 受限等价
  L4  // 不等价
}
```

### 5.3 MoonBit 表达式节点（v0.10.0 完整）

```moonbit
pub enum MoonExpr {
  EInt(Int)
  EDouble(Double)
  EBool(Bool)
  EString(String)
  EVar(String)
  ECall(String, Array[MoonExpr])
  EBinOp(String, MoonExpr, MoonExpr)
  EIf(MoonExpr, MoonExpr, MoonExpr)
  EMatch(MoonExpr, Array[(MoonPattern, MoonExpr)])
  ELambda(Array[(String, MoonType)], MoonExpr)  // 闭包 v0.5.0
  EAwait(MoonExpr)                              // async v0.5.0
}
```

### 5.4 MoonBit 声明节点（v0.10.0 完整）

```moonbit
pub enum MoonDecl {
  DFn(String, Array[(String, MoonType)], MoonType, MoonExpr)
  DAsyncFn(String, Array[(String, MoonType)], MoonType, MoonExpr)  // async v0.5.0
  DStruct(String, Array[(String, MoonType)], Array[String])        // derive 列表 v0.3.0
  DEnum(String, Array[(String, Array[MoonType])])                  // 带数据 enum
  DTrait(String, Array[TraitMethod])                                // trait v0.3.0
  DImpl(String, String, Array[ImplMethod])                          // impl v0.3.0
  DExternFn(String, String, Array[(String, MoonType)], MoonType, String)  // FFI v0.6.0
}
```

## 6. codegen 设计 | Codegen Design

```moonbit
pub fn emit_dart_type(t : DartType) -> String
pub fn emit_dart_expr(e : MoonExpr) -> String
pub fn emit_dart_decl(d : MoonDecl) -> String
pub fn emit_dart_program(decls : Array[MoonDecl]) -> String

pub fn emit_option_class(inner : DartType) -> String              // v0.10.0 嵌套 Option
pub fn emit_semantic_diagnostic(level : SemanticLevel, ..) -> String  // v0.10.0 诊断标注
pub fn emit_flutter_program(decls : Array[MoonDecl]) -> String    // v0.7.0 Flutter
```

## 7. CLI 设计 | CLI Design

```bash
# 基本用法
moon2dart convert input.mbt -o output.dart
moon2dart convert input.mbt --strict         # strict 模式，L4 类型拒绝
moon2dart convert input.mbt --pure-only      # 只转换纯子集，FFI 报错
moon2dart convert input.dart --reverse       # Dart → MoonBit 反向转换

# 项目级
moon2dart project <dir> -o <output>
moon2dart sync <dir> -o <output>             # 增量同步
moon2dart sync <dir> -o <output> --bidirectional  # 双向同步
moon2dart watch <dir> -o <output>            # 文件监听

# MCP 服务器
moon2dart serve                              # STDIO 模式
moon2dart serve --http 8080                  # HTTP 模式
moon2dart serve --agent "convert this code"  # Agent 模式

# 其他
moon2dart demo
moon2dart --help
moon2dart --version
```

## 8. 设计原则 | Design Principles

1. **双向转换 + 语义等价分级**：MoonBit ↔ Dart 双向转换，四级语义等价分类（L1 全等价/L2 结构等价/L3 受限/L4 不等价），strict 模式拒绝 L4 映射
2. **可读输出**：生成可读 Dart 代码（非压缩），便于人工审查与修正
3. **保守转换**：遇到不确定的构造，默认报错而非猜测生成
4. **映射表驱动**：类型/构造映射集中在 typesys，便于版本跟随
5. **零运行时依赖**：生成的 Dart 代码尽量不依赖 moon2dart runtime（除 FFI 桥接辅助）

## 9. 语义等价架构 | Semantic Equivalence Architecture

### 9.1 四级分类管线

```
MoonBit 类型 ──► map_type() ──► DartType + SemanticLevel
                                    │
                      ┌─────────────┼─────────────┐
                      │             │             │
                      ▼             ▼             ▼
                  L1/L2 纯生成  L3 诊断标注   L4 strict 拒绝
                  (无额外处理)  ([L3-CONSTRAINED])  (raise TypeError)
```

### 9.2 嵌套 Option 检测与辅助类生成

```
map_type(MOption(inner))
    │
    ├── is_nested_option? ──► DNullable(DNullable(inner')) + emit_option_class()
    │
    └── 单层 ──► DNullable(inner')
```

### 9.3 DResult 结构化节点

```
正向：MResult(ok, err) ──► DResult(map_type(ok), map_type(err))
反向：DResult(ok, err) ──► MResult(dart_type_to_moon(ok), dart_type_to_moon(err))

旧版退化：MResult → DCustom("Result<...>") ──► 反向丢失结构 ❌
新版结构化：MResult → DResult(ok, err) ──► 反向精确恢复 ✅
```

### 9.4 诊断标注规则

| 等级 | 标注格式 | 生成时机 |
|------|---------|---------|
| L3 | `// [L3-CONSTRAINED] <type>: <restriction>` | typesys 检测到 L3 类型时自动生成 |
| L4 | `// [L4-INEQUIVALENT] <type>: <loss>` | 非 strict 模式下 L4 类型生成时注释 |
| L4 | `raise Moon2DartError::TypeError` | strict 模式下 L4 类型直接拒绝 |

### 9.5 验收三口径

| 口径 | 公式 | 目标 |
|------|------|------|
| 往返类型恢复率 | L1 round-trip 通过数 / L1 总数 | ≥ 95% |
| 语义等价测试通过率 | 通过断言数 / 总断言数 | ≥ 95% |
| strict 模式 L4 拒绝率 | L4 strict 拒绝数 / L4 总数 | 100% |