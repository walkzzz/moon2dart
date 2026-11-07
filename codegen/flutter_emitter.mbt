///|
/// Flutter widget 名称集合 — 判断函数名是否对应 Flutter widget 构造器。
fn is_flutter_widget(name : String) -> Bool {
  match name {
    "Text"
    | "Container"
    | "Row"
    | "Column"
    | "Stack"
    | "Padding"
    | "Expanded"
    | "Center"
    | "SizedBox"
    | "ListTile"
    | "Icon"
    | "FloatingActionButton"
    | "ElevatedButton"
    | "GestureDetector"
    | "AppBar"
    | "Scaffold"
    | "MaterialApp"
    | "TextButton"
    | "OutlinedButton"
    | "Card"
    | "Divider"
    | "Spacer"
    | "Flexible"
    | "Positioned"
    | "Align"
    | "AspectRatio"
    | "ConstrainedBox"
    | "FittedBox"
    | "Opacity"
    | "Transform"
    | "DecoratedBox"
    | "ClipRRect"
    | "ClipOval"
    | "IntrinsicHeight"
    | "IntrinsicWidth"
    | "LimitedBox"
    | "Offstage"
    | "OverflowBox"
    | "FractionallySizedBox"
    | "ShaderMask"
    | "ColorFiltered"
    | "BackdropFilter"
    | "ClipPath"
    | "CircularProgressIndicator"
    | "LinearProgressIndicator"
    | "Image"
    | "CircleAvatar"
    | "Tooltip"
    | "Hero"
    | "DefaultTextStyle"
    | "Directionality"
    | "Baseline"
    | "SliverToBoxAdapter"
    | "SliverList"
    | "SliverGrid"
    | "CustomScrollView"
    | "NestedScrollView"
    | "RefreshIndicator"
    | "Dismissible"
    | "Draggable"
    | "DragTarget"
    | "LongPressDraggable"
    | "Semantics"
    | "MergeSemantics"
    | "ExcludeSemantics"
    | "TextField"
    | "TextFormField"
    | "InputDecoration"
    | "Switch"
    | "Checkbox"
    | "Radio"
    | "Slider"
    | "DropdownButton"
    | "PopupMenuButton"
    | "InkWell"
    | "InkResponse" => true
    _ => false
  }
}

///|
/// Flutter 辅助类名称集合 — EdgeInsets, BoxDecoration 等。
fn is_flutter_helper(name : String) -> Bool {
  match name {
    "EdgeInsets_all"
    | "EdgeInsets_symmetric"
    | "EdgeInsets_only"
    | "EdgeInsets_zero"
    | "BoxDecoration"
    | "BorderRadius_all"
    | "BorderRadius_circular"
    | "BorderRadius_only"
    | "Matrix4_identity"
    | "Matrix4_rotationZ"
    | "Matrix4_translationValues"
    | "Icons_xxx"
    | "TextStyle"
    | "CircularBorderRadius" => true
    _ => false
  }
}

