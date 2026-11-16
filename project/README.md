# Package: project

项目级扫描与转换（native only） | Project-level scanning and conversion (native only)

## 概述 | Overview

负责 MoonBit 项目级别的扫描、结构映射、多文件转换、增量同步和双向同步。从 moon.mod/moon.pkg 读取项目元数据，构建依赖图拓扑排序，映射为 Dart 项目结构（pubspec.yaml + lib/ 目录），并通过 IncrementalCache 实现增量检测和冲突检测。

Handles MoonBit project-level scanning, structure mapping, multi-file conversion, incremental sync, and bidirectional sync. Reads project metadata from moon.mod/moon.pkg, builds dependency graph for topological sort, maps to Dart project structure (pubspec.yaml + lib/ directory), and implements incremental detection and conflict detection via IncrementalCache.

## 核心类型 | Core Types

| Type | Description |
|------|-------------|
| `ProjectInfo` | [CN] 项目信息（模块名+版本+包列表） / [EN] Project info (module name + version + package list) |
| `PackageInfo` | [CN] 包信息（名称+路径+依赖+源文件列表） / [EN] Package info (name + path + dependencies + source files) |
| `DependencyGraph` | [CN] 依赖图（节点+边，支持拓扑排序） / [EN] Dependency graph (nodes + edges, supports topo sort) |
| `IncrementalCache` | [CN] 增量缓存（hash 对比检测文件变更） / [EN] Incremental cache (hash-based file change detection) |
| `SyncDirection` | [CN] 同步方向（Forward/Reverse/Bidirectional） / [EN] Sync direction |
| `SyncConflict` | [CN] 同步冲突信息 / [EN] Sync conflict info |
| `SyncResult` | [CN] 同步操作结果 / [EN] Sync operation result |

## 核心函数 | Core Functions

### 项目扫描 | Scanning (scanner.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `parse_moon_mod` | `String -> (String, String)` | [CN] 解析 moon.mod（返回模块名+版本） / [EN] Parse moon.mod (returns module name + version) |
| `parse_moon_pkg` | `String -> Array[String]` | [CN] 解析 moon.pkg（返回依赖列表） / [EN] Parse moon.pkg (returns dependency list) |
| `infer_package_name` | `(String, String) -> String` | [CN] 从目录路径推断包名 / [EN] Infer package name from directory path |

### 结构映射 | Structure Mapping (structure.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `emit_pubspec_yaml` | `ProjectInfo -> String` | [CN] 生成 pubspec.yaml / [EN] Generate pubspec.yaml |
| `map_package_to_dart_path` | `String -> String` | [CN] 映射包名到 Dart lib/ 路径 / [EN] Map package name to Dart lib/ path |
| `emit_dart_project_files` | `(ProjectInfo, (String)->String) -> Array[(String, String)]` | [CN] 生成 Dart 项目文件列表 / [EN] Generate Dart project file list |
| `emit_dart_imports` | `PackageInfo -> String` | [CN] 生成 Dart import 声明 / [EN] Generate Dart import declarations |

### 项目转换 | Transpilation (transpile.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `transpile_project` | `ProjectInfo -> Array[(String, String)]` | [CN] 转换整个项目（async） / [EN] Transpile entire project (async) |
| `find_package_by_name` | `(Array[PackageInfo], String) -> PackageInfo?` | [CN] 按名称查找包 / [EN] Find package by name |

### 增量同步 | Incremental (incremental.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `IncrementalCache::new` | `() -> IncrementalCache` | [CN] 构造增量缓存 / [EN] Construct incremental cache |
| `IncrementalCache::should_transpile` | `(String, String) -> Bool` | [CN] 判断文件是否需重转 / [EN] Check if file needs re-transpilation |
| `IncrementalCache::update` | `(String, String) -> Unit` | [CN] 更新文件 hash 缓存 / [EN] Update file hash cache |
| `IncrementalCache::get_changed_files` | `Array[(String, String)] -> Array[String]` | [CN] 获取需重转的文件列表 / [EN] Get files needing re-transpilation |

### 双向同步 | Bidirectional Sync (sync.mbt)

| Function | Signature | Description |
|----------|-----------|-------------|
| `SyncResult::has_conflicts` | `SyncResult -> Bool` | [CN] 是否有冲突 / [EN] Whether there are conflicts |
| `SyncResult::summary` | `SyncResult -> String` | [CN] 生成同步结果摘要 / [EN] Generate sync result summary |

## 依赖 | Dependencies

- `walkzzz/moon2dart/ast`
- `walkzzz/moon2dart/codegen`
- `walkzzz/moon2dart/parser`
- `walkzzz/moon2dart/reverse_codegen`
- `moonbitlang/core/encoding/utf8`
- `moonbitlang/async/fs`

## 测试 | Tests

- 白盒测试 / Whitebox: 17
  - scanner_wbtest.mbt: 9 tests
  - structure_wbtest.mbt: 5 tests
  - transpile_wbtest.mbt: 3 tests
  - incremental_wbtest.mbt: (included in 17)
  - sync_wbtest.mbt: (included in 17)
- 黑盒测试 / Blackbox: 0

## 平台限制 | Platform Restriction

- 仅 native 后端 / Native backend only (`supported_targets = "-all+native"`)
