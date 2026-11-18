///|
/// 发射上下文 — 类型环境 + 语义模式 + 嵌套 Option 标记 | Emission context — type env + semantics mode + nested-Option flag
pub(all) struct EmitCtx {
  env : @typesys.TypeEnv? // 程序级发射提供的类型环境；单表达式 API 为 None（保守 fast）| provided at program level; None for single-expression APIs
  mode : @ast.SemanticsMode // Wrapping 生成回绕模拟层；Fast 裸发 | Wrapping generates wrapping shims; Fast emits raw
  nested_option_context : Bool // 嵌套 Option 上下文 | nested Option context
}

///|
/// 默认单表达式上下文 — 无类型环境 + Fast 模式 | Default single-expression context — no env + Fast mode
fn default_expr_ctx(nested : Bool) -> EmitCtx {
  { env: None, mode: @ast.Fast, nested_option_context: nested, }
}

///|
/// Dart 表达式发射 — 将 MoonBit 表达式节点转为 Dart 代码字符串 | Dart expression emission — convert MoonBit expression nodes to Dart code strings
pub fn emit_dart_expr(e : @ast.MoonExpr) -> String {
  emit_dart_expr_inner(e, default_expr_ctx(false))
}

///|
/// Dart 表达式发射（嵌套 Option 感知）| Dart expression emission (nested Option aware)
/// 当 nested_option_context 为 true 时 Some/None 使用 Option.some/Option.none 辅助类语法 | When nested_option_context is true, Some/None use Option.some/Option.none auxiliary class syntax
pub fn emit_dart_expr_nested(e : @ast.MoonExpr) -> String {
  emit_dart_expr_inner(e, default_expr_ctx(true))
}

///|
fn emit_dart_expr_inner(e : @ast.MoonExpr, ctx : EmitCtx) -> String {
  match e {
    @ast.EInt(n) => n.to_string()
    @ast.EDouble(d) => d.to_string()
    @ast.EBool(b) => if b { "true" } else { "false" }
    @ast.EString(s) => "\"\{s}\""
    @ast.EVar(name) =>
      if name == "None" {
        if ctx.nested_option_context {
          "Option.none()"
        } else {
          "null"
        }
      } else {
        name
      }
    @ast.ECall(name, args) =>
      if name == "Some" && args.length() == 1 {
        if ctx.nested_option_context {
          let inner = emit_dart_expr_inner(args[0], ctx)
          "Option.some(\{inner})"
        } else {
          emit_dart_expr_inner(args[0], ctx)
        }
      } else if name == "None" && args.length() == 0 {
        if ctx.nested_option_context {
          "Option.none()"
        } else {
          "null"
        }
      } else {
        let arg_str = args
          .map(fn(a) { emit_dart_expr_inner(a, ctx) })
          .join(", ")
        // MoonBit println → Dart print（Dart 无 println，输出语义一致）| MoonBit println maps to Dart print
        if name == "println" && args.length() == 1 {
          "print(\{arg_str})"
        } else {
          "\{name}(\{arg_str})"
        }
      }
    @ast.EBinOp(op, lhs, rhs) => {
      let lhs_s = emit_dart_expr_inner(lhs, ctx)
      let rhs_s = emit_dart_expr_inner(rhs, ctx)
      emit_binop(op, lhs_s, rhs_s, e, ctx)
    }
    @ast.EIf(cond, then_, else_) => {
      let c = emit_dart_expr_inner(cond, ctx)
      let t = emit_dart_expr_inner(then_, ctx)
      let e_ = emit_dart_expr_inner(else_, ctx)
      "\{c} ? \{t} : \{e_}"
    }
    @ast.EMatch(scrutinee, cases) => {
      let scrut = emit_dart_expr_inner(scrutinee, ctx)
      let sorted = sort_option_cases(cases)
      let arms = sorted
        .map(fn(pair) {
          let (pat, body) = pair
          "  \{emit_dart_pattern_inner(pat, ctx.nested_option_context)} => \{emit_dart_expr_inner(body, ctx)}"
        })
        .join(",\n")
      "switch (\{scrut}) {\n\{arms}\n}"
    }
    @ast.EAwait(inner) => "await \{emit_dart_expr_inner(inner, ctx)}"
    @ast.ELambda(params, body) => {
      let param_str = params
        .map(fn(pair) {
          let (pname, _) = pair
          pname
        })
        .join(", ")
      match body {
        @ast.EBlock([single]) =>
          "(\{param_str}) => \{emit_dart_expr_inner(single, ctx)}"
        @ast.EBlock(stmts) => {
          let lines : Array[String] = []
          let n = stmts.length()
          for i in 0..<n {
            let s = emit_dart_expr_inner(stmts[i], ctx)
            if i == n - 1 {
              lines.push("  return \{s};")
            } else {
              lines.push("  \{s};")
            }
          }
          "(\{param_str}) {\n\{lines.join("\n")}\n}"
        }
        _ => "(\{param_str}) => \{emit_dart_expr_inner(body, ctx)}"
      }
    }
    @ast.EBlock(stmts) => {
      // 兜底：块作为子表达式出现（正常不发生）| fallback: block as sub-expression (should not normally occur)
      let parts = stmts.map(fn(s) { emit_dart_expr_inner(s, ctx) }).join("; ")
      "(\{parts})"
    }
  }
}

