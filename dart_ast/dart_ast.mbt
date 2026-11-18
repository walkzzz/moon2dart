///|
/// Dart 类型节点 — 表示 Dart 源码中的类型 | Dart type node — represents types in Dart source
#derive(Eq, Compare, Debug)
pub(all) enum DartType {
  DInt // int | Dart int
  DDouble // double | Dart double
  DBool // bool | Dart bool
  DString // String | Dart String
  DRune // int (rune) | Dart int (rune)
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
/// Dart 表达式节点 — 表示 Dart 源码中的表达式 | Dart expression node — represents expressions in Dart source
#derive(Eq, Compare, Debug)
pub(all) enum DartExpr {
  DIntLit(Int32) // 整数字面量 | Integer literal
  DDoubleLit(Double) // 浮点字面量 | Double literal
  DBoolLit(Bool) // 布尔字面量 | Boolean literal
  DStringLit(String) // 字符串字面量 | String literal
  DVarRef(String) // 变量引用 | Variable reference
  DMethodCall(String, String, Array[DartExpr]) // 方法调用 | Method call
  DFunctionCall(String, Array[DartExpr]) // 函数调用 | Function call
  DBinOp(String, DartExpr, DartExpr) // 二元运算 | Binary operation
  DIfExpr(DartExpr, DartExpr, DartExpr) // 三元条件 | Ternary conditional
  DSwitchExpr(DartExpr, Array[(DartPattern, DartExpr)]) // switch 表达式 | Switch expression
  DAwaitExpr(DartExpr) // await 表达式 | Await expression
  DArrowFn(Array[String], DartExpr) // 箭头函数 | Arrow function
  DNullLit // null 字面量 | Null literal
}

///|
pub extend DartExpr with Eq::{equal, not_equal}

///|
pub extend DartExpr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartExpr with Debug::{to_repr}

///|
/// Dart 模式节点 — 表示 Dart 3 switch expression 中的模式 | Dart pattern node — represents patterns in Dart 3 switch expression
#derive(Eq, Compare, Debug)
pub(all) enum DartPattern {
  DPVar(String) // 变量绑定 | Variable binding
  DPInt(Int32) // 整数模式 | Integer pattern
  DPString(String) // 字符串模式 | String pattern
  DPWild // 通配符 _ | Wildcard _
  DPNull // null 模式 | Null pattern
  DPCtor(String, Array[DartPattern]) // 构造器模式 | Constructor pattern
}

///|
pub extend DartPattern with Eq::{equal, not_equal}

///|
pub extend DartPattern with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartPattern with Debug::{to_repr}

///|
/// Dart 声明节点 — 表示 Dart 源码中的顶层声明 | Dart declaration node — represents top-level declarations in Dart source
#derive(Eq, Compare, Debug)
pub(all) enum DartDecl {
  DTopFn(String, Array[String], Array[(String, DartType)], DartType, DartExpr) // 顶层函数 | Top-level function
  // 异步顶层函数 | Async top-level function
  DAsyncTopFn(
    String,
    Array[String],
    Array[(String, DartType)],
    DartType,
    DartExpr,
  )
  DClass(String, Array[String], Array[(String, DartType)], Array[DartMethod]) // 类 | Class
  DSealedClass(String, Array[DartVariant]) // sealed 类 | Sealed class
  DAbstractClass(String, Array[DartMethod]) // 抽象类 | Abstract class
}

///|
pub extend DartDecl with Eq::{equal, not_equal}

///|
pub extend DartDecl with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartDecl with Debug::{to_repr}

///|
/// Dart 方法 — 表示 class 中的方法定义 | Dart method — represents a method definition in a class
#derive(Eq, Compare, Debug)
pub(all) struct DartMethod {
  name : String
  params : Array[(String, DartType)]
  ret_type : DartType
  body : DartExpr
  is_async : Bool
}

///|
pub extend DartMethod with Eq::{equal, not_equal}

///|
pub extend DartMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartMethod with Debug::{to_repr}

///|
/// Dart 变体 — 表示 sealed class 的子类 | Dart variant — represents a subclass of a sealed class
#derive(Eq, Compare, Debug)
pub(all) struct DartVariant {
  name : String
  fields : Array[(String, DartType)]
}

///|
pub extend DartVariant with Eq::{equal, not_equal}

///|
pub extend DartVariant with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend DartVariant with Debug::{to_repr}

///|
/// DartType → MoonBit 类型字符串表示 | DartType to MoonBit type string representation
#as_free_fn(dart_type_to_moon)
pub fn DartType::to_moon_string(self : DartType) -> String {
  match self {
    DInt => "Int"
    DDouble => "Double"
    DBool => "Bool"
    DString => "String"
    DRune => "Char"
    DVoid => "Unit"
    DList(inner) => "Array[" + inner.to_moon_string() + "]"
    DMap(k, v) => "Map[" + k.to_moon_string() + ", " + v.to_moon_string() + "]"
    DSet(inner) => "Set[" + inner.to_moon_string() + "]"
    DNullable(inner) => inner.to_moon_string() + "?"
    DFuture(inner) => "Future[" + inner.to_moon_string() + "]"
    DResult(ok, err) =>
      "Result[" + ok.to_moon_string() + ", " + err.to_moon_string() + "]"
    DCustom(name) => name
  }
}
