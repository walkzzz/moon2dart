///|
/// 反向代码生成器 — 将 Dart AST 节点转换为 MoonBit 源码字符串。
///
/// 这是 moon2dart 的反向管线核心：Dart 源码 → Dart AST → MoonBit 源码。

///|
/// DartType → MoonBit 类型字符串。
pub fn dart_type_to_moon(t : @dart_ast.DartType) -> String {
  match t {
    @dart_ast.DInt => "Int"
    @dart_ast.DDouble => "Double"
    @dart_ast.DBool => "Bool"
    @dart_ast.DString => "String"
    @dart_ast.DRune => "Char"
    @dart_ast.DVoid => "Unit"
    @dart_ast.DList(inner) => {
      let s = dart_type_to_moon(inner)
      "Array[\{s}]"
    }
    @dart_ast.DMap(k, v) => {
      let ks = dart_type_to_moon(k)
      let vs = dart_type_to_moon(v)
      "Map[\{ks}, \{vs}]"
    }
    @dart_ast.DSet(inner) => {
      let s = dart_type_to_moon(inner)
      "Set[\{s}]"
    }
    @dart_ast.DNullable(inner) => {
      let s = dart_type_to_moon(inner)
      "Option[\{s}]"
    }
    @dart_ast.DFuture(inner) => {
      let s = dart_type_to_moon(inner)
      "Future[\{s}]"
    }
    @dart_ast.DCustom(name) => name
  }
}

///|
/// DartType → MoonType（AST 节点）。
pub fn dart_type_to_moon_ast(t : @dart_ast.DartType) -> @ast.MoonType {
  match t {
    @dart_ast.DInt => @ast.MInt
    @dart_ast.DDouble => @ast.MDouble
    @dart_ast.DBool => @ast.MBool
    @dart_ast.DString => @ast.MString
    @dart_ast.DRune => @ast.MChar
    @dart_ast.DVoid => @ast.MUnit
    @dart_ast.DList(inner) => @ast.MArray(dart_type_to_moon_ast(inner))
    @dart_ast.DMap(k, v) =>
      @ast.MMap(dart_type_to_moon_ast(k), dart_type_to_moon_ast(v))
    @dart_ast.DSet(inner) => @ast.MSet(dart_type_to_moon_ast(inner))
    @dart_ast.DNullable(inner) => @ast.MOption(dart_type_to_moon_ast(inner))
    @dart_ast.DFuture(inner) => @ast.MFuture(dart_type_to_moon_ast(inner))
    @dart_ast.DCustom(name) => @ast.MCustom(name)
  }
}

///|
/// DartExpr → MoonBit 表达式字符串。
pub fn emit_moon_expr(e : @dart_ast.DartExpr) -> String {
  match e {
    @dart_ast.DIntLit(n) => n.to_string()
    @dart_ast.DDoubleLit(d) => d.to_string()
    @dart_ast.DBoolLit(b) => if b { "true" } else { "false" }
    @dart_ast.DStringLit(s) => "\"\{s}\""
    @dart_ast.DVarRef(name) => name
    @dart_ast.DNullLit => "None"
    @dart_ast.DFunctionCall(name, args) =>
      if name == "Some" && args.length() == 1 {
        let inner = emit_moon_expr(args[0])
        "Some(\{inner})"
      } else {
        let arg_str = args.map(emit_moon_expr).join(", ")
        "\{name}(\{arg_str})"
      }
    @dart_ast.DMethodCall(obj, mname, args) => {
      let arg_str = args.map(emit_moon_expr).join(", ")
      "\{obj}.\{mname}(\{arg_str})"
    }
    @dart_ast.DBinOp(op, lhs, rhs) => {
      let l = emit_moon_expr(lhs)
      let r = emit_moon_expr(rhs)
      "\{l} \{op} \{r}"
    }
    @dart_ast.DIfExpr(cond, then_, else_) => {
      let c = emit_moon_expr(cond)
      let t = emit_moon_expr(then_)
      let e = emit_moon_expr(else_)
      "if \{c} { \{t} } else { \{e} }"
    }
    @dart_ast.DSwitchExpr(scrut, cases) => {
      let s = emit_moon_expr(scrut)
      let arms = cases
        .map(fn(pair) {
          let (pat, body) = pair
          let p_str = emit_moon_pattern(pat)
          let b_str = emit_moon_expr(body)
          "  \{p_str} => \{b_str}"
        })
        .join("\n")
      "match \{s} {\n\{arms}\n}"
    }
    @dart_ast.DAwaitExpr(inner) => {
      let s = emit_moon_expr(inner)
      "await \{s}"
    }
    @dart_ast.DArrowFn(params, body) => {
      let param_str = params.join(", ")
      let b = emit_moon_expr(body)
      "fn(\{param_str}) { \{b} }"
    }
  }
}