///|
/// 二元运算分类发射 — 按操作数推断类型与语义模式决定发射形态 | Classified binary-op emission — decided by inferred operand type and semantics mode
fn emit_binop(
  op : String,
  lhs_s : String,
  rhs_s : String,
  whole : @ast.MoonExpr,
  ctx : EmitCtx,
) -> String {
  let inferred = match ctx.env {
    Some(env) => @typesys.infer_expr_type(whole, env)
    None => None
  }
  match inferred {
    Some(@ast.MInt) => emit_int_binop(op, lhs_s, rhs_s, ctx)
    Some(@ast.MInt64) => emit_int64_binop(op, lhs_s, rhs_s)
    // Double/Float/String/Bool/推断失败：裸发（Double 为 IEEE 754 64 位，两端语义一致）
    _ => "\{lhs_s} \{op} \{rhs_s}"
  }
}

///|
/// MoonBit Int（32 位回绕）算术发射 | MoonBit Int (32-bit wrapping) arithmetic emission
///
/// Wrapping 模式：+ - * / % 经 mb32* shim 模拟 wasm i32 回绕，两端结果一致。
/// Fast 模式：+ - * 裸发（L2：64 位溢出行为差异，程序级诊断标注）；/ % 修正为 Dart 整数语义。
fn emit_int_binop(op : String, l : String, r : String, ctx : EmitCtx) -> String {
  if ctx.mode is @ast.Wrapping {
    match op {
      "+" => "mb32Add(\{l}, \{r})"
      "-" => "mb32Sub(\{l}, \{r})"
      "*" => "mb32Mul(\{l}, \{r})"
      "/" => "mb32Div(\{l}, \{r})" // 整数除法（~/）+ INT_MIN/-1 回绕保护
      "%" => "mb32Rem(\{l}, \{r})" // 截断取余（符号跟被除数），非 Dart %（欧几里得）
      _ => "\{l} \{op} \{r}" // 比较与逻辑运算两端语义一致，裸发
    }
  } else {
    match op {
      "/" => "\{l} ~/ \{r}" // 修正：整数除法不可发 `/`（Dart `/` 是浮点除法）
      "%" => "\{l}.remainder(\{r})" // 修正：Dart % 为欧几里得余数，MoonBit 为截断余数
      _ => "\{l} \{op} \{r}"
    }
  }
}

///|
/// MoonBit Int64 算术发射 — Dart VM int 亦为 64 位回绕，+ - * 天然一致 | MoonBit Int64 arithmetic — Dart VM int is also 64-bit wrapping
/// 适用约束：Dart VM；编译到 web 时 int 退化为 JS number（值域 2^53），见语义文档。
fn emit_int64_binop(op : String, l : String, r : String) -> String {
  match op {
    "/" => "\{l} ~/ \{r}" // 整除修正（原发 `/` 是浮点除法 bug）
    "%" => "\{l}.remainder(\{r})" // 截断余数修正
    _ => "\{l} \{op} \{r}"
  }
}

