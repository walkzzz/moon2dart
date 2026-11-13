///|
/// 项目双向同步 — MoonBit ↔ Dart 双向同步 + 冲突检测。
///
/// 同步方向：
///   Forward（正向）: MoonBit → Dart（已有 sync_project）
///   Reverse（反向）: Dart → MoonBit（基于 reverse_codegen）
///   Bidirectional（双向）: 同时执行正向 + 反向，检测冲突

// ============================================================
// 数据结构
// ============================================================

///|
pub enum SyncDirection {
  Forward
  Reverse
  Bidirectional
}

///|
/// SyncConflict — 同步冲突信息。
///
/// 当 MoonBit 源文件和对应的 Dart 文件都有变更时产生冲突。
pub struct SyncConflict {
  moonbit_path : String
  dart_path : String
  message : String
}

///|
/// SyncResult — 同步操作结果。
pub struct SyncResult {
  direction : SyncDirection
  transpiled_files : Array[String]
  conflicts : Array[SyncConflict]
}

///|
/// SyncResult::has_conflicts — 是否有冲突。
pub fn SyncResult::has_conflicts(self : SyncResult) -> Bool {
  self.conflicts.length() > 0
}

///|
/// SyncResult::summary — 生成结果摘要文本。
pub fn SyncResult::summary(self : SyncResult) -> String {
  let dir_str = match self.direction {
    Forward => "Forward (MoonBit -> Dart)"
    Reverse => "Reverse (Dart -> MoonBit)"
    Bidirectional => "Bidirectional (MoonBit <-> Dart)"
  }
  let lines : Array[String] = []
  lines.push("Direction: \{dir_str}")
  lines.push("Transpiled files: \{self.transpiled_files.length()}")
  for f in self.transpiled_files {
    lines.push("  - \{f}")
  }
  if self.conflicts.length() > 0 {
    lines.push("Conflicts: \{self.conflicts.length()}")
    for c in self.conflicts {
      lines.push("  ! \{c.message}")
    }
  } else {
    lines.push("Conflicts: 0")
  }
  lines.join("\n")
}

// ============================================================
// 正向同步 — MoonBit → Dart
// ============================================================

///|
/// sync_project_forward — 正向同步（MoonBit → Dart），返回 SyncResult。
///
/// 包装 sync_project 的结果为 SyncResult，提供与 reverse_sync_project
/// 一致的 API 接口。
pub async fn sync_project_forward(
  project : ProjectInfo,
  cache : IncrementalCache,
) -> SyncResult {
  let forward_files = sync_project(project, cache)
  let transpiled : Array[String] = []
  for pair in forward_files {
    let (path, _) = pair
    transpiled.push(path)
  }
  { direction: Forward, transpiled_files: transpiled, conflicts: [], }
}

// ============================================================
// 反向同步 — Dart → MoonBit
// ============================================================

///|
/// reverse_sync_project — Dart → MoonBit 反向同步。
///
/// 扫描 dart_dir 中的 .dart 文件，将变更的文件反向转换为 MoonBit 源码，
/// 写入 moonbit_output_dir 对应位置。
pub async fn reverse_sync_project(
  dart_dir : String,
  moonbit_output_dir : String,
  cache : IncrementalCache,
) -> SyncResult {
  let dart_files : Array[String] = []
  @fs.walk(
    dart_dir,
    fn(dir, entries) {
      for entry in entries {
        if entry.has_suffix(".dart") {
          dart_files.push(dir + "/" + entry)
        }
      }
    },
    exclude=fn(path) { path.contains("_build") || path.contains(".git") },
  )
  let transpiled : Array[String] = []
  for dart_path in dart_files {
    let dart_content = @fs.read_file(dart_path).text()
    if cache.should_transpile(dart_path, dart_content) {
      let moon_code = @reverse_codegen.reverse_transpile_source(dart_content)
      let rel_path = dart_path[dart_dir.length() + 1:].to_owned()
      let moon_path = moonbit_output_dir +
        "/" +
        rel_path.replace(old=".dart", new=".mbt")
      let dir_end = find_last_slash(moon_path)
      if dir_end > 0 {
        let dir = moon_path[:dir_end].to_owned()
        @fs.mkdir(dir, recursive=true, allow_exist=true)
      }
      @fs.write_file(moon_path, @utf8.encode(moon_code))
      transpiled.push(moon_path)
      cache.update(dart_path, dart_content)
    }
  }
  { direction: Reverse, transpiled_files: transpiled, conflicts: [], }
}

// ============================================================
// 双向同步 — MoonBit ↔ Dart
// ============================================================

///|
/// sync_project_bidirectional — 双向同步，检测冲突。
///
/// 先执行正向同步（MoonBit → Dart），再检测冲突。
/// 如果同一包的 MoonBit 源文件和 Dart 文件都有变更，报告冲突。
pub async fn sync_project_bidirectional(
  project : ProjectInfo,
  dart_dir : String,
  cache : IncrementalCache,
) -> SyncResult {
  let forward_files = sync_project(project, cache)
  let transpiled : Array[String] = []
  for pair in forward_files {
    let (path, _) = pair
    transpiled.push(path)
  }
  let conflicts : Array[SyncConflict] = []
  for pkg in project.packages {
    let mut mb_has_change = false
    for src_file in pkg.source_files {
      let src_path = pkg.path + "/" + src_file
      let src_content = @fs.read_file(src_path).text()
      if cache.should_transpile(src_path, src_content) {
        mb_has_change = true
      }
    }
    let dart_path = map_package_to_dart_path(pkg.name)
    let full_dart_path = dart_dir + "/" + dart_path
    let dart_content = @fs.read_file(full_dart_path).text() catch {
      _ => continue
    }
    if cache.should_transpile(full_dart_path, dart_content) {
      if mb_has_change {
        conflicts.push({
          moonbit_path: pkg.path,
          dart_path: full_dart_path,
          message: "Both MoonBit source and Dart output have changes in package '\{pkg.name}'. Manual resolution required.",
        })
      }
    }
  }
  { direction: Bidirectional, transpiled_files: transpiled, conflicts, }
}

// ============================================================
// 辅助函数
// ============================================================

///|
fn find_last_slash(s : String) -> Int32 {
  let mut idx = -1
  let chars = s.to_array()
  for i in 0..<s.length() {
    if chars[i] == '/' || chars[i] == '\\' {
      idx = i
    }
  }
  idx
}
