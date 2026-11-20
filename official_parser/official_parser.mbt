///|
/// 官方 parser 适配层 — 用 `moonbitlang/parser`（MoonBit 官方语法树）替代自研 Lexer/Parser。
/// Official-parser adapter — replaces the hand-written lexer/parser with
/// `moonbitlang/parser` (the official MoonBit syntax tree).
///
/// 设计原则（fail-closed）：
/// 1. 官方 AST → moon2dart AST 仅覆盖已声明子集；子集外节点**显式拒绝**并给出原因；
/// 2. 元信息节点（test/using/import）不参与转换，直接忽略；
/// 3. 任一解析错误都会转换为 `ParseError`，不静默丢弃。

///|
/// 子集外节点拒绝（fail-closed）| Reject out-of-subset nodes (fail-closed)
fn[T] unsupported(msg : String) -> T raise @ast.Moon2DartError {
  raise @ast.Moon2DartError::ParseError("official parser: unsupported " + msg)
}

///|
/// 官方 LongIdent → 字符串（`Ident("x")` → `x`，`Dot("p","x")` → `p.x`）
/// Official LongIdent → string
fn long_ident_name(id : @syntax.LongIdent) -> String {
  match id {
    @syntax.Ident(name~) => name
    @syntax.Dot(pkg~, id~) => pkg + "." + id
  }
}

///|
fn type_name_name(t : @syntax.TypeName) -> String {
  long_ident_name(t.name)
}

///|
/// 解析 MoonBit 源码为 moon2dart 声明数组（官方 parser 前端）
/// Parse MoonBit source into moon2dart declarations via the official parser.
pub fn parse_source(
  src : String,
) -> Array[@ast.MoonDecl] raise @ast.Moon2DartError {
  let (impls, errors) = @parser.parse_string(src)
  if errors.length() > 0 {
    raise @ast.Moon2DartError::ParseError(
      "official parser reported \{errors.length()} error(s) in source",
    )
  }
  let decls : Array[@ast.MoonDecl] = []
  // impl 方法按 (trait, self type) 聚合为单个 DImpl | aggregate impl methods per (trait, self type)
  let groups : Array[(String, String, Array[@ast.ImplMethod])] = []
  for impl_ in impls {
    match impl_ {
      @syntax.TopFuncDef(fun_decl~, decl_body~, where_clause~, ..) => {
        match where_clause {
          Some(_) => unsupported("where clause")
          None => ()
        }
        decls.push(conv_fun(fun_decl, decl_body))
      }
      @syntax.TopTypeDef(td) => decls.push(conv_type_decl(td))
      @syntax.TopTrait(td) => decls.push(conv_trait(td))
      @syntax.TopImpl(
        self_ty~,
        trait_~,
        method_name~,
        params~,
        ret_ty~,
        body~,
        ..
      ) => {
        let self_name = match self_ty {
          Some(t) => conv_self_type(t)
          None => unsupported("impl without self type")
        }
        let imethod = conv_impl_method(method_name, params, ret_ty, body)
        let trait_name = type_name_name(trait_)
        let mut placed = false
        let mut i = 0
        while i < groups.length() {
          let (tn, sn, methods) = groups[i]
          if tn == trait_name && sn == self_name {
            methods.push(imethod)
            placed = true
          }
          i = i + 1
        }
        if !placed {
          groups.push((trait_name, self_name, [imethod]))
        }
      }
      // 元信息节点：测试 / using / import / 顶层表达式不参与库代码转换
      @syntax.TopTest(..) | @syntax.TopUsing(..) | @syntax.TopImport(..) => ()
      @syntax.TopExpr(..) => ()
      @syntax.TopLetDef(..) => unsupported("top-level let/const")
      @syntax.TopView(..) => unsupported("view expression")
      @syntax.TopImplRelation(..) => unsupported("impl relation")
      @syntax.TopExtend(..) => unsupported("extend declaration")
    }
  }
  for g in groups {
    let (trait_name, self_name, methods) = g
    decls.push(@ast.DImpl(trait_name, self_name, methods))
  }
  decls
}

