///|
/// sync.mbt 白盒测试 — 测试 SyncDirection / SyncConflict / SyncResult 数据结构和辅助函数。
test "SyncDirection enum values" {
  let f = SyncDirection::Forward
  let r = SyncDirection::Reverse
  let b = SyncDirection::Bidirectional
  assert_true(
    match f {
      Forward => true
      _ => false
    },
  )
  assert_true(
    match r {
      Reverse => true
      _ => false
    },
  )
  assert_true(
    match b {
      Bidirectional => true
      _ => false
    },
  )
}

///|
test "SyncConflict construction" {
  let c = {
    moonbit_path: "src/foo.mbt",
    dart_path: "lib/foo.dart",
    message: "Both changed",
  }
  assert_eq(c.moonbit_path, "src/foo.mbt")
  assert_eq(c.dart_path, "lib/foo.dart")
  assert_eq(c.message, "Both changed")
}

///|
test "SyncResult with no conflicts" {
  let r = {
    direction: Forward,
    transpiled_files: ["lib/root.dart"],
    conflicts: [],
  }
  assert_false(r.has_conflicts())
  assert_eq(r.transpiled_files.length(), 1)
}

///|
test "SyncResult with conflicts" {
  let r = {
    direction: Bidirectional,
    transpiled_files: ["lib/root.dart"],
    conflicts: [
      {
        moonbit_path: "src",
        dart_path: "lib/root.dart",
        message: "Both changed",
      },
    ],
  }
  assert_true(r.has_conflicts())
  assert_eq(r.conflicts.length(), 1)
}

///|
test "SyncResult summary - forward no conflicts" {
  let r = {
    direction: Forward,
    transpiled_files: ["lib/root.dart", "lib/sub/sub.dart"],
    conflicts: [],
  }
  let s = r.summary()
  assert_true(s.contains("Forward"))
  assert_true(s.contains("Transpiled files: 2"))
  assert_true(s.contains("Conflicts: 0"))
}

///|
test "SyncResult summary - bidirectional with conflicts" {
  let r = {
    direction: Bidirectional,
    transpiled_files: ["lib/root.dart"],
    conflicts: [
      {
        moonbit_path: "src",
        dart_path: "lib/root.dart",
        message: "Both changed",
      },
    ],
  }
  let s = r.summary()
  assert_true(s.contains("Bidirectional"))
  assert_true(s.contains("Conflicts: 1"))
  assert_true(s.contains("Both changed"))
}

///|
test "find_last_slash - unix path" {
  assert_eq(find_last_slash("a/b/c.mbt"), 3)
}

///|
test "find_last_slash - windows path" {
  assert_eq(find_last_slash("a\\b\\c.mbt"), 3)
}

///|
test "find_last_slash - no slash" {
  assert_eq(find_last_slash("file.mbt"), -1)
}

///|
test "IncrementalCache integration with SyncResult" {
  let cache = IncrementalCache::new()
  let r = { direction: Reverse, transpiled_files: [], conflicts: [], }
  assert_false(r.has_conflicts())
  assert_eq(cache.cache_size(), 0)
}
