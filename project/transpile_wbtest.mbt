///|
/// transpile.mbt 白盒测试 — 项目转换逻辑。

///|
/// 测试 find_package_by_name 查找包信息。
test "find_package_by_name" {
  let packages = [
    { name: "root", path: ".", dependencies: ["ast"], source_files: [], },
    { name: "ast", path: "ast", dependencies: [], source_files: [], },
  ]
  let found = find_package_by_name(packages, "ast")
  assert_true(found is Some({ name: "ast", .. }))
  let not_found = find_package_by_name(packages, "codegen")
  assert_true(not_found is None)
}

///|
/// 测试 find_package_by_name 空列表。
test "find_package_by_name_empty" {
  let packages : Array[PackageInfo] = []
  let found = find_package_by_name(packages, "root")
  assert_true(found is None)
}

///|
/// 测试 transpile_project 拓扑排序顺序（通过 emit_dart_project_files 验证）。
test "transpile_project_topo_order" {
  let project = {
    module_name: "test/module",
    version: "0.1.0",
    packages: [
      {
        name: "root",
        path: ".",
        dependencies: ["ast", "codegen"],
        source_files: ["main.mbt"],
      },
      {
        name: "codegen",
        path: "codegen",
        dependencies: ["ast"],
        source_files: ["emitter.mbt"],
      },
      { name: "ast", path: "ast", dependencies: [], source_files: ["ast.mbt"], },
    ],
  }
  let graph = build_dependency_graph(project.packages)
  let sorted = graph.topo_sort()
  assert_eq(sorted.length(), 3)
  let mut ast_pos = -1
  let mut codegen_pos = -1
  let mut root_pos = -1
  for i in 0..<sorted.length() {
    if sorted[i] == "ast" {
      ast_pos = i
    } else if sorted[i] == "codegen" {
      codegen_pos = i
    } else if sorted[i] == "root" {
      root_pos = i
    }
  }
  assert_true(ast_pos < codegen_pos)
  assert_true(codegen_pos < root_pos)
}