///|
/// 发射 Flutter widget 表达式 — 将 widget 函数调用转为 Flutter widget 代码。
pub fn emit_flutter_expr(e : @ast.MoonExpr) -> String {
  match e {
    @ast.EString(s) => "'\{s}'"
    @ast.EInt(n) => n.to_string()
    @ast.EDouble(d) => d.to_string()
    @ast.EBool(b) => if b { "true" } else { "false" }
    @ast.EVar(name) => if name == "None" { "null" } else { name }
    @ast.ECall(name, args) =>
      if is_flutter_widget(name) {
        emit_flutter_widget_call(name, args)
      } else if name == "Some" && args.length() == 1 {
        emit_flutter_expr(args[0])
      } else if name == "None" && args.length() == 0 {
        "null"
      } else if name == "EdgeInsets_all" && args.length() == 1 {
        "EdgeInsets.all(\{emit_flutter_expr(args[0])})"
      } else if name == "EdgeInsets_symmetric" {
        let h = if args.length() >= 1 {
          emit_flutter_expr(args[0])
        } else {
          "0.0"
        }
        let v = if args.length() >= 2 {
          emit_flutter_expr(args[1])
        } else {
          "0.0"
        }
        "EdgeInsets.symmetric(horizontal: \{h}, vertical: \{v})"
      } else if name == "EdgeInsets_only" {
        let left = if args.length() >= 1 {
          emit_flutter_expr(args[0])
        } else {
          "0.0"
        }
        let top = if args.length() >= 2 {
          emit_flutter_expr(args[1])
        } else {
          "0.0"
        }
        let right = if args.length() >= 3 {
          emit_flutter_expr(args[2])
        } else {
          "0.0"
        }
        let bottom = if args.length() >= 4 {
          emit_flutter_expr(args[3])
        } else {
          "0.0"
        }
        "EdgeInsets.only(left: \{left}, top: \{top}, right: \{right}, bottom: \{bottom})"
      } else if name == "BorderRadius_all" && args.length() == 1 {
        "BorderRadius.all(Radius.circular(\{emit_flutter_expr(args[0])}))"
      } else if name == "BorderRadius_circular" && args.length() == 1 {
        "BorderRadius.circular(\{emit_flutter_expr(args[0])})"
      } else if name == "TextStyle" && args.length() >= 1 {
        let size = emit_flutter_expr(args[0])
        if args.length() >= 2 {
          let color = emit_flutter_expr(args[1])
          "TextStyle(fontSize: \{size}, color: \{color})"
        } else {
          "TextStyle(fontSize: \{size})"
        }
      } else if name == "BoxDecoration" && args.length() >= 1 {
        let color = emit_flutter_expr(args[0])
        if args.length() >= 2 {
          let borderRadius = emit_flutter_expr(args[1])
          "BoxDecoration(color: \{color}, borderRadius: \{borderRadius})"
        } else {
          "BoxDecoration(color: \{color})"
        }
      } else if name == "Matrix4_identity" {
        "Matrix4.identity()"
      } else if name == "Icons" && args.length() == 1 {
        "Icons.\{emit_flutter_expr(args[0])}"
      } else {
        let arg_str = args.map(emit_flutter_expr).join(", ")
        "\{name}(\{arg_str})"
      }
    @ast.EBinOp(op, lhs, rhs) =>
      "\{emit_flutter_expr(lhs)} \{op} \{emit_flutter_expr(rhs)}"
    @ast.EIf(cond, then_, else_) =>
      "\{emit_flutter_expr(cond)} ? \{emit_flutter_expr(then_)} : \{emit_flutter_expr(else_)}"
    @ast.ELambda(params, body) => {
      let param_str = params
        .map(fn(pair) {
          let (pname, _) = pair
          pname
        })
        .join(", ")
      "(\{param_str}) {\n    \{emit_flutter_expr(body)};\n  }"
    }
    @ast.EAwait(inner) => "await \{emit_flutter_expr(inner)}"
    @ast.EMatch(scrutinee, cases) => {
      let scrut = emit_flutter_expr(scrutinee)
      let sorted = sort_option_cases(cases)
      let arms = sorted
        .map(fn(pair) {
          let (pat, body) = pair
          "  \{emit_dart_pattern(pat)} => \{emit_flutter_expr(body)}"
        })
        .join(",\n")
      "switch (\{scrut}) {\n\{arms}\n}"
    }
  }
}

