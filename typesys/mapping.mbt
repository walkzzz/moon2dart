///|
/// Dart 类型节点 — 表示 Dart 目标代码中的类型 | Dart type node — represents types in Dart target code
#derive(Eq, Compare, Debug)
pub(all) enum DartType {
  DInt // int | Dart int
  DInt64 // int (64-bit) | Dart int (64-bit)
  DDouble // double | Dart double
  DBool // bool | Dart bool
  DString // String | Dart String
  DRune // int (rune) | Dart int (rune representation)
  DVoid // void | Dart void
  DList(DartType) // List<T> | Dart List<T>
  DMap(DartType, DartType) // Map<K,V> | Dart Map<K,V>
  DSet(DartType) // Set<T> | Dart Set<T>
  DNullable(DartType) // T? | Dart nullable T?
  DFuture(DartType) // Future<T> | Dart Future<T>
  DResult(DartType, DartType) // Result<T,E> | Dart Result<T,E>
  DCustom(String) // 自定义类型名 | Custom type name
}

///|
pub extend DartType with Eq::{equal, not_equal}

///|
pub extend DartType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartType with Debug::{to_repr}

///|
/// 将 MoonBit 类型映射为 Dart 类型 | Map a MoonBit type to its Dart equivalent
/// 单层 Option 映射为 DNullable（T?），嵌套 Option 映射为 DNullable(DNullable(inner)) | Single-layer Option maps to DNullable (T?), nested Option maps to DNullable(DNullable(inner))
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
    @ast.MOption(inner) =>
      if @ast.is_nested_option(@ast.MOption(inner)) {
        // inner is MOption(inner_inner), so we directly map inner_inner
        // to produce DNullable(DNullable(map_type(inner_inner)))
        match inner {
          @ast.MOption(inner_inner) =>
            DNullable(DNullable(map_type(inner_inner)))
          _ => DNullable(map_type(inner))
        }
      } else {
        DNullable(map_type(inner))
      }
    @ast.MFuture(inner) => DFuture(map_type(inner))
    @ast.MTypeVar(name) => DCustom(name)
    @ast.MResult(ok, err) => DResult(map_type(ok), map_type(err))
    @ast.MCustom(name) => DCustom(name)
  }
}

///|
/// Dart 类型 → Dart 代码字符串发射（方法形式） | DartType to Dart code string emission (method form)
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
    DResult(ok, err) =>
      "Result<\{ok.to_dart_string()}, \{err.to_dart_string()}>"
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
/// 便捷：MoonBit 类型 → Dart 类型字符串 | Convenience: MoonBit type to Dart type string
pub fn moon_to_dart_type(t : @ast.MoonType) -> String {
  map_type(t).to_dart_string()
}

///|
/// 检测声明数组是否需要生成 Option 辅助类（存在嵌套 Option 使用时需要） | Check if declarations need the Option auxiliary class (needed when nested Option usage exists)
pub fn needs_option_class(decls : Array[@ast.MoonDecl]) -> Bool {
  @ast.has_nested_option_in_decls(decls)
}

///|
/// 语义等价等级 — L1 完全等价 / L2 结构等价 / L3 受限 / L4 不等价 | Semantic equivalence level — L1 full / L2 structural / L3 constrained / L4 inequivalent
#derive(Eq, Compare, Debug)
pub(all) enum SemanticLevel {
  L1 // 完全等价 | Fully equivalent
  L2 // 结构等价 | Structurally equivalent
  L3 // 受限（值域有损）| Constrained (value domain loss)
  L4 // 不等价 | Inequivalent
}

///|
pub extend SemanticLevel with Eq::{equal, not_equal}

///|
pub extend SemanticLevel with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend SemanticLevel with Debug::{to_repr}

///|
/// 判断 MoonBit 类型的语义等价等级 | Determine the semantic equivalence level of a MoonBit type
pub fn semantic_level(t : @ast.MoonType) -> SemanticLevel {
  match t {
    @ast.MUInt => L3
    @ast.MFloat => L3
    @ast.MChar => L3
    _ => if has_l4_type(t) { L4 } else if has_l3_type(t) { L3 } else { L1 }
  }
}

///|
/// 递归检查类型中是否包含 L4 类型（FFI/Channel 等无 Dart 对应） | Recursively check if type contains L4 types (FFI/Channel etc. with no Dart equivalent)
fn has_l4_type(t : @ast.MoonType) -> Bool {
  match t {
    @ast.MCustom(name) =>
      name == "ForeignFunction" || name == "Channel" || name == "Spawn"
    @ast.MArray(inner) => has_l4_type(inner)
    @ast.MMap(k, v) => has_l4_type(k) || has_l4_type(v)
    @ast.MSet(inner) => has_l4_type(inner)
    @ast.MOption(inner) => has_l4_type(inner)
    @ast.MResult(ok, err) => has_l4_type(ok) || has_l4_type(err)
    @ast.MFuture(inner) => has_l4_type(inner)
    _ => false
  }
}

