///|
/// IncrementalCache — 文件内容 hash 缓存，用于增量转换。
///
/// 通过对比文件内容的 hash 值，判断文件是否需要重新转换。
/// 避免每次项目级转换时重新转换所有文件。

///|
pub struct IncrementalCache {
  hashes : Map[String, Int32]
}

///|
pub fn IncrementalCache::new() -> Self {
  { hashes: Map([]), }
}

///|
/// should_transpile — 判断文件是否需要重新转换。
/// 如果缓存中没有该文件的 hash，或 hash 与当前内容不匹配，则返回 true。
pub fn IncrementalCache::should_transpile(
  self : Self,
  path : String,
  content : String,
) -> Bool {
  let h = content.hash()
  match self.hashes.get(path) {
    Some(old_hash) => h != old_hash
    None => true
  }
}

///|
/// update — 更新文件 hash 缓存。
pub fn IncrementalCache::update(
  self : Self,
  path : String,
  content : String,
) -> Unit {
  self.hashes[path] = content.hash()
}

///|
/// get_changed_files — 获取所有需要重新转换的文件列表。
/// 输入：(path, content) 元组数组，输出：需要重新转换的文件路径列表。
pub fn IncrementalCache::get_changed_files(
  self : Self,
  files : Array[(String, String)],
) -> Array[String] {
  let changed : Array[String] = []
  for entry in files {
    let (path, content) = entry
    if self.should_transpile(path, content) {
      changed.push(path)
    }
  }
  changed
}

///|
/// mark_all_transpiled — 将所有文件标记为已转换（更新缓存）。
pub fn IncrementalCache::mark_all_transpiled(
  self : Self,
  files : Array[(String, String)],
) -> Unit {
  for entry in files {
    let (path, content) = entry
    self.update(path, content)
  }
}

///|
/// cache_size — 返回缓存中的文件数量。
pub fn IncrementalCache::cache_size(self : Self) -> Int32 {
  self.hashes.length()
}

///|
/// is_cached — 判断文件是否在缓存中。
pub fn IncrementalCache::is_cached(self : Self, path : String) -> Bool {
  self.hashes.contains(path)
}
