# moon2dart 测试策略 | Testing Strategy

> v0.10.0 · 2026-11-16 · 含语义等价测试 + 变异测试 + round-trip 方法论

## 1. 测试分层 | Test Layers

```
┌──────────────────────────────────────────────────┐
│  L4: 语义等价测试（v0.10.0+）                       │  assert_round_trip + 变异测试 + strict 拒绝
├──────────────────────────────────────────────────┤
│  L3: round-trip 测试（v0.3.0+）                    │  生成 Dart → dart analyze → 语义对比
├──────────────────────────────────────────────────┤
│  L2: 快照测试                                      │  codegen 输出快照
├──────────────────────────────────────────────────┤
│  L1: 单元测试                                      │  类型映射 + 表达式发射
└──────────────────────────────────────────────────┘
```

## 2. L1 单元测试 | Unit Tests

### 2.1 类型映射测试 | Type Mapping
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

### 2.2 codegen 测试 | Codegen
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

## 3. L2 快照测试 | Snapshot Tests

复杂 codegen 输出用快照：
```moonbit
test "emit struct snapshot" {
  let decl = DStruct("Point", [("x", MInt), ("y", MInt)])
  debug_inspect(emit_dart_decl(decl))
  // snapshot: class Point { int x; int y; Point({required this.x, required this.y}); }
}
```

`moon test --update` 刷新快照。

## 4. L3 round-trip 测试 | Round-Trip Tests

1. MoonBit 源码 → AST → Dart 代码
2. 写入临时 .dart 文件
3. 调用 `dart analyze` 验证无错误
4. （可选）调用 `dart test` 运行生成的测试

## 5. L4 语义等价测试 | Semantic Equivalence Tests（v0.10.0+）

### 5.1 assert_round_trip — 往返类型恢复

验证 MoonBit 类型 → Dart 类型 → MoonBit 类型 后与原始一致：

```moonbit
test "round-trip Int" {
  assert_round_trip(MInt)  // MInt → DInt → MInt ✅
}

test "round-trip nested Option" {
  assert_round_trip(MOption(MOption(MInt)))  // → DNullable(DNullable(DInt)) → MOption(MOption(MInt)) ✅
}

test "round-trip Result" {
  assert_round_trip(MResult(MInt, MString))  // → DResult(DInt, DString) → MResult(MInt, MString) ✅
}
```

18 个 L1 条目全覆盖，往返恢复率 100%。

### 5.2 assert_value_domain — 值域语义验证

验证语义等价等级与映射行为一致：

```moonbit
test "L1 value domain" {
  assert_value_domain(MInt, L1)  // Int → int，值域完全一致
}

test "L3 value domain" {
  assert_value_domain(MUInt, L3)  // UInt → int，值域有损但映射可用
}

test "L4 value domain" {
  assert_value_domain(MCustom("Channel"), L4)  // Channel 无 Dart 对应
}
```

### 5.3 变异测试 — 回归安全网

验证语义等价机制的回归检测能力：

```moonbit
test "nested Option 塌缩变异检测" {
  // 临时移除辅助类生成 → round-trip 变红
  // 撤回 → round-trip 变绿
}

test "Result 退化变异检测" {
  // 临时将 DResult 改回 DCustom → round-trip 变红
  // 撤回 → round-trip 变绿
}
```

### 5.4 strict 模式 L4 拒绝测试

```moonbit
test "strict rejects L4 ForeignFunction" {
  try {
    let _ = map_type_strict(MCustom("ForeignFunction"))
    assert_eq(true, false)  // 不应到达
  } catch {
    _ => assert_eq(true, true)  // TypeError 被抛出 ✅
  }
}
```

5 个 L4 场景全覆盖（ForeignFunction/Channel/Spawn 及容器包装）。

### 5.5 诊断标注测试

验证 L3/L4 类型自动生成诊断注释：

```moonbit
test "L3 diagnostic comment" {
  let dart = transpile_source_strict("fn f(x : UInt) -> UInt { x }")
  assert_eq(dart.contains("// [L3-CONSTRAINED]"), true)
}
```

## 6. 测试覆盖目标 | Coverage Targets

| 模块 | 覆盖目标 | 当前测试数 |
|------|---------|:----------:|
| ast | 80%（构造/访问/嵌套检测） | 11 |
| typesys | 100%（映射表全测 + 语义分级） | 50 |
| codegen | 90%（每种构造至少一例 + 诊断标注） | 140 |
| parser | 80%（词法/语法） | 38 |
| project | 70%（扫描/同步/增量） | 17 |
| dart_ast | 80%（Dart AST 构造） | 14 |
| moon2dart (根) | 90%（管线 + 往返 + blackbox） | 37 |
| **总计** | | **500+** |

## 7. 测试命令 | Test Commands

```bash
moon test                             # 全量（native）
moon test --target all                # 四后端
moon test --update                    # 刷新快照
moon test -p moon2dart/typesys        # 单包
moon test --enable-coverage           # 启用覆盖率
moon coverage analyze                 # 覆盖率报告
```