# moon2dart 架构设计

> 已实现 v0.1.0 · 2026-11-06

## 1. 顶层架构

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

## 2. 模块划分

| 模块 | 职责 | 迭代 |
|------|------|------|
| `parser/` | MoonBit 源码 → AST（简化解析） | v0.2.0（v0.1.0 用 AST 直接构造） |
| `ast/` | MoonBit AST 类型定义 | v0.1.0 |
| `typesys/` | MoonBit 类型 → Dart 类型映射 | v0.1.0 |
| `codegen/` | AST → Dart 代码字符串发射 | v0.1.0 |
| `verifier/` | 生成 Dart 代码验证（dart analyze 调用） | v0.3.0 |
| `cmd/main/` | CLI 入口 | v0.1.0 |

## 3. 数据流

```
MoonBit 源码 (.mbt)
    │
    ▼  parser
MoonBit AST
    │
    ▼  typesys (类型映射)
带 Dart 类型的 AST
    │
    ▼  codegen
Dart 源码字符串
    │
    ▼  verifier (可选)
dart analyze 通过?
    │
    ▼
.dart 文件
```

## 4. 转换策略

### 4.1 纯转换（85%）
MoonBit 构造直接映射为 Dart 构造，无运行时桥接：
- 基础类型：`Int`→`int`、`Double`→`double`、`Bool`→`bool`、`String`→`String`
- 复合类型：`Array[T]`→`List<T>`、`Map[K,V]`→`Map<K,V>`、`Option[T]`→`T?`
- 逻辑构造：`fn`→函数、`struct`→`class`、`enum`→`sealed class`、模式匹配→`switch expression`

### 4.2 混合模式（15%）
不可纯转换，需生成桥接代码：
- **FFI**（`extern "C"`）：生成 `dart:ffi` 绑定 + 原生库加载代码
- **`pub(open) trait` 跨包实现**：转换为 `mixin`，限制多继承
- **动态分派（特征对象）**：转换为 `abstract class` 多态

### 4.3 不支持（明确排除）
- MoonBit 的 C FFI 内联汇编
- MoonBit 的 wasm 特定 intrinsics
- MoonBit 的编译期常量计算（保留为字面量）

## 5. AST 设计（v0.1.0 简化）

```moonbit
// MoonBit 类型节点
pub enum MoonType {
  MInt | MUInt | MInt64 | MUInt64
  MDouble | MFloat | MBool | MString | MChar | MUnit
  MArray(MoonType)
  MMap(MoonType, MoonType)
  MSet(MoonType)
  MOption(MoonType)
  MResult(MoonType, MoonType)
  MCustom(String)
}

// MoonBit 表达式节点（v0.1.0 子集）
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
}

// MoonBit 声明节点
pub enum MoonDecl {
  DFn(String, Array[(String, MoonType)], MoonType, MoonExpr)  // fn name(params) -> ret body
  DStruct(String, Array[(String, MoonType)])                  // struct name { fields }
  DEnum(String, Array[String])                                // enum name { variants }
}
```

## 6. codegen 设计

```moonbit
// Dart 类型发射
pub fn emit_dart_type(t : DartType) -> String

// Dart 表达式发射
pub fn emit_dart_expr(e : MoonExpr) -> String

// Dart 声明发射
pub fn emit_dart_decl(d : MoonDecl) -> String

// 完整程序发射
pub fn emit_dart_program(decls : Array[MoonDecl]) -> String
```

## 7. CLI 设计

```bash
# 基本用法
moon2dart input.mbt -o output.dart

# 选项
moon2dart --help
moon2dart --version
moon2dart input.mbt -o output.dart --verify   # 调用 dart analyze 验证
moon2dart input.mbt -o output.dart --pure-only # 只转换纯子集，FFI 报错
```

## 8. 设计原则

1. **单向转换**：MoonBit → Dart，不承诺反向（Dart → MoonBit）
2. **可读输出**：生成可读 Dart 代码（非压缩），便于人工审查与修正
3. **保守转换**：遇到不确定的构造，默认报错而非猜测生成
4. **映射表驱动**：类型/构造映射集中在 typesys，便于版本跟随
5. **零运行时依赖**：生成的 Dart 代码尽量不依赖 moon2dart runtime（除 FFI 桥接辅助）