///|
/// 发射 Flutter widget 构造器调用 — 将位置参数映射到 Flutter 命名参数。
fn emit_flutter_widget_call(
  name : String,
  args : Array[@ast.MoonExpr],
) -> String {
  match name {
    "Text" => {
      if args.length() == 0 {
        return "Text('')"
      }
      let data = emit_flutter_expr(args[0])
      if args.length() >= 2 {
        let style = emit_flutter_expr(args[1])
        "Text(\{data}, style: \{style})"
      } else {
        "Text(\{data})"
      }
    }
    "Row" | "Column" | "Stack" => {
      let children = args.map(emit_flutter_expr).join(", ")
      "\{name}(children: [\{children}])"
    }
    "Container" => {
      if args.length() == 0 {
        return "Container()"
      }
      let child = emit_flutter_expr(args[0])
      if args.length() >= 2 {
        let padding = emit_flutter_expr(args[1])
        "Container(padding: \{padding}, child: \{child})"
      } else {
        "Container(child: \{child})"
      }
    }
    "Padding" => {
      if args.length() < 2 {
        return "Padding(padding: EdgeInsets.zero)"
      }
      let padding = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "Padding(padding: \{padding}, child: \{child})"
    }
    "Expanded"
    | "Center"
    | "Flexible"
    | "Align"
    | "FittedBox"
    | "IntrinsicHeight"
    | "IntrinsicWidth"
    | "Offstage"
    | "ClipOval"
    | "ClipPath"
    | "SliverToBoxAdapter"
    | "DefaultTextStyle"
    | "Directionality"
    | "Baseline"
    | "MergeSemantics"
    | "ExcludeSemantics"
    | "Semantics"
    | "Tooltip"
    | "Hero"
    | "Dismissible"
    | "CircleAvatar" => {
      if args.length() == 0 {
        return "\{name}(child: SizedBox())"
      }
      let child = emit_flutter_expr(args[0])
      "\{name}(child: \{child})"
    }
    "SizedBox" => {
      if args.length() == 0 {
        return "SizedBox()"
      }
      if args.length() == 1 {
        let child = emit_flutter_expr(args[0])
        "SizedBox(child: \{child})"
      } else {
        let width = emit_flutter_expr(args[0])
        let height = emit_flutter_expr(args[1])
        if args.length() >= 3 {
          let child = emit_flutter_expr(args[2])
          "SizedBox(width: \{width}, height: \{height}, child: \{child})"
        } else {
          "SizedBox(width: \{width}, height: \{height})"
        }
      }
    }
    "ListTile" => {
      if args.length() == 0 {
        return "ListTile()"
      }
      let title = emit_flutter_expr(args[0])
      if args.length() >= 2 {
        let subtitle = emit_flutter_expr(args[1])
        "ListTile(title: \{title}, subtitle: \{subtitle})"
      } else {
        "ListTile(title: \{title})"
      }
    }
    "Icon" => {
      if args.length() == 0 {
        return "Icon(Icons.help)"
      }
      let icon = emit_flutter_expr(args[0])
      "Icon(\{icon})"
    }
    "AppBar" => {
      if args.length() == 0 {
        return "AppBar()"
      }
      let title = emit_flutter_expr(args[0])
      "AppBar(title: \{title})"
    }
    "Scaffold" => {
      if args.length() == 0 {
        return "Scaffold()"
      }
      let body = emit_flutter_expr(args[0])
      if args.length() >= 2 {
        let appBar = emit_flutter_expr(args[1])
        "Scaffold(appBar: \{appBar}, body: \{body})"
      } else {
        "Scaffold(body: \{body})"
      }
    }
    "MaterialApp" => {
      if args.length() == 0 {
        return "MaterialApp()"
      }
      let home = emit_flutter_expr(args[0])
      "MaterialApp(home: \{home})"
    }
    "ElevatedButton" | "TextButton" | "OutlinedButton" => {
      if args.length() < 2 {
        return "\{name}(onPressed: () {}, child: Text(''))"
      }
      let onPressed = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "\{name}(onPressed: \{onPressed}, child: \{child})"
    }
    "FloatingActionButton" => {
      if args.length() < 2 {
        return "FloatingActionButton(onPressed: () {}, child: Icon(Icons.add))"
      }
      let onPressed = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "FloatingActionButton(onPressed: \{onPressed}, child: \{child})"
    }
    "GestureDetector" => {
      if args.length() < 2 {
        return "GestureDetector(onTap: () {}, child: SizedBox())"
      }
      let onTap = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "GestureDetector(onTap: \{onTap}, child: \{child})"
    }
    "Card" => {
      if args.length() == 0 {
        return "Card()"
      }
      let child = emit_flutter_expr(args[0])
      "Card(child: \{child})"
    }
    "Divider" => "Divider()"
    "Spacer" => "Spacer()"
    "CircularProgressIndicator" => "CircularProgressIndicator()"
    "LinearProgressIndicator" => "LinearProgressIndicator()"
    "Positioned" => {
      if args.length() < 4 {
        return "Positioned(child: SizedBox())"
      }
      let left = emit_flutter_expr(args[0])
      let top = emit_flutter_expr(args[1])
      let right = emit_flutter_expr(args[2])
      let bottom = emit_flutter_expr(args[3])
      let child = if args.length() >= 5 {
        emit_flutter_expr(args[4])
      } else {
        "SizedBox()"
      }
      "Positioned(left: \{left}, top: \{top}, right: \{right}, bottom: \{bottom}, child: \{child})"
    }
    "AspectRatio" => {
      if args.length() < 2 {
        return "AspectRatio(aspectRatio: 1.0, child: SizedBox())"
      }
      let ratio = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "AspectRatio(aspectRatio: \{ratio}, child: \{child})"
    }
    "ConstrainedBox" => {
      if args.length() < 2 {
        return "ConstrainedBox(constraints: BoxConstraints(), child: SizedBox())"
      }
      let constraints = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "ConstrainedBox(constraints: \{constraints}, child: \{child})"
    }
    "LimitedBox" => {
      if args.length() < 3 {
        return "LimitedBox(maxWidth: double.infinity, maxHeight: double.infinity, child: SizedBox())"
      }
      let maxWidth = emit_flutter_expr(args[0])
      let maxHeight = emit_flutter_expr(args[1])
      let child = emit_flutter_expr(args[2])
      "LimitedBox(maxWidth: \{maxWidth}, maxHeight: \{maxHeight}, child: \{child})"
    }
    "Opacity" => {
      if args.length() < 2 {
        return "Opacity(opacity: 1.0, child: SizedBox())"
      }
      let opacity = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "Opacity(opacity: \{opacity}, child: \{child})"
    }
    "Transform" => {
      if args.length() < 2 {
        return "Transform(transform: Matrix4.identity(), child: SizedBox())"
      }
      let transform = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "Transform(transform: \{transform}, child: \{child})"
    }
    "DecoratedBox" => {
      if args.length() < 2 {
        return "DecoratedBox(decoration: BoxDecoration(), child: SizedBox())"
      }
      let decoration = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "DecoratedBox(decoration: \{decoration}, child: \{child})"
    }
    "ClipRRect" => {
      if args.length() < 2 {
        return "ClipRRect(borderRadius: BorderRadius.zero, child: SizedBox())"
      }
      let borderRadius = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "ClipRRect(borderRadius: \{borderRadius}, child: \{child})"
    }
    "RefreshIndicator" => {
      if args.length() < 2 {
        return "RefreshIndicator(onRefresh: () async {}, child: SizedBox())"
      }
      let onRefresh = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "RefreshIndicator(onRefresh: \{onRefresh}, child: \{child})"
    }
    "Draggable" | "LongPressDraggable" => {
      if args.length() < 2 {
        return "\{name}(child: SizedBox(), feedback: SizedBox())"
      }
      let child = emit_flutter_expr(args[0])
      let feedback = emit_flutter_expr(args[1])
      "\{name}(child: \{child}, feedback: \{feedback})"
    }
    "DragTarget" => {
      if args.length() < 1 {
        return "DragTarget(builder: (context, candidateData, rejectedData) => SizedBox())"
      }
      let builder = emit_flutter_expr(args[0])
      "DragTarget(builder: \{builder})"
    }
    "Image" => {
      if args.length() == 0 {
        return "Image.network('')"
      }
      let src = emit_flutter_expr(args[0])
      "Image.network(\{src})"
    }
    "CustomScrollView" => {
      if args.length() == 0 {
        return "CustomScrollView(slivers: [])"
      }
      let slivers = args.map(emit_flutter_expr).join(", ")
      "CustomScrollView(slivers: [\{slivers}])"
    }
    "SliverList" | "SliverGrid" => {
      if args.length() == 0 {
        return "\{name}(delegate: SliverChildListDelegate([]))"
      }
      let children = args.map(emit_flutter_expr).join(", ")
      "\{name}(delegate: SliverChildListDelegate([\{children}]))"
    }
    "NestedScrollView" => {
      if args.length() < 2 {
        return "NestedScrollView(headerSliverBuilder: (context, innerBoxIsScrolled) => [], body: SizedBox())"
      }
      let header = emit_flutter_expr(args[0])
      let body = emit_flutter_expr(args[1])
      "NestedScrollView(headerSliverBuilder: \{header}, body: \{body})"
    }
    "TextField" | "TextFormField" => {
      if args.length() == 0 {
        return "\{name}()"
      }
      let onChanged = emit_flutter_expr(args[0])
      if args.length() >= 2 {
        let decoration = emit_flutter_expr(args[1])
        "\{name}(onChanged: \{onChanged}, decoration: \{decoration})"
      } else {
        "\{name}(onChanged: \{onChanged})"
      }
    }
    "InputDecoration" => {
      if args.length() == 0 {
        return "InputDecoration()"
      }
      let hintText = emit_flutter_expr(args[0])
      "InputDecoration(hintText: \{hintText})"
    }
    "Switch" => {
      if args.length() < 2 {
        return "Switch(value: false, onChanged: (v) {})"
      }
      let value = emit_flutter_expr(args[0])
      let onChanged = emit_flutter_expr(args[1])
      "Switch(value: \{value}, onChanged: \{onChanged})"
    }
    "Checkbox" => {
      if args.length() < 2 {
        return "Checkbox(value: false, onChanged: (v) {})"
      }
      let value = emit_flutter_expr(args[0])
      let onChanged = emit_flutter_expr(args[1])
      "Checkbox(value: \{value}, onChanged: \{onChanged})"
    }
    "Radio" => {
      if args.length() < 3 {
        return "Radio(value: null, groupValue: null, onChanged: (v) {})"
      }
      let value = emit_flutter_expr(args[0])
      let groupValue = emit_flutter_expr(args[1])
      let onChanged = emit_flutter_expr(args[2])
      "Radio(value: \{value}, groupValue: \{groupValue}, onChanged: \{onChanged})"
    }
    "Slider" => {
      if args.length() < 3 {
        return "Slider(value: 0.0, min: 0.0, max: 1.0, onChanged: (v) {})"
      }
      let value = emit_flutter_expr(args[0])
      let onChanged = emit_flutter_expr(args[1])
      let min = if args.length() >= 3 {
        emit_flutter_expr(args[2])
      } else {
        "0.0"
      }
      let max = if args.length() >= 4 {
        emit_flutter_expr(args[3])
      } else {
        "1.0"
      }
      "Slider(value: \{value}, onChanged: \{onChanged}, min: \{min}, max: \{max})"
    }
    "DropdownButton" => {
      if args.length() < 2 {
        return "DropdownButton(value: null, onChanged: (v) {})"
      }
      let value = emit_flutter_expr(args[0])
      let onChanged = emit_flutter_expr(args[1])
      "DropdownButton(value: \{value}, onChanged: \{onChanged})"
    }
    "InkWell" | "InkResponse" => {
      if args.length() < 2 {
        return "\{name}(onTap: () {}, child: SizedBox())"
      }
      let onTap = emit_flutter_expr(args[0])
      let child = emit_flutter_expr(args[1])
      "\{name}(onTap: \{onTap}, child: \{child})"
    }
    "PopupMenuButton" => {
      if args.length() == 0 {
        return "PopupMenuButton(onSelected: (v) {}, itemBuilder: (context) => [])"
      }
      let onSelected = emit_flutter_expr(args[0])
      "PopupMenuButton(onSelected: \{onSelected}, itemBuilder: (context) => [])"
    }
    _ => {
      let arg_str = args.map(emit_flutter_expr).join(", ")
      "\{name}(\{arg_str})"
    }
  }
}

