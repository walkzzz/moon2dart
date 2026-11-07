///|
/// Dart 表达式发射 — 将 MoonBit 表达式节点转为 Dart 代码字符串。
pub fn emit_dart_expr(e : @ast.MoonExpr) -> String {
  match e {
    @ast.EInt(n) => n.to_string()
    @ast.EDouble(d) => d.to_string()
    @ast.EBool(b) => if b { "true" } else { "false" }
    @ast.EString(s) => "\"\{s}\""
    @ast.EVar(name) => name
    @ast.ECall(name, args) => {
      let arg_str = args.map(emit_dart_expr).join(", ")
      "\{name}(\{arg_str})"
    }
    @ast.EBinOp(op, lhs, rhs) =>
      "\{emit_dart_expr(lhs)} \{op} \{emit_dart_expr(rhs)}"
    @ast.EIf(cond, then_, else_) =>
      "\{emit_dart_expr(cond)} ? \{emit_dart_expr(then_)} : \{emit_dart_expr(else_)}"
    @ast.EMatch(scrutinee, cases) => {
      let scrut = emit_dart_expr(scrutinee)
      let arms = cases
        .map(fn(pair) {
          let (pat, body) = pair
          "  \{emit_dart_pattern(pat)} => \{emit_dart_expr(body)}"
        })
        .join(",\n")
      "switch (\{scrut}) {\n\{arms}\n}"
    }
  }
}

///|
/// Dart 模式发射 — 将 MoonBit 模式节点转为 Dart 3 pattern 语法。
pub fn emit_dart_pattern(p : @ast.MoonPattern) -> String {
  match p {
    @ast.PVar(name) => "var \{name}"
    @ast.PInt(n) => n.to_string()
    @ast.PString(s) => "\"\{s}\""
    @ast.PWild => "_"
    @ast.PCtor(name, args) =>
      if args.length() == 0 {
        "\{name}()"
      } else {
        let arg_str = args.map(emit_dart_pattern).join(", ")
        "\{name}(\{arg_str})"
      }
  }
}

///|
/// Dart 声明发射。
pub fn emit_dart_decl(d : @ast.MoonDecl) -> String {
  match d {
    @ast.DFn(name, params, ret, body) => {
      let param_str = params
        .map(fn(pair) {
          let (pname, ptype) = pair
          "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
        })
        .join(", ")
      let ret_str = @typesys.emit_dart(@typesys.map_type(ret))
      "\{ret_str} \{name}(\{param_str}) {\n  return \{emit_dart_expr(body)};\n}"
    }
    @ast.DStruct(name, fields, derives) => {
      let field_str = fields
        .map(fn(pair) {
          let (fname, ftype) = pair
          "  \{@typesys.emit_dart(@typesys.map_type(ftype))} \{fname};"
        })
        .join("\n")
      let ctor_params = fields
        .map(fn(pair) {
          let (fname, _) = pair
          "required this.\{fname}"
        })
        .join(", ")
      let derive_methods = emit_derive_methods(name, fields, derives)
      "class \{name} {\n\{field_str}\n  \{name}({\{ctor_params}});\{derive_methods}\n}"
    }
    @ast.DEnum(name, variants) => {
      let variant_str = variants
        .map(fn(v) { "class \{v} extends \{name} {}" })
        .join("\n")
      "sealed class \{name} {}\n\{variant_str}"
    }
    @ast.DTrait(name, methods) => {
      let method_str = methods
        .map(fn(m) {
          let param_str = m.params
            .map(fn(pair) {
              let (pname, ptype) = pair
              "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
            })
            .join(", ")
          let ret_str = @typesys.emit_dart(@typesys.map_type(m.ret_type))
          "  \{ret_str} \{m.name}(\{param_str});"
        })
        .join("\n")
      "abstract class \{name} {\n\{method_str}\n}"
    }
    @ast.DImpl(trait_name, type_name, methods) => {
      let method_str = methods
        .map(fn(m) {
          let param_str = m.params
            .map(fn(pair) {
              let (pname, ptype) = pair
              "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
            })
            .join(", ")
          let ret_str = @typesys.emit_dart(@typesys.map_type(m.ret_type))
          "  \{ret_str} \{m.name}(\{param_str}) {\n    return \{emit_dart_expr(m.body)};\n  }"
        })
        .join("\n")
      "class \{type_name} implements \{trait_name} {\n\{method_str}\n}"
    }
  }
}

