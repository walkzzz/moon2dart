# 最小转换示例 | Minimal Conversion Example

同一份 MoonBit 源码，双端运行结果一致：

```
main.mbt（MoonBit 源码）
    │
    ├─ moon run（MoonBit 工具链原生求值）────────────→ 42 / 3
    │
    └─ moon2dart convert --semantics wrapping → main.dart（Dart）
                                                  └─ dart run → 42 / 3
```

## 源码 | Source（`main.mbt`）

```moonbit
fn add(a : Int, b : Int) -> Int { a + b }

fn half(a : Int) -> Int { a / 2 }

fn main {
  println(add(40, 2))
  println(half(7))
}
```

## 转换 | Convert

```bash
moon run cmd/main --target native -- convert examples/hello/main.mbt --semantics wrapping > examples/hello/main.dart
```

生成的 Dart（自动包含 `mb32*` 回绕模拟层——`half(7)` 的整除经 `~/` 而非浮点 `/`，详见 [docs/golden_results.md](../docs/golden_results.md)）：

```dart
int mb32Add(int a, int b) => (a + b).toSigned(32);
int mb32Div(int a, int b) => (a == -2147483648 && b == -1 || b == 0)
    ? (throw StateError('integer overflow trap'))
    : ((a ~/ b).toSigned(32));

void main() {
  print(mb32Add(40, 2));   // 42
  print(mb32Div(7, 2));    // 3（MoonBit 整数除法语义，非 3.5）
}
```

## 运行对比 | Run Both Sides

```bash
moon run examples/hello --target native 2>/dev/null   # MoonBit 端（需为 examples/hello 配 moon.pkg 或改用 golden 包）
dart run examples/hello/main.dart                      # Dart 端 → 42 / 3
```

> 注意：本目录不参与 MoonBit 编译（无 moon.pkg，与 `scripts/golden_fixture/` 同理）；
> 双端逐行对比的完整设施见 [golden 包 + scripts/golden_check.mjs](../docs/golden_results.md)（CI 中由 `golden-dual-runtime` 作业自动执行）。

## 扩展场景 | What's Covered

- `Int` 32 位回绕（`2147483647 + 1 → -2147483648`）、截断除法/余数 —— 见 golden 14 行对比
- 嵌套 `Option[Option[T]]` 三分态辅助类、`Result[T,E]` sealed class —— 见 [docs/semantic_equivalence.md](../docs/semantic_equivalence.md)
- Flutter widget 转换（`Text(...)` → `Text(...)`、`fn main { MaterialApp(...) }` → `runApp`）—— `moon2dart project <dir> -o <out>` 一键生成 Flutter 工程