///|
/// 判断表达式是否是 widget 表达式（用于区分 widget 函数和普通函数）。
fn is_widget_expr(e : @ast.MoonExpr) -> Bool {
  match e {
    @ast.ECall(name, _) => is_flutter_widget(name) || is_flutter_helper(name)
    @ast.EIf(_, then_, else_) => is_widget_expr(then_) || is_widget_expr(else_)
    @ast.EMatch(_, cases) => {
      let mut all_widget = true
      for c in cases {
        let (_, body) = c
        if !is_widget_expr(body) {
          all_widget = false
        }
      }
      all_widget
    }
    _ => false
  }
}

///|

///|
/// 完整 Flutter 程序发射 — 生成含 import、main、runApp 的完整 Flutter 应用。
pub fn emit_flutter_program(decls : Array[@ast.MoonDecl]) -> String {
  let header = "// Generated by moon2dart v0.7.0\n// DO NOT EDIT BY HAND\n\n"
  let imports = "import 'package:flutter/material.dart';\n\n"
  let main_fn = detect_and_emit_main(decls)
  let body = emit_flutter_decls(decls)
  "\{header}\{imports}\{main_fn}\{body}\n"
}

///|
/// 检测并发射 main 函数 — fn main() → void main() { runApp(...); }
fn detect_and_emit_main(decls : Array[@ast.MoonDecl]) -> String {
  for d in decls {
    match d {
      @ast.DFn(name, _, params, _, body) =>
        if name == "main" && params.length() == 0 {
          let app_widget = emit_flutter_expr(body)
          return "void main() {\n  runApp(\{app_widget});\n}\n\n"
        }
      _ => ()
    }
  }
  "void main() {\n  runApp(MyApp());\n}\n\n"
}