///|
/// DartPattern → MoonBit 模式字符串。
pub fn emit_moon_pattern(p : @dart_ast.DartPattern) -> String {
  match p {
    @dart_ast.DPVar(name) => name
    @dart_ast.DPInt(n) => n.to_string()
    @dart_ast.DPString(s) => "\"\{s}\""
    @dart_ast.DPWild => "_"
    @dart_ast.DPNull => "None"
    @dart_ast.DPCtor(name, args) =>
      if args.length() == 0 {
        "\{name}"
      } else {
        let arg_str = args.map(emit_moon_pattern).join(", ")
        "\{name}(\{arg_str})"
      }
  }
}

///|
/// 格式化参数列表为 MoonBit 参数字符串。
fn format_params(params : Array[(String, @dart_ast.DartType)]) -> String {
  params
  .map(fn(pair) {
    let (pname, ty) = pair
    let ty_str = dart_type_to_moon(ty)
    "\{pname} : \{ty_str}"
  })
  .join(", ")
}

///|
/// DartDecl → MoonBit 声明字符串。
pub fn emit_moon_decl(d : @dart_ast.DartDecl) -> String {
  match d {
    @dart_ast.DTopFn(name, type_params, params, ret, body) => {
      let param_str = format_params(params)
      let ret_str = dart_type_to_moon(ret)
      let generic = if type_params.length() > 0 {
        "[\{type_params.join(", ")}]"
      } else {
        ""
      }
      let body_str = emit_moon_expr(body)
      "fn \{name}\{generic}(\{param_str}) -> \{ret_str} {\n  \{body_str}\n}"
    }
    @dart_ast.DAsyncTopFn(name, type_params, params, ret, body) => {
      let param_str = format_params(params)
      let inner_ret = match ret {
        @dart_ast.DFuture(inner) => dart_type_to_moon(inner)
        _ => dart_type_to_moon(ret)
      }
      let generic = if type_params.length() > 0 {
        "[\{type_params.join(", ")}]"
      } else {
        ""
      }
      let body_str = emit_moon_expr(body)
      "async fn \{name}\{generic}(\{param_str}) -> \{inner_ret} {\n  \{body_str}\n}"
    }
    @dart_ast.DClass(name, type_params, fields, methods) => {
      let field_str = fields
        .map(fn(pair) {
          let (fname, ftype) = pair
          let ty_str = dart_type_to_moon(ftype)
          "  \{fname} : \{ty_str}"
        })
        .join("\n")
      let generic = if type_params.length() > 0 {
        "[\{type_params.join(", ")}]"
      } else {
        ""
      }
      let derive_str = "derive(Eq, Compare, Debug)"
      let struct_body = "struct \{name}\{generic} {\n\{field_str}\n} \{derive_str}"
      if methods.length() > 0 {
        let method_str = methods
          .map(fn(m) { emit_moon_method(name, m) })
          .join("\n\n")
        "\{struct_body}\n\n\{method_str}"
      } else {
        struct_body
      }
    }
    @dart_ast.DSealedClass(name, variants) => {
      let variant_str = variants
        .map(fn(v) {
          if v.fields.length() == 0 {
            "  \{v.name}"
          } else {
            let field_str = v.fields
              .map(fn(pair) {
                let (fname, ftype) = pair
                let ty_str = dart_type_to_moon(ftype)
                "\{fname} : \{ty_str}"
              })
              .join(", ")
            "  \{v.name}(\{field_str})"
          }
        })
        .join("\n")
      "enum \{name} {\n\{variant_str}\n} derive(Eq, Compare, Debug)"
    }
    @dart_ast.DAbstractClass(name, methods) => {
      let method_str = methods
        .map(fn(m) {
          let param_str = format_params(m.params)
          let ret_str = dart_type_to_moon(m.ret_type)
          "  fn \{m.name}(\{param_str}) -> \{ret_str}"
        })
        .join("\n")
      "trait \{name} {\n\{method_str}\n}"
    }
  }
}

///|
/// 发射 MoonBit 方法（impl 块中的方法或独立方法）。
fn emit_moon_method(class_name : String, m : @dart_ast.DartMethod) -> String {
  let param_str = format_params(m.params)
  let ret_str = dart_type_to_moon(m.ret_type)
  let body_str = emit_moon_expr(m.body)
  "fn \{class_name}::\{m.name}(\{param_str}) -> \{ret_str} {\n  \{body_str}\n}"
}

///|
/// 完整程序发射（Dart AST → MoonBit 源码）。
pub fn emit_moon_program(decls : Array[@dart_ast.DartDecl]) -> String {
  let header = "// Generated by moon2dart reverse transpiler v0.8.0\n// DO NOT EDIT BY HAND\n\n"
  let body = decls.map(emit_moon_decl).join("\n\n")
  "\{header}\{body}\n"
}

///|
/// 反向转换管线 — Dart 源码字符串 → MoonBit 源码字符串。
pub fn reverse_transpile_source(src : String) -> String {
  let tokens = @dart_parser.DartLexer::make(src).tokenize()
  let decls = @dart_parser.DartParser::make(tokens).parse_program()
  emit_moon_program(decls)
}
