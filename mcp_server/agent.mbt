///|
/// moon2dart Agent 模式 — 基于 colmugx/posoco 的 LLM Agent 循环。
///
/// Agent 模式架构：
///   RuleBasedModel — 基于关键词的 ModelPort，自动选择工具
///   ToolRegistry — 注册 moon2dart 的 6 个工具
///   InMemorySessionPort — 内存会话存储
///   Moon2DartExtension — 组合以上组件的 Extension

// ============================================================
// JSON 辅助函数
// ============================================================

///|
/// escape_json_string — 转义字符串中的特殊字符，用于 JSON 字符串拼接。
fn escape_json_string(s : String) -> String {
  s
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new="\\n")
  .replace(old="\r", new="\\r")
  .replace(old="\t", new="\\t")
}

///|
/// make_json_args — 构造包含单个字符串参数的 JSON 对象。
fn make_json_args(key : String, value : String) -> Json raise @ast.Moon2DartError {
  let escaped = escape_json_string(value)
  @mcpsdk.parse_json("{\"" + key + "\":\"" + escaped + "\"}") catch {
    _ => @mcpsdk.parse_json("{}") catch {
      _ => raise @ast.Moon2DartError::JsonParseError("invalid JSON args for key: " + key)
    }
  }
}

///|
/// json_get_string — 从 Json 对象中提取字符串值。
fn json_get_string(json : Json, key : String) -> String {
  match @mcpsdk.get_string(json, key) {
    Ok(s) => s
    Err(_) => ""
  }
}

// ============================================================
// RuleBasedModel — 基于关键词的 ModelPort
// ============================================================

///|
/// RuleBasedModel — 根据用户输入的关键词自动选择工具。
///
/// 不依赖 LLM API，通过关键词匹配实现工具选择。
/// 后续可替换为真正的 LLM provider（如 OpenAI）。
struct RuleBasedModel {}

///|
fn RuleBasedModel::RuleBasedModel() -> RuleBasedModel {
  RuleBasedModel::{ }
}

///|
pub extend RuleBasedModel with @posoco.ModelPort::{
  chat,
  compact,
  provider_config,
}

///|
/// extract_text_from_content — 从 Content 数组中提取纯文本。
fn extract_text_from_content(contents : Array[@posoco.Content]) -> String {
  let parts : Array[String] = []
  for content in contents {
    match content {
      @posoco.Content::Text(text) => parts.push(text)
      @posoco.Content::Image(..) => ()
    }
  }
  parts.join(" ")
}

///|
/// select_tool — 根据用户输入的关键词选择工具名称和参数。
fn select_tool(input : String) -> (String?, String) {
  let lower = input.to_lower()
  if lower.contains("convert") || lower.contains("转换") {
    let idx = find_keyword_pos(lower, ["convert", "转换"])
    let source = input[idx:].trim().to_owned()
    (Some("moon2dart_convert"), source)
  } else if lower.contains("reverse") || lower.contains("反向") {
    let idx = find_keyword_pos(lower, ["reverse", "反向"])
    let source = input[idx:].trim().to_owned()
    (Some("moon2dart_reverse"), source)
  } else if lower.contains("flutter") || lower.contains("widget") {
    let idx = find_keyword_pos(lower, ["flutter", "widget"])
    let source = input[idx:].trim().to_owned()
    (Some("moon2dart_flutter"), source)
  } else if lower.contains("analyze") || lower.contains("分析") {
    let idx = find_keyword_pos(lower, ["analyze", "分析"])
    let source = input[idx:].trim().to_owned()
    (Some("moon2dart_analyze"), source)
  } else if lower.contains("project") || lower.contains("项目") {
    let idx = find_keyword_pos(lower, ["project", "项目"])
    let dir = input[idx:].trim().to_owned()
    (Some("moon2dart_project"), dir)
  } else if lower.contains("list") || lower.contains("工具") {
    (Some("moon2dart_list_tools"), "")
  } else {
    (None, "")
  }
}

///|
/// find_keyword_pos — 找到关键词在字符串中的结束位置。
fn find_keyword_pos(lower : String, keywords : Array[String]) -> Int32 {
  for kw in keywords {
    match lower.find(kw) {
      Some(pos) => return pos + kw.length()
      None => ()
    }
  }
  0
}