///|
/// 发射 Flutter 声明集合 — widget 函数 → StatelessWidget，其他 → 普通 Dart 声明。
fn emit_flutter_decls(decls : Array[@ast.MoonDecl]) -> String {
  let result : Array[String] = []
  for d in decls {
    match d {
      @ast.DFn(name, _, params, _, body) =>
        if name == "main" {
          ()
        } else if is_widget_expr(body) {
          let widget_name = to_pascal(name)
          let body_str = emit_flutter_expr(body)
          let build_params = if params.length() > 0 {
            let param_str = params
              .map(fn(pair) {
                let (pname, ptype) = pair
                "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
              })
              .join(", ")
            "(\{param_str})"
          } else {
            "(BuildContext context)"
          }
          result.push(
            "class \{widget_name} extends StatelessWidget {\n  @override\n  Widget build\{build_params} {\n    return \{body_str};\n  }\n}",
          )
        } else {
          result.push(emit_dart_decl(d))
        }
      @ast.DAsyncFn(name, _, params, _, body) =>
        if is_widget_expr(body) {
          let widget_name = to_pascal(name)
          let body_str = emit_flutter_expr(body)
          let build_params = if params.length() > 0 {
            let param_str = params
              .map(fn(pair) {
                let (pname, ptype) = pair
                "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
              })
              .join(", ")
            "(\{param_str})"
          } else {
            "(BuildContext context)"
          }
          result.push(
            "class \{widget_name} extends StatelessWidget {\n  @override\n  Widget build\{build_params} {\n    return \{body_str};\n  }\n}",
          )
        } else {
          result.push(emit_dart_decl(d))
        }
      _ =>
        match d {
          @ast.DStruct(name, type_params, fields, derives) => {
            let impls = collect_impls_for(decls, name)
            let has_widget_impl = {
              let mut found = false
              for impl_pair in impls {
                let (trait_name, _) = impl_pair
                if trait_name == "Widget" || trait_name == "StatefulWidget" {
                  found = true
                }
              }
              found
            }
            if has_widget_impl {
              result.push(
                emit_flutter_widget_struct(
                  name, type_params, fields, derives, impls,
                ),
              )
            } else {
              result.push(emit_dart_decl_in_program(d, decls))
            }
          }
          @ast.DImpl(trait_name, type_name, _) =>
            if trait_name == "Widget" || trait_name == "StatefulWidget" {
              if has_struct_named(decls, type_name) {
                ()
              } else {
                result.push(emit_dart_decl(d))
              }
            } else {
              result.push(emit_dart_decl_in_program(d, decls))
            }
          _ => result.push(emit_dart_decl_in_program(d, decls))
        }
    }
  }
  result.join("\n\n")
}

