///|
/// Dart 类型节点 — 表示 Dart 目标代码中的类型。
#derive(Eq, Compare, Debug)
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
  DFuture(DartType)
  DCustom(String)
}

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
    @ast.MFuture(inner) => DFuture(map_type(inner))
    @ast.MTypeVar(name) => DCustom(name)
    @ast.MResult(ok, err) =>
      DCustom(
        "Result<\{map_type(ok).to_dart_string()}, \{map_type(err).to_dart_string()}>",
      )
    @ast.MCustom(name) => DCustom(name)
  }
}

///|
/// Dart 类型 → Dart 代码字符串发射（方法形式）。
#as_free_fn(emit_dart)
pub fn DartType::to_dart_string(self : DartType) -> String {
  match self {
    DInt => "int"
    DInt64 => "int"
    DDouble => "double"
    DBool => "bool"
    DString => "String"
    DRune => "int"
    DVoid => "void"
    DList(inner) => "List<\{inner.to_dart_string()}>"
    DMap(k, v) => "Map<\{k.to_dart_string()}, \{v.to_dart_string()}>"
    DSet(inner) => "Set<\{inner.to_dart_string()}>"
    DNullable(inner) => "\{inner.to_dart_string()}?"
    DFuture(inner) => "Future<\{inner.to_dart_string()}>"
    DCustom(name) => name
  }
}

///|
pub impl @ast.TypeDisplay for DartType with fn to_display_string(self) {
  self.to_dart_string()
}

///|
pub extend DartType with @ast.TypeDisplay::{to_display_string}

///|
/// 便捷：MoonBit 类型 → Dart 类型字符串。
pub fn moon_to_dart_type(t : @ast.MoonType) -> String {
  map_type(t).to_dart_string()
}

///|

///|
/// MoonBit 类型 → Dart ffi Native 类型字符串（用于 typedef Native）。
pub fn ffi_native_type(t : @ast.MoonType) -> String {
  match t {
    @ast.MInt => "Int32"
    @ast.MUInt => "Uint32"
    @ast.MInt64 => "Int64"
    @ast.MUInt64 => "Uint64"
    @ast.MDouble => "Double"
    @ast.MFloat => "Float"
    @ast.MBool => "Bool"
    @ast.MString => "Pointer<Utf8>"
    @ast.MChar => "Uint8"
    @ast.MUnit => "Void"
    @ast.MArray(_) => "Pointer<Opaque>"
    @ast.MMap(_, _) => "Pointer<Opaque>"
    @ast.MSet(_) => "Pointer<Opaque>"
    @ast.MOption(_) => "Pointer<Opaque>"
    @ast.MResult(_, _) => "Pointer<Opaque>"
    @ast.MFuture(_) => "Pointer<Opaque>"
    @ast.MTypeVar(_) => "Pointer<Opaque>"
    @ast.MCustom(_) => "Pointer<Opaque>"
  }
}

///|
/// MoonBit 类型 → Dart ffi Dart 侧类型字符串（用于 typedef Dart）。
pub fn ffi_dart_type(t : @ast.MoonType) -> String {
  match t {
    @ast.MInt => "int"
    @ast.MUInt => "int"
    @ast.MInt64 => "int"
    @ast.MUInt64 => "int"
    @ast.MDouble => "double"
    @ast.MFloat => "double"
    @ast.MBool => "bool"
    @ast.MString => "Pointer<Utf8>"
    @ast.MChar => "int"
    @ast.MUnit => "void"
    @ast.MArray(_) => "Pointer<Opaque>"
    @ast.MMap(_, _) => "Pointer<Opaque>"
    @ast.MSet(_) => "Pointer<Opaque>"
    @ast.MOption(_) => "Pointer<Opaque>?"
    @ast.MResult(_, _) => "Pointer<Opaque>"
    @ast.MFuture(_) => "Pointer<Opaque>"
    @ast.MTypeVar(_) => "Pointer<Opaque>"
    @ast.MCustom(_) => "Pointer<Opaque>"
  }
}