///|
/// make_tool_call — 构造 posoco ToolCall struct。
fn make_tool_call(
  call_id : String,
  name : String,
  arguments : Json,
) -> @posoco.ToolCall {
  {
    call_id: @posoco.CallId::unchecked(call_id),
    name: @posoco.ToolName::unchecked(name),
    arguments,
  }
}

///|
/// make_model_call_result — 构造 posoco ModelCallResult struct。
fn make_model_call_result(
  completion : @posoco.Completion,
  processed_messages : Array[@posoco.Message],
) -> @posoco.ModelCallResult {
  { completion, processed_messages, }
}

///|
pub impl @posoco.ModelPort for RuleBasedModel with fn chat(
  _self,
  _scope : @posoco.InvocationScope,
  messages : ArrayView[@posoco.Message],
  _tools : Array[@posoco.ToolDef],
  _options : @posoco.ChatOptions,
  _stream : @posoco.StreamMode,
) -> @posoco.ModelCallResult raise @posoco.ModelError {
  if messages.length() == 0 {
    raise @posoco.ModelError::ResponseParse("No messages provided")
  }
  let last_msg = messages[messages.length() - 1]
  match last_msg {
    @posoco.Message::UserMessage(content~) => {
      let input = extract_text_from_content(content)
      let (tool_name, param) = select_tool(input)
      match tool_name {
        Some(name) => {
          let args = if name == "moon2dart_list_tools" {
            @mcpsdk.parse_json("{}") catch {
              _ => raise @posoco.ModelError::ResponseParse("invalid JSON for list_tools")
            }
          } else if name == "moon2dart_project" {
            try make_json_args("dir", param) catch {
              @ast.Moon2DartError::JsonParseError(msg) =>
                raise @posoco.ModelError::ResponseParse(msg)
              _ => raise @posoco.ModelError::ResponseParse("unexpected error")
            }
          } else {
            try make_json_args("source", param) catch {
              @ast.Moon2DartError::JsonParseError(msg) =>
                raise @posoco.ModelError::ResponseParse(msg)
              _ => raise @posoco.ModelError::ResponseParse("unexpected error")
            }
          }
          let completion = @posoco.Completion(
            content=[],
            tool_calls=[make_tool_call("1", name, args)],
            reasoning=None,
            finish_reason=@posoco.FinishReason::ToolCalls,
            usage=None,
          )
          make_model_call_result(completion, messages.to_owned())
        }
        None => {
          let help_text = "moon2dart Agent — available commands:\n  convert <source>  — Convert MoonBit to Dart\n  reverse <source>  — Convert Dart to MoonBit\n  flutter <source>  — Convert to Flutter widget\n  analyze <source>  — Analyze MoonBit code structure\n  project <dir>     — Scan and convert a project\n  list              — List all available tools"
          let completion = @posoco.Completion(
            content=[@posoco.Content::Text(help_text)],
            tool_calls=[],
            reasoning=None,
            finish_reason=@posoco.FinishReason::Stop,
            usage=None,
          )
          make_model_call_result(completion, messages.to_owned())
        }
      }
    }
    @posoco.Message::ToolMessage(tool_name~, outcome~, ..) => {
      let result_text = format_tool_outcome(tool_name.to_string(), outcome)
      let completion = @posoco.Completion(
        content=[@posoco.Content::Text(result_text)],
        tool_calls=[],
        reasoning=None,
        finish_reason=@posoco.FinishReason::Stop,
        usage=None,
      )
      make_model_call_result(completion, messages.to_owned())
    }
    _ => {
      let completion = @posoco.Completion(
        content=[@posoco.Content::Text("...")],
        tool_calls=[],
        reasoning=None,
        finish_reason=@posoco.FinishReason::Stop,
        usage=None,
      )
      make_model_call_result(completion, messages.to_owned())
    }
  }
}