///|
/// 将 None pattern（对应 null）的 case 排到最前面 | Sort None pattern (null) cases to the front
/// 确保 Dart 3 switch expression 中 null case 先匹配 | Ensure null case matches first in Dart 3 switch expression
fn sort_option_cases(
  cases : Array[(@ast.MoonPattern, @ast.MoonExpr)],
) -> Array[(@ast.MoonPattern, @ast.MoonExpr)] {
  let null_cases : Array[(@ast.MoonPattern, @ast.MoonExpr)] = []
  let other_cases : Array[(@ast.MoonPattern, @ast.MoonExpr)] = []
  for c in cases {
    let (pat, _) = c
    match pat {
      @ast.PCtor(name, args) =>
        if name == "None" && args.length() == 0 {
          null_cases.push(c)
        } else {
          other_cases.push(c)
        }
      _ => other_cases.push(c)
    }
  }
  for c in other_cases {
    null_cases.push(c)
  }
  null_cases
}

///|
/// Dart 模式发射 — 将 MoonBit 模式节点转为 Dart 3 pattern 语法 | Dart pattern emission — convert MoonBit pattern nodes to Dart 3 pattern syntax
pub fn emit_dart_pattern(p : @ast.MoonPattern) -> String {
  emit_dart_pattern_inner(p, false)
}

///|
fn emit_dart_pattern_inner(
  p : @ast.MoonPattern,
  nested_option_context : Bool,
) -> String {
  match p {
    @ast.PVar(name) => "var \{name}"
    @ast.PInt(n) => n.to_string()
    @ast.PString(s) => "\"\{s}\""
    @ast.PWild => "_"
    @ast.PCtor(name, args) =>
      if name == "None" && args.length() == 0 {
        if nested_option_context {
          "Option _ when _.isNone"
        } else {
          "null"
        }
      } else if name == "Some" && args.length() == 1 {
        if nested_option_context {
          let inner = emit_dart_pattern_inner(args[0], nested_option_context)
          "Option _ when _.isSome && _.value is \{inner}"
        } else {
          emit_dart_pattern_inner(args[0], nested_option_context)
        }
      } else if args.length() == 0 {
        "\{name}()"
      } else {
        let arg_str = args
          .map(fn(a) { emit_dart_pattern_inner(a, nested_option_context) })
          .join(", ")
        "\{name}(\{arg_str})"
      }
  }
}

///|
/// Dart 声明发射 | Dart declaration emission
pub fn emit_dart_decl(d : @ast.MoonDecl) -> String {
  emit_dart_decl_with_ctx(d, default_expr_ctx(false))
}

///|
/// 函数体发射 — EBlock 多语句（尾语句按返回类型 return；Unit 函数为语句）与单表达式两种形态 | Function body emission — EBlock multi-statement (last returned; Unit fn as statement) vs single expression
fn emit_fn_body(
  body : @ast.MoonExpr,
  ret : @ast.MoonType,
  ctx : EmitCtx,
) -> String {
  match body {
    @ast.EBlock(stmts) => {
      let lines : Array[String] = []
      let n = stmts.length()
      for i in 0..<n {
        let s = emit_dart_expr_inner(stmts[i], ctx)
        if i == n - 1 && !(ret is @ast.MUnit) {
          lines.push("  return \{s};")
        } else {
          lines.push("  \{s};")
        }
      }
      lines.join("\n")
    }
    _ =>
      if ret is @ast.MUnit {
        "  \{emit_dart_expr_inner(body, ctx)};"
      } else {
        "  return \{emit_dart_expr_inner(body, ctx)};"
      }
  }
}