///|
/// impl 的自类型（仅支持命名的具体类型）| impl self type (named concrete types only)
fn conv_self_type(t : @syntax.Type) -> String raise @ast.Moon2DartError {
  let result : String = match t {
    @syntax.Name(constr_id~, tys~, ..) =>
      if tys.length() == 0 {
        long_ident_name(constr_id.id)
      } else {
        unsupported("generic impl self type")
      }
    _ => unsupported("non-nominal impl self type")
  }
  result
}

///|
fn conv_fun(
  decl : @syntax.FunDecl,
  body : @syntax.DeclBody,
) -> @ast.MoonDecl raise @ast.Moon2DartError {
  let params = conv_parameters(decl.decl_params)
  let ret = match decl.return_type {
    Some(t) => conv_type(t)
    None => @ast.MUnit
  }
  let type_params = conv_type_params(decl.quantifiers)
  let body_expr = match body {
    @syntax.DeclBody(expr~) => conv_expr(expr)
    @syntax.DeclStubs(_) => unsupported("extern/stub function body")
    @syntax.DeclNone => unsupported("declaration-only function")
  }
  let name = decl.name.name
  match decl.is_async {
    Some(_) => @ast.DAsyncFn(name, type_params, params, ret, body_expr)
    None => @ast.DFn(name, type_params, params, ret, body_expr)
  }
}

///|
fn conv_type_params(
  params : @list.List[@syntax.TypeVarBinder],
) -> Array[String] {
  let out : Array[String] = []
  for p in params {
    out.push(p.name)
  }
  out
}

///|
fn conv_parameters(
  params : @syntax.Parameters?,
) -> Array[(String, @ast.MoonType)] raise @ast.Moon2DartError {
  let out : Array[(String, @ast.MoonType)] = []
  match params {
    Some(ps) =>
      for p in ps {
        out.push(conv_parameter(p))
      }
    None => ()
  }
  out
}

///|
fn conv_parameter(
  p : @syntax.Parameter,
) -> (String, @ast.MoonType) raise @ast.Moon2DartError {
  let result : (String, @ast.MoonType) = match p {
    @syntax.Positional(binder~, ty~) => {
      let t = match ty {
        Some(t) => conv_type(t)
        None => unsupported("unannotated parameter (add a type annotation)")
      }
      (binder.name, t)
    }
    @syntax.DiscardPositional(ty~, ..) => {
      let t = match ty {
        Some(t) => conv_type(t)
        None => unsupported("unannotated discard parameter")
      }
      ("_", t)
    }
    @syntax.Labelled(..) => unsupported("labelled parameter")
    @syntax.Optional(..) => unsupported("optional parameter")
    @syntax.QuestionOptional(..) => unsupported("optional parameter")
  }
  result
}

///|
fn conv_trait(
  decl : @syntax.TraitDecl,
) -> @ast.MoonDecl raise @ast.Moon2DartError {
  let methods : Array[@ast.TraitMethod] = []
  for m in decl.methods {
    match m.has_default {
      Some(_) => unsupported("trait default method")
      None => ()
    }
    let params = conv_parameters(Some(m.params))
    let ret = match m.return_type {
      Some(t) => conv_type(t)
      None => @ast.MUnit
    }
    methods.push({ name: m.name.name, params, ret_type: ret, })
  }
  @ast.DTrait(decl.name.name, methods)
}

///|
fn conv_impl_method(
  name : @syntax.Binder,
  params : @syntax.Parameters,
  ret_ty : @syntax.Type?,
  body : @syntax.DeclBody,
) -> @ast.ImplMethod raise @ast.Moon2DartError {
  let params2 = conv_parameters(Some(params))
  let ret = match ret_ty {
    Some(t) => conv_type(t)
    None => @ast.MUnit
  }
  let body_expr = match body {
    @syntax.DeclBody(expr~) => conv_expr(expr)
    @syntax.DeclStubs(_) => unsupported("impl stub method")
    @syntax.DeclNone => unsupported("declaration-only impl method")
  }
  { name: name.name, params: params2, ret_type: ret, body: body_expr, }
}