///|
/// 根据 derive 列表生成 Dart 方法（Debug→toString, Eq→operator==, Compare→compareTo）。
fn emit_derive_methods(
  name : String,
  fields : Array[(String, @ast.MoonType)],
  derives : Array[String],
) -> String {
  let mut methods = ""
  for d in derives {
    match d {
      "Debug" => {
        let field_list = fields
          .map(fn(pair) {
            let (fname, _) = pair
            "\{fname}: $\{fname}"
          })
          .join(", ")
        methods = methods +
          "\n  @override\n  String toString() => '\{name}(\{field_list})';"
      }
      "Eq" => {
        let field_cmps = fields
          .map(fn(pair) {
            let (fname, _) = pair
            "other.\{fname} == \{fname}"
          })
          .join(" && ")
        methods = methods +
          "\n  @override\n  bool operator==(Object other) =>\n    other is \{name} && \{field_cmps};"
      }
      "Compare" => {
        let field_cmps = fields
          .map(fn(pair) {
            let (fname, _) = pair
            "\{fname}.compareTo(other.\{fname})"
          })
          .join(" ?? ")
        methods = methods +
          "\n  @override\n  int compareTo(\{name} other) =>\n    \{field_cmps};"
      }
      _ => ()
    }
  }
  methods
}

///|
/// 完整程序发射（含文件头，DImpl 合并到 DStruct）。
pub fn emit_dart_program(decls : Array[@ast.MoonDecl]) -> String {
  let header = "// Generated by moon2dart v0.3.0\n// DO NOT EDIT BY HAND\n\n"
  let body = decls
    .map(fn(d) { emit_dart_decl_in_program(d, decls) })
    .filter(fn(s) { s != "" })
    .join("\n\n")
  "\{header}\{body}\n"
}

///|
/// 在程序上下文中发射声明 — DStruct 合并 DImpl，DImpl 有对应 DStruct 时跳过。
fn emit_dart_decl_in_program(
  d : @ast.MoonDecl,
  all_decls : Array[@ast.MoonDecl],
) -> String {
  match d {
    @ast.DImpl(_, type_name, _) =>
      if has_struct_named(all_decls, type_name) {
        ""
      } else {
        emit_dart_decl(d)
      }
    @ast.DStruct(name, fields, derives) => {
      let impls = collect_impls_for(all_decls, name)
      if impls.length() > 0 {
        emit_dart_struct_with_impls(name, fields, derives, impls)
      } else {
        emit_dart_decl(d)
      }
    }
    _ => emit_dart_decl(d)
  }
}

///|
/// 检查声明数组中是否存在指定名称的 DStruct。
fn has_struct_named(decls : Array[@ast.MoonDecl], name : String) -> Bool {
  for d in decls {
    match d {
      @ast.DStruct(n, _, _) => if n == name { return true }
      _ => ()
    }
  }
  false
}

///|
/// 收集指定类型名称的所有 DImpl（返回 (trait_name, methods) 列表）。
fn collect_impls_for(
  decls : Array[@ast.MoonDecl],
  type_name : String,
) -> Array[(String, Array[@ast.ImplMethod])] {
  let result : Array[(String, Array[@ast.ImplMethod])] = []
  for d in decls {
    match d {
      @ast.DImpl(trait_name, tn, methods) =>
        if tn == type_name {
          result.push((trait_name, methods))
        }
      _ => ()
    }
  }
  result
}

///|
/// 发射带 impl 合并的 DStruct — class Name implements Trait1, Trait2 { ... }
fn emit_dart_struct_with_impls(
  name : String,
  fields : Array[(String, @ast.MoonType)],
  derives : Array[String],
  impls : Array[(String, Array[@ast.ImplMethod])],
) -> String {
  let field_str = fields
    .map(fn(pair) {
      let (fname, ftype) = pair
      "  \{@typesys.emit_dart(@typesys.map_type(ftype))} \{fname};"
    })
    .join("\n")
  let ctor_params = fields
    .map(fn(pair) {
      let (fname, _) = pair
      "required this.\{fname}"
    })
    .join(", ")
  let derive_methods = emit_derive_methods(name, fields, derives)
  let implements_clause = impls
    .map(fn(pair) {
      let (trait_name, _) = pair
      trait_name
    })
    .join(", ")
  let impl_methods = impls
    .map(fn(pair) {
      let (_, methods) = pair
      methods
      .map(fn(m) {
        let param_str = m.params
          .map(fn(p) {
            let (pname, ptype) = p
            "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
          })
          .join(", ")
        let ret_str = @typesys.emit_dart(@typesys.map_type(m.ret_type))
        "  \{ret_str} \{m.name}(\{param_str}) {\n    return \{emit_dart_expr(m.body)};\n  }"
      })
      .join("\n")
    })
    .join("\n")
  "class \{name} implements \{implements_clause} {\n\{field_str}\n  \{name}({\{ctor_params}});\{derive_methods}\n\{impl_methods}\n}"
}