///|
/// Dart 声明发射（带上下文：类型环境 + 语义模式）| Dart declaration emission with context (type env + semantics mode)
fn emit_dart_decl_with_ctx(d : @ast.MoonDecl, ctx : EmitCtx) -> String {
  match d {
    @ast.DFn(name, type_params, params, ret, body) => {
      let param_str = format_dart_params(params)
      let ret_str = @typesys.map_type(ret).to_dart_string()
      let generic = format_generics(type_params)
      let body_str = emit_fn_body(body, ret, ctx)
      "\{ret_str} \{name}\{generic}(\{param_str}) {\n\{body_str}\n}"
    }
    @ast.DAsyncFn(name, type_params, params, ret, body) => {
      let param_str = format_dart_params(params)
      let ret_str = @typesys.map_type(ret).to_dart_string()
      let generic = format_generics(type_params)
      let body_str = emit_fn_body(body, ret, ctx)
      "Future<\{ret_str}> \{name}\{generic}(\{param_str}) async {\n\{body_str}\n}"
    }
    @ast.DStruct(name, type_params, fields, derives) => {
      let field_str = format_dart_fields(fields)
      let ctor_params = format_ctor_params(fields)
      let derive_methods = emit_derive_methods(name, fields, derives)
      let generic = format_generics(type_params)
      "class \{name}\{generic} {\n\{field_str}\n  \{name}\{generic}({\{ctor_params}});\{derive_methods}\n}"
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
          let param_str = format_dart_params(m.params)
          let ret_str = @typesys.map_type(m.ret_type).to_dart_string()
          "  \{ret_str} \{m.name}(\{param_str});"
        })
        .join("\n")
      "abstract class \{name} {\n\{method_str}\n}"
    }
    @ast.DImpl(trait_name, type_name, methods) => {
      let method_str = methods
        .map(fn(m) {
          let param_str = format_dart_params(m.params)
          let ret_str = @typesys.map_type(m.ret_type).to_dart_string()
          let body_str = emit_fn_body(m.body, m.ret_type, ctx)
          "  \{ret_str} \{m.name}(\{param_str}) {\n\{body_str}\n  }"
        })
        .join("\n")
      "class \{type_name} implements \{trait_name} {\n\{method_str}\n}"
    }
    @ast.DExternFn(name, params, ret, c_symbol) => {
      let native_params = params
        .map(fn(pair) {
          let (pname, ptype) = pair
          "\{@typesys.ffi_native_type(ptype)} \{pname}"
        })
        .join(", ")
      let dart_typedef_params = params
        .map(fn(pair) {
          let (pname, ptype) = pair
          "\{@typesys.ffi_dart_type(ptype)} \{pname}"
        })
        .join(", ")
      let native_ret = @typesys.ffi_native_type(ret)
      let dart_typedef_ret = @typesys.ffi_dart_type(ret)
      let wrapper_params = params
        .map(fn(pair) {
          let (pname, ptype) = pair
          if ptype is @ast.MString {
            "String \{pname}"
          } else {
            "\{@typesys.ffi_dart_type(ptype)} \{pname}"
          }
        })
        .join(", ")
      let wrapper_ret = if ret is @ast.MString {
        "String"
      } else {
        @typesys.ffi_dart_type(ret)
      }
      let has_string_param = {
        let mut found = false
        for p in params {
          let (_, t) = p
          if t is @ast.MString {
            found = true
          }
        }
        found
      }
      let has_string_ret = ret is @ast.MString
      let lookup_var = "_\{name}"
      let call_args = params
        .map(fn(pair) {
          let (pname, ptype) = pair
          if ptype is @ast.MString {
            "\{pname}.toUtf8(allocator: arena)"
          } else {
            pname
          }
        })
        .join(", ")
      let wrapper_body = if has_string_param && has_string_ret {
        "using((arena) {\n    return \{lookup_var}(\{call_args}).toDartString();\n  })"
      } else if has_string_param && !has_string_ret {
        "using((arena) {\n    return \{lookup_var}(\{call_args});\n  })"
      } else if !has_string_param && has_string_ret {
        "return \{lookup_var}(\{call_args}).toDartString();"
      } else {
        "return \{lookup_var}(\{call_args});"
      }
      let native_typedef_name = "_\{to_pascal(name)}Native"
      let dart_typedef_name = "_\{to_pascal(name)}Dart"

      let typedefs = "typedef \{native_typedef_name} = \{native_ret} Function(\{native_params});\ntypedef \{dart_typedef_name} = \{dart_typedef_ret} Function(\{dart_typedef_params});"
      let lookup = "final \{lookup_var} = _dylib.lookupFunction<\{native_typedef_name}, \{dart_typedef_name}>('\{c_symbol}');"
      let wrapper = "\{wrapper_ret} \{name}(\{wrapper_params}) {\n  \{wrapper_body}\n}"
      "\{typedefs}\n\{lookup}\n\{wrapper}"
    }
  }
}

