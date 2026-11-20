# walkzzz/moon2dart
MoonBit → Dart transpiler — 让 MoonBit 代码跑在 Flutter 上。

## 快速开始

```moonbit nocheck
///|
let prog = [
  @ast.DFn(
    "add",
    [("a", @ast.MInt), ("b", @ast.MInt)],
    @ast.MInt,
    @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
  ),
]

///|
let dart_code = @moon2dart.transpile(prog)
```

## API

- `transpile(Array[@ast.MoonDecl]) -> String` — 转换为 Dart 代码
- `transpile_decl(@ast.MoonDecl) -> String` — 转换单个声明
- `transpile_expr(@ast.MoonExpr) -> String` — 转换表达式
- `transpile_type(@ast.MoonType) -> String` — 类型映射
- `transpile_source_safe(String) -> String` — **fail-closed** 安全管线（Wrapping + 推断失败即拒绝）
- `transpile_source_report(String, String, SemanticsMode, UnresolvedPolicy) -> (String, TranspileReport)` — 代码 + 可审计报告
- `report_to_json` / `report_to_markdown` — 报告序列化

## 语义与安全边界（v0.12.0）

- 集合（Array/Map/Set）为 **L2-C**：相等语义用 `mbEquals` 还原（MoonBit 逐元素 vs Dart 引用）
- 推断失败默认**拒绝生成**（`--on-unresolved error`）；`warn` 标注并写 JSON/MD 报告
- golden 双端 **27/27**（算术 14 + 业务函数 13）；`node scripts/golden_check.mjs` 复现
- 安全边界门禁 8/8：`node scripts/safety_gate.mjs`

## 支持后端

wasm / wasm-gc / js / native

## 许可证

Apache-2.0