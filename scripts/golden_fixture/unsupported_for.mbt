// 安全边界材料 — 未支持语法（for 循环），用于验证解析器 fail-closed（不静默跳过）。
// Safety-boundary fixture: unsupported syntax (for loop) to verify the parser fails closed.

fn f() -> Int {
  for i in 0..<3 {
    i
  }
  0
}