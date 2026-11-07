///|
/// Flutter emitter 白盒测试。
test "is_flutter_widget: basic widgets" {
  assert_true(is_flutter_widget("Text"))
  assert_true(is_flutter_widget("Container"))
  assert_true(is_flutter_widget("Row"))
  assert_true(is_flutter_widget("Column"))
  assert_true(is_flutter_widget("Stack"))
  assert_true(is_flutter_widget("Padding"))
  assert_true(is_flutter_widget("Expanded"))
  assert_true(is_flutter_widget("Center"))
  assert_true(is_flutter_widget("Scaffold"))
  assert_true(is_flutter_widget("MaterialApp"))
  assert_true(is_flutter_widget("AppBar"))
  assert_true(is_flutter_widget("ElevatedButton"))
  assert_true(is_flutter_widget("GestureDetector"))
  assert_true(is_flutter_widget("Card"))
  assert_true(is_flutter_widget("Icon"))
  assert_true(is_flutter_widget("ListTile"))
}

///|
test "is_flutter_widget: non-widgets" {
  assert_false(is_flutter_widget("foo"))
  assert_false(is_flutter_widget("bar"))
  assert_false(is_flutter_widget("my_func"))
  assert_false(is_flutter_widget("add"))
}

///|
test "emit_flutter_expr: Text widget" {
  let e = @ast.ECall("Text", [@ast.EString("Hello World")])
  assert_eq(emit_flutter_expr(e), "Text('Hello World')")
}

