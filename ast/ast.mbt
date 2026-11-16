///|
/// MoonBit 类型节点 — 表示 MoonBit 源码中的类型 | MoonBit type node — represents types in MoonBit source
#derive(Eq, Compare, Debug)
pub(all) enum MoonType {
  MInt // Int | MoonBit Int
  MUInt // UInt | MoonBit UInt
  MInt64 // Int64 | MoonBit Int64
  MUInt64 // UInt64 | MoonBit UInt64
  MDouble // Double | MoonBit Double
  MFloat // Float | MoonBit Float
  MBool // Bool | MoonBit Bool
  MString // String | MoonBit String
  MChar // Char | MoonBit Char
  MUnit // Unit | MoonBit Unit
  MArray(MoonType) // Array[T] | MoonBit Array[T]
  MMap(MoonType, MoonType) // Map[K,V] | MoonBit Map[K,V]
  MSet(MoonType) // Set[T] | MoonBit Set[T]
  MOption(MoonType) // Option[T] / T? | MoonBit Option[T]
  MResult(MoonType, MoonType) // Result[T,E] | MoonBit Result[T,E]
  MFuture(MoonType) // Future[T] | MoonBit Future[T]
  MTypeVar(String) // 泛型类型变量 | Generic type variable
  MCustom(String) // 自定义类型名 | Custom type name
}

///|
pub extend MoonType with Eq::{equal, not_equal}

///|
pub extend MoonType with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonType with Debug::{to_repr}

///|
/// MoonBit 表达式节点（v0.1.0 子集）| MoonBit expression node (v0.1.0 subset)
#derive(Eq, Compare, Debug)
pub(all) enum MoonExpr {
  EInt(Int32) // 整数字面量 | Integer literal
  EDouble(Double) // 浮点字面量 | Double literal
  EBool(Bool) // 布尔字面量 | Boolean literal
  EString(String) // 字符串字面量 | String literal
  EVar(String) // 变量引用 | Variable reference
  ECall(String, Array[MoonExpr]) // 函数调用 | Function call
  EBinOp(String, MoonExpr, MoonExpr) // 二元运算 | Binary operation
  EIf(MoonExpr, MoonExpr, MoonExpr) // 三元条件 | Ternary conditional
  EMatch(MoonExpr, Array[(MoonPattern, MoonExpr)]) // match 表达式 | Match expression
  EAwait(MoonExpr) // await 表达式 | Await expression
  ELambda(Array[(String, MoonType)], MoonExpr) // 闭包/lambda | Closure/lambda
}

///|
pub extend MoonExpr with Eq::{equal, not_equal}

///|
pub extend MoonExpr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonExpr with Debug::{to_repr}

///|
/// MoonBit 模式匹配节点 | MoonBit pattern matching node
#derive(Eq, Compare, Debug)
pub(all) enum MoonPattern {
  PVar(String) // 变量绑定 | Variable binding
  PInt(Int32) // 整数模式 | Integer pattern
  PString(String) // 字符串模式 | String pattern
  PWild // 通配符 _ | Wildcard _
  PCtor(String, Array[MoonPattern]) // 构造器模式 | Constructor pattern
}

///|
pub extend MoonPattern with Eq::{equal, not_equal}

///|
pub extend MoonPattern with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonPattern with Debug::{to_repr}

///|
/// MoonBit 声明节点 | MoonBit declaration node
#derive(Eq, Compare, Debug)
pub(all) enum MoonDecl {
  DFn(String, Array[String], Array[(String, MoonType)], MoonType, MoonExpr) // 普通函数 | Regular function
  DAsyncFn(String, Array[String], Array[(String, MoonType)], MoonType, MoonExpr) // 异步函数 | Async function
  DStruct(String, Array[String], Array[(String, MoonType)], Array[String]) // 结构体 | Struct
  DEnum(String, Array[String]) // 枚举 | Enum
  DTrait(String, Array[TraitMethod]) // trait 声明 | Trait declaration
  DImpl(String, String, Array[ImplMethod]) // impl 实现 | Impl block
  DExternFn(String, Array[(String, MoonType)], MoonType, String) // extern "c" FFI | extern "c" FFI
}

///|
pub extend MoonDecl with Eq::{equal, not_equal}

///|
pub extend MoonDecl with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend MoonDecl with Debug::{to_repr}

///|
/// Trait 方法签名 — 方法名 + 参数列表 + 返回类型 | Trait method signature — name + params + return type
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
/// impl 方法实现 — 方法名 + 参数列表 + 返回类型 + 方法体 | Impl method — name + params + return type + body
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
/// MoonType → MoonBit 类型字符串表示 | MoonType to MoonBit type string representation
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
/// 类型显示 trait — 统一类型到字符串的转换接口 | Type display trait — unified type-to-string conversion interface
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
/// 递归检查类型中是否包含 Result | Recursively check if type contains Result
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
/// 判断类型是否可纯转换（不含 Result 和 Custom） | Check if type is purely transpilable (no Result or Custom)
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
/// 判断类型是否需要自定义 Result 类型定义 | Check if type requires a custom Result type definition
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

