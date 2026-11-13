///|
/// moon2dart 基准测试 — 衡量 transpiler 各阶段性能。
///
/// 使用 @moonbench 的 benchmark/measure 函数进行计时，
/// 覆盖 Lexer / Parser / Codegen / Flutter / 类型映射 / 反向转换。

///|
/// 小型 MoonBit 源码样本 — 单个简单函数。
fn small_source() -> String {
  "fn id(x : Int) -> Int { x }"
}

///|
/// 中型 MoonBit 源码样本 — struct + enum + fn + match。
fn medium_source() -> String {
  let lines = [
    "enum Color { Red, Green, Blue }",
    "struct Point { x : Int, y : Int }",
    "fn add(a : Int, b : Int) -> Int { a + b }",
    "fn color_name(c : Color) -> String { match c { Red => \"red\", Green => \"green\", Blue => \"blue\" } }",
  ]
  lines.join("\n")
}

///|
/// 大型 MoonBit 源码样本 — 多声明 + 泛型 + trait + async。
fn large_source() -> String {
  let lines = [
    "enum OptionT[T] { Some(T), None }",
    "enum ResultT[T, E] { Ok(T), Err(E) }",
    "struct Stack[T] { items : Array[T] }",
    "trait Show { show(Self) -> String }",
    "fn empty_stack[T]() -> Stack[T] { Stack::{ items: [] } }",
    "fn push[T](stack : Stack[T], item : T) -> Stack[T] { Stack::{ items: stack.items + [item] } }",
    "fn pop[T](stack : Stack[T]) -> OptionT[T] { if stack.items.length() == 0 { None } else { Some(stack.items[stack.items.length() - 1]) } }",
    "async fn fetch_data(url : String) -> String { \"data from \" + url }",
    "fn map_option[T, U](opt : OptionT[T], f : (T) -> U) -> OptionT[U] { match opt { Some(x) => Some(f(x)), None => None } }",
    "fn factorial(n : Int) -> Int { if n <= 1 { 1 } else { n * factorial(n - 1) } }",
    "fn fib(n : Int) -> Int { match n { 0 => 0, 1 => 1, _ => fib(n - 1) + fib(n - 2) } }",
  ]
  lines.join("\n")
}

///|
/// Flutter widget 源码样本 — MaterialApp + Scaffold + Widget 树。
fn flutter_source() -> String {
  let lines = [
    "fn main() {",
    "  MaterialApp(",
    "    title: \"Demo\",",
    "    home: Scaffold(",
    "      appBar: AppBar(title: Text(\"Hello\")),",
    "      body: Center(",
    "        child: Column(",
    "          children: [",
    "            Text(\"Welcome\"),",
    "            ElevatedButton(onPressed: fn() { }, child: Text(\"Click\")),",
    "            Row(children: [Icon(Icons.star), Text(\"Row item\")])",
    "          ]",
    "        )",
    "      ),",
    "      floatingActionButton: FloatingActionButton(",
    "        onPressed: fn() { },",
    "        child: Icon(Icons.add)",
    "      )",
    "    )",
    "  )",
    "}",
  ]
  lines.join("\n")
}

///|
/// Dart 源码样本 — 用于反向转换基准测试。
fn dart_source() -> String {
  let lines = [
    "int add(int a, int b) { return a + b; }",
    "void greet(String name) { return name; }",
    "Future<int> fetch() async { return 42; }",
    "class Point { int x; int y; }",
    "sealed class Color { class Red; class Green; class Blue; }",
    "abstract class Named { String name(); }",
    "List<int> make_list() { return null; }",
    "Map<String, int> make_map() { return null; }",
  ]
  lines.join("\n")
}

///|
/// === Lexer 基准测试 ===

///|
test "bench: lexer tokenize small" {
  let src = small_source()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@parser.Lexer::make(src).tokenize())
  })
  println("lexer small: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: lexer tokenize medium" {
  let src = medium_source()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@parser.Lexer::make(src).tokenize())
  })
  println("lexer medium: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: lexer tokenize large" {
  let src = large_source()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@parser.Lexer::make(src).tokenize())
  })
  println("lexer large: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === Parser 基准测试 ===

///|
test "bench: parser parse small" {
  let src = small_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@parser.Parser::make(tokens).parse_program())
  })
  println("parser small: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: parser parse medium" {
  let src = medium_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@parser.Parser::make(tokens).parse_program())
  })
  println("parser medium: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: parser parse large" {
  let src = large_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@parser.Parser::make(tokens).parse_program())
  })
  println("parser large: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === Codegen 基准测试 ===

///|
test "bench: codegen emit small" {
  let src = small_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@codegen.emit_dart_program(decls))
  })
  println("codegen small: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: codegen emit medium" {
  let src = medium_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@codegen.emit_dart_program(decls))
  })
  println("codegen medium: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: codegen emit large" {
  let src = large_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@codegen.emit_dart_program(decls))
  })
  println("codegen large: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === 完整 transpile 管线基准测试 ===

///|
test "bench: transpile_source small" {
  let src = small_source()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@lib.transpile_source(src))
  })
  println("transpile small: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: transpile_source medium" {
  let src = medium_source()
  let summary = @moonbench.benchmark(1000, fn() {
    ignore(@lib.transpile_source(src))
  })
  println("transpile medium: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: transpile_source large" {
  let src = large_source()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@lib.transpile_source(src))
  })
  println("transpile large: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === Flutter codegen 基准测试 ===

///|
test "bench: flutter codegen" {
  let src = flutter_source()
  let tokens = @parser.Lexer::make(src).tokenize()
  let decls = @parser.Parser::make(tokens).parse_program()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@codegen.emit_flutter_program(decls))
  })
  println("flutter codegen: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
test "bench: transpile_source_flutter" {
  let src = flutter_source()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@lib.transpile_source_flutter(src))
  })
  println("flutter pipeline: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === 类型映射基准测试 ===

///|
test "bench: type mapping basic" {
  let types = [
    @ast.MInt,
    @ast.MString,
    @ast.MBool,
    @ast.MDouble,
    @ast.MUnit,
    @ast.MArray(@ast.MInt),
    @ast.MOption(@ast.MString),
    @ast.MResult(@ast.MInt, @ast.MString),
  ]
  let summary = @moonbench.benchmark(5000, fn() {
    for t in types {
      ignore(@typesys.moon_to_dart_type(t))
    }
  })
  println("type mapping: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === 反向转换基准测试 ===

///|
test "bench: reverse transpile_source" {
  let src = dart_source()
  let summary = @moonbench.benchmark(500, fn() {
    ignore(@reverse_codegen.reverse_transpile_source(src))
  })
  println("reverse transpile: " + @moonbench.describe(summary))
  assert_true(summary.count > 0)
}

///|
/// === 性能预算检查 ===

///|
test "bench: budget check transpile large" {
  let src = large_source()
  let summary = @moonbench.benchmark(200, fn() {
    ignore(@lib.transpile_source(src))
  })
  let budget : @moonbench.Budget = { max_mean_ns: 5_000_000, max_spread_ppm: 500_000 }
  let report = @moonbench.budget_report(summary, budget)
  println("budget check: " + report)
  assert_true(@moonbench.has_samples(summary))
}