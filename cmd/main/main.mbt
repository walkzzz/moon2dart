///|
/// CLI 入口 — v0.1.0 演示模式。
/// 内置 AST 示例，展示 MoonBit → Dart 转换。
/// 运行：`moon run cmd/main`
fn main {
  let demo = [
    @ast.DEnum("Color", ["Red", "Green", "Blue"]),
    @ast.DStruct("Point", [("x", @ast.MInt), ("y", @ast.MInt)]),
    @ast.DFn(
      "add",
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "greet",
      [("name", @ast.MString)],
      @ast.MString,
      @ast.EString("Hello"),
    ),
  ]
  let dart_code = @lib.transpile(demo)
  println(dart_code)
  println("---")
  println("moon2dart v0.1.0 — MoonBit → Dart transpiler (demo mode)")
}
