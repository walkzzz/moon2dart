///|
/// Dart 类型节点 — 表示 Dart 目标代码中的类型。
pub(all) enum DartType {
  DInt
  DInt64
  DDouble
  DBool
  DString
  DRune
  DVoid
  DList(DartType)
  DMap(DartType, DartType)
  DSet(DartType)
  DNullable(DartType)
  DCustom(String)
} derive(Eq, Compare, Debug)

///|
pub extend DartType with Eq::{equal, not_equal}

///|
pub extend DartType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartType with Debug::{to_repr}

///|
/// MoonBit 类型 → Dart 类型映射。
pub fn map_type(t : @ast.MoonType) -> DartType {
  match t {
    @ast.MInt => DInt
    @ast.MUInt => DInt
    @ast.MInt64 => DInt64
    @ast.MUInt64 => DInt64
    @ast.MDouble => DDouble
    @ast.MFloat => DDouble
    @ast.MBool => DBool
    @ast.MString => DString
    @ast.MChar => DRune
    @ast.MUnit => DVoid
    @ast.MArray(inner) => DList(map_type(inner))
    @ast.MMap(k, v) => DMap(map_type(k), map_type(v))
    @ast.MSet(inner) => DSet(map_type(inner))
    @ast.MOption(inner) => DNullable(map_type(inner))
    @ast.MResult(ok, err) =>
      DCustom("Result<\{emit_dart(map_type(ok))}, \{emit_dart(map_type(err))}>")
    @ast.MCustom(name) => DCustom(name)
  }
}

///|
/// Dart 类型 → Dart 代码字符串发射。
pub fn emit_dart(t : DartType) -> String {
  match t {
    DInt => "int"
    DInt64 => "int"
    DDouble => "double"
    DBool => "bool"
    DString => "String"
    DRune => "int"
    DVoid => "void"
    DList(inner) => "List<\{emit_dart(inner)}>"
    DMap(k, v) => "Map<\{emit_dart(k)}, \{emit_dart(v)}>"
    DSet(inner) => "Set<\{emit_dart(inner)}>"
    DNullable(inner) => "\{emit_dart(inner)}?"
    DCustom(name) => name
  }
}

///|
/// 便捷：MoonBit 类型 → Dart 类型字符串。
pub fn moon_to_dart_type(t : @ast.MoonType) -> String {
  emit_dart(map_type(t))
}

///|
/// 判断 MoonBit 类型是否可纯退化（无需混合模式）。
pub fn is_pure(t : @ast.MoonType) -> Bool {
  match t {
    @ast.MResult(_, _) => false
    @ast.MCustom(_) => false
    @ast.MArray(inner) => is_pure(inner)
    @ast.MMap(k, v) => is_pure(k) && is_pure(v)
    @ast.MSet(inner) => is_pure(inner)
    @ast.MOption(inner) => is_pure(inner)
    _ => true
  }
}

///|
/// 判断 MoonBit 类型是否需要自定义 Result 类型。
pub fn needs_result_type(t : @ast.MoonType) -> Bool {
  match t {
    @ast.MResult(_, _) => true
    @ast.MArray(inner) => needs_result_type(inner)
    @ast.MMap(k, v) => needs_result_type(k) || needs_result_type(v)
    @ast.MSet(inner) => needs_result_type(inner)
    @ast.MOption(inner) => needs_result_type(inner)
    _ => false
  }
}
