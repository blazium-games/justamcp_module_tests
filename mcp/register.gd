extends Node

## Project-owned Streamable HTTP MCP tools and prompts.
## JustAMCPRuntime.load_project_mcp_scripts() instantiates this script and calls register().
## Use the engine singleton — JustAMCPRuntime cannot be constructed with .new().

func register() -> void:
	var runtime := _runtime()
	if runtime == null:
		push_error("JustAMCP: mcp/register.gd needs the JustAMCPRuntime singleton")
		return

	runtime.register_tool(
		"project_echo",
		"Echo text from the JustAMCP module test project.",
		{
			"type": "object",
			"properties": {
				"text": {"type": "string", "description": "Text to echo"},
			},
			"required": ["text"],
		},
		Callable(self, "_echo")
	)
	runtime.register_prompt(
		"project_hello",
		"Greet from the JustAMCP module test project.",
		Callable(self, "_hello")
	)

func _runtime() -> Object:
	if Engine.has_singleton("JustAMCPRuntime"):
		return Engine.get_singleton("JustAMCPRuntime")
	if Engine.has_singleton("JustAMCP"):
		return Engine.get_singleton("JustAMCP")
	if ClassDB.can_instantiate("JustAMCPRuntime"):
		return ClassDB.instantiate("JustAMCPRuntime")
	return null

func _echo(args: Dictionary) -> String:
	return str(args.get("text", ""))

func _hello(args: Dictionary) -> String:
	return "hello " + str(args.get("name", "world"))
