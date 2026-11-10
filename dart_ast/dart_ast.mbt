///|
/// Dart 类型节点 — 表示 Dart 源码中的类型。
pub(all) enum DartType {
  DInt
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
} derive(Eq, Compare, Debug)

///|
pub extend DartType with Eq::{equal, not_equal}

///|
pub extend DartType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartType with Debug::{to_repr}

///|
/// Dart 表达式节点 — 表示 Dart 源码中的表达式。
pub(all) enum DartExpr {
  DIntLit(Int32)
  DDoubleLit(Double)
  DBoolLit(Bool)
  DStringLit(String)
  DVarRef(String)
  DMethodCall(String, String, Array[DartExpr])
  DFunctionCall(String, Array[DartExpr])
  DBinOp(String, DartExpr, DartExpr)
  DIfExpr(DartExpr, DartExpr, DartExpr)
  DSwitchExpr(DartExpr, Array[(DartPattern, DartExpr)])
  DAwaitExpr(DartExpr)
  DArrowFn(Array[String], DartExpr)
  DNullLit
} derive(Eq, Compare, Debug)

///|
pub extend DartExpr with Eq::{equal, not_equal}

///|
pub extend DartExpr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartExpr with Debug::{to_repr}

///|
/// Dart 模式节点 — 表示 Dart 3 switch expression 中的模式。
pub(all) enum DartPattern {
  DPVar(String)
  DPInt(Int32)
  DPString(String)
  DPWild
  DPNull
  DPCtor(String, Array[DartPattern])
} derive(Eq, Compare, Debug)

///|
pub extend DartPattern with Eq::{equal, not_equal}

///|
pub extend DartPattern with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartPattern with Debug::{to_repr}

///|
/// Dart 声明节点 — 表示 Dart 源码中的顶层声明。
pub(all) enum DartDecl {
  DTopFn(String, Array[String], Array[(String, DartType)], DartType, DartExpr)
  DAsyncTopFn(
    String,
    Array[String],
    Array[(String, DartType)],
    DartType,
    DartExpr
  )
  DClass(String, Array[String], Array[(String, DartType)], Array[DartMethod])
  DSealedClass(String, Array[DartVariant])
  DAbstractClass(String, Array[DartMethod])
} derive(Eq, Compare, Debug)

///|
pub extend DartDecl with Eq::{equal, not_equal}

///|
pub extend DartDecl with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartDecl with Debug::{to_repr}

///|
/// Dart 方法 — 表示 class 中的方法定义。
pub(all) struct DartMethod {
  name : String
  params : Array[(String, DartType)]
  ret_type : DartType
  body : DartExpr
  is_async : Bool
} derive(Eq, Compare, Debug)

///|
pub extend DartMethod with Eq::{equal, not_equal}

///|
pub extend DartMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartMethod with Debug::{to_repr}

///|
/// Dart 变体 — 表示 sealed class 的子类。
pub(all) struct DartVariant {
  name : String
  fields : Array[(String, DartType)]
} derive(Eq, Compare, Debug)

///|
pub extend DartVariant with Eq::{equal, not_equal}

///|
pub extend DartVariant with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartVariant with Debug::{to_repr}