///|
pub impl @posoco.ModelPort for RuleBasedModel with fn compact(
  _self,
  _scope : @posoco.InvocationScope,
  _messages : ArrayView[@posoco.Message],
  _tools : Array[@posoco.ToolDef],
  _options : @posoco.ChatOptions,
  _trigger : @posoco.CompactTrigger,
) -> @posoco.CompactResult raise @posoco.ModelError {
  raise @posoco.ModelError::ResponseParse(
    "RuleBasedModel does not implement compact",
  )
}

///|
pub impl @posoco.ModelPort for RuleBasedModel with fn provider_config(_self) -> @posoco.ProviderConfig {
  @posoco.ProviderConfig::empty()
}

///|
/// format_tool_outcome — 将工具执行结果格式化为文本。
fn format_tool_outcome(
  tool_name : String,
  outcome : @posoco.ToolOutcome,
) -> String {
  match outcome {
    @posoco.ToolOutcome::Success(content~, ..) =>
      "[" + tool_name + "] Success:\n" + content
    @posoco.ToolOutcome::SuccessWithAttachments(content~, ..) =>
      "[" + tool_name + "] Success:\n" + content
    @posoco.ToolOutcome::ToolReportedError(content~, ..) =>
      "[" + tool_name + "] Error: " + content
    @posoco.ToolOutcome::RuntimeFailure(error_category~, message~) =>
      "[" + tool_name + "] Runtime failure (" + error_category + "): " + message
    @posoco.ToolOutcome::NotExecuted(reason~, ..) =>
      "[" + tool_name + "] Not executed: " + reason.to_string()
  }
}

// ============================================================
// InMemorySessionPort — 内存会话存储
// ============================================================

///|
/// InMemorySessionPort — 简单的内存会话存储，用于 Agent 模式。
struct InMemorySessionPort {
  sessions : Map[String, @posoco.Session]
}

///|
fn InMemorySessionPort::InMemorySessionPort() -> InMemorySessionPort {
  { sessions: Map([]), }
}

///|
pub extend InMemorySessionPort with @posoco.SessionPort::{
  load,
  save,
  append_messages,
  checkpoint,
  truncate,
}

///|
pub impl @posoco.SessionPort for InMemorySessionPort with fn load(
  self,
  id : String,
) -> @posoco.Session {
  match self.sessions.get(id) {
    Some(session) =>
      { messages: session.messages.copy(), metadata: session.metadata.copy(), }
    None => { messages: [], metadata: Map([]), }
  }
}

///|
pub impl @posoco.SessionPort for InMemorySessionPort with fn save(
  self,
  id : String,
  session : @posoco.Session,
) -> Unit {
  self.sessions[id] = {
    messages: session.messages.copy(),
    metadata: session.metadata.copy(),
  }
}

// ============================================================
// Moon2DartExtension — 组合 Model + Tools + Sessions
// ============================================================

///|
/// Moon2DartExtension — moon2dart 的 posoco Extension。
///
/// 提供：
///   - RuleBasedModel（ModelPort）
///   - ToolRegistry（ToolProvider，6 个 moon2dart 工具）
///   - InMemorySessionPort（SessionPort）
struct Moon2DartExtension {
  model : RuleBasedModel
  tools : @posoco.ToolRegistry
  sessions : InMemorySessionPort
}

///|
fn Moon2DartExtension::Moon2DartExtension() -> Moon2DartExtension raise @ast.Moon2DartError {
  let model = RuleBasedModel()
  let tools = @posoco.ToolRegistry::ToolRegistry()
  let sessions = InMemorySessionPort()
  register_moon2dart_tools(tools)
  { model, tools, sessions, }
}

///|
pub extend Moon2DartExtension with @posoco.Extension::{extension_id, manifest}

///|
pub impl @posoco.Extension for Moon2DartExtension with fn extension_id(_self) -> String {
  "moon2dart"
}

///|
pub impl @posoco.Extension for Moon2DartExtension with fn manifest(self) -> @posoco.ExtensionManifest {
  let manifest = @posoco.ExtensionManifest::default(id="moon2dart")
  {
    ..manifest,
    models: [self.model],
    tools: [self.tools],
    sessions: [self.sessions],
  }
}

// ============================================================
// 工具注册
// ============================================================

