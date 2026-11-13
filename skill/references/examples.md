# moon2dart Conversion Examples

## Example 1: Basic Function

**MoonBit input**:
```moonbit
fn add(a : Int, b : Int) -> Int {
  a + b
}

fn main {
  println(add(1, 2))
}
```

**Dart output**:
```dart
int add(int a, int b) {
  return a + b;
}

void main() {
  print(add(1, 2));
}
```

## Example 2: Struct with derive

**MoonBit input**:
```moonbit
struct Point derive(Debug, Eq, Compare) {
  x : Int
  y : Int
}

fn main {
  let p = Point { x: 1, y: 2 }
  println(p)
}
```

**Dart output**:
```dart
class Point {
  final int x;
  final int y;

  const Point({required this.x, required this.y});

  @override
  String toString() => 'Point(x: $x, y: $y)';

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  int compareTo(Point other) {
    if (x != other.x) return x.compareTo(other.x);
    return y.compareTo(other.y);
  }
}

void main() {
  final p = Point(x: 1, y: 2);
  print(p);
}
```

## Example 3: Enum with Pattern Matching

**MoonBit input**:
```moonbit
enum Color {
  Red
  Green
  Blue
}

fn to_hex(c : Color) -> String {
  match c {
    Red => "#FF0000"
    Green => "#00FF00"
    Blue => "#0000FF"
  }
}
```

**Dart output**:
```dart
enum Color { red, green, blue }

String toHex(Color c) {
  return switch (c) {
    Color.red => '#FF0000',
    Color.green => '#00FF00',
    Color.blue => '#0000FF',
  };
}
```

## Example 4: Async/Await

**MoonBit input**:
```moonbit
async fn fetch_data(url : String) -> String {
  // ... fetch implementation
  "data"
}

async fn main {
  let data = await fetch_data("https://example.com")
  println(data)
}
```

**Dart output**:
```dart
Future<String> fetchData(String url) async {
  // ... fetch implementation
  return 'data';
}

Future<void> main() async {
  final data = await fetchData('https://example.com');
  print(data);
}
```

## Example 5: Option and Result

**MoonBit input**:
```moonbit
fn divide(a : Int, b : Int) -> Result[Int, String] {
  if b == 0 {
    Err("division by zero")
  } else {
    Ok(a / b)
  }
}

fn safe_divide(a : Int, b : Int) -> Option[Int] {
  match divide(a, b) {
    Ok(v) => Some(v)
    Err(_) => None
  }
}
```

**Dart output**:
```dart
sealed class Result<T, E> {
  const Result();
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}

Result<int, String> divide(int a, int b) {
  if (b == 0) {
    return Err('division by zero');
  } else {
    return Ok(a ~/ b);
  }
}

int? safeDivide(int a, int b) {
  switch (divide(a, b)) {
    case Ok(:final value):
      return value;
    case Err():
      return null;
  }
}
```

## Example 6: Flutter Widget

**MoonBit input**:
```moonbit
fn counter(count : Int) {
  Column(
    Text("Count: \{count}"),
    ElevatedButton(
      fn() { println("increment") },
      Text("Increment"),
    ),
  )
}

fn main {
  MaterialApp(
    Scaffold(
      AppBar(Text("Counter App")),
      counter(0),
    ),
  )
}
```

**Dart output**:
```dart
import 'package:flutter/material.dart';

class Counter extends StatelessWidget {
  final int count;
  const Counter({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () { print('increment'); },
          child: Text('Increment'),
        ),
      ],
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Counter App')),
        body: Counter(count: 0),
      ),
    ),
  );
}
```

## Example 7: FFI (extern "c")

**MoonBit input**:
```moonbit
extern "c" fn c_add(a : Int, b : Int) -> Int = "c_add"

fn main {
  println(c_add(1, 2))
}
```

**Dart output**:
```dart
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef _CAddNative = Int32 Function(Int32 a, Int32 b);
typedef _CAddDart = int Function(int a, int b);

final _dylib = DynamicLibrary.open('libnative.so');
final _c_add = _dylib.lookupFunction<_CAddNative, _CAddDart>('c_add');

int c_add(int a, int b) {
  return _c_add(a, b);
}

void main() {
  print(c_add(1, 2));
}
```