///|
/// 收集声明中使用的所有 MoonType | Collect all MoonType used in a declaration
fn collect_types_from_decl(d : @ast.MoonDecl) -> Array[@ast.MoonType] {
  match d {
    @ast.DFn(_, _, params, ret, _) => {
      let param_types = params.map(fn(p) {
        let (_, t) = p
        t
      })
      param_types + [ret]
    }
    @ast.DAsyncFn(_, _, params, ret, _) => {
      let param_types = params.map(fn(p) {
        let (_, t) = p
        t
      })
      param_types + [ret]
    }
    @ast.DStruct(_, _, fields, _) =>
      fields.map(fn(f) {
        let (_, t) = f
        t
      })
    @ast.DTrait(_, methods) =>
      methods
      .iter()
      .flat_map(fn(m) {
        let param_types : Array[@ast.MoonType] = m.params.map(fn(p) {
          let (_, t) = p
          t
        })
        (param_types + [m.ret_type]).iter()
      })
      .to_array()
    @ast.DImpl(_, _, methods) =>
      methods
      .iter()
      .flat_map(fn(m) {
        let param_types : Array[@ast.MoonType] = m.params.map(fn(p) {
          let (_, t) = p
          t
        })
        (param_types + [m.ret_type]).iter()
      })
      .to_array()
    @ast.DExternFn(_, params, ret, _) => {
      let param_types = params.map(fn(p) {
        let (_, t) = p
        t
      })
      param_types + [ret]
    }
    @ast.DEnum(_, _) => []
  }
}

///|
/// 为声明生成语义诊断注释（Fast 模式 L2 标注 + L3/L4 类型标注） | Generate semantic diagnostic comments (Fast-mode L2 annotation + L3/L4 type annotations)
fn emit_semantic_diagnostic(
  d : @ast.MoonDecl,
  mode : @ast.SemanticsMode,
) -> String {
  let types = collect_types_from_decl(d)
  let all_comments : Array[String] = []
  // Fast 模式：签名含 MInt 时追加 L2 标注（64 位算术，溢出行为与 MoonBit 不同）
  if mode is @ast.Fast {
    let mut int_found = false
    for t in types {
      if t is @ast.MInt && !int_found {
        int_found = true
        all_comments.push(
          "// [L2-SEMANTICS] Int: MoonBit 32-bit wrapping arithmetic vs Dart 64-bit int; overflow behavior differs (use --semantics wrapping to emulate)",
        )
      }
    }
  }
  let l3_comments = types
    .iter()
    .filter(fn(t) { @typesys.semantic_level(t) is L3 })
    .map(fn(t) {
      let restriction = match t {
        @ast.MUInt => "unsigned semantics lost → signed int"
        @ast.MUInt64 => "unsigned 64-bit semantics lost → signed int"
        @ast.MFloat => "float precision promoted → double"
        @ast.MChar => "char → int (rune representation)"
        _ => "semantic loss in type mapping"
      }
      "// [L3-CONSTRAINED] \{t.to_moon_string()}: \{restriction}"
    })
    .to_array()
  let l4_comments = types
    .iter()
    .filter(fn(t) { @typesys.semantic_level(t) is L4 })
    .map(fn(t) {
      let loss = match t {
        @ast.MCustom(name) => "no Dart equivalent for \{name}"
        _ => "no Dart equivalent"
      }
      "// [L4-INEQUIVALENT] \{t.to_moon_string()}: \{loss}"
    })
    .to_array()
  for c in l3_comments {
    all_comments.push(c)
  }
  for c in l4_comments {
    all_comments.push(c)
  }
  if all_comments.length() > 0 {
    all_comments.join("\n") + "\n"
  } else {
    ""
  }
}

