# moon2dart 测试策略

> 待审核 · 2026-11-06

## 1. 测试分层

```
┌─────────────────────────────────┐
│  L3: round-trip 测试（v0.3.0+）  │  生成 Dart → dart analyze → 语义对比
├─────────────────────────────────┤
│  L2: 快照测试                    │  codegen 输出快照
├─────────────────────────────────┤
│  L1: 单元测试                    │  类型映射 + 表达式发射
└─────────────────────────────────┘
```

## 2. L1 单元测试（v0.1.0）

### 2.1 类型映射测试
```moonbit
test "map basic types" {
  assert_eq(map_type(MInt), DInt)
  assert_eq(map_type(MDouble), DDouble)
  assert_eq(map_type(MString), DString)
}

test "map composite types" {
  assert_eq(map_type(MArray(MInt)), DList(DInt))
  assert_eq(map_type(MOption(MInt)), DNullable(DInt))
}
```

### 2.2 codegen 测试
```moonbit
test "emit dart types" {
  assert_eq(emit_dart_type(DInt), "int")
  assert_eq(emit_dart_type(DList(DInt)), "List<int>")
  assert_eq(emit_dart_type(DNullable(DInt)), "int?")
}

test "emit dart expr" {
  assert_eq(emit_dart_expr(EInt(42)), "42")
  assert_eq(emit_dart_expr(EString("hi")), "\"hi\"")
}
```

## 3. L2 快照测试（v0.1.0+）

复杂 codegen 输出用快照：
```moonbit
test "emit struct snapshot" {
  let decl = DStruct("Point", [("x", MInt), ("y", MInt)])
  debug_inspect(emit_dart_decl(decl))
  // snapshot: class Point { int x; int y; Point({required this.x, required this.y}); }
}
```

`moon test --update` 刷新快照。

## 4. L3 round-trip 测试（v0.3.0+）

1. MoonBit 源码 → AST → Dart 代码
2. 写入临时 .dart 文件
3. 调用 `dart analyze` 验证无错误
4. （可选）调用 `dart test` 运行生成的测试

## 5. 测试覆盖目标

| 模块 | 覆盖目标 |
|------|---------|
| typesys | 100%（映射表全测） |
| codegen | 90%（每种构造至少一例） |
| ast | 80%（构造/访问） |
| parser | 80%（v0.2.0+） |
| verifier | 70%（v0.3.0+） |

## 6. 测试命令

```bash
moon test                    # 全量
moon test --update           # 刷新快照
moon test -p moon2dart/typesys  # 单包
moon coverage analyze        # 覆盖率
```