///|
/// register_moon2dart_tools — 将 moon2dart 的 6 个工具注册到 ToolRegistry。
fn register_moon2dart_tools(registry : @posoco.ToolRegistry) -> Unit raise @ast.Moon2DartError {
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_convert"),
      description="Convert MoonBit source code to Dart",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{\"source\":{\"type\":\"string\",\"description\":\"MoonBit source code\"}},\"required\":[\"source\"]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(ctx) -> @posoco.ToolOutcome {
      let source = json_get_string(ctx.arguments, "source")
      if source == "" {
        return @posoco.ToolOutcome::ToolReportedError(
          content="missing 'source' parameter",
          structured=None,
        )
      }
      let dart_code = try @lib.transpile_source_with_lib(source, "libnative.so") catch {
        @ast.Moon2DartError::ParseError(msg) =>
          return @posoco.ToolOutcome::ToolReportedError(content="Parse error: " + msg, structured=None)
        @ast.Moon2DartError::TranspileError(msg) =>
          return @posoco.ToolOutcome::ToolReportedError(content="Transpile error: " + msg, structured=None)
        _ =>
          return @posoco.ToolOutcome::ToolReportedError(content="Unexpected error", structured=None)
      }
      @posoco.ToolOutcome::Success(content=dart_code, structured=None)
    },
  )
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_reverse"),
      description="Convert Dart source code to MoonBit (reverse transpile)",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{\"source\":{\"type\":\"string\",\"description\":\"Dart source code\"}},\"required\":[\"source\"]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(ctx) -> @posoco.ToolOutcome {
      let source = json_get_string(ctx.arguments, "source")
      if source == "" {
        return @posoco.ToolOutcome::ToolReportedError(
          content="missing 'source' parameter",
          structured=None,
        )
      }
      let moon_code = try @lib.reverse_transpile_source(source) catch {
        @ast.Moon2DartError::ReverseTranspileError(msg) =>
          return @posoco.ToolOutcome::ToolReportedError(content="Reverse transpile error: " + msg, structured=None)
        _ =>
          return @posoco.ToolOutcome::ToolReportedError(content="Unexpected error", structured=None)
      }
      @posoco.ToolOutcome::Success(content=moon_code, structured=None)
    },
  )
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_flutter"),
      description="Convert MoonBit source to Flutter widget Dart code",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{\"source\":{\"type\":\"string\",\"description\":\"MoonBit source with Flutter widgets\"}},\"required\":[\"source\"]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(ctx) -> @posoco.ToolOutcome {
      let source = json_get_string(ctx.arguments, "source")
      if source == "" {
        return @posoco.ToolOutcome::ToolReportedError(
          content="missing 'source' parameter",
          structured=None,
        )
      }
      let flutter_code = try @lib.transpile_source_flutter(source) catch {
        @ast.Moon2DartError::ParseError(msg) =>
          return @posoco.ToolOutcome::ToolReportedError(content="Parse error: " + msg, structured=None)
        @ast.Moon2DartError::TranspileError(msg) =>
          return @posoco.ToolOutcome::ToolReportedError(content="Transpile error: " + msg, structured=None)
        _ =>
          return @posoco.ToolOutcome::ToolReportedError(content="Unexpected error", structured=None)
      }
      @posoco.ToolOutcome::Success(content=flutter_code, structured=None)
    },
  )
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_analyze"),
      description="Analyze MoonBit code structure and return AST summary",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{\"source\":{\"type\":\"string\",\"description\":\"MoonBit source code\"}},\"required\":[\"source\"]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(ctx) -> @posoco.ToolOutcome {
      let source = json_get_string(ctx.arguments, "source")
      if source == "" {
        return @posoco.ToolOutcome::ToolReportedError(
          content="missing 'source' parameter",
          structured=None,
        )
      }
      @posoco.ToolOutcome::Success(
        content=analyze_source(source),
        structured=None,
      )
    },
  )
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_project"),
      description="Scan and convert a MoonBit project directory to Dart",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{\"dir\":{\"type\":\"string\",\"description\":\"MoonBit project directory\"}},\"required\":[\"dir\"]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(ctx) -> @posoco.ToolOutcome {
      let dir = json_get_string(ctx.arguments, "dir")
      if dir == "" {
        return @posoco.ToolOutcome::ToolReportedError(
          content="missing 'dir' parameter",
          structured=None,
        )
      }
      @posoco.ToolOutcome::Success(
        content="Project scanning requires async I/O. Use 'moon2dart project " +
          dir +
          "' CLI command instead.",
        structured=None,
      )
    },
  )
  registry.register(
    @posoco.ToolDef(
      name=@posoco.ToolName::unchecked("moon2dart_list_tools"),
      description="List all available moon2dart tools",
      input_schema=@mcpsdk.parse_json(
        "{\"type\":\"object\",\"properties\":{},\"required\":[]}",
      ) catch {
        _ => raise @ast.Moon2DartError::SchemaError("invalid tool schema")
      },
      owner=@posoco.OwnerId::unchecked("moon2dart"),
      policy=@posoco.ExecutionPolicy::Sequential,
      provenance=None,
    ),
    fn(_ctx) -> @posoco.ToolOutcome {
      @posoco.ToolOutcome::Success(content=list_tools_info(), structured=None)
    },
  )
}

