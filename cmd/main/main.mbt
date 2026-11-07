///|
/// moon2dart CLI — MoonBit → Dart 转换工具。
///
/// 用法：
///   moon2dart convert <file.mbt>    转换 .mbt 文件为 Dart 代码
///   moon2dart demo                  演示模式（内置示例）
///   moon2dart help                  显示帮助
///
/// 运行：moon run cmd/main --target native -- <args>

// ============================================================
// 子命令
// ============================================================

///|
/// convert — 转换 .mbt 文件为 Dart 代码。
async fn cmd_convert(args : Array[String]) -> Unit {
  if args.length() < 1 {
    println("Error: missing <file> argument")
    println("Usage: moon2dart convert <file.mbt>")
    return
  }
  let path = args[0]
  let content = @fs.read_file(path).text() catch {
    _ => {
      println("Error: cannot read file '\{path}'")
      return
    }
  }
  let dart_code = @lib.transpile_source(content)
  println(dart_code)
}

///|
/// demo — 演示模式（内置 AST 示例）。
fn cmd_demo(_args : Array[String]) -> Unit {
  let demo = [
    @ast.DEnum("Color", ["Red", "Green", "Blue"]),
    @ast.DStruct("Point", [("x", @ast.MInt), ("y", @ast.MInt)], []),
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
  println("moon2dart v0.3.0 — MoonBit → Dart transpiler (demo mode)")
}

///|
/// help — 显示用法。
fn usage() -> Unit {
  println("moon2dart v0.3.0 — MoonBit → Dart transpiler")
  println("")
  println("Usage:")
  println("  moon2dart convert <file.mbt>    Convert .mbt file to Dart code")
  println("  moon2dart demo                  Demo mode with built-in examples")
  println("  moon2dart help                  Show this help")
  println("")
  println("Example:")
  println("  moon run cmd/main --target native -- convert example.mbt")
}

// ============================================================
// 入口
// ============================================================

///|
async fn main {
  let args = @env.args()
  if args.length() < 2 {
    usage()
    return
  }
  let subcommand = args[1]
  let rest : Array[String] = []
  for j in 2..<args.length() {
    rest.push(args[j])
  }
  match subcommand {
    "convert" => cmd_convert(rest)
    "demo" => cmd_demo(rest)
    "help" | "--help" | "-h" => usage()
    _ => {
      println("Error: unknown subcommand '\{subcommand}'")
      println("")
      usage()
    }
  }
}
