///|
/// 项目扫描器 — 读取 MoonBit 项目目录结构，构建 ProjectInfo。

///|
/// 解析 moon.mod 文件内容，提取模块名和版本。
pub fn parse_moon_mod(content : String) -> (String, String) {
  let mut module_name = ""
  let mut version = ""
  for line in content.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("name") {
      module_name = extract_quoted_value(trimmed)
    } else if trimmed.has_prefix("version") {
      version = extract_quoted_value(trimmed)
    }
  }
  (module_name, version)
}

///|
/// 解析 moon.pkg 文件内容，提取依赖列表。
pub fn parse_moon_pkg(content : String) -> Array[String] {
  let deps : Array[String] = []
  let mut in_import = false
  for line in content.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("import") && trimmed.contains("{") {
      in_import = true
      continue
    }
    if in_import {
      if trimmed == "}" {
        break
      }
      let dep = extract_quoted_value(trimmed)
      if dep != "" {
        deps.push(dep)
      }
    }
  }
  deps
}

///|
/// 从目录路径推断包名（相对于项目根目录的路径）。
pub fn infer_package_name(dir : String, root_dir : String) -> String {
  if dir == root_dir {
    "root"
  } else {
    let rel_start = root_dir.length() + 1
    let relative = dir[rel_start:].to_owned()
    relative.replace(old="/", new="_").replace(old="\\", new="_")
  }
}

///|
/// 从字符串中提取引号内的值。
fn extract_quoted_value(s : String) -> String {
  let mut start = -1
  let mut end = -1
  let chars = s.to_array()
  for i in 0..<chars.length() {
    if chars[i] == '"' {
      if start == -1 {
        start = i
      } else {
        end = i
        break
      }
    }
  }
  if start != -1 && end != -1 && end > start {
    s[start + 1:end].to_owned()
  } else {
    ""
  }
}

///|
/// 扫描 MoonBit 项目目录，构建 ProjectInfo。
pub async fn scan_project(root_dir : String) -> ProjectInfo {
  let mod_content = @fs.read_file(root_dir + "/moon.mod").text()
  let (module_name, version) = parse_moon_mod(mod_content)
  let packages : Array[PackageInfo] = []
  let pkg_dirs : Array[String] = []
  @fs.walk(
    root_dir,
    fn(dir, entries) {
      for entry in entries {
        if entry == "moon.pkg" {
          pkg_dirs.push(dir)
          break
        }
      }
    },
    exclude=fn(path) { path.contains("_build") || path.contains(".git") },
  )
  for dir in pkg_dirs {
    let pkg_content = @fs.read_file(dir + "/moon.pkg").text()
    let deps = parse_moon_pkg(pkg_content)
    let entries = @fs.readdir(dir)
    let source_files : Array[String] = []
    for entry in entries {
      if entry.has_suffix(".mbt") {
        source_files.push(entry)
      }
    }
    let pkg_name = infer_package_name(dir, root_dir)
    packages.push({
      name: pkg_name,
      path: dir,
      dependencies: deps,
      source_files,
    })
  }
  { module_name, version, packages, }
}
