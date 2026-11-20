///|
/// 表达式类型环境 — 局部变量绑定 + 全局函数签名 | Expression type environment — local variable bindings + global function signatures
/// 供 mini 推断器在发射期判断算术操作数的类型（Int/Double/String 等） | Used by the mini inferencer to determine operand types (Int/Double/String etc.) during emission
pub(all) struct TypeEnv {
  vars : Map[String, @ast.MoonType] // 变量名 → 类型 | variable name to type
  fns : Map[String, @ast.MoonType] // 函数名 → 返回类型 | function name to return type
}

///|
pub fn TypeEnv::make() -> TypeEnv {
  { vars: Map([]), fns: Map([]), }
}

///|
/// 复制类型环境（闭包/lambda 参数绑定用，避免污染外层环境）| Clone the type env (for lambda parameter binding without polluting the outer env)
pub fn TypeEnv::clone(self : TypeEnv) -> TypeEnv {
  let vars : Map[String, @ast.MoonType] = Map([])
  for k, v in self.vars {
    vars[k] = v
  }
  let fns : Map[String, @ast.MoonType] = Map([])
  for k, v in self.fns {
    fns[k] = v
  }
  { vars, fns, }
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
pub fn infer_expr_type(e : @ast.MoonExpr, env : TypeEnv) -> @ast.MoonType? {
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
      // 仅当两侧都可推断且类型一致时才给出类型；任一侧未知即 None（触发 fail-closed 诊断）
      // Only give a type when both sides are inferable and agree; any unknown side yields None (fail-closed diagnostic)
      let lt = infer_expr_type(lhs, env)
      let rt = infer_expr_type(rhs, env)
      match (lt, rt) {
        (Some(a), Some(b)) => if a == b { Some(a) } else { None }
        _ => None
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
    @ast.EBlock(stmts) => {
      // 块表达式类型 = 尾语句类型；let 绑定在块内进入变量环境 | block type = last statement type; let bindings extend the env
      let mut last : @ast.MoonType? = None
      let mut i = 0
      while i < stmts.length() {
        match stmts[i] {
          @ast.ELet(name, _, ty, init) => {
            let t = match ty {
              Some(t) => Some(t)
              None => infer_expr_type(init, env)
            }
            match t {
              Some(tv) => env.vars[name] = tv
              None => ()
            }
            last = Some(@ast.MUnit)
          }
          s => last = infer_expr_type(s, env)
        }
        i += 1
      }
      match stmts.length() {
        0 => None
        _ => last
      }
    }
    @ast.EArrayLit(items) =>
      if items.length() == 0 {
        None // 空数组元素类型不可知 | element type of empty array is unknowable
      } else {
        match infer_expr_type(items[0], env) {
          Some(t) => Some(@ast.MArray(t))
          None => None
        }
      }
    @ast.EIndex(arr, _) =>
      match infer_expr_type(arr, env) {
        Some(@ast.MArray(t)) => Some(t)
        _ => None
      }
    @ast.EMethodCall(recv, mname, _args) =>
      match mname {
        "length" => Some(@ast.MInt)
        "push" => Some(@ast.MUnit)
        "get" | "pop" =>
          match infer_expr_type(recv, env) {
            Some(@ast.MArray(t)) => Some(@ast.MOption(t))
            _ => None
          }
        _ => None
      }
    @ast.EWhile(_, _) => Some(@ast.MUnit)
    @ast.ELet(_, _, ty, init) =>
      match ty {
        Some(t) => Some(t)
        None => infer_expr_type(init, env)
      }
    @ast.EAssign(_, _) => Some(@ast.MUnit)
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
    @ast.EBlock(stmts) =>
      for s in stmts {
        match s {
          @ast.ELet(name, _, ty, init) => {
            let t = match ty {
              Some(t) => Some(t)
              None => infer_expr_type(init, env)
            }
            match t {
              Some(tv) => env.vars[name] = tv
              None => ()
            }
          }
          _ => ()
        }
        collect_int_arith_ops_expr(s, env, ops)
      }
    @ast.EArrayLit(items) =>
      for a in items {
        collect_int_arith_ops_expr(a, env, ops)
      }
    @ast.EIndex(arr, idx) => {
      collect_int_arith_ops_expr(arr, env, ops)
      collect_int_arith_ops_expr(idx, env, ops)
    }
    @ast.EMethodCall(recv, _, args) => {
      collect_int_arith_ops_expr(recv, env, ops)
      for a in args {
        collect_int_arith_ops_expr(a, env, ops)
      }
    }
    @ast.EWhile(cond, body) => {
      collect_int_arith_ops_expr(cond, env, ops)
      collect_int_arith_ops_expr(body, env, ops)
    }
    @ast.ELet(_, _, _, init) => collect_int_arith_ops_expr(init, env, ops)
    @ast.EAssign(_, rhs) => collect_int_arith_ops_expr(rhs, env, ops)
    @ast.EInt(_)
    | @ast.EDouble(_)
    | @ast.EBool(_)
    | @ast.EString(_)
    | @ast.EVar(_) => ()
  }
}

///|
/// 收集"算术操作数类型不可推断"的表达式 — 安全边界的核心输入 | Collect arithmetic expressions whose operand type is not inferable — the core input of the safety boundary
///
/// 默认 `UnresolvedPolicy::Error` 下，任何一条都会拒绝生成（fail-closed），
/// 而不是静默裸发。`Warn` 策略写入报告并标注 `[L2-UNRESOLVED]`。
pub fn collect_unresolved_arith(
  decls : Array[@ast.MoonDecl],
) -> Array[@ast.Diagnostic] {
  let out : Array[@ast.Diagnostic] = []
  for d in decls {
    match d {
      @ast.DFn(name, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        collect_unresolved_expr(body, env, name, out)
      }
      @ast.DAsyncFn(name, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        collect_unresolved_expr(body, env, name, out)
      }
      @ast.DImpl(_trait_name, type_name, methods) =>
        for m in methods {
          let env = TypeEnv::for_function(decls, m.params)
          collect_unresolved_expr(m.body, env, "\{type_name}::\{m.name}", out)
        }
      _ => ()
    }
  }
  out
}

///|
fn is_arith_op(op : String) -> Bool {
  op == "+" ||
  op == "-" ||
  op == "*" ||
  op == "/" ||
  op == "%" ||
  op == "&" ||
  op == "|" ||
  op == "^" ||
  op == "<<" ||
  op == ">>" ||
  op == ">>>"
}

///|
fn collect_unresolved_expr(
  e : @ast.MoonExpr,
  env : TypeEnv,
  site : String,
  out : Array[@ast.Diagnostic],
) -> Unit {
  match e {
    @ast.EBinOp(op, lhs, rhs) => {
      if is_arith_op(op) && infer_expr_type(e, env) is None {
        out.push({
          code: "UNRESOLVED_ARITH",
          site,
          detail: "operator \{op}: operand type not inferable (add a type annotation or avoid untyped arithmetic)",
        })
      }
      collect_unresolved_expr(lhs, env, site, out)
      collect_unresolved_expr(rhs, env, site, out)
    }
    @ast.EBlock(stmts) =>
      for s in stmts {
        match s {
          @ast.ELet(name, _, ty, init) => {
            let t = match ty {
              Some(t) => Some(t)
              None => infer_expr_type(init, env)
            }
            match t {
              Some(tv) => env.vars[name] = tv
              None => ()
            }
          }
          _ => ()
        }
        collect_unresolved_expr(s, env, site, out)
      }
    @ast.EArrayLit(items) =>
      for a in items {
        collect_unresolved_expr(a, env, site, out)
      }
    @ast.EIndex(arr, idx) => {
      collect_unresolved_expr(arr, env, site, out)
      collect_unresolved_expr(idx, env, site, out)
    }
    @ast.EMethodCall(recv, _, args) => {
      collect_unresolved_expr(recv, env, site, out)
      for a in args {
        collect_unresolved_expr(a, env, site, out)
      }
    }
    @ast.EWhile(cond, body) => {
      collect_unresolved_expr(cond, env, site, out)
      collect_unresolved_expr(body, env, site, out)
    }
    @ast.ELet(_, _, _, init) => collect_unresolved_expr(init, env, site, out)
    @ast.EAssign(_, rhs) => collect_unresolved_expr(rhs, env, site, out)
    @ast.EIf(c, t, f) => {
      collect_unresolved_expr(c, env, site, out)
      collect_unresolved_expr(t, env, site, out)
      collect_unresolved_expr(f, env, site, out)
    }
    @ast.EMatch(scrutinee, cases) => {
      collect_unresolved_expr(scrutinee, env, site, out)
      for c in cases {
        let (_, body) = c
        collect_unresolved_expr(body, env, site, out)
      }
    }
    @ast.EAwait(inner) => collect_unresolved_expr(inner, env, site, out)
    @ast.ELambda(_, body) => collect_unresolved_expr(body, env, site, out)
    @ast.ECall(_, args) =>
      for a in args {
        collect_unresolved_expr(a, env, site, out)
      }
    @ast.EInt(_)
    | @ast.EDouble(_)
    | @ast.EBool(_)
    | @ast.EString(_)
    | @ast.EVar(_) => ()
  }
}

///|
/// 把函数体内的局部 let 绑定注册进类型环境（发射期推断用）| Register local let bindings from a function body into the type env (for emission-time inference)
pub fn bind_local_lets(e : @ast.MoonExpr, env : TypeEnv) -> Unit {
  match e {
    @ast.EBlock(stmts) =>
      for s in stmts {
        bind_local_lets(s, env)
      }
    @ast.ELet(name, _, ty, init) => {
      let t = match ty {
        Some(t) => Some(t)
        None => infer_expr_type(init, env)
      }
      match t {
        Some(tv) => env.vars[name] = tv
        None => ()
      }
      bind_local_lets(init, env)
    }
    @ast.EWhile(cond, body) => {
      bind_local_lets(cond, env)
      bind_local_lets(body, env)
    }
    @ast.EIf(c, t, f) => {
      bind_local_lets(c, env)
      bind_local_lets(t, env)
      bind_local_lets(f, env)
    }
    @ast.EMatch(scrutinee, cases) => {
      bind_local_lets(scrutinee, env)
      for c in cases {
        let (_, body) = c
        bind_local_lets(body, env)
      }
    }
    @ast.EAwait(inner) => bind_local_lets(inner, env)
    @ast.ELambda(_, body) => bind_local_lets(body, env)
    @ast.ECall(_, args) =>
      for a in args {
        bind_local_lets(a, env)
      }
    @ast.EArrayLit(items) =>
      for a in items {
        bind_local_lets(a, env)
      }
    @ast.EIndex(arr, idx) => {
      bind_local_lets(arr, env)
      bind_local_lets(idx, env)
    }
    @ast.EMethodCall(recv, _, args) => {
      bind_local_lets(recv, env)
      for a in args {
        bind_local_lets(a, env)
      }
    }
    @ast.EAssign(_, rhs) => bind_local_lets(rhs, env)
    @ast.EBinOp(_, lhs, rhs) => {
      bind_local_lets(lhs, env)
      bind_local_lets(rhs, env)
    }
    @ast.EInt(_)
    | @ast.EDouble(_)
    | @ast.EBool(_)
    | @ast.EString(_)
    | @ast.EVar(_) => ()
  }
}

///|
/// 程序是否需要集合结构相等 helper（MoonBit `==` 对 Array/Map/Set 是逐元素比较，
/// Dart `==` 是引用比较——Wrapping 模式必须发射 mbEquals）| Whether the program needs
/// the structural-equality helper (MoonBit compare is element-wise; Dart `==` is identity).
pub fn needs_collection_equals(decls : Array[@ast.MoonDecl]) -> Bool {
  for d in decls {
    match d {
      @ast.DFn(_, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        bind_local_lets(body, env)
        if expr_needs_collection_equals(body, env) {
          return true
        }
      }
      @ast.DAsyncFn(_, _, params, _, body) => {
        let env = TypeEnv::for_function(decls, params)
        bind_local_lets(body, env)
        if expr_needs_collection_equals(body, env) {
          return true
        }
      }
      @ast.DImpl(_, _, methods) =>
        for m in methods {
          let env = TypeEnv::for_function(decls, m.params)
          bind_local_lets(m.body, env)
          if expr_needs_collection_equals(m.body, env) {
            return true
          }
        }
      _ => ()
    }
  }
  false
}

///|
fn expr_needs_collection_equals(e : @ast.MoonExpr, env : TypeEnv) -> Bool {
  match e {
    @ast.EBinOp(op, lhs, rhs) => {
      let hit = if op == "==" || op == "!=" {
        match infer_expr_type(e, env) {
          Some(t) => is_collection_type(t)
          None => false
        }
      } else {
        false
      }
      hit ||
      expr_needs_collection_equals(lhs, env) ||
      expr_needs_collection_equals(rhs, env)
    }
    @ast.EBlock(stmts) => {
      for s in stmts {
        if expr_needs_collection_equals(s, env) {
          return true
        }
      }
      false
    }
    @ast.EIf(c, t, f) =>
      expr_needs_collection_equals(c, env) ||
      expr_needs_collection_equals(t, env) ||
      expr_needs_collection_equals(f, env)
    @ast.EMatch(scrutinee, cases) => {
      if expr_needs_collection_equals(scrutinee, env) {
        return true
      }
      for c in cases {
        let (_, body) = c
        if expr_needs_collection_equals(body, env) {
          return true
        }
      }
      false
    }
    @ast.EAwait(inner) => expr_needs_collection_equals(inner, env)
    @ast.ELambda(_, body) => expr_needs_collection_equals(body, env)
    @ast.ECall(_, args) => {
      for a in args {
        if expr_needs_collection_equals(a, env) {
          return true
        }
      }
      false
    }
    @ast.EArrayLit(items) => {
      for a in items {
        if expr_needs_collection_equals(a, env) {
          return true
        }
      }
      false
    }
    @ast.EIndex(arr, idx) =>
      expr_needs_collection_equals(arr, env) ||
      expr_needs_collection_equals(idx, env)
    @ast.EMethodCall(recv, _, args) => {
      if expr_needs_collection_equals(recv, env) {
        return true
      }
      for a in args {
        if expr_needs_collection_equals(a, env) {
          return true
        }
      }
      false
    }
    @ast.EWhile(cond, body) =>
      expr_needs_collection_equals(cond, env) ||
      expr_needs_collection_equals(body, env)
    @ast.ELet(_, _, _, init) => expr_needs_collection_equals(init, env)
    @ast.EAssign(_, rhs) => expr_needs_collection_equals(rhs, env)
    @ast.EInt(_)
    | @ast.EDouble(_)
    | @ast.EBool(_)
    | @ast.EString(_)
    | @ast.EVar(_) => false
  }
}

///|
/// 收集 L3/L4 降级类型诊断（可审计）| Collect L3/L4 degraded-type diagnostics (auditable)
pub fn collect_degraded_types(
  decls : Array[@ast.MoonDecl],
) -> Array[@ast.Diagnostic] {
  let out : Array[@ast.Diagnostic] = []
  for d in decls {
    let types = @ast.collect_types_from_decl(d)
    for t in types {
      match semantic_level(t) {
        L3 =>
          out.push({
            code: "L3_TYPE",
            site: "type",
            detail: "constrained type mapped with a diagnostic comment",
          })
        L4 =>
          out.push({
            code: "L4_TYPE",
            site: "type",
            detail: "inequivalent type rejected by --strict",
          })
        _ => ()
      }
    }
  }
  out
}