///|
fn conv_type_decl(
  decl : @syntax.TypeDecl,
) -> @ast.MoonDecl raise @ast.Moon2DartError {
  let name = decl.tycon
  let type_params : Array[String] = []
  for p in decl.params {
    match p.name {
      Some(n) => type_params.push(n)
      None => type_params.push("_")
    }
  }
  let deriving : Array[String] = []
  for d in decl.deriving {
    deriving.push(type_name_name(d.type_name))
  }
  let result : @ast.MoonDecl = match decl.components {
    @syntax.Record(fields~, constr_decl~) => {
      match constr_decl {
        Some(_) => unsupported("struct with custom constructor")
        None => ()
      }
      let fs : Array[(String, @ast.MoonType)] = []
      for f in fields {
        fs.push((f.name.label, conv_type(f.ty)))
      }
      @ast.DStruct(name, type_params, fs, deriving)
    }
    @syntax.Variant(constrs) => {
      let variants : Array[String] = []
      for c in constrs {
        // 现有 DEnum 只承载变体名（参数/类型参数由 L2 标注）| DEnum carries names only (L2)
        variants.push(c.name.name)
      }
      @ast.DEnum(name, variants)
    }
    @syntax.Alias(_) => unsupported("type alias")
    @syntax.TupleStruct(_) => unsupported("tuple struct")
    @syntax.Error(_) => unsupported("error type declaration")
    @syntax.Abstract => unsupported("abstract type declaration")
    @syntax.ExtensibleEnum(_) => unsupported("extensible enum")
    @syntax.ExtendEnum(..) => unsupported("extend enum")
  }
  result
}

///|
fn conv_type(t : @syntax.Type) -> @ast.MoonType raise @ast.Moon2DartError {
  match t {
    @syntax.Name(constr_id~, tys~, ..) => {
      let name = long_ident_name(constr_id.id)
      let args : Array[@ast.MoonType] = []
      for a in tys {
        args.push(conv_type(a))
      }
      let ty : @ast.MoonType = match (name, args.length()) {
        ("Int", 0) | ("Int32", 0) | ("Int16", 0) => @ast.MInt
        ("UInt", 0) | ("UInt32", 0) | ("UInt16", 0) => @ast.MUInt
        ("Int64", 0) => @ast.MInt64
        ("UInt64", 0) => @ast.MUInt64
        ("Float", 0) => @ast.MFloat
        ("Double", 0) => @ast.MDouble
        ("Bool", 0) => @ast.MBool
        ("String", 0) => @ast.MString
        ("Char", 0) => @ast.MChar
        ("Unit", 0) => @ast.MUnit
        ("Array", 1) => @ast.MArray(args[0])
        ("Map", 2) => @ast.MMap(args[0], args[1])
        ("Set", 1) => @ast.MSet(args[0])
        ("Option", 1) => @ast.MOption(args[0])
        ("Result", 2) => @ast.MResult(args[0], args[1])
        ("Future", 1) => @ast.MFuture(args[0])
        ("Iter", 1) => unsupported("Iter type")
        (_, 0) => @ast.MCustom(name)
        _ => unsupported("generic custom type \{name}")
      }
      ty
    }
    @syntax.Option(ty~, ..) => @ast.MOption(conv_type(ty))
    @syntax.Any(..) => unsupported("Any type")
    @syntax.Arrow(..) => unsupported("function type")
    @syntax.Tuple(..) => unsupported("tuple type")
    @syntax.Object(_) => unsupported("object type")
  }
}