///|
/// 检测声明数组中是否包含 widget 函数（需要 Flutter import）。
pub fn needs_flutter(decls : Array[@ast.MoonDecl]) -> Bool {
  for d in decls {
    match d {
      @ast.DFn(name, _, _, _, body) =>
        if name == "main" || is_widget_expr(body) {
          return true
        }
      @ast.DImpl(trait_name, _, _) =>
        if trait_name == "Widget" || trait_name == "StatefulWidget" {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
/// 发射 Flutter widget struct — DStruct + DImpl(Widget) → StatelessWidget / StatefulWidget。
fn emit_flutter_widget_struct(
  name : String,
  type_params : Array[String],
  fields : Array[(String, @ast.MoonType)],
  derives : Array[String],
  impls : Array[(String, Array[@ast.ImplMethod])],
) -> String {
  let generic = if type_params.length() > 0 {
    "<\{type_params.join(", ")}>"
  } else {
    ""
  }
  let mut widget_kind = "StatelessWidget"
  for impl_pair in impls {
    let (trait_name, _) = impl_pair
    if trait_name == "StatefulWidget" {
      widget_kind = "StatefulWidget"
    }
  }
  let field_str = fields
    .map(fn(pair) {
      let (fname, ftype) = pair
      "  final \{@typesys.emit_dart(@typesys.map_type(ftype))} \{fname};"
    })
    .join("\n")
  let ctor_params = fields
    .map(fn(pair) {
      let (fname, _) = pair
      "required this.\{fname}"
    })
    .join(", ")
  let derive_methods = emit_derive_methods(name, fields, derives)
  let mut build_body = "SizedBox()"
  let other_methods : Array[String] = []
  let other_trait_names : Array[String] = []
  for impl_pair in impls {
    let (trait_name, methods) = impl_pair
    if trait_name == "Widget" || trait_name == "StatefulWidget" {
      for m in methods {
        if m.name == "build" {
          build_body = emit_flutter_expr(m.body)
        } else {
          let param_str = m.params
            .map(fn(pair) {
              let (pname, ptype) = pair
              "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
            })
            .join(", ")
          let ret_str = @typesys.emit_dart(@typesys.map_type(m.ret_type))
          other_methods.push(
            "  \{ret_str} \{m.name}(\{param_str}) {\n    return \{emit_flutter_expr(m.body)};\n  }",
          )
        }
      }
    } else {
      other_trait_names.push(trait_name)
      for m in methods {
        let param_str = m.params
          .map(fn(pair) {
            let (pname, ptype) = pair
            "\{@typesys.emit_dart(@typesys.map_type(ptype))} \{pname}"
          })
          .join(", ")
        let ret_str = @typesys.emit_dart(@typesys.map_type(m.ret_type))
        other_methods.push(
          "  \{ret_str} \{m.name}(\{param_str}) {\n    return \{emit_flutter_expr(m.body)};\n  }",
        )
      }
    }
  }
  let implements_clause = if other_trait_names.length() > 0 {
    " implements \{other_trait_names.join(", ")}"
  } else {
    ""
  }
  let other_method_str = if other_methods.length() > 0 {
    "\n" + other_methods.join("\n")
  } else {
    ""
  }
  if widget_kind == "StatefulWidget" {
    "class \{name}\{generic} extends StatefulWidget\{implements_clause} {\n\{field_str}\n  const \{name}\{generic}({\{ctor_params}});\{derive_methods}\n  @override\n  State<\{name}\{generic}> createState() => _\{name}State();\n}\n\nclass _\{name}State extends State<\{name}\{generic}> {\n  @override\n  Widget build(BuildContext context) {\n    return \{build_body};\n  }\{other_method_str}\n}"
  } else {
    "class \{name}\{generic} extends StatelessWidget\{implements_clause} {\n\{field_str}\n  const \{name}\{generic}({\{ctor_params}});\{derive_methods}\n  @override\n  Widget build(BuildContext context) {\n    return \{build_body};\n  }\{other_method_str}\n}"
  }
}
