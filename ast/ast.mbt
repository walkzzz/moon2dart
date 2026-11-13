///|
/// MoonBit 类型节点 — 表示 MoonBit 源码中的类型。
#derive(Eq, Compare, Debug)
pub(all) enum MoonType {
  MInt
  MUInt
  MInt64
  MUInt64
  MDouble
  MFloat
  MBool
  MString
  MChar
  MUnit
  MArray(MoonType)
  MMap(MoonType, MoonType)
  MSet(MoonType)
  MOption(MoonType)
  MResult(MoonType, MoonType)
  MFuture(MoonType)
  MTypeVar(String)
  MCustom(String)
}

///|
pub extend MoonType with Eq::{equal, not_equal}

///|
pub extend MoonType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonType with Debug::{to_repr}

///|
/// MoonBit 表达式节点（v0.1.0 子集）。
#derive(Eq, Compare, Debug)
pub(all) enum MoonExpr {
  EInt(Int32)
  EDouble(Double)
  EBool(Bool)
  EString(String)
  EVar(String)
  ECall(String, Array[MoonExpr])
  EBinOp(String, MoonExpr, MoonExpr)
  EIf(MoonExpr, MoonExpr, MoonExpr)
  EMatch(MoonExpr, Array[(MoonPattern, MoonExpr)])
  EAwait(MoonExpr)
  ELambda(Array[(String, MoonType)], MoonExpr)
}

///|
pub extend MoonExpr with Eq::{equal, not_equal}

///|
pub extend MoonExpr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonExpr with Debug::{to_repr}

///|
/// MoonBit 模式匹配节点。
#derive(Eq, Compare, Debug)
pub(all) enum MoonPattern {
  PVar(String)
  PInt(Int32)
  PString(String)
  PWild
  PCtor(String, Array[MoonPattern])
}

///|
pub extend MoonPattern with Eq::{equal, not_equal}

///|
pub extend MoonPattern with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonPattern with Debug::{to_repr}

///|
/// MoonBit 声明节点。
#derive(Eq, Compare, Debug)
pub(all) enum MoonDecl {
  DFn(String, Array[String], Array[(String, MoonType)], MoonType, MoonExpr)
  DAsyncFn(String, Array[String], Array[(String, MoonType)], MoonType, MoonExpr)
  DStruct(String, Array[String], Array[(String, MoonType)], Array[String])
  DEnum(String, Array[String])
  DTrait(String, Array[TraitMethod])
  DImpl(String, String, Array[ImplMethod])
  DExternFn(String, Array[(String, MoonType)], MoonType, String)
}

///|
pub extend MoonDecl with Eq::{equal, not_equal}

///|
pub extend MoonDecl with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonDecl with Debug::{to_repr}

///|
/// Trait 方法签名 — 方法名 + 参数列表 + 返回类型。
#derive(Eq, Compare, Debug)
pub(all) struct TraitMethod {
  name : String
  params : Array[(String, MoonType)]
  ret_type : MoonType
}

///|
pub extend TraitMethod with Eq::{equal, not_equal}

///|
pub extend TraitMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend TraitMethod with Debug::{to_repr}

///|
/// impl 方法实现 — 方法名 + 参数列表 + 返回类型 + 方法体。
#derive(Eq, Compare, Debug)
pub(all) struct ImplMethod {
  name : String
  params : Array[(String, MoonType)]
  ret_type : MoonType
  body : MoonExpr
}

///|
pub extend ImplMethod with Eq::{equal, not_equal}

///|
pub extend ImplMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend ImplMethod with Debug::{to_repr}

///|
/// MoonType → MoonBit 类型字符串表示。
pub fn MoonType::to_moon_string(self : MoonType) -> String {
  match self {
    MInt => "Int"
    MUInt => "UInt"
    MInt64 => "Int64"
    MUInt64 => "UInt64"
    MFloat => "Float"
    MDouble => "Double"
    MBool => "Bool"
    MString => "String"
    MChar => "Char"
    MUnit => "Unit"
    MArray(inner) => "Array[" + inner.to_moon_string() + "]"
    MMap(k, v) => "Map[" + k.to_moon_string() + ", " + v.to_moon_string() + "]"
    MSet(inner) => "Set[" + inner.to_moon_string() + "]"
    MOption(inner) => inner.to_moon_string() + "?"
    MResult(ok, err) =>
      "Result[" + ok.to_moon_string() + ", " + err.to_moon_string() + "]"
    MFuture(inner) => "Future[" + inner.to_moon_string() + "]"
    MCustom(name) => name
    MTypeVar(name) => name
  }
}

///|
/// 类型显示 trait — 统一类型到字符串的转换接口。
pub(open) trait TypeDisplay {
  fn to_display_string(Self) -> String
}

///|
pub impl TypeDisplay for MoonType with fn to_display_string(self) {
  self.to_moon_string()
}

///|
pub extend MoonType with TypeDisplay::{to_display_string}

///|
/// 递归检查类型中是否包含 Result。
pub fn MoonType::contains_result(self : MoonType) -> Bool {
  match self {
    MResult(_, _) => true
    MArray(inner) => inner.contains_result()
    MMap(k, v) => k.contains_result() || v.contains_result()
    MSet(inner) => inner.contains_result()
    MOption(inner) => inner.contains_result()
    MFuture(inner) => inner.contains_result()
    _ => false
  }
}

///|
/// 判断类型是否可纯转换（不含 Result 和 Custom）。
pub fn MoonType::is_pure(self : MoonType) -> Bool {
  match self {
    MResult(_, _) => false
    MCustom(_) => false
    MArray(inner) => inner.is_pure()
    MMap(k, v) => k.is_pure() && v.is_pure()
    MSet(inner) => inner.is_pure()
    MOption(inner) => inner.is_pure()
    MFuture(inner) => inner.is_pure()
    _ => true
  }
}

///|
/// 判断类型是否需要自定义 Result 类型定义。
pub fn MoonType::needs_result_type(self : MoonType) -> Bool {
  match self {
    MResult(_, _) => true
    MArray(inner) => inner.needs_result_type()
    MMap(k, v) => k.needs_result_type() || v.needs_result_type()
    MSet(inner) => inner.needs_result_type()
    MOption(inner) => inner.needs_result_type()
    MFuture(inner) => inner.needs_result_type()
    _ => false
  }
}