///|
fn conv_expr(e : @syntax.Expr) -> @ast.MoonExpr raise @ast.Moon2DartError {
  let result : @ast.MoonExpr = match e {
    @syntax.Constant(c~, ..) => conv_constant(c)
    @syntax.Ident(id~, ..) => @ast.EVar(long_ident_name(id.name))
    @syntax.Apply(func~, args~, ..) => {
      let name = match func {
        @syntax.Ident(id~, ..) => long_ident_name(id.name)
        _ =>
          unsupported("call of non-identifier (function value / static method)")
      }
      let values : Array[@ast.MoonExpr] = []
      for a in args {
        match a.kind {
          @syntax.Positional => values.push(conv_expr(a.value))
          _ => unsupported("labelled argument")
        }
      }
      @ast.ECall(name, values)
    }
    @syntax.Infix(op~, lhs~, rhs~, ..) =>
      @ast.EBinOp(long_ident_name(op.name), conv_expr(lhs), conv_expr(rhs))
    @syntax.Unary(op~, expr~, ..) => {
      let op_name = long_ident_name(op.name)
      if op_name == "-" {
        @ast.EBinOp("-", @ast.EInt(0), conv_expr(expr))
      } else {
        unsupported("unary operator \{op_name}")
      }
    }
    @syntax.Array(exprs~, is_iter~, ..) =>
      if is_iter {
        unsupported("iter array literal")
      } else {
        let items : Array[@ast.MoonExpr] = []
        for x in exprs {
          items.push(conv_expr(x))
        }
        @ast.EArrayLit(items)
      }
    @syntax.ArrayGet(array~, index~, ..) =>
      @ast.EIndex(conv_expr(array), conv_expr(index))
    @syntax.If(cond~, ifso~, ifnot~, ..) => {
      let else_ = match ifnot {
        Some(x) => conv_expr(x)
        None => @ast.EBlock([])
      }
      @ast.EIf(conv_expr(cond), conv_expr(ifso), else_)
    }
    @syntax.While(loop_cond~, loop_body~, while_else~, label~, ..) => {
      match while_else {
        Some(_) => unsupported("while-else")
        None => ()
      }
      match label {
        Some(_) => unsupported("labelled loop")
        None => ()
      }
      @ast.EWhile(conv_expr(loop_cond), conv_expr(loop_body))
    }
    @syntax.Sequence(exprs~, last_expr~, ..) => {
      let stmts : Array[@ast.MoonExpr] = []
      for x in exprs {
        stmts.push(conv_expr(x))
      }
      stmts.push(conv_expr(last_expr))
      @ast.EBlock(stmts)
    }
    @syntax.Let(pattern~, expr~, body~, ..) => {
      let (name, ty) = match pattern {
        @syntax.Var(b) => (b.name, None)
        @syntax.Constraint(pat~, ty~, ..) =>
          match pat {
            @syntax.Var(b) => (b.name, Some(conv_type(ty)))
            _ => unsupported("typed non-variable let pattern")
          }
        _ => unsupported("irrefutable let pattern")
      }
      let stmt = @ast.ELet(name, false, ty, conv_expr(expr))
      prepend_stmt(stmt, conv_expr(body))
    }
    @syntax.LetMut(binder~, ty~, expr~, body~, ..) => {
      let t = match ty {
        Some(t) => Some(conv_type(t))
        None => None
      }
      let stmt = @ast.ELet(binder.name, true, t, conv_expr(expr))
      prepend_stmt(stmt, conv_expr(body))
    }
    @syntax.Assign(var_~, expr~, augmented_by~, ..) => {
      match augmented_by {
        Some(_) => unsupported("augmented assignment")
        None => ()
      }
      @ast.EAssign(long_ident_name(var_.name), conv_expr(expr))
    }
    @syntax.DotApply(self~, method_name~, args~, return_self~, ..) => {
      match return_self {
        true => unsupported("return-self dot apply")
        false => ()
      }
      let values : Array[@ast.MoonExpr] = []
      for a in args {
        match a.kind {
          @syntax.Positional => values.push(conv_expr(a.value))
          _ => unsupported("labelled argument")
        }
      }
      @ast.EMethodCall(conv_expr(self), method_name.name, values)
    }
    @syntax.Match(expr~, cases~, ..) => {
      let pairs : Array[(@ast.MoonPattern, @ast.MoonExpr)] = []
      for c in cases {
        match c.guard_ {
          Some(_) => unsupported("match guard")
          None => ()
        }
        pairs.push((conv_pattern(c.pattern), conv_expr(c.body)))
      }
      @ast.EMatch(conv_expr(expr), pairs)
    }
    @syntax.Function(func~, ..) => {
      let params = conv_parameters(Some(func.parameters))
      @ast.ELambda(params, conv_expr(func.body))
    }
    @syntax.Group(expr~, ..) => conv_expr(expr)
    @syntax.Unit(..) => @ast.EBlock([])
    @syntax.Pipe(lhs~, rhs~, ..) =>
      // `lhs |> f` / `lhs |> f(args)` 展开为直接调用（仅限标识符/调用）
      match rhs {
        @syntax.Ident(id~, ..) =>
          @ast.ECall(long_ident_name(id.name), [conv_expr(lhs)])
        @syntax.Apply(func~, args~, ..) => {
          let name = match func {
            @syntax.Ident(id~, ..) => long_ident_name(id.name)
            _ => unsupported("pipe into non-identifier call")
          }
          let values : Array[@ast.MoonExpr] = [conv_expr(lhs)]
          for a in args {
            match a.kind {
              @syntax.Positional => values.push(conv_expr(a.value))
              _ => unsupported("labelled argument")
            }
          }
          @ast.ECall(name, values)
        }
        _ => unsupported("pipe into non-call")
      }
    @syntax.Constraint(..) => unsupported("type constraint expression")
    @syntax.Interp(..) => unsupported("string interpolation")
    @syntax.MultilineString(..) => unsupported("multiline string")
    @syntax.Tuple(..) => unsupported("tuple expression")
    @syntax.Record(..) => unsupported("record literal")
    @syntax.RecordUpdate(..) => unsupported("record update")
    @syntax.Field(..) => unsupported("field access")
    @syntax.Method(..) => unsupported("static method reference")
    @syntax.As(..) => unsupported("as-cast")
    @syntax.ArraySet(..) => unsupported("array element assignment")
    @syntax.ArrayAugmentedSet(..) => unsupported("array augmented assignment")
    @syntax.ArraySpread(..) => unsupported("array spread")
    @syntax.ListComprehension(..) => unsupported("list comprehension")
    @syntax.ArrayGetSlice(..) => unsupported("array slice")
    @syntax.LetFn(..) => unsupported("local function")
    @syntax.LetAnd(..) => unsupported("let-and")
    @syntax.For(..) => unsupported("for loop")
    @syntax.ForEach(..) => unsupported("for-in loop")
    @syntax.Break(..) => unsupported("break")
    @syntax.Continue(..) => unsupported("continue")
    @syntax.Return(..) => unsupported("return expression")
    @syntax.Raise(..) => unsupported("raise expression")
    @syntax.Try(..) => unsupported("try/catch")
    @syntax.TryOperator(..) => unsupported("try! operator")
    @syntax.Defer(..) => unsupported("defer")
    @syntax.ErrDefer(..) => unsupported("errdefer")
    @syntax.Guard(..) => unsupported("guard")
    @syntax.Is(..) => unsupported("is-expression")
    @syntax.RegexMatch(..) => unsupported("regex match")
    @syntax.LexScan(..) => unsupported("lexscan")
    @syntax.Map(..) => unsupported("map literal")
    @syntax.Mutate(..) => unsupported("field mutation")
    @syntax.Hole(..) => unsupported("hole")
    @syntax.LabelledBlock(..) => unsupported("labelled block")
    @syntax.TemplateWriting(..) => unsupported("template writing")
    @syntax.Quantifier(..) => unsupported("quantifier expression")
    @syntax.Implies(..) => unsupported("implies")
    @syntax.ProofAssert(..) => unsupported("proof assertion")
    @syntax.ProofLet(..) => unsupported("proof let")
    @syntax.StaticAssert(..) => unsupported("static assert")
    @syntax.BytesInterp(..) => unsupported("bytes interpolation")
    @syntax.Constr(..) => unsupported("constructor expression")
    @syntax.RevPipe(..) => unsupported("reverse pipe")
  }
  result
}

