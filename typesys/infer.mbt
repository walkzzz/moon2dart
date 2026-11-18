///|
/// 表达式类型环境 — 局部变量绑定 + 全局函数签名 | Expression type environment — local variable bindings + global function signatures
/// 供 mini 推断器在发射期判断算术操作数的类型（Int/Double/String 等） | Used by the mini inferencer to determine operand types (Int/Double/String etc.) during emission
pub(all) struct TypeEnv {
  vars : Map[String, @ast.MoonType] // 变量名 → 类型 | variable name to type
  fns : Map[String, @ast.MoonType] // 函数名 → 返回类型 | function name to return type
}

///|
pub fn TypeEnv::make() -> TypeEnv {
  { vars: Map([]), fns: Map([]) }
}

///|
/// 构建推断环境 — 全局函数签名（来自声明数组）+ 局部参数绑定 | Build inference env — global function signatures (from declarations) + local parameter bindings
pub fn TypeEnv::for_function(
  decls : Array[@ast.MoonDecl],
  params : Array[(String, @ast.MoonType)],
) -> TypeEnv {
  let env = TypeEnv::from_decls(decls)
  for p in params {
    let (name, t) = p
    env.vars[name] = t
  }
  env
}

///|
/// 从声明数组构建全局环境（DFn / DAsyncFn / DExternFn 的返回类型签名） | Build global environment from declarations (return type signatures of DFn / DAsyncFn / DExternFn)
pub fn TypeEnv::from_decls(decls : Array[@ast.MoonDecl]) -> TypeEnv {
  let env = TypeEnv::make()
  for d in decls {
    match d {
      @ast.DFn(name, _, _, ret, _) => env.fns[name] = ret
      @ast.DAsyncFn(name, _, _, ret, _) => env.fns[name] = ret
      @ast.DExternFn(name, _, ret, _) => env.fns[name] = ret
      _ => ()
    }
  }
  env
}

///|
/// 表达式类型推断（mini 推断器，覆盖 v0.1.0 AST 子集） | Expression type inference (mini inferencer covering the v0.1.0 AST subset)
///
/// 推断失败（未知变量、无签名调用、闭包体等）返回 `None` — 发射端保守裸发（fast 语义）。
/// 推断成功且为 `MInt` 时，Wrapping 模式发射 mb32* 回绕调用 / `~/` / `remainder()`。
pub fn infer_expr_type(
  e : @ast.MoonExpr,
  env : TypeEnv,
) -> @ast.MoonType? {
  match e {
    @ast.EInt(_) => Some(@ast.MInt)
    @ast.EDouble(_) => Some(@ast.MDouble)
    @ast.EBool(_) => Some(@ast.MBool)
    @ast.EString(_) => Some(@ast.MString)
    @ast.EVar(name) =>
      if name == "true" || name == "false" {
        Some(@ast.MBool)
      } else {
        env.vars.get(name)
      }
    @ast.ECall(name, args) =>
      if name == "Some" && args.length() == 1 {
        infer_expr_type(args[0], env)
      } else if name == "None" && args.length() == 0 {
        None // None 内层类型不可知，按推断失败处理 | inner type of None is unknowable
      } else {
        env.fns.get(name)
      }
    @ast.EBinOp(_, lhs, rhs) => {
      let lt = infer_expr_type(lhs, env)
      match lt {
        Some(t) => Some(t)
        None => infer_expr_type(rhs, env)
      }
    }
    @ast.EIf(_, then_, _) => infer_expr_type(then_, env)
    @ast.EMatch(_, cases) => {
      let mut result : @ast.MoonType? = None
      for c in cases {
        let (_, body) = c
        if result is None {
          result = infer_expr_type(body, env)
        }
      }
      result
    }
    @ast.EAwait(inner) =>
      match infer_expr_type(inner, env) {
        Some(@ast.MFuture(t)) => Some(t)
        other => other
      }
    @ast.ELambda(_, _) => None
  }
}

///|
/// 收集程序中需要 32 位回绕模拟的 Int 算术操作符（去重、按声明遍历） | Collect Int arithmetic operators in the program that need 32-bit wrapping shims (deduplicated, walked per declaration)
///
/// 返回操作符数组（元素 ∈ {"+", "-", "*", "/", "%"}），供 emit 端按需生成 shim。
pub fn collect_int_arith_ops(decls : Array[@ast.MoonDecl]) -> Array[String] {
  let ops : Array[String] = []
  for d in decls {
    match d {
      @ast.DFn(_, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        collect_int_arith_ops_expr(body, env, ops)
      }
      @ast.DAsyncFn(_, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        collect_int_arith_ops_expr(body, env, ops)
      }
      @ast.DImpl(_, _, methods) =>
        for m in methods {
          let env = TypeEnv::for_function(decls, m.params)
          collect_int_arith_ops_expr(m.body, env, ops)
        }
      _ => ()
    }
  }
  ops
}

///|
/// 递归遍历表达式树，记录推断为 MInt 的算术操作符 | Recursively walk the expression tree, recording arithmetic operators inferred as MInt
fn collect_int_arith_ops_expr(
  e : @ast.MoonExpr,
  env : TypeEnv,
  ops : Array[String],
) -> Unit {
  match e {
    @ast.EBinOp(op, lhs, rhs) => {
      let t = infer_expr_type(e, env)
      match t {
        Some(@ast.MInt) =>
          if op == "+" || op == "-" || op == "*" || op == "/" || op == "%" {
            let mut found = false
            for existing in ops {
              if existing == op {
                found = true
              }
            }
            if !found {
              ops.push(op)
            }
          }
        _ => ()
      }
      collect_int_arith_ops_expr(lhs, env, ops)
      collect_int_arith_ops_expr(rhs, env, ops)
    }
    @ast.ECall(_, args) =>
      for a in args {
        collect_int_arith_ops_expr(a, env, ops)
      }
    @ast.EIf(c, then_, else_) => {
      collect_int_arith_ops_expr(c, env, ops)
      collect_int_arith_ops_expr(then_, env, ops)
      collect_int_arith_ops_expr(else_, env, ops)
    }
    @ast.EMatch(scrutinee, cases) => {
      collect_int_arith_ops_expr(scrutinee, env, ops)
      for c in cases {
        let (_, body) = c
        collect_int_arith_ops_expr(body, env, ops)
      }
    }
    @ast.EAwait(inner) => collect_int_arith_ops_expr(inner, env, ops)
    @ast.ELambda(_, body) => collect_int_arith_ops_expr(body, env, ops)
    @ast.EInt(_) | @ast.EDouble(_) | @ast.EBool(_) | @ast.EString(_)
    | @ast.EVar(_) => ()
  }
}