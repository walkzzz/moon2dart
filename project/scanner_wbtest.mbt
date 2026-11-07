///|
/// project 包白盒测试 — 数据模型 + 解析逻辑 + 依赖图。

///|
/// 测试 parse_moon_mod 解析模块名和版本。
test "parse_moon_mod" {
  let content = "name = \"walkzzz/moon2dart\"\n\nversion = \"0.3.0\"\n"
  let (module_name, version) = parse_moon_mod(content)
  assert_eq(module_name, "walkzzz/moon2dart")
  assert_eq(version, "0.3.0")
}

///|
/// 测试 parse_moon_mod 只提取引号内的值。
test "parse_moon_mod_partial" {
  let content = "name = \"my_module\"\n"
  let (module_name, version) = parse_moon_mod(content)
  assert_eq(module_name, "my_module")
  assert_eq(version, "")
}

///|
/// 测试 parse_moon_pkg 解析依赖列表。
test "parse_moon_pkg" {
  let content = "import {\n  \"walkzzz/moon2dart/ast\",\n  \"moonbitlang/async/fs\",\n}\n"
  let deps = parse_moon_pkg(content)
  assert_eq(deps.length(), 2)
  assert_eq(deps[0], "walkzzz/moon2dart/ast")
  assert_eq(deps[1], "moonbitlang/async/fs")
}

///|
/// 测试 parse_moon_pkg 无 import 块。
test "parse_moon_pkg_no_import" {
  let content = "// no imports\n"
  let deps = parse_moon_pkg(content)
  assert_eq(deps.length(), 0)
}

///|
/// 测试 infer_package_name 从目录路径推断包名。
test "infer_package_name" {
  assert_eq(infer_package_name("E:/project", "E:/project"), "root")
  assert_eq(infer_package_name("E:/project/ast", "E:/project"), "ast")
  assert_eq(infer_package_name("E:/project/cmd/main", "E:/project"), "cmd_main")
}

///|
/// 测试 build_dependency_graph 构建依赖图。
test "build_dependency_graph" {
  let packages = [
    {
      name: "root",
      path: ".",
      dependencies: ["ast", "codegen"],
      source_files: [],
    },
    { name: "ast", path: "ast", dependencies: [], source_files: [], },
    {
      name: "codegen",
      path: "codegen",
      dependencies: ["ast"],
      source_files: [],
    },
  ]
  let graph = build_dependency_graph(packages)
  assert_eq(graph.nodes.length(), 3)
  assert_eq(graph.edges.length(), 3)
  assert_eq(graph.nodes[0], "root")
  assert_eq(graph.nodes[1], "ast")
  assert_eq(graph.nodes[2], "codegen")
}

///|
/// 测试 DependencyGraph::topo_sort 拓扑排序。
test "topo_sort" {
  let packages = [
    {
      name: "root",
      path: ".",
      dependencies: ["ast", "codegen"],
      source_files: [],
    },
    { name: "ast", path: "ast", dependencies: [], source_files: [], },
    {
      name: "codegen",
      path: "codegen",
      dependencies: ["ast"],
      source_files: [],
    },
  ]
  let graph = build_dependency_graph(packages)
  let sorted = graph.topo_sort()
  assert_eq(sorted.length(), 3)
  let mut ast_idx = -1
  let mut codegen_idx = -1
  let mut root_idx = -1
  for i in 0..<sorted.length() {
    if sorted[i] == "ast" {
      ast_idx = i
    } else if sorted[i] == "codegen" {
      codegen_idx = i
    } else if sorted[i] == "root" {
      root_idx = i
    }
  }
  assert_true(ast_idx < codegen_idx)
  assert_true(codegen_idx < root_idx)
}

///|
/// 测试 DependencyGraph::topo_sort 无依赖情况。
test "topo_sort_no_deps" {
  let packages = [
    { name: "a", path: "a", dependencies: [], source_files: [], },
    { name: "b", path: "b", dependencies: [], source_files: [], },
  ]
  let graph = build_dependency_graph(packages)
  let sorted = graph.topo_sort()
  assert_eq(sorted.length(), 2)
}

///|
/// 测试 extract_quoted_value 提取引号内的值。
test "extract_quoted_value" {
  assert_eq(extract_quoted_value("name = \"hello\""), "hello")
  assert_eq(extract_quoted_value("\"world\""), "world")
  assert_eq(extract_quoted_value("no quotes"), "")
}