///|
fn conv_constant(
  c : @syntax.Constant,
) -> @ast.MoonExpr raise @ast.Moon2DartError {
  let result : @ast.MoonExpr = match c {
    @syntax.Int(s) => @ast.EInt(parse_int_literal(s))
    @syntax.Double(s) => @ast.EDouble(parse_double_literal(s))
    @syntax.Bool(b) => @ast.EBool(b)
    @syntax.String(s) => @ast.EString(s)
    @syntax.Int64(_) => unsupported("Int64 literal")
    @syntax.UInt(_) => unsupported("UInt literal")
    @syntax.UInt64(_) => unsupported("UInt64 literal")
    @syntax.Float(_) => unsupported("Float literal")
    @syntax.Char(_) => unsupported("Char literal")
    @syntax.Byte(_) => unsupported("Byte literal")
    @syntax.Bytes(_) => unsupported("Bytes literal")
    @syntax.BigInt(_) => unsupported("BigInt literal")
    @syntax.Regex(_) => unsupported("regex literal")
    @syntax.BytesRegex(_) => unsupported("bytes regex literal")
  }
  result
}

///|
fn conv_pattern(
  p : @syntax.Pattern,
) -> @ast.MoonPattern raise @ast.Moon2DartError {
  let result : @ast.MoonPattern = match p {
    @syntax.Any(..) => @ast.PWild
    @syntax.Var(b) => @ast.PVar(b.name)
    @syntax.Constant(c~, ..) =>
      match c {
        @syntax.Int(s) => @ast.PInt(parse_int_literal(s))
        @syntax.String(s) => @ast.PString(s)
        _ => unsupported("non-int/string constant pattern")
      }
    @syntax.Constr(constr~, args~, is_open~, ..) => {
      if is_open {
        unsupported("open constructor pattern")
      }
      let sub : Array[@ast.MoonPattern] = []
      match args {
        Some(ps) =>
          for a in ps {
            match a.kind {
              @syntax.Positional => sub.push(conv_pattern(a.pat))
              _ => unsupported("labelled constructor pattern")
            }
          }
        None => ()
      }
      @ast.PCtor(constr.name.name, sub)
    }
    @syntax.Alias(..) => unsupported("pattern alias")
    @syntax.Array(..) => unsupported("array pattern")
    @syntax.Tuple(..) => unsupported("tuple pattern")
    @syntax.Constraint(..) => unsupported("constrained pattern")
    @syntax.Or(..) => unsupported("or-pattern")
    @syntax.Record(..) => unsupported("record pattern")
    @syntax.Map(..) => unsupported("map pattern")
    @syntax.Range(..) => unsupported("range pattern")
    @syntax.With(..) => unsupported("with-pattern")
    @syntax.SpecialConstr(..) => unsupported("special constructor pattern")
    @syntax.ConstrAny(..) => unsupported("constructor-any pattern")
    @syntax.ConstrUnknown(..) => unsupported("constructor-unknown pattern")
  }
  result
}

