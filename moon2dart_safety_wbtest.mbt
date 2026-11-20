///|
/// 安全边界端到端测试 — fail-closed / warn 标注 / 报告序列化 / 业务函数转换（v0.12.0）
/// End-to-end safety-boundary tests: fail-closed, warn annotation, report serialization, business functions.

///|
test "fail-closed rejects unresolved arithmetic" {
  let src = "fn f() -> Int { g() + h() }"
  let mut raised = false
  let mut msg = ""
  try {
    let _ = transpile_source_report(
      src,
      "libnative.so",
      @ast.Wrapping,
      @ast.Error,
    )
  } catch {
    @ast.Moon2DartError::TypeError(m) => {
      msg = m
      raised = true
    }
    _ => ()
  }
  assert_true(raised)
  assert_true(msg.contains("UNRESOLVED"))
  assert_true(msg.contains("fail-closed"))
}

///|
test "warn policy annotates and reports" {
  let src = "fn f() -> Int { g() + h() }"
  let (code, report) = transpile_source_report(
    src,
    "libnative.so",
    @ast.Wrapping,
    @ast.Warn,
  )
  assert_true(code.contains("[L2-UNRESOLVED]"))
  assert_eq(report.unresolved.length(), 1)
  assert_true(report.is_ok())
}

///|
test "safe pipeline resolves annotated arithmetic without diagnostics" {
  let src = "fn inc(a : Int) -> Int { a + 1 }"
  let (code, report) = transpile_source_report(
    src,
    "libnative.so",
    @ast.Wrapping,
    @ast.Error,
  )
  assert_eq(report.unresolved.length(), 0)
  assert_true(report.is_ok())
  assert_true(code.contains("mb32Add(a, 1)"))
}

///|
test "report serialization json and markdown" {
  let diag : @ast.Diagnostic = {
    code: "UNRESOLVED_ARITH",
    site: "f",
    detail: "operator +",
  }
  let report : @ast.TranspileReport = {
    policy: @ast.Warn,
    unresolved: [diag],
    degraded: [],
  }
  let json = report_to_json(report)
  assert_true(json.contains("\"policy\":\"warn\""))
  assert_true(json.contains("\"ok\":true"))
  assert_true(json.contains("UNRESOLVED_ARITH"))
  let md = report_to_markdown(report)
  assert_true(md.contains("# moon2dart 安全报告"))
  assert_true(md.contains("| `UNRESOLVED_ARITH` | `f` |"))
}

///|
test "business function transpiles Array/while/push with wrapping" {
  let src = "fn sum(xs : Array[Int]) -> Int { let mut i = 0\n let mut acc = 0\n while i < xs.length() { acc = acc + xs[i]\n i = i + 1 }\n acc }\n fn build(n : Int) -> Array[Int] { let mut i = 0\n let out : Array[Int] = []\n while i < n { out.push(i * i)\n i = i + 1 }\n out }\n fn main { println(sum([1, 2, 3])) }"
  let code = transpile_source_safe(src)
  assert_true(code.contains("int sum(List<int> xs)"))
  assert_true(code.contains("List<int> build(int n)"))
  assert_true(code.contains("xs.length"))
  assert_true(code.contains("xs[i]"))
  assert_true(code.contains("xs["))
  assert_true(code.contains("out.add(mb32Mul(i, i))"))
  assert_true(code.contains("while (i < n)"))
  assert_true(code.contains("mb32Add"))
}

///|
test "collection diagnosis is auditable in report" {
  let src = "fn f(xs : Array[Int]) -> Int { xs.length() }"
  let (_code, report) = transpile_source_report(
    src,
    "libnative.so",
    @ast.Wrapping,
    @ast.Error,
  )
  assert_eq(report.unresolved.length(), 0)
  assert_eq(report.degraded.length(), 0)
}

///|
test "collection equality emits mbEquals helper and call" {
  let src = "fn same(xs : Array[Int], ys : Array[Int]) -> Bool { xs == ys }"
  let code = transpile_source_safe(src)
  assert_true(code.contains("bool mbEquals(dynamic a, dynamic b)"))
  assert_true(code.contains("return mbEquals(xs, ys);"))
}

///|
test "collection inequality negates mbEquals" {
  let src = "fn differ(xs : Array[Int], ys : Array[Int]) -> Bool { xs != ys }"
  let code = transpile_source_safe(src)
  assert_true(code.contains("return !mbEquals(xs, ys);"))
}

///|
test "fast mode keeps raw collection equality (L2)" {
  let src = "fn same(xs : Array[Int], ys : Array[Int]) -> Bool { xs == ys }"
  let code = transpile_source_with_mode(src, @ast.Fast)
  assert_true(code.contains("return xs == ys;"))
  assert_true(!code.contains("mbEquals"))
}

///|
test "business golden fixture source passes fail-closed pipeline" {
  let src = "fn sum(xs : Array[Int]) -> Int { let mut i = 0\n let mut acc = 0\n while i < xs.length() { acc = acc + xs[i]\n i = i + 1 }\n acc }\n fn same(xs : Array[Int], ys : Array[Int]) -> Bool { xs == ys }\n fn main { println(sum([1, 2, 3]))\n println(same([1], [1])) }"
  let (code, report) = transpile_source_report(
    src,
    "libnative.so",
    @ast.Wrapping,
    @ast.Error,
  )
  assert_true(report.is_ok())
  assert_eq(report.unresolved.length(), 0)
  assert_true(code.contains("List<int>"))
  assert_true(code.contains("mbEquals"))
  assert_true(code.contains("mb32Add"))
}