///|
/// 检测类型是否为嵌套 Option（MOption(MOption(_))）| Check if type is a nested Option (MOption(MOption(_)))
pub fn is_nested_option(t : MoonType) -> Bool {
  match t {
    MOption(inner) =>
      match inner {
        MOption(_) => true
        _ => false
      }
    _ => false
  }
}

///|
/// 遍历声明列表，检测是否使用了嵌套 Option 类型 | Scan declaration list for nested Option type usage
pub fn has_nested_option_in_decls(decls : Array[MoonDecl]) -> Bool {
  for d in decls {
    match d {
      DFn(_, _, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if contains_nested_option(t) {
            return true
          }
        }
        if contains_nested_option(ret) {
          return true
        }
      }
      DAsyncFn(_, _, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if contains_nested_option(t) {
            return true
          }
        }
        if contains_nested_option(ret) {
          return true
        }
      }
      DStruct(_, _, fields, _) =>
        for f in fields {
          let (_, t) = f
          if contains_nested_option(t) {
            return true
          }
        }
      DTrait(_, methods) =>
        for m in methods {
          for p in m.params {
            let (_, t) = p
            if contains_nested_option(t) {
              return true
            }
          }
          if contains_nested_option(m.ret_type) {
            return true
          }
        }
      DImpl(_, _, methods) =>
        for m in methods {
          for p in m.params {
            let (_, t) = p
            if contains_nested_option(t) {
              return true
            }
          }
          if contains_nested_option(m.ret_type) {
            return true
          }
        }
      DExternFn(_, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if contains_nested_option(t) {
            return true
          }
        }
        if contains_nested_option(ret) {
          return true
        }
      }
      DEnum(_, _) => ()
    }
  }
  false
}

///|
/// 递归检查类型树中是否存在嵌套 Option | Recursively check if type tree contains nested Option
fn contains_nested_option(t : MoonType) -> Bool {
  if is_nested_option(t) {
    return true
  }
  match t {
    MArray(inner) => contains_nested_option(inner)
    MMap(k, v) => contains_nested_option(k) || contains_nested_option(v)
    MSet(inner) => contains_nested_option(inner)
    MOption(inner) => contains_nested_option(inner)
    MResult(ok, err) =>
      contains_nested_option(ok) || contains_nested_option(err)
    MFuture(inner) => contains_nested_option(inner)
    _ => false
  }
}

///|
/// 收集声明中使用的所有 MoonType | Collect all MoonType used in a declaration
pub fn collect_types_from_decl(d : MoonDecl) -> Array[MoonType] {
  let types : Array[MoonType] = []
  match d {
    DFn(_, _, params, ret, _) => {
      for p in params {
        let (_, t) = p
        types.push(t)
      }
      types.push(ret)
    }
    DAsyncFn(_, _, params, ret, _) => {
      for p in params {
        let (_, t) = p
        types.push(t)
      }
      types.push(ret)
    }
    DStruct(_, _, fields, _) =>
      for f in fields {
        let (_, t) = f
        types.push(t)
      }
    DTrait(_, methods) =>
      for m in methods {
        for p in m.params {
          let (_, t) = p
          types.push(t)
        }
        types.push(m.ret_type)
      }
    DImpl(_, _, methods) =>
      for m in methods {
        for p in m.params {
          let (_, t) = p
          types.push(t)
        }
        types.push(m.ret_type)
      }
    DExternFn(_, params, ret, _) => {
      for p in params {
        let (_, t) = p
        types.push(t)
      }
      types.push(ret)
    }
    DEnum(_, _) => ()
  }
  types
}

///|
/// moon2dart 统一错误类型 — 覆盖所有阶段的错误场景 | moon2dart unified error type — covers all error scenarios
/// 各包通过 raise Moon2DartError::XXX(...) 抛出，调用方通过 try...catch 捕获 | Packages raise via raise Moon2DartError::XXX(...), callers catch via try...catch
pub(all) suberror Moon2DartError {
  ParseError(String) // 解析错误 | Parse error
  TranspileError(String) // 转换错误 | Transpile error
  ReverseTranspileError(String) // 反向转换错误 | Reverse transpile error
  JsonParseError(String) // JSON 解析错误 | JSON parse error
  SchemaError(String) // Schema 错误 | Schema error
  FileIOError(String) // 文件 I/O 错误 | File I/O error
  ProjectError(String) // 项目级错误 | Project-level error
  TypeError(String) // 类型错误 | Type error
}
