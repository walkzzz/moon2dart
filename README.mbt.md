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

## 支持后端

wasm / wasm-gc / js / native

## 许可证

Apache-2.0