///|
/// 根据 derive 列表生成 Dart 方法（Debug→toString, Eq→operator==, Compare→compareTo） | Generate Dart methods from derive list (Debug→toString, Eq→operator==, Compare→compareTo)
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
/// 完整程序发射（含文件头，DImpl 合并到 DStruct，Result class 自动生成，FFI import 自动生成）| Full program emission (with header, DImpl merged into DStruct, Result class auto-generated, FFI import auto-generated)
pub fn emit_dart_program(decls : Array[@ast.MoonDecl]) -> String {
  emit_dart_program_full(decls, "libnative.so", @ast.Wrapping)
}

///|
/// 完整程序发射（可指定 FFI 库名）| Full program emission (with configurable FFI library name)
pub fn emit_dart_program_with_lib(
  decls : Array[@ast.MoonDecl],
  lib_name : String,
) -> String {
  emit_dart_program_full(decls, lib_name, @ast.Wrapping)
}

///|
/// 完整程序发射（语义模式感知）| Full program emission (semantics-mode aware)
pub fn emit_dart_program_with_mode(
  decls : Array[@ast.MoonDecl],
  mode : @ast.SemanticsMode,
) -> String {
  emit_dart_program_full(decls, "libnative.so", mode)
}

///|
/// 完整程序发射（FFI 库名 + 语义模式完整控制） | Full program emission (full control of FFI library name + semantics mode)
pub fn emit_dart_program_full(
  decls : Array[@ast.MoonDecl],
  lib_name : String,
  mode : @ast.SemanticsMode,
) -> String {
  let header = generate_header()
  let ffi_imports = if needs_ffi(decls) {
    "import 'dart:ffi';\nimport 'package:ffi/ffi.dart';\n\n"
  } else {
    ""
  }
  let ffi_init = if needs_ffi(decls) {
    "final _dylib = DynamicLibrary.open('\{lib_name}');\n\n"
  } else {
    ""
  }
  let result_class = if needs_result_class(decls) {
    emit_result_class() + "\n\n"
  } else {
    ""
  }
  let option_class = if @typesys.needs_option_class(decls) {
    emit_option_class() + "\n\n"
  } else {
    ""
  }
  let shim = if mode is @ast.Wrapping {
    let ops = @typesys.collect_int_arith_ops(decls)
    if ops.length() > 0 {
      emit_wrapping_shim(ops) + "\n\n"
    } else {
      ""
    }
  } else {
    ""
  }
  let body = decls
    .map(fn(d) { emit_dart_decl_in_program_with_mode(d, decls, mode) })
    .filter(fn(s) { s != "" })
    .join("\n\n")
  "\{header}\{ffi_imports}\{ffi_init}\{result_class}\{option_class}\{shim}\{body}\n"
}

///|
/// 生成 32 位回绕运行时 shim（仅包含程序实际用到的操作） | Generate 32-bit wrapping runtime shim (only ops actually used by the program)
///
/// MoonBit Int 算术是 wasm i32 语义：加/减/乘回绕，除法向零截断，取余符号跟被除数。
/// `INT_MIN / -1` 与除零按 wasm i32.div_s 规范是 **trap**（异常终止）——mb32Div 显式抛异常模拟，
/// 使两端行为类别一致（MoonBit native 硬件 trap / Dart throw）。
fn emit_wrapping_shim(ops : Array[String]) -> String {
  let header = "// === moon2dart Int wrapping shim — emulates MoonBit 32-bit overflow (wasm i32) on Dart 64-bit int ==="
  let defs : Array[String] = []
  for op in ops {
    let def = match op {
      "+" => "int mb32Add(int a, int b) => (a + b).toSigned(32);"
      "-" => "int mb32Sub(int a, int b) => (a - b).toSigned(32);"
      "*" => "int mb32Mul(int a, int b) => (a * b).toSigned(32);"
      "/" =>
        "int mb32Div(int a, int b) => (a == -2147483648 && b == -1 || b == 0) ? (throw StateError('mb32Div: integer overflow trap (INT_MIN/-1 or div by zero), mirrors MoonBit wasm i32.div_s')) : ((a ~/ b).toSigned(32));"
      "%" =>
        "int mb32Rem(int a, int b) => b == 0 ? (throw StateError('mb32Rem: division by zero trap, mirrors MoonBit wasm i32.rem_s')) : a.remainder(b).toSigned(32);"
      _ => ""
    }
    if def != "" {
      defs.push(def)
    }
  }
  header + "\n" + defs.join("\n")
}

