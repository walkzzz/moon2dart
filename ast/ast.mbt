///|
/// MoonBit 类型节点 — 表示 MoonBit 源码中的类型。
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
  MCustom(String)
} derive(Eq, Compare, Debug)

///|
pub extend MoonType with Eq::{equal, not_equal}

///|
pub extend MoonType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonType with Debug::{to_repr}

///|
/// MoonBit 表达式节点（v0.1.0 子集）。
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
} derive(Eq, Compare, Debug)

///|
pub extend MoonExpr with Eq::{equal, not_equal}

///|
pub extend MoonExpr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonExpr with Debug::{to_repr}

///|
/// MoonBit 模式匹配节点。
pub(all) enum MoonPattern {
  PVar(String)
  PInt(Int32)
  PString(String)
  PWild
  PCtor(String, Array[MoonPattern])
} derive(Eq, Compare, Debug)

///|
pub extend MoonPattern with Eq::{equal, not_equal}

///|
pub extend MoonPattern with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonPattern with Debug::{to_repr}

///|
/// MoonBit 声明节点。
pub(all) enum MoonDecl {
  DFn(String, Array[(String, MoonType)], MoonType, MoonExpr)
  DStruct(String, Array[(String, MoonType)])
  DEnum(String, Array[String])
  DTrait(String, Array[TraitMethod])
} derive(Eq, Compare, Debug)

///|
pub extend MoonDecl with Eq::{equal, not_equal}

///|
pub extend MoonDecl with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonDecl with Debug::{to_repr}

///|
/// Trait 方法签名 — 方法名 + 参数列表 + 返回类型。
pub(all) struct TraitMethod {
  name : String
  params : Array[(String, MoonType)]
  ret_type : MoonType
} derive(Eq, Compare, Debug)

///|
pub extend TraitMethod with Eq::{equal, not_equal}

///|
pub extend TraitMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend TraitMethod with Debug::{to_repr}
