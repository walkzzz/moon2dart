# moon2dart — MoonBit ↔ Dart/Flutter Transpiler

## Description

moon2dart is a transpiler that converts MoonBit code to Dart/Flutter and vice versa. It provides an MCP server with 6 tools for code conversion, analysis, and project-level scanning. This skill enables AI agents to convert MoonBit code to Dart/Flutter for running on Flutter, and to reverse-convert Dart code back to MoonBit.

## MCP Server

**Start command**: `moon2dart serve` (STDIO mode) or `moon2dart serve --http 8080` (HTTP mode)

**Server name**: `moon2dart`  
**Version**: `0.9.0`  
**Protocol**: MCP (Model Context Protocol) 2026-07-28  
**Transport**: STDIO (default) / HTTP (optional)

## Tools

### moon2dart_convert

Convert MoonBit source code to Dart code.

**Parameters**:
- `source` (string, required): MoonBit source code to convert
- `lib_name` (string, optional): Native library name for FFI (default: `libnative.so`)

**Example input**:
```moonbit
fn add(a : Int, b : Int) -> Int {
  a + b
}
```

**Example output**:
```dart
int add(int a, int b) {
  return a + b;
}
```

### moon2dart_reverse

Convert Dart source code to MoonBit code (reverse transpile).

**Parameters**:
- `source` (string, required): Dart source code to convert to MoonBit

**Example input**:
```dart
int add(int a, int b) {
  return a + b;
}
```

**Example output**:
```moonbit
fn add(a : Int, b : Int) -> Int {
  a + b
}
```

### moon2dart_flutter

Convert MoonBit source code to Flutter widget Dart code.

**Parameters**:
- `source` (string, required): MoonBit source code with Flutter widget definitions

**Example input**:
```moonbit
fn greeting() {
  Text("Hello, World!")
}
```

**Example output**:
```dart
import 'package:flutter/material.dart';

class Greeting extends StatelessWidget {
  const Greeting({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('Hello, World!');
  }
}
```

### moon2dart_analyze

Analyze MoonBit code structure and return AST summary.

**Parameters**:
- `source` (string, required): MoonBit source code to analyze

**Output format**: Text summary listing all declarations (fn, struct, enum, trait, impl, extern fn, async fn) with their signatures, plus token count.

### moon2dart_project

Scan a MoonBit project directory and return project structure summary.

**Parameters**:
- `dir` (string, required): MoonBit project directory path to scan

**Output format**: Text summary listing module name, version, package count, and source files per package.

### moon2dart_list_tools

List all available moon2dart MCP tools and their parameters.

**Parameters**: None

## Supported MoonBit Features

| Feature | MoonBit → Dart | Dart → MoonBit |
|---------|:-:|:-:|
| Basic types (Int, String, Bool, etc.) | ✅ | ✅ |
| Functions | ✅ | ✅ |
| Structs → Classes | ✅ | ✅ |
| Enums | ✅ | ✅ |
| Traits → Abstract Classes | ✅ | ✅ |
| Pattern Matching → Switch | ✅ | ✅ |
| derive(Debug, Eq, Compare) | ✅ | ✅ |
| async/await → Future/await | ✅ | ✅ |
| Option[T] → T? | ✅ | ✅ |
| Result[T,E] → sealed class | ✅ | ✅ |
| Generics | ✅ | ✅ |
| Closures → Arrow functions | ✅ | ✅ |
| extern "c" → dart:ffi | ✅ | ❌ |
| Flutter widgets | ✅ | ❌ |

## Limitations

- FFI (extern "c") is one-way only: MoonBit → Dart (dart:ffi)
- Flutter widget generation is one-way only: MoonBit → Dart
- Agent mode (--agent) is a placeholder; full posoco integration is planned for a future release
- File change detection and incremental update are in-progress features

## Installation

```bash
moon add walkzzz/moon2dart
```

## CLI Usage

```bash
moon2dart convert <file.mbt>                    # MoonBit → Dart
moon2dart convert <file.dart> --reverse         # Dart → MoonBit
moon2dart convert <file.mbt> --pure-only        # Skip FFI declarations
moon2dart convert <file.mbt> --lib <name>       # Specify native library
moon2dart project <dir> -o <output>             # Project-level conversion
moon2dart serve                                  # Start MCP server (STDIO)
moon2dart serve --http 8080                      # Start MCP server (HTTP)
moon2dart demo                                   # Demo mode
moon2dart help                                   # Show help
```