///|
fn prepend_stmt(stmt : @ast.MoonExpr, body : @ast.MoonExpr) -> @ast.MoonExpr {
  match body {
    @ast.EBlock(stmts) => {
      let out : Array[@ast.MoonExpr] = [stmt]
      for s in stmts {
        out.push(s)
      }
      @ast.EBlock(out)
    }
    other => @ast.EBlock([stmt, other])
  }
}

///|
fn parse_int_literal(s : String) -> Int32 raise @ast.Moon2DartError {
  let cleaned = s.replace(old="_", new="")
  try {
    if cleaned.has_prefix("0x") || cleaned.has_prefix("0X") {
      @string.parse_int(cleaned[2:], radix=16)
    } else if cleaned.has_prefix("0o") || cleaned.has_prefix("0O") {
      @string.parse_int(cleaned[2:], radix=8)
    } else if cleaned.has_prefix("0b") || cleaned.has_prefix("0B") {
      @string.parse_int(cleaned[2:], radix=2)
    } else {
      @string.parse_int(cleaned)
    }
  } catch {
    _ => raise @ast.Moon2DartError::ParseError("invalid Int literal: " + s)
  }
}

///|
fn parse_double_literal(s : String) -> Double raise @ast.Moon2DartError {
  let cleaned = s.replace(old="_", new="")
  @string.parse_double(cleaned) catch {
    _ => raise @ast.Moon2DartError::ParseError("invalid Double literal: " + s)
  }
}