///|
/// 过滤掉 DExternFn 声明，只保留纯 MoonBit 子集 | Filter out DExternFn declarations, keeping only the pure MoonBit subset
pub fn filter_pure(decls : Array[@ast.MoonDecl]) -> Array[@ast.MoonDecl] {
  let result : Array[@ast.MoonDecl] = []
  for d in decls {
    match d {
      @ast.DExternFn(_, _, _, _) => ()
      _ => result.push(d)
    }
  }
  result
}

///|
/// 检测声明数组中是否使用了 Result 类型 | Check if declarations use the Result type
fn needs_result_class(decls : Array[@ast.MoonDecl]) -> Bool {
  for d in decls {
    match d {
      @ast.DFn(_, _, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if t.contains_result() {
            return true
          }
        }
        if ret.contains_result() {
          return true
        }
      }
      @ast.DAsyncFn(_, _, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if t.contains_result() {
            return true
          }
        }
        if ret.contains_result() {
          return true
        }
      }
      @ast.DStruct(_, _, fields, _) =>
        for f in fields {
          let (_, t) = f
          if t.contains_result() {
            return true
          }
        }
      @ast.DTrait(_, methods) =>
        for m in methods {
          for p in m.params {
            let (_, t) = p
            if t.contains_result() {
              return true
            }
          }
          if m.ret_type.contains_result() {
            return true
          }
        }
      @ast.DImpl(_, _, methods) =>
        for m in methods {
          for p in m.params {
            let (_, t) = p
            if t.contains_result() {
              return true
            }
          }
          if m.ret_type.contains_result() {
            return true
          }
        }
      @ast.DExternFn(_, params, ret, _) => {
        for p in params {
          let (_, t) = p
          if t.contains_result() {
            return true
          }
        }
        if ret.contains_result() {
          return true
        }
      }
      _ => ()
    }
  }
  false
}

///|
/// 生成 Result sealed class 定义 | Generate the Result sealed class definition
fn emit_result_class() -> String {
  "sealed class Result<T, E> {}\nclass Ok<T, E> extends Result<T, E> {\n  final T value;\n  Ok(this.value);\n}\nclass Err<T, E> extends Result<T, E> {\n  final E error;\n  Err(this.error);\n}"
}

///|
/// 生成 Option 辅助类定义（用于嵌套 Option 三分态语义保留） | Generate the Option auxiliary class definition (for nested Option ternary-state semantic preservation)
pub fn emit_option_class() -> String {
  "class Option<T> {\n  final T? _value;\n  final bool _isSome;\n\n  Option._internal(this._value, this._isSome);\n\n  factory Option.some(T value) => Option._internal(value, true);\n  factory Option.none() => Option._internal(null, false);\n\n  bool get isSome => _isSome;\n  bool get isNone => !_isSome;\n  T get value => _value!;\n}"
}

///|
/// 在程序上下文中发射声明（默认 Wrapping 语义，flutter_emitter 兼容入口） | Emit declaration in program context (default Wrapping semantics, flutter_emitter compatibility entry)
fn emit_dart_decl_in_program(
  d : @ast.MoonDecl,
  all_decls : Array[@ast.MoonDecl],
) -> String {
  emit_dart_decl_in_program_with_mode(d, all_decls, @ast.Wrapping)
}

