///|
test "IncrementalCache::new creates empty cache" {
  let cache = IncrementalCache::new()
  assert_eq(cache.cache_size(), 0)
}

///|
test "IncrementalCache::should_transpile returns true for new file" {
  let cache = IncrementalCache::new()
  assert_true(cache.should_transpile("src/main.mbt", "fn main { }"))
}

///|
test "IncrementalCache::should_transpile returns false after update" {
  let cache = IncrementalCache::new()
  cache.update("src/main.mbt", "fn main { }")
  assert_false(cache.should_transpile("src/main.mbt", "fn main { }"))
}

///|
test "IncrementalCache::should_transpile returns true when content changes" {
  let cache = IncrementalCache::new()
  cache.update("src/main.mbt", "fn main { }")
  assert_true(cache.should_transpile("src/main.mbt", "fn main { println(1) }"))
}

///|
test "IncrementalCache::get_changed_files detects all changes" {
  let cache = IncrementalCache::new()
  cache.update("a.mbt", "content_a")
  cache.update("b.mbt", "content_b")
  let files = [
    ("a.mbt", "content_a"),
    ("b.mbt", "content_b_changed"),
    ("c.mbt", "content_c"),
  ]
  let changed = cache.get_changed_files(files)
  assert_eq(changed.length(), 2)
  assert_true(changed.contains("b.mbt"))
  assert_true(changed.contains("c.mbt"))
}

///|
test "IncrementalCache::get_changed_files returns empty when no changes" {
  let cache = IncrementalCache::new()
  cache.update("a.mbt", "content_a")
  cache.update("b.mbt", "content_b")
  let files = [("a.mbt", "content_a"), ("b.mbt", "content_b")]
  let changed = cache.get_changed_files(files)
  assert_eq(changed.length(), 0)
}

///|
test "IncrementalCache::mark_all_transpiled updates all hashes" {
  let cache = IncrementalCache::new()
  let files = [("a.mbt", "content_a"), ("b.mbt", "content_b")]
  cache.mark_all_transpiled(files)
  assert_eq(cache.cache_size(), 2)
  assert_false(cache.should_transpile("a.mbt", "content_a"))
  assert_false(cache.should_transpile("b.mbt", "content_b"))
}

///|
test "IncrementalCache::is_cached checks presence" {
  let cache = IncrementalCache::new()
  cache.update("a.mbt", "content_a")
  assert_true(cache.is_cached("a.mbt"))
  assert_false(cache.is_cached("b.mbt"))
}

///|
test "IncrementalCache::cache_size returns correct count" {
  let cache = IncrementalCache::new()
  assert_eq(cache.cache_size(), 0)
  cache.update("a.mbt", "content_a")
  assert_eq(cache.cache_size(), 1)
  cache.update("b.mbt", "content_b")
  assert_eq(cache.cache_size(), 2)
  cache.update("a.mbt", "content_a_updated")
  assert_eq(cache.cache_size(), 2)
}
