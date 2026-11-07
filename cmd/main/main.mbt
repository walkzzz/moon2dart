///|
/// moon2dart CLI — MoonBit → Dart 转换工具。
///
/// 用法：
///   moon2dart convert <file.mbt>    转换 .mbt 文件为 Dart 代码
///   moon2dart project <dir> -o <output>  转换整个 MoonBit 项目为 Dart 项目
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
    println("Usage: moon2dart convert <file.mbt> [--pure-only] [--lib <name>]")
    return
  }
  let path = args[0]
  let mut pure_only = false
  let mut lib_name = "libnative.so"
  let mut i = 1
  while i < args.length() {
    if args[i] == "--pure-only" {
      pure_only = true
      i = i + 1
    } else if args[i] == "--lib" && i + 1 < args.length() {
      lib_name = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }
  let content = @fs.read_file(path).text() catch {
    _ => {
      println("Error: cannot read file '\{path}'")
      return
    }
  }
  let dart_code = if pure_only {
    @lib.transpile_source_pure(content)
  } else {
    @lib.transpile_source_with_lib(content, lib_name)
  }
  println(dart_code)
}

///|
/// project — 转换整个 MoonBit 项目目录为 Dart 项目。
async fn cmd_project(args : Array[String]) -> Unit {
  if args.length() < 1 {
    println("Error: missing <dir> argument")
    println("Usage: moon2dart project <dir> -o <output>")
    return
  }
  let dir = args[0]
  let mut output_dir = "dart_output"
  let mut i = 1
  while i < args.length() {
    if args[i] == "-o" && i + 1 < args.length() {
      output_dir = args[i + 1]
      i = i + 2
    } else {
      i = i + 1
    }
  }
  let project = @project.scan_project(dir) catch {
    _ => {
      println("Error: cannot scan project at '\{dir}'")
      return
    }
  }
  println(
    "Scanned: \{project.module_name} v\{project.version} (\{project.packages.length()} packages)",
  )
  let files = @project.transpile_project(project) catch {
    _ => {
      println("Error: transpile failed")
      return
    }
  }
  @project.write_dart_project(files, output_dir) catch {
    _ => {
      println("Error: cannot write to '\{output_dir}'")
      return
    }
  }
  println("Generated \{files.length()} files in \{output_dir}/")
}

///|
/// demo — 演示模式（内置 AST 示例）。
fn cmd_demo(_args : Array[String]) -> Unit {
  let demo = [
    @ast.DEnum("Color", ["Red", "Green", "Blue"]),
    @ast.DStruct("Point", [], [("x", @ast.MInt), ("y", @ast.MInt)], []),
    @ast.DFn(
      "add",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
    @ast.DFn(
      "greet",
      [],
      [("name", @ast.MString)],
      @ast.MString,
      @ast.EString("Hello"),
    ),
  ]
  let dart_code = @lib.transpile(demo)
  println(dart_code)
  println("---")
  println("moon2dart v0.7.0 — MoonBit → Dart transpiler (demo mode)")
}

///|
/// help — 显示用法。
fn usage() -> Unit {
  println("moon2dart v0.7.0 — MoonBit → Dart transpiler")
  println("")
  println("Usage:")
  println(
    "  moon2dart convert <file.mbt> [--pure-only] [--lib <name>]  Convert .mbt file to Dart code",
  )
  println(
    "  moon2dart project <dir> -o <output>  Convert MoonBit project to Dart project",
  )
  println(
    "  moon2dart demo                        Demo mode with built-in examples",
  )
  println("  moon2dart help                        Show this help")
  println("")
  println("Options:")
  println("  --pure-only    Skip FFI declarations (only convert pure MoonBit)")
  println(
    "  --lib <name>   Specify native library name (default: libnative.so)",
  )
  println("")
  println("Example:")
  println("  moon run cmd/main --target native -- convert example.mbt")
  println(
    "  moon run cmd/main --target native -- convert example.mbt --pure-only",
  )
  println(
    "  moon run cmd/main --target native -- project ./my_project -o ./dart_output",
  )
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
    "project" => cmd_project(rest)
    "demo" => cmd_demo(rest)
    "help" | "--help" | "-h" => usage()
    _ => {
      println("Error: unknown subcommand '\{subcommand}'")
      println("")
      usage()
    }
  }
}