///|
/// 在程序上下文中发射声明（语义模式感知：DFn/DAsyncFn/DImpl 构建类型环境） | Emit declaration in program context (mode-aware: builds type env for DFn/DAsyncFn/DImpl)
fn emit_dart_decl_in_program_with_mode(
  d : @ast.MoonDecl,
  all_decls : Array[@ast.MoonDecl],
  mode : @ast.SemanticsMode,
) -> String {
  let diagnostic = emit_semantic_diagnostic(d, mode)
  match d {
    @ast.DImpl(_, type_name, _) =>
      if has_struct_named(all_decls, type_name) {
        ""
      } else {
        "\{diagnostic}\{emit_dart_decl_with_ctx(d, { env: None, mode: mode, nested_option_context: false })}"
      }
    @ast.DStruct(name, type_params, fields, derives) => {
      let impls = collect_impls_for(all_decls, name)
      if impls.length() > 0 {
        "\{diagnostic}\{emit_dart_struct_with_impls(name, type_params, fields, derives, impls, all_decls, mode)}"
      } else {
        "\{diagnostic}\{emit_dart_decl_with_ctx(d, { env: None, mode: mode, nested_option_context: false })}"
      }
    }
    @ast.DFn(_, _, params, _, _) =>
      "\{diagnostic}\{emit_dart_decl_with_ctx(d, { env: Some(@typesys.TypeEnv::for_function(all_decls, params)), mode: mode, nested_option_context: false })}"
    @ast.DAsyncFn(_, _, params, _, _) =>
      "\{diagnostic}\{emit_dart_decl_with_ctx(d, { env: Some(@typesys.TypeEnv::for_function(all_decls, params)), mode: mode, nested_option_context: false })}"
    _ =>
      "\{diagnostic}\{emit_dart_decl_with_ctx(d, { env: None, mode: mode, nested_option_context: false })}"
  }
}

///|
/// 检查声明数组中是否存在指定名称的 DStruct | Check if a DStruct with the given name exists in declarations
fn has_struct_named(decls : Array[@ast.MoonDecl], name : String) -> Bool {
  for d in decls {
    match d {
      @ast.DStruct(n, _, _, _) => if n == name { return true }
      _ => ()
    }
  }
  false
}

///|
/// 收集指定类型名称的所有 DImpl（返回 (trait_name, methods) 列表） | Collect all DImpl for the given type name (returns (trait_name, methods) list)
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
/// 发射带 impl 合并的 DStruct — class Name implements Trait1, Trait2 { ... } | Emit DStruct with merged impls — class Name implements Trait1, Trait2 { ... }
fn emit_dart_struct_with_impls(
  name : String,
  type_params : Array[String],
  fields : Array[(String, @ast.MoonType)],
  derives : Array[String],
  impls : Array[(String, Array[@ast.ImplMethod])],
  all_decls : Array[@ast.MoonDecl],
  mode : @ast.SemanticsMode,
) -> String {
  let field_str = format_dart_fields(fields)
  let ctor_params = format_ctor_params(fields)
  let derive_methods = emit_derive_methods(name, fields, derives)
  let generic = format_generics(type_params)
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
        let param_str = format_dart_params(m.params)
        let ret_str = @typesys.map_type(m.ret_type).to_dart_string()
        let mctx : EmitCtx = {
          env: Some(@typesys.TypeEnv::for_function(all_decls, m.params)),
          mode,
          nested_option_context: false,
        }
        let body_str = emit_fn_body(m.body, m.ret_type, mctx)
        "  \{ret_str} \{m.name}(\{param_str}) {\n\{body_str}\n  }"
      })
      .join("\n")
    })
    .join("\n")
  "class \{name}\{generic} implements \{implements_clause} {\n\{field_str}\n  \{name}\{generic}({\{ctor_params}});\{derive_methods}\n\{impl_methods}\n}"
}

///|
/// 检测声明数组中是否包含 DExternFn（需要 FFI） | Check if declarations contain DExternFn (requiring FFI)
fn needs_ffi(decls : Array[@ast.MoonDecl]) -> Bool {
  for d in decls {
    match d {
      @ast.DExternFn(_, _, _, _) => return true
      _ => ()
    }
  }
  false
}

///|
/// snake_case → PascalCase（用于 typedef 命名） | snake_case to PascalCase (for typedef naming)
fn to_pascal(s : String) -> String {
  let mut result = ""
  let mut capitalize_next = true
  for ch in s.to_array() {
    if ch == '_' {
      capitalize_next = true
    } else if capitalize_next {
      let upper_ch = if ch >= 'a' && ch <= 'z' {
        (ch.to_int() - 32).unsafe_to_char()
      } else {
        ch
      }
      result = result + upper_ch.to_string()
      capitalize_next = false
    } else {
      result = result + ch.to_string()
    }
  }
  result
}