///|
test "emit_flutter_expr: Text with style" {
  let e = @ast.ECall("Text", [
    @ast.EString("Hello"),
    @ast.ECall("TextStyle", [@ast.EInt(16)]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Text('Hello', style: TextStyle(fontSize: 16))",
  )
}

///|
test "emit_flutter_expr: Row with children" {
  let e = @ast.ECall("Row", [
    @ast.ECall("Text", [@ast.EString("A")]),
    @ast.ECall("Text", [@ast.EString("B")]),
  ])
  assert_eq(emit_flutter_expr(e), "Row(children: [Text('A'), Text('B')])")
}

///|
test "emit_flutter_expr: Column with children" {
  let e = @ast.ECall("Column", [
    @ast.ECall("Text", [@ast.EString("A")]),
    @ast.ECall("Text", [@ast.EString("B")]),
  ])
  assert_eq(emit_flutter_expr(e), "Column(children: [Text('A'), Text('B')])")
}

///|
test "emit_flutter_expr: Container with child" {
  let e = @ast.ECall("Container", [@ast.ECall("Text", [@ast.EString("Child")])])
  assert_eq(emit_flutter_expr(e), "Container(child: Text('Child'))")
}

///|
test "emit_flutter_expr: Container with padding" {
  let e = @ast.ECall("Container", [
    @ast.ECall("Text", [@ast.EString("Child")]),
    @ast.ECall("EdgeInsets_all", [@ast.EInt(16)]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Container(padding: EdgeInsets.all(16), child: Text('Child'))",
  )
}

///|
test "emit_flutter_expr: Stack with children" {
  let e = @ast.ECall("Stack", [@ast.ECall("Text", [@ast.EString("A")])])
  assert_eq(emit_flutter_expr(e), "Stack(children: [Text('A')])")
}

///|
test "emit_flutter_expr: Padding with EdgeInsets" {
  let e = @ast.ECall("Padding", [
    @ast.ECall("EdgeInsets_all", [@ast.EInt(8)]),
    @ast.ECall("Text", [@ast.EString("Padded")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Padding(padding: EdgeInsets.all(8), child: Text('Padded'))",
  )
}

///|
test "emit_flutter_expr: Expanded" {
  let e = @ast.ECall("Expanded", [
    @ast.ECall("Text", [@ast.EString("Expanded")]),
  ])
  assert_eq(emit_flutter_expr(e), "Expanded(child: Text('Expanded'))")
}

///|
test "emit_flutter_expr: Center" {
  let e = @ast.ECall("Center", [@ast.ECall("Text", [@ast.EString("Centered")])])
  assert_eq(emit_flutter_expr(e), "Center(child: Text('Centered'))")
}

///|
test "emit_flutter_expr: SizedBox width height child" {
  let e = @ast.ECall("SizedBox", [
    @ast.EInt(100),
    @ast.EInt(200),
    @ast.ECall("Text", [@ast.EString("Box")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "SizedBox(width: 100, height: 200, child: Text('Box'))",
  )
}

///|
test "emit_flutter_expr: SizedBox width height only" {
  let e = @ast.ECall("SizedBox", [@ast.EInt(100), @ast.EInt(200)])
  assert_eq(emit_flutter_expr(e), "SizedBox(width: 100, height: 200)")
}

///|
test "emit_flutter_expr: SizedBox child only" {
  let e = @ast.ECall("SizedBox", [@ast.ECall("Text", [@ast.EString("Box")])])
  assert_eq(emit_flutter_expr(e), "SizedBox(child: Text('Box'))")
}

///|
test "emit_flutter_expr: ListTile" {
  let e = @ast.ECall("ListTile", [@ast.ECall("Text", [@ast.EString("Title")])])
  assert_eq(emit_flutter_expr(e), "ListTile(title: Text('Title'))")
}

///|
test "emit_flutter_expr: Icon" {
  let e = @ast.ECall("Icon", [@ast.EVar("Icons.add")])
  assert_eq(emit_flutter_expr(e), "Icon(Icons.add)")
}

///|
test "emit_flutter_expr: AppBar" {
  let e = @ast.ECall("AppBar", [@ast.ECall("Text", [@ast.EString("My App")])])
  assert_eq(emit_flutter_expr(e), "AppBar(title: Text('My App'))")
}

///|
test "emit_flutter_expr: Scaffold with body" {
  let e = @ast.ECall("Scaffold", [@ast.ECall("Text", [@ast.EString("Body")])])
  assert_eq(emit_flutter_expr(e), "Scaffold(body: Text('Body'))")
}

///|
test "emit_flutter_expr: Scaffold with appBar and body" {
  let e = @ast.ECall("Scaffold", [
    @ast.ECall("Text", [@ast.EString("Body")]),
    @ast.ECall("AppBar", [@ast.ECall("Text", [@ast.EString("Title")])]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Scaffold(appBar: AppBar(title: Text('Title')), body: Text('Body'))",
  )
}

///|
test "emit_flutter_expr: MaterialApp" {
  let e = @ast.ECall("MaterialApp", [
    @ast.ECall("Scaffold", [@ast.ECall("Text", [@ast.EString("Home")])]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "MaterialApp(home: Scaffold(body: Text('Home')))",
  )
}

///|
test "emit_flutter_expr: ElevatedButton" {
  let e = @ast.ECall("ElevatedButton", [
    @ast.ELambda([], @ast.ECall("print", [@ast.EString("clicked")])),
    @ast.ECall("Text", [@ast.EString("Click")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("ElevatedButton(onPressed:"))
  assert_true(result.contains("child: Text('Click')"))
}

///|
test "emit_flutter_expr: FloatingActionButton" {
  let e = @ast.ECall("FloatingActionButton", [
    @ast.ELambda([], @ast.EInt(0)),
    @ast.ECall("Icon", [@ast.EVar("Icons.add")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("FloatingActionButton(onPressed:"))
  assert_true(result.contains("child: Icon(Icons.add)"))
}

///|
test "emit_flutter_expr: GestureDetector" {
  let e = @ast.ECall("GestureDetector", [
    @ast.ELambda([], @ast.EInt(0)),
    @ast.ECall("Text", [@ast.EString("Tap me")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("GestureDetector(onTap:"))
  assert_true(result.contains("child: Text('Tap me')"))
}

///|
test "emit_flutter_expr: Card" {
  let e = @ast.ECall("Card", [
    @ast.ECall("Text", [@ast.EString("Card content")]),
  ])
  assert_eq(emit_flutter_expr(e), "Card(child: Text('Card content'))")
}

///|
test "emit_flutter_expr: Divider" {
  let e = @ast.ECall("Divider", [])
  assert_eq(emit_flutter_expr(e), "Divider()")
}

///|
test "emit_flutter_expr: Spacer" {
  let e = @ast.ECall("Spacer", [])
  assert_eq(emit_flutter_expr(e), "Spacer()")
}

///|
test "emit_flutter_expr: EdgeInsets_all" {
  let e = @ast.ECall("EdgeInsets_all", [@ast.EInt(16)])
  assert_eq(emit_flutter_expr(e), "EdgeInsets.all(16)")
}

///|
test "emit_flutter_expr: EdgeInsets_symmetric" {
  let e = @ast.ECall("EdgeInsets_symmetric", [@ast.EInt(8), @ast.EInt(4)])
  assert_eq(
    emit_flutter_expr(e),
    "EdgeInsets.symmetric(horizontal: 8, vertical: 4)",
  )
}

///|
test "emit_flutter_expr: EdgeInsets_only" {
  let e = @ast.ECall("EdgeInsets_only", [
    @ast.EInt(10),
    @ast.EInt(20),
    @ast.EInt(10),
    @ast.EInt(20),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 20)",
  )
}

///|
test "emit_flutter_expr: BorderRadius_circular" {
  let e = @ast.ECall("BorderRadius_circular", [@ast.EInt(8)])
  assert_eq(emit_flutter_expr(e), "BorderRadius.circular(8)")
}

///|
test "emit_flutter_expr: TextStyle" {
  let e = @ast.ECall("TextStyle", [@ast.EInt(16)])
  assert_eq(emit_flutter_expr(e), "TextStyle(fontSize: 16)")
}

///|
test "emit_flutter_expr: TextStyle with color" {
  let e = @ast.ECall("TextStyle", [@ast.EInt(16), @ast.EVar("Colors.red")])
  assert_eq(emit_flutter_expr(e), "TextStyle(fontSize: 16, color: Colors.red)")
}

///|
test "emit_flutter_expr: BoxDecoration" {
  let e = @ast.ECall("BoxDecoration", [@ast.EVar("Colors.blue")])
  assert_eq(emit_flutter_expr(e), "BoxDecoration(color: Colors.blue)")
}

///|
test "emit_flutter_expr: nested widgets" {
  let e = @ast.ECall("Column", [
    @ast.ECall("Text", [@ast.EString("Hello")]),
    @ast.ECall("Container", [@ast.ECall("Text", [@ast.EString("World")])]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Column(children: [Text('Hello'), Container(child: Text('World'))])",
  )
}

///|
test "emit_flutter_expr: deeply nested widgets" {
  let e = @ast.ECall("MaterialApp", [
    @ast.ECall("Scaffold", [
      @ast.ECall("Column", [
        @ast.ECall("AppBar", [@ast.ECall("Text", [@ast.EString("My App")])]),
        @ast.ECall("Center", [@ast.ECall("Text", [@ast.EString("Hello")])]),
      ]),
    ]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("MaterialApp(home:"))
  assert_true(result.contains("Scaffold(body:"))
  assert_true(result.contains("Column(children:"))
  assert_true(result.contains("AppBar(title: Text('My App'))"))
  assert_true(result.contains("Center(child: Text('Hello'))"))
}

///|
test "emit_flutter_expr: non-widget function call" {
  let e = @ast.ECall("add", [@ast.EInt(1), @ast.EInt(2)])
  assert_eq(emit_flutter_expr(e), "add(1, 2)")
}

///|
test "emit_flutter_expr: EVar" {
  let e = @ast.EVar("myVar")
  assert_eq(emit_flutter_expr(e), "myVar")
}

///|
test "emit_flutter_expr: EVar None" {
  let e = @ast.EVar("None")
  assert_eq(emit_flutter_expr(e), "null")
}

///|
test "emit_flutter_expr: EInt" {
  let e = @ast.EInt(42)
  assert_eq(emit_flutter_expr(e), "42")
}

///|
test "emit_flutter_expr: EBool" {
  let e = @ast.EBool(true)
  assert_eq(emit_flutter_expr(e), "true")
}

///|
test "emit_flutter_expr: EDouble" {
  let e = @ast.EDouble(3.14)
  assert_eq(emit_flutter_expr(e), "3.14")
}

///|
test "emit_flutter_expr: EIf" {
  let e = @ast.EIf(
    @ast.EVar("flag"),
    @ast.ECall("Text", [@ast.EString("Yes")]),
    @ast.ECall("Text", [@ast.EString("No")]),
  )
  assert_eq(emit_flutter_expr(e), "flag ? Text('Yes') : Text('No')")
}

///|
test "emit_flutter_expr: Opacity" {
  let e = @ast.ECall("Opacity", [
    @ast.EDouble(0.5),
    @ast.ECall("Text", [@ast.EString("Half")]),
  ])
  assert_eq(emit_flutter_expr(e), "Opacity(opacity: 0.5, child: Text('Half'))")
}

///|
test "emit_flutter_expr: AspectRatio" {
  let e = @ast.ECall("AspectRatio", [
    @ast.EDouble(1.0),
    @ast.ECall("Text", [@ast.EString("Square")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("AspectRatio(aspectRatio:"))
  assert_true(result.contains("child: Text('Square')"))
}

///|
test "emit_flutter_expr: ClipRRect" {
  let e = @ast.ECall("ClipRRect", [
    @ast.ECall("BorderRadius_circular", [@ast.EInt(8)]),
    @ast.ECall("Text", [@ast.EString("Clipped")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "ClipRRect(borderRadius: BorderRadius.circular(8), child: Text('Clipped'))",
  )
}

///|
test "emit_flutter_program: simple app" {
  let decls = [
    @ast.DFn(
      "main",
      [],
      [],
      @ast.MUnit,
      @ast.ECall("MaterialApp", [
        @ast.ECall("Scaffold", [
          @ast.ECall("Center", [
            @ast.ECall("Text", [@ast.EString("Hello Flutter")]),
          ]),
        ]),
      ]),
    ),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("import 'package:flutter/material.dart'"))
  assert_true(result.contains("void main()"))
  assert_true(
    result.contains(
      "runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Hello Flutter'))))",
    ),
  )
}

///|
test "emit_flutter_program: widget function → StatelessWidget" {
  let decls = [
    @ast.DFn(
      "main",
      [],
      [],
      @ast.MUnit,
      @ast.ECall("MaterialApp", [@ast.EVar("MyHomePage")]),
    ),
    @ast.DFn(
      "home_page",
      [],
      [],
      @ast.MCustom("Widget"),
      @ast.ECall("Scaffold", [
        @ast.ECall("Column", [
          @ast.ECall("AppBar", [@ast.ECall("Text", [@ast.EString("Home")])]),
          @ast.ECall("Center", [@ast.ECall("Text", [@ast.EString("Welcome")])]),
        ]),
      ]),
    ),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class HomePage extends StatelessWidget"))
  assert_true(result.contains("Widget build(BuildContext context)"))
  assert_true(result.contains("Scaffold(body: Column(children:"))
  assert_true(result.contains("AppBar(title: Text('Home'))"))
  assert_true(result.contains("Center(child: Text('Welcome'))"))
}

///|
test "emit_flutter_program: non-widget function preserved" {
  let decls = [
    @ast.DFn(
      "add",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("int add(int a, int b)"))
  assert_false(result.contains("StatelessWidget"))
}

///|
test "emit_flutter_program: no main → default runApp" {
  let decls = [
    @ast.DFn(
      "my_widget",
      [],
      [],
      @ast.MCustom("Widget"),
      @ast.ECall("Text", [@ast.EString("Hello")]),
    ),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("void main()"))
  assert_true(result.contains("runApp(MyApp())"))
  assert_true(result.contains("class MyWidget extends StatelessWidget"))
}

///|
test "needs_flutter: with widget function" {
  let decls = [
    @ast.DFn(
      "main",
      [],
      [],
      @ast.MUnit,
      @ast.ECall("MaterialApp", [@ast.ECall("Text", [@ast.EString("Hi")])]),
    ),
  ]
  assert_true(needs_flutter(decls))
}

///|
test "needs_flutter: without widget function" {
  let decls = [
    @ast.DFn(
      "add",
      [],
      [("a", @ast.MInt), ("b", @ast.MInt)],
      @ast.MInt,
      @ast.EBinOp("+", @ast.EVar("a"), @ast.EVar("b")),
    ),
  ]
  assert_false(needs_flutter(decls))
}

///|
test "emit_flutter_expr: ELambda for onPressed" {
  let e = @ast.ELambda([], @ast.ECall("print", [@ast.EString("tapped")]))
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("() {"))
  assert_true(result.contains("print('tapped')"))
}

///|
test "emit_flutter_expr: Positioned" {
  let e = @ast.ECall("Positioned", [
    @ast.EInt(0),
    @ast.EInt(0),
    @ast.EInt(100),
    @ast.EInt(100),
    @ast.ECall("Text", [@ast.EString("Pos")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Positioned(left: 0, top: 0, right: 100, bottom: 100, child: Text('Pos'))",
  )
}

///|
test "emit_flutter_expr: RefreshIndicator" {
  let e = @ast.ECall("RefreshIndicator", [
    @ast.ELambda([], @ast.EInt(0)),
    @ast.ECall("Text", [@ast.EString("Pull")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("RefreshIndicator(onRefresh:"))
  assert_true(result.contains("child: Text('Pull')"))
}

///|
test "emit_flutter_expr: Image" {
  let e = @ast.ECall("Image", [@ast.EString("https://example.com/img.png")])
  assert_eq(
    emit_flutter_expr(e),
    "Image.network('https://example.com/img.png')",
  )
}

///|
test "emit_flutter_expr: Transform" {
  let e = @ast.ECall("Transform", [
    @ast.ECall("Matrix4_identity", []),
    @ast.ECall("Text", [@ast.EString("Transformed")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "Transform(transform: Matrix4.identity(), child: Text('Transformed'))",
  )
}

///|
test "emit_flutter_expr: DecoratedBox" {
  let e = @ast.ECall("DecoratedBox", [
    @ast.ECall("BoxDecoration", [@ast.EVar("Colors.red")]),
    @ast.ECall("Text", [@ast.EString("Decorated")]),
  ])
  assert_eq(
    emit_flutter_expr(e),
    "DecoratedBox(decoration: BoxDecoration(color: Colors.red), child: Text('Decorated'))",
  )
}

///|
test "emit_flutter_program: StatelessWidget from struct+impl Widget" {
  let decls = [
    @ast.DStruct("Counter", [], [("count", @ast.MInt)], []),
    @ast.DImpl("Widget", "Counter", [
      {
        name: "build",
        params: [
          ("self", @ast.MCustom("Counter")),
          ("context", @ast.MCustom("BuildContext")),
        ],
        ret_type: @ast.MCustom("Widget"),
        body: @ast.ECall("Column", [
          @ast.ECall("Text", [@ast.EString("Count")]),
          @ast.ECall("ElevatedButton", [
            @ast.ELambda([], @ast.EInt(0)),
            @ast.ECall("Text", [@ast.EString("Increment")]),
          ]),
        ]),
      },
    ]),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class Counter extends StatelessWidget"))
  assert_true(result.contains("final int count"))
  assert_true(result.contains("const Counter({required this.count})"))
  assert_true(result.contains("Widget build(BuildContext context)"))
  assert_true(result.contains("Column(children: [Text('Count')"))
  assert_true(result.contains("ElevatedButton(onPressed:"))
  assert_true(result.contains("child: Text('Increment')"))
}

///|
test "emit_flutter_program: StatefulWidget from struct+impl StatefulWidget" {
  let decls = [
    @ast.DStruct("CounterPage", [], [("count", @ast.MInt)], []),
    @ast.DImpl("StatefulWidget", "CounterPage", [
      {
        name: "build",
        params: [
          ("self", @ast.MCustom("CounterPage")),
          ("context", @ast.MCustom("BuildContext")),
        ],
        ret_type: @ast.MCustom("Widget"),
        body: @ast.ECall("Text", [@ast.EString("Counter")]),
      },
    ]),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class CounterPage extends StatefulWidget"))
  assert_true(
    result.contains("State<CounterPage> createState() => _CounterPageState()"),
  )
  assert_true(
    result.contains("class _CounterPageState extends State<CounterPage>"),
  )
  assert_true(result.contains("Widget build(BuildContext context)"))
  assert_true(result.contains("Text('Counter')"))
}

///|
test "emit_flutter_program: struct without Widget impl → normal class" {
  let decls = [
    @ast.DStruct("Point", [], [("x", @ast.MInt), ("y", @ast.MInt)], ["Debug"]),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class Point"))
  assert_false(result.contains("StatelessWidget"))
  assert_false(result.contains("StatefulWidget"))
}

///|
test "emit_flutter_program: StatelessWidget with other trait impls" {
  let decls = [
    @ast.DStruct("MyWidget", [], [("title", @ast.MString)], []),
    @ast.DImpl("Widget", "MyWidget", [
      {
        name: "build",
        params: [
          ("self", @ast.MCustom("MyWidget")),
          ("context", @ast.MCustom("BuildContext")),
        ],
        ret_type: @ast.MCustom("Widget"),
        body: @ast.ECall("Text", [@ast.EVar("title")]),
      },
    ]),
    @ast.DImpl("Comparable", "MyWidget", [
      {
        name: "compareTo",
        params: [
          ("self", @ast.MCustom("MyWidget")),
          ("other", @ast.MCustom("MyWidget")),
        ],
        ret_type: @ast.MInt,
        body: @ast.EInt(0),
      },
    ]),
  ]
  let result = emit_flutter_program(decls)
  assert_true(
    result.contains(
      "class MyWidget extends StatelessWidget implements Comparable",
    ),
  )
  assert_true(result.contains("final String title"))
  assert_true(result.contains("Widget build(BuildContext context)"))
  assert_true(result.contains("compareTo"))
}

///|
test "emit_flutter_program: widget function with params → StatelessWidget with typed build" {
  let decls = [
    @ast.DFn(
      "greeting",
      [],
      [("name", @ast.MString)],
      @ast.MCustom("Widget"),
      @ast.ECall("Text", [@ast.EVar("name")]),
    ),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class Greeting extends StatelessWidget"))
  assert_true(result.contains("Widget build(String name)"))
  assert_true(result.contains("Text(name)"))
}

///|
test "emit_flutter_program: StatelessWidget with non-build method" {
  let decls = [
    @ast.DStruct("MyCard", [], [("title", @ast.MString)], []),
    @ast.DImpl("Widget", "MyCard", [
      {
        name: "build",
        params: [
          ("self", @ast.MCustom("MyCard")),
          ("context", @ast.MCustom("BuildContext")),
        ],
        ret_type: @ast.MCustom("Widget"),
        body: @ast.ECall("Card", [@ast.ECall("Text", [@ast.EVar("title")])]),
      },
      {
        name: "getTitle",
        params: [("self", @ast.MCustom("MyCard"))],
        ret_type: @ast.MString,
        body: @ast.EVar("title"),
      },
    ]),
  ]
  let result = emit_flutter_program(decls)
  assert_true(result.contains("class MyCard extends StatelessWidget"))
  assert_true(result.contains("Widget build(BuildContext context)"))
  assert_true(result.contains("Card(child: Text(title))"))
  assert_true(result.contains("String getTitle"))
}

///|
test "needs_flutter: with Widget impl" {
  let decls = [
    @ast.DStruct("MyWidget", [], [], []),
    @ast.DImpl("Widget", "MyWidget", []),
  ]
  assert_true(needs_flutter(decls))
}

///|
test "needs_flutter: with StatefulWidget impl" {
  let decls = [
    @ast.DStruct("MyPage", [], [], []),
    @ast.DImpl("StatefulWidget", "MyPage", []),
  ]
  assert_true(needs_flutter(decls))
}

///|
test "needs_flutter: without any widget" {
  let decls = [@ast.DStruct("Point", [], [("x", @ast.MInt)], [])]
  assert_false(needs_flutter(decls))
}

///|
test "emit_flutter_expr: TextField with onChanged" {
  let e = @ast.ECall("TextField", [
    @ast.ELambda([("value", @ast.MString)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("TextField(onChanged:"))
}

///|
test "emit_flutter_expr: TextField with onChanged and decoration" {
  let e = @ast.ECall("TextField", [
    @ast.ELambda([("value", @ast.MString)], @ast.EInt(0)),
    @ast.ECall("InputDecoration", [@ast.EString("Enter text")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("TextField(onChanged:"))
  assert_true(
    result.contains("decoration: InputDecoration(hintText: 'Enter text')"),
  )
}

///|
test "emit_flutter_expr: InputDecoration" {
  let e = @ast.ECall("InputDecoration", [@ast.EString("Hint")])
  assert_eq(emit_flutter_expr(e), "InputDecoration(hintText: 'Hint')")
}

///|
test "emit_flutter_expr: Switch" {
  let e = @ast.ECall("Switch", [
    @ast.EBool(true),
    @ast.ELambda([("v", @ast.MBool)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("Switch(value: true"))
  assert_true(result.contains("onChanged:"))
}

///|
test "emit_flutter_expr: Checkbox" {
  let e = @ast.ECall("Checkbox", [
    @ast.EBool(false),
    @ast.ELambda([("v", @ast.MBool)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("Checkbox(value: false"))
  assert_true(result.contains("onChanged:"))
}

///|
test "emit_flutter_expr: Slider" {
  let e = @ast.ECall("Slider", [
    @ast.EDouble(0.5),
    @ast.ELambda([("v", @ast.MDouble)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("Slider(value:"))
  assert_true(result.contains("onChanged:"))
}

///|
test "emit_flutter_expr: InkWell" {
  let e = @ast.ECall("InkWell", [
    @ast.ELambda([], @ast.EInt(0)),
    @ast.ECall("Text", [@ast.EString("Tap")]),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.has_prefix("InkWell(onTap:"))
  assert_true(result.contains("child: Text('Tap')"))
}

///|
test "emit_flutter_expr: DropdownButton" {
  let e = @ast.ECall("DropdownButton", [
    @ast.EVar("selectedValue"),
    @ast.ELambda([("v", @ast.MString)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("DropdownButton(value: selectedValue"))
  assert_true(result.contains("onChanged:"))
}

///|
test "emit_flutter_expr: Radio" {
  let e = @ast.ECall("Radio", [
    @ast.EVar("value"),
    @ast.EVar("groupValue"),
    @ast.ELambda([("v", @ast.MString)], @ast.EInt(0)),
  ])
  let result = emit_flutter_expr(e)
  assert_true(result.contains("Radio(value: value"))
  assert_true(result.contains("groupValue: groupValue"))
  assert_true(result.contains("onChanged:"))
}
