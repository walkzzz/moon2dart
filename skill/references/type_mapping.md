# moon2dart Type Mapping Reference

## MoonBit → Dart Type Mapping

| MoonBit Type | Dart Type | Notes |
|-------------|-----------|-------|
| `Int` | `int` | 32-bit signed integer |
| `UInt` | `int` | 32-bit unsigned integer |
| `Int64` | `int` | 64-bit signed integer |
| `UInt64` | `int` | 64-bit unsigned integer |
| `Double` | `double` | 64-bit floating point |
| `Float` | `double` | Dart has no 32-bit float |
| `Bool` | `bool` | Boolean |
| `String` | `String` | String |
| `Char` | `String` | Dart has no char type |
| `Unit` | `void` | Unit type |
| `Array[T]` | `List<T>` | Mutable list |
| `Map[K,V]` | `Map<K,V>` | Key-value map |
| `Set[T]` | `Set<T>` | Set |
| `Option[T]` | `T?` | Nullable type |
| `Result[T,E]` | `sealed class Result<T,E>` | Ok/Err pattern |
| `Future[T]` | `Future<T>` | Async result |
| `T` (type var) | `T` | Generic type parameter |
| `CustomType` | `CustomType` | User-defined type |

## Dart → MoonBit Type Mapping (Reverse)

| Dart Type | MoonBit Type | Notes |
|-----------|-------------|-------|
| `int` | `Int` | Default to 32-bit |
| `double` | `Double` | Floating point |
| `bool` | `Bool` | Boolean |
| `String` | `String` | String |
| `void` | `Unit` | Unit type |
| `List<T>` | `Array[T]` | Mutable array |
| `Map<K,V>` | `Map[K,V]` | Key-value map |
| `Set<T>` | `Set[T]` | Set |
| `T?` | `Option[T]` | Nullable → Option |
| `Future<T>` | `Future[T]` | Async result |
| `class` | `struct` | Class → Struct |
| `abstract class` | `trait` | Abstract → Trait |
| `sealed class` | `enum` | Sealed → Enum |
| `enum` | `enum` | Enum → Enum |