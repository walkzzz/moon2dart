///|
/// 项目信息 — 从 moon.mod 文件读取的模块元数据 + 包列表。
#derive(Debug)
pub(all) struct ProjectInfo {
  module_name : String
  version : String
  packages : Array[PackageInfo]
}

///|
pub extend ProjectInfo with Debug::{to_repr}

///|
/// 包信息 — 从 moon.pkg 文件和目录结构推断的单个包信息。
#derive(Debug)
pub(all) struct PackageInfo {
  name : String
  path : String
  dependencies : Array[String]
  source_files : Array[String]
}

///|
pub extend PackageInfo with Debug::{to_repr}

///|
/// 依赖图 — 包之间的依赖关系，用于拓扑排序。
#derive(Debug)
pub(all) struct DependencyGraph {
  nodes : Array[String]
  edges : Array[(String, String)]
}

///|
pub extend DependencyGraph with Debug::{to_repr}

///|
/// 拓扑排序 — 返回按依赖顺序排列的包名列表（被依赖的包在前）。
pub fn DependencyGraph::topo_sort(self : DependencyGraph) -> Array[String] {
  let result : Array[String] = []
  let visited : Array[String] = []
  for node in self.nodes {
    if !visited.contains(node) {
      visit_node(node, self.edges, visited, result)
    }
  }
  result
}

///|
fn visit_node(
  node : String,
  edges : Array[(String, String)],
  visited : Array[String],
  result : Array[String],
) -> Unit {
  if visited.contains(node) {
    return
  }
  visited.push(node)
  for pair in edges {
    let (from, to) = pair
    if from == node {
      visit_node(to, edges, visited, result)
    }
  }
  result.push(node)
}

///|
/// 构建依赖图 — 从包列表中提取节点和边。
pub fn build_dependency_graph(packages : Array[PackageInfo]) -> DependencyGraph {
  let nodes : Array[String] = []
  let edges : Array[(String, String)] = []
  for pkg in packages {
    nodes.push(pkg.name)
    for dep in pkg.dependencies {
      edges.push((pkg.name, dep))
    }
  }
  { nodes, edges, }
}