// ============================================================
// Agent 模式入口
// ============================================================

///|
/// run_agent_mode_with_input — 启动 posoco Agent 模式。
///
/// 创建 Moon2DartExtension（包含 RuleBasedModel + ToolRegistry + SessionPort），
/// 组装 Agent，运行一轮对话，输出结果。
///
/// 参数：
///   user_input — 用户输入的自然语言请求（如 "convert fn add(a: Int, b: Int) -> Int { a + b }"）
///   如果为 None，则打印帮助信息并退出。
pub async fn run_agent_mode_with_input(user_input : String?) -> Unit {
  let input = match user_input {
    Some(text) => text
    None => {
      println("moon2dart Agent mode — powered by posoco")
      println("")
      println("Usage: moon2dart serve --agent \"<your request>\"")
      println("")
      println("Examples:")
      println(
        "  moon2dart serve --agent \"convert fn add(a: Int, b: Int) -> Int { a + b }\"",
      )
      println(
        "  moon2dart serve --agent \"reverse int add(int a, int b) { return a + b; }\"",
      )
      println("  moon2dart serve --agent \"analyze fn main() { println(42) }\"")
      println("  moon2dart serve --agent \"list\"")
      println("")
      println("Available commands:")
      println("  convert <source>  — Convert MoonBit to Dart")
      println("  reverse <source>  — Convert Dart to MoonBit")
      println("  flutter <source>  — Convert to Flutter widget")
      println("  analyze <source>  — Analyze MoonBit code structure")
      println("  project <dir>     — Scan and convert a project")
      println("  list              — List all available tools")
      return
    }
  }
  let system = @posoco.EventSystem()
  let extension = try Moon2DartExtension() catch {
    @ast.Moon2DartError::SchemaError(msg) => {
      println("Error: tool schema registration failed: " + msg)
      return
    }
    @ast.Moon2DartError::JsonParseError(msg) => {
      println("Error: JSON parsing failed: " + msg)
      return
    }
    _ => {
      println("Error: extension initialization failed")
      return
    }
  }
  let agent = @posoco.Agent(
    exts=[extension],
    config=@posoco.agent_config(
      max_tool_rounds=Some(5),
      system_prompt=Some(
        "You are moon2dart, a MoonBit <-> Dart transpiler agent. Use the available tools to convert code between MoonBit and Dart/Flutter.",
      ),
    ),
    events=system,
  ) catch {
    _ => {
      println("Error: failed to compose Agent")
      return
    }
  }
  let message = @posoco.Message::UserMessage(content=[
    @posoco.Content::Text(input),
  ])
  let result = agent.run_turn(message, "moon2dart-session") catch {
    _ => {
      println("Error: agent turn failed")
      return
    }
  }
  match result.message {
    @posoco.Message::AssistantMessage(content~, ..) =>
      for item in content {
        match item {
          @posoco.Content::Text(text) => println(text)
          @posoco.Content::Image(..) => ()
        }
      }
    _ => println("Agent returned unexpected message type")
  }
  agent.shutdown() catch {
    _ => ()
  }
}