///|
/// 递归检查类型中是否包含 L3 类型（UInt/Float/Char 值域有损） | Recursively check if type contains L3 types (UInt/Float/Char with value domain loss)
fn has_l3_type(t : @ast.MoonType) -> Bool {
  match t {
    @ast.MUInt => true
    @ast.MFloat => true
    @ast.MChar => true
    @ast.MArray(inner) => has_l3_type(inner)
    @ast.MMap(k, v) => has_l3_type(k) || has_l3_type(v)
    @ast.MSet(inner) => has_l3_type(inner)
    @ast.MOption(inner) => has_l3_type(inner)
    @ast.MResult(ok, err) => has_l3_type(ok) || has_l3_type(err)
    @ast.MFuture(inner) => has_l3_type(inner)
    _ => false
  }
}

///|
/// strict 模式映射 — L4 类型 raise 错误 | Strict mode mapping — L4 types raise error
pub fn map_type_strict(t : @ast.MoonType) -> DartType raise @ast.Moon2DartError {
  let level = semantic_level(t)
  match level {
    L4 =>
      raise @ast.Moon2DartError::TypeError(
        "[L4-INEQUIVALENT] Type \{t.to_moon_string()} has no Dart equivalent and is rejected in strict mode",
      )
    L3 => {
      let mapped = map_type(t)
      mapped
    }
    _ => map_type(t)
  }
}

///|
/// 往返断言 — 验证 MoonBit 类型经正向映射再反向转换后恢复一致 | Round-trip assertion — verify MoonBit type restores after forward then reverse mapping
pub fn assert_round_trip(moon_type : @ast.MoonType) -> Bool {
  let dart_type = map_type(moon_type)
  let dart_ast_type = convert_to_dart_ast_type(dart_type)
  // Use to_moon_string from dart_ast for reverse type string
  let recovered_str = dart_ast_type.to_moon_string()
  // 比较恢复后的类型字符串是否一致
  recovered_str == moon_type.to_moon_string()
}

///|
/// 值域断言 — 验证语义等价等级与映射行为一致 | Value domain assertion — verify semantic level matches mapping behavior
pub fn assert_value_domain(
  moon_type : @ast.MoonType,
  level : SemanticLevel,
) -> Bool {
  match level {
    L1 =>
      // L1 类型：往返恢复一致
      assert_round_trip(moon_type)
    L2 => {
      // L2 类型：结构保留但值域有差异
      let dart_type = map_type(moon_type)
      let dart_str = emit_dart(dart_type)
      dart_str.length() > 0
    }
    L3 => {
      // L3 类型：映射可用但语义有损
      let dart_type = map_type(moon_type)
      let s_level = semantic_level(moon_type)
      s_level == L3 && !(dart_type is DCustom(_))
    }
    L4 => {
      // L4 类型：strict 模式应拒绝
      let mut raised = false
      try {
        let _ = map_type_strict(moon_type)
      } catch {
        @ast.Moon2DartError::TypeError(_) => raised = true
        _ => ()
      }
      raised
    }
  }
}

///|
/// 将 typesys::DartType 转换为 dart_ast::DartType（用于反向映射测试） | Convert typesys::DartType to dart_ast::DartType (for reverse mapping tests)
fn convert_to_dart_ast_type(t : DartType) -> @dart_ast.DartType {
  match t {
    DInt => @dart_ast.DInt
    DInt64 => @dart_ast.DInt
    DDouble => @dart_ast.DDouble
    DBool => @dart_ast.DBool
    DString => @dart_ast.DString
    DRune => @dart_ast.DRune
    DVoid => @dart_ast.DVoid
    DList(inner) => @dart_ast.DList(convert_to_dart_ast_type(inner))
    DMap(k, v) =>
      @dart_ast.DMap(convert_to_dart_ast_type(k), convert_to_dart_ast_type(v))
    DSet(inner) => @dart_ast.DSet(convert_to_dart_ast_type(inner))
    DNullable(inner) => @dart_ast.DNullable(convert_to_dart_ast_type(inner))
    DFuture(inner) => @dart_ast.DFuture(convert_to_dart_ast_type(inner))
    DResult(ok, err) =>
      @dart_ast.DResult(
        convert_to_dart_ast_type(ok),
        convert_to_dart_ast_type(err),
      )
    DCustom(name) => @dart_ast.DCustom(name)
  }
}

///|

///|
/// MoonBit 类型 → Dart ffi Native 类型字符串（用于 typedef Native） | MoonBit type to Dart FFI native type string (for Native typedef)
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
/// MoonBit 类型 → Dart ffi Dart 侧类型字符串（用于 typedef Dart） | MoonBit type to Dart FFI Dart-side type string (for Dart typedef)
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
