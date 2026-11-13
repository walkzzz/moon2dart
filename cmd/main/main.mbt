///|
/// moon2dart CLI — MoonBit ↔ Dart 双向转换工具。
///
/// 用法：
///   moon2dart convert <file.mbt>    转换 .mbt 文件为 Dart 代码
///   moon2dart convert <file.dart> --reverse  转换 .dart 文件为 MoonBit 代码
///   moon2dart project <dir> -o <output>  转换整个 MoonBit 项目为 Dart 项目
///   moon2dart sync <dir> -o <output>  增量同步（支持 --reverse / --bidirectional）
///   moon2dart watch <dir> -o <output>  持续监听文件变更并自动同步
///   moon2dart serve [--http <port>]  启动 MCP 服务器（STDIO 或 HTTP 模式）
///   moon2dart demo                  演示模式（内置示例）
///   moon2dart help                  显示帮助
///
/// 运行：moon run cmd/main --target native -- <args>

// ============================================================
// 子命令
// ============================================================

///|
/// convert — 转换文件（默认 MoonBit→Dart，--reverse 时 Dart→MoonBit）。
async fn cmd_convert(args : Array[String]) -> Unit {
  if args.length() < 1 {
    println("Error: missing <file> argument")
    println(
      "Usage: moon2dart convert <file> [--reverse] [--pure-only] [--lib <name>]",
    )
    return
  }
  let path = args[0]
  let mut reverse = false
  let mut pure_only = false
  let mut lib_name = "libnative.so"
  let mut i = 1
  while i < args.length() {
    if args[i] == "--reverse" {
      reverse = true
      i = i + 1
    } else if args[i] == "--pure-only" {
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
  if reverse {
    let moon_code = try @lib.reverse_transpile_source(content) catch {
      @ast.Moon2DartError::ReverseTranspileError(msg) => { println("Error: " + msg); return }
      @ast.Moon2DartError::ParseError(msg) => { println("Error: " + msg); return }
      _ => { println("Error: unexpected error during reverse conversion"); return }
    }
    println(moon_code)
  } else if pure_only {
    let dart_code = try @lib.transpile_source_pure(content) catch {
      @ast.Moon2DartError::ParseError(msg) => { println("Error: " + msg); return }
      @ast.Moon2DartError::TranspileError(msg) => { println("Error: " + msg); return }
      _ => { println("Error: unexpected error during conversion"); return }
    }
    println(dart_code)
  } else {
    let dart_code = try @lib.transpile_source_with_lib(content, lib_name) catch {
      @ast.Moon2DartError::ParseError(msg) => { println("Error: " + msg); return }
      @ast.Moon2DartError::TranspileError(msg) => { println("Error: " + msg); return }
      _ => { println("Error: unexpected error during conversion"); return }
    }
    println(dart_code)
  }
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
/// serve — 启动 MCP 服务器（默认 STDIO 模式，--http 启动 HTTP 模式）。
async fn cmd_serve(args : Array[String]) -> Unit {
  @mcp_server.serve_mcp(args)
}

///|
/// sync — 增量同步 MoonBit 项目到 Dart 项目。
/// 只转换有变更的文件，避免重复转换。
/// 支持正向（默认）、反向（--reverse）、双向（--bidirectional）同步。
async fn cmd_sync(args : Array[String]) -> Unit {
  if args.length() < 1 {
    println("Error: missing <dir> argument")
    println(
      "Usage: moon2dart sync <dir> -o <output> [--reverse] [--bidirectional]",
    )
    return
  }
  let dir = args[0]
  let mut output_dir = "dart_output"
  let mut use_reverse = false
  let mut use_bidirectional = false
  let mut i = 1
  while i < args.length() {
    if args[i] == "-o" && i + 1 < args.length() {
      output_dir = args[i + 1]
      i = i + 2
    } else if args[i] == "--reverse" {
      use_reverse = true
      i = i + 1
    } else if args[i] == "--bidirectional" {
      use_bidirectional = true
      i = i + 1
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
  let cache = @project.IncrementalCache::new()
  if use_bidirectional {
    let result = @project.sync_project_bidirectional(project, output_dir, cache) catch {
      _ => {
        println("Error: bidirectional sync failed")
        return
      }
    }
    println(result.summary())
    if result.has_conflicts() {
      println("")
      println("WARNING: Conflicts detected. Manual resolution required.")
      for c in result.conflicts {
        println("  Conflict: \{c.message}")
      }
    }
    let pkg_count = result.transpiled_files.length() - 1
    if pkg_count > 0 {
      let files : Array[(String, String)] = []
      for f in result.transpiled_files {
        files.push((f, ""))
      }
      @project.write_dart_project(files, output_dir) catch {
        _ => {
          println("Error: cannot write to '\{output_dir}'")
          return
        }
      }
      println("Synced \{pkg_count} changed package(s) to \{output_dir}/")
    } else {
      println("No changes detected. All files up to date.")
    }
  } else if use_reverse {
    let result = @project.reverse_sync_project(output_dir, dir, cache) catch {
      _ => {
        println("Error: reverse sync failed")
        return
      }
    }
    println(result.summary())
    if result.transpiled_files.length() > 0 {
      println(
        "Reverse synced \{result.transpiled_files.length()} file(s) from \{output_dir}/ to \{dir}/",
      )
    } else {
      println("No changes detected. All Dart files up to date.")
    }
  } else {
    let changed = @project.sync_project(project, cache) catch {
      _ => {
        println("Error: sync failed")
        return
      }
    }
    let pkg_count = changed.length() - 1
    if pkg_count <= 0 {
      println("No changes detected. All files up to date.")
      return
    }
    @project.write_dart_project(changed, output_dir) catch {
      _ => {
        println("Error: cannot write to '\{output_dir}'")
        return
      }
    }
    println("Synced \{pkg_count} changed package(s) to \{output_dir}/")
  }
}

///|
/// watch — 持续监听 MoonBit 项目文件变更，自动增量同步到 Dart 项目。
/// 使用文件系统 Watcher 实时检测 .mbt 文件变更。
async fn cmd_watch(args : Array[String]) -> Unit {
  if args.length() < 1 {
    println("Error: missing <dir> argument")
    println("Usage: moon2dart watch <dir> -o <output> [--max-iterations <n>]")
    return
  }
  let dir = args[0]
  let mut output_dir = "dart_output"
  let mut max_iter = 1000
  let mut i = 1
  while i < args.length() {
    if args[i] == "-o" && i + 1 < args.length() {
      output_dir = args[i + 1]
      i = i + 2
    } else if args[i] == "--max-iterations" && i + 1 < args.length() {
      let parsed = parse_int_arg(args[i + 1])
      if parsed > 0 {
        max_iter = parsed
      }
      i = i + 2
    } else {
      i = i + 1
    }
  }
  let cache = @project.IncrementalCache::new()
  let project = @project.scan_project(dir) catch {
    _ => {
      println("Error: cannot scan project at '\{dir}'")
      return
    }
  }
  println(
    "Watching: \{project.module_name} v\{project.version} (\{project.packages.length()} packages)",
  )
  let changed = @project.sync_project(project, cache) catch {
    _ => {
      println("Error: initial sync failed")
      return
    }
  }
  @project.write_dart_project(changed, output_dir) catch {
    _ => {
      println("Error: cannot write to '\{output_dir}'")
      return
    }
  }
  let pkg_count = changed.length() - 1
  println("Initial sync: \{pkg_count} package(s) to \{output_dir}/")
  println("Watching for changes... (Ctrl+C to stop)")
  let watcher = @fs.Watcher::Watcher(dir, ignored_paths=fn(path) {
    path.contains("_build") || path.contains(".git")
  })
  let mut iter = 0
  while iter < max_iter {
    let events = watcher.wait()
    if has_mbt_changes(events) {
      let project = @project.scan_project(dir)
      let changed = @project.sync_project(project, cache)
      let pkg_count = changed.length() - 1
      if pkg_count > 0 {
        @project.write_dart_project(changed, output_dir)
        println(
          "[\{iter + 1}] Detected changes, synced \{pkg_count} package(s)",
        )
      }
    }
    iter = iter + 1
  }
  watcher.close()
  println("Watch ended after \{max_iter} iterations.")
}

///|
/// has_mbt_changes — 检查文件系统事件中是否包含 .mbt 文件变更。
fn has_mbt_changes(events : Array[@fs.FsEvent]) -> Bool {
  for event in events {
    match event {
      @fs.FsEvent::Modify(path) => if path.has_suffix(".mbt") { return true }
      @fs.FsEvent::Create(path) => if path.has_suffix(".mbt") { return true }
      @fs.FsEvent::Remove(path) => if path.has_suffix(".mbt") { return true }
      @fs.FsEvent::Rename(old~, new~) =>
        if old.has_suffix(".mbt") || new.has_suffix(".mbt") {
          return true
        }
    }
  }
  false
}

///|
/// parse_int_arg — 解析字符串为正整数，失败时返回 0。
fn parse_int_arg(s : String) -> Int32 {
  let mut result = 0
  for c in s {
    let digit = c.to_int() - 48
    if digit >= 0 && digit <= 9 {
      result = result * 10 + digit
    } else {
      return 0
    }
  }
  result
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
  println("moon2dart v0.8.0 — MoonBit ↔ Dart transpiler (demo mode)")
}

///|
/// help — 显示用法。
fn usage() -> Unit {
  println("moon2dart v0.9.0 — MoonBit <-> Dart transpiler")
  println("")
  println("Usage:")
  println("  moon2dart convert <file> [--reverse] [--pure-only] [--lib <name>]")
  println(
    "    Convert file (default: MoonBit to Dart, --reverse: Dart to MoonBit)",
  )
  println(
    "  moon2dart project <dir> -o <output>  Convert MoonBit project to Dart project",
  )
  println(
    "  moon2dart sync <dir> -o <output>     Incremental sync (supports --reverse, --bidirectional)",
  )
  println(
    "  moon2dart watch <dir> -o <output>    Watch for changes and auto-sync",
  )
  println(
    "  moon2dart serve [--http <port>]      Start MCP server (STDIO or HTTP mode)",
  )
  println(
    "  moon2dart serve --agent \"<request>\"  Start MCP server in agent mode",
  )
  println(
    "  moon2dart demo                        Demo mode with built-in examples",
  )
  println("  moon2dart help                        Show this help")
  println("")
  println("Options:")
  println("  --reverse      Reverse mode: convert Dart source to MoonBit")
  println("  --pure-only    Skip FFI declarations (only convert pure MoonBit)")
  println(
    "  --lib <name>   Specify native library name (default: libnative.so)",
  )
  println("  --http <port>  Start MCP server in HTTP mode on given port")
  println("  --agent <text> Start MCP server in agent mode with user request")
  println("  --max-iterations <n>  Max watch iterations (default: 1000)")
  println("")
  println("Example:")
  println("  moon run cmd/main --target native -- convert example.mbt")
  println(
    "  moon run cmd/main --target native -- convert example.dart --reverse",
  )
  println(
    "  moon run cmd/main --target native -- project ./my_project -o ./dart_output",
  )
  println(
    "  moon run cmd/main --target native -- sync ./my_project -o ./dart_output",
  )
  println(
    "  moon run cmd/main --target native -- watch ./my_project -o ./dart_output",
  )
  println("  moon run cmd/main --target native -- serve --http 8080")
  println(
    "  moon run cmd/main --target native -- serve --agent \"convert fn add(a: Int, b: Int) -> Int { a + b }\"",
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
    "sync" => cmd_sync(rest)
    "watch" => cmd_watch(rest)
    "serve" => cmd_serve(rest)
    "demo" => cmd_demo(rest)
    "help" | "--help" | "-h" => usage()
    _ => {
      println("Error: unknown subcommand '\{subcommand}'")
      println("")
      usage()
    }
  }
}
