/// ============================================================================
/// transpiler 性能基准 — moon bench 框架（与 astrolabe/image 三项目统一机制）
/// ============================================================================

///| 生成 N 个 MoonBit 函数声明的测试源码（transpile 性能基准 workload）。

///|

///|
/// Build N MoonBit function declarations as the transpile benchmark workload.
fn make_moon_source(fn_count : Int32) -> String {
  let buf : StringBuilder = StringBuilder()
  for i in 0..<fn_count {
    buf.write_string("fn add_\{i}(a : Int, b : Int) -> Int { a + b }\n\n")
  }
  buf.to_string()
}

///| 生成 N 个 Flutter Text/Container widget 构造的测试源码（Flutter emitter workload）。

///|

///|
/// Build N Flutter widget constructors as the Flutter emitter benchmark workload.
fn make_flutter_source(widget_count : Int32) -> String {
  let buf : StringBuilder = StringBuilder()
  for i in 0..<widget_count {
    buf.write_string("struct Page_\{i} {\n  title : String\n}\n\n")
    buf.write_string("fn page_\{i}_view(self : Page_\{i}) -> Widget {\n")
    buf.write_string(
      "  Scaffold(app_bar: AppBar(title: Text(self.title)), body: Container(child: Text(\"page \{i}\")))\n}\n\n",
    )
  }
  buf.to_string()
}

///| transpile_source 管线基准（ MoonBit 源码 → Dart 代码，100/500 函数规模）。

///|

///|
/// transpile_source pipeline benchmark (100/500 function scale).
test (b : @bench.T) {
  let src_100 = make_moon_source(100)
  let src_500 = make_moon_source(500)
  b.bench(name="transpile_source_100fn", fn() {
    b.keep(transpile_source(src_100).length() catch { _ => -1 })
  })
  b.bench(name="transpile_source_500fn", fn() {
    b.keep(transpile_source(src_500).length() catch { _ => -1 })
  })
}

///| Flutter emitter 基准（20/50 widget 规模，含 StatelessWidget 生成）。

///|

///|
/// Flutter emitter benchmark (20/50 widget scale, includes StatelessWidget generation).
test (b : @bench.T) {
  let src_20 = make_flutter_source(20)
  b.bench(name="transpile_flutter_20widgets", fn() {
    b.keep(transpile_source_flutter(src_20).length() catch { _ => -1 })
  })
}

///| 反向转换基准（Dart 源码 → MoonBit 源码）。

///|

///|
/// Reverse transpile benchmark (Dart source → MoonBit source).
test (b : @bench.T) {
  let dart_src = "class Foo {\n  int add(int a, int b) {\n    return a + b;\n  }\n}\n"
  b.bench(name="reverse_transpile_1class", fn() {
    b.keep(reverse_transpile_source(dart_src).length() catch { _ => -1 })
  })
}
