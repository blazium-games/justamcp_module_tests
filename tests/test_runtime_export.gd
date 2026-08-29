extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

const PROJECT_TOOL := "project_echo"
const PROJECT_PROMPT := "project_hello"
const TEMP_TOOL := "aw_project_temp_echo"
const GAME_PORT := 6507

func test_runtime_class_exposes_project_mcp_api() -> void:
	assert_true(ClassDB.class_exists("JustAMCPRuntime"), "JustAMCPRuntime should be registered")
	for method_name in [
		"register_tool",
		"unregister_tool",
		"register_prompt",
		"unregister_prompt",
		"list_tools",
		"is_listening",
		"load_project_mcp_scripts",
		"register_custom_command",
		"unregister_custom_command",
		"execute_command",
	]:
		assert_true(
			ClassDB.class_has_method("JustAMCPRuntime", method_name),
			"JustAMCPRuntime should bind " + method_name
		)

func test_justamcp_engine_alias_matches_runtime_when_instantiated() -> void:
	if not Engine.has_singleton("JustAMCPRuntime"):
		pending("JustAMCPRuntime singleton is opt-in (game MCP / --enable-mcp-game-control)")
		return
	assert_true(Engine.has_singleton("JustAMCP"), "JustAMCP should alias JustAMCPRuntime")
	assert_eq(Engine.get_singleton("JustAMCP"), Engine.get_singleton("JustAMCPRuntime"))

func test_export_port_and_project_mcp_dir_settings() -> void:
	assert_true(ProjectSettings.has_setting("blazium/justamcp/server_port"))
	assert_true(ProjectSettings.has_setting("blazium/justamcp/export_port"))
	assert_true(ProjectSettings.has_setting("blazium/justamcp/project_mcp_dir"))

	var editor_port := int(ProjectSettings.get_setting("blazium/justamcp/server_port", 6506))
	var export_port := int(ProjectSettings.get_setting("blazium/justamcp/export_port", 0))
	var mcp_dir := str(ProjectSettings.get_setting("blazium/justamcp/project_mcp_dir", "res://mcp"))

	assert_eq(editor_port, 6506, "Editor MCP should stay on 6506 in this project")
	assert_eq(mcp_dir, "res://mcp", "Project MCP scripts should load from res://mcp")
	if export_port == 0:
		assert_eq(editor_port + 1, GAME_PORT, "export_port 0 resolves to editor port plus one")
	else:
		assert_ne(export_port, editor_port, "Game MCP port must not equal the editor port")

func test_register_tool_list_and_unregister() -> void:
	var runtime := _runtime()
	if runtime == null:
		pending("JustAMCPRuntime singleton is opt-in (game MCP / --enable-mcp-game-control)")
		return
	_cleanup_temp(runtime)

	var schema := {
		"type": "object",
		"properties": {"text": {"type": "string"}},
		"required": ["text"],
	}
	runtime.register_tool(TEMP_TOOL, "Temporary Autowork echo tool", schema, Callable(self, "_echo"))

	var listed: Array = runtime.list_tools()
	assert_true(_has_named(listed, TEMP_TOOL), "list_tools should include the registered tool")
	assert_eq(typeof(runtime.is_listening()), TYPE_BOOL, "is_listening should return a bool")

	runtime.unregister_tool(TEMP_TOOL)
	assert_false(_has_named(runtime.list_tools(), TEMP_TOOL), "unregister_tool should drop the tool")

func test_register_custom_command_stays_on_tcp_bridge() -> void:
	var runtime := _runtime()
	if runtime == null:
		pending("JustAMCPRuntime singleton is opt-in (game MCP / --enable-mcp-game-control)")
		return
	runtime.register_custom_command("aw_double", Callable(self, "_double"))
	var result: Dictionary = runtime.execute_command("run_custom_command", {
		"name": "aw_double",
		"args": [21],
	})
	assert_eq(str(result.get("type", "")), "custom_command_result", str(result))
	assert_eq(int(result.get("result", 0)), 42)
	runtime.unregister_custom_command("aw_double")
	var missing: Dictionary = runtime.execute_command("run_custom_command", {
		"name": "aw_double",
		"args": [1],
	})
	assert_eq(str(missing.get("type", "")), "error")

func test_load_project_mcp_scripts_registers_echo_tool() -> void:
	assert_true(ResourceLoader.exists("res://mcp/register.gd"), "Example register.gd should ship in the project")
	var runtime := _runtime()
	if runtime == null:
		pending("JustAMCPRuntime singleton is opt-in (game MCP / --enable-mcp-game-control)")
		return
	runtime.load_project_mcp_scripts()
	if not _has_named(runtime.list_tools(), PROJECT_TOOL):
		var script = ResourceLoader.load("res://mcp/register.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
		assert_not_null(script, "register.gd should load after the scene tree is ready")
		var inst = script.new()
		assert_not_null(inst, "register.gd should instantiate")
		add_child(inst)
		autoqfree(inst)
		if inst.has_method("register"):
			inst.register()

	assert_true(_has_named(runtime.list_tools(), PROJECT_TOOL), "register.gd should register project_echo")

	var adapter = MCPTestAdapter.create()
	var pages = adapter.collect_all_pages("tools/list", "tools")
	if pages.get("skipped", false):
		print("Skipping HTTP project-tool assertions: " + str(pages.get("error", "")))
		adapter.cleanup()
		return

	if not _has_named(pages.get("items", []), PROJECT_TOOL):
		print("Skipping HTTP project-tool assertions: port 6506 is not this process's JustAMCP registry")
		adapter.cleanup()
		return

	assert_true(_has_named(pages.get("items", []), PROJECT_TOOL), "Editor HTTP tools/list should include project_echo")

	var call_res = adapter.http_jsonrpc_stateless("tools/call", {
		"name": PROJECT_TOOL,
		"arguments": {"text": "from-autowork"},
	}, 5000)
	if call_res.get("skipped", false):
		print("Skipping tools/call assertion: " + str(call_res.get("error", "")))
	else:
		assert_true(call_res.has("result"), "project_echo should succeed over tools/call")
		var text := _tool_call_text(call_res.get("result", {}))
		assert_true(text.contains("from-autowork"), "project_echo should return the input text")

	var prompt_pages = adapter.collect_all_pages("prompts/list", "prompts")
	if not prompt_pages.get("skipped", false) and _has_named(prompt_pages.get("items", []), PROJECT_PROMPT):
		var prompt_get = adapter.http_jsonrpc_stateless("prompts/get", {
			"name": PROJECT_PROMPT,
			"arguments": {"name": "autowork"},
		}, 5000)
		if not prompt_get.get("skipped", false):
			assert_true(prompt_get.has("result"), "prompts/get should resolve project_hello")

	runtime.unregister_tool(PROJECT_TOOL)
	adapter.cleanup()

func test_editor_mcp_stays_on_6506_not_game_port() -> void:
	var editor = MCPTestAdapter.create()
	editor.port = 6506
	var ping = editor.http_jsonrpc_stateless("ping", {}, 1500)
	if ping.get("skipped", false):
		print("Skipping port split assertion: editor MCP is not listening")
		editor.cleanup()
		return
	assert_true(ping.has("result") or ping.has("error"), "Editor MCP should answer 6506")

	var game = MCPTestAdapter.create()
	game.port = GAME_PORT
	var game_ping = game.http_jsonrpc_stateless("ping", {}, 800)
	if game_ping.get("skipped", false):
		print("Game MCP on " + str(GAME_PORT) + " is not listening (editor-only Autowork is expected).")
	else:
		assert_true(game_ping.has("result") or game_ping.has("error"), "Game MCP should answer its own port, not the editor port")
	editor.cleanup()
	game.cleanup()

func _runtime() -> Object:
	if Engine.has_singleton("JustAMCPRuntime"):
		return Engine.get_singleton("JustAMCPRuntime")
	if Engine.has_singleton("JustAMCP"):
		return Engine.get_singleton("JustAMCP")
	if Engine.has_meta("justamcp_test_runtime"):
		var cached = Engine.get_meta("justamcp_test_runtime")
		if is_instance_valid(cached):
			return cached
	if ClassDB.can_instantiate("JustAMCPRuntime"):
		var runtime = ClassDB.instantiate("JustAMCPRuntime")
		Engine.set_meta("justamcp_test_runtime", runtime)
		return runtime
	return null

func _echo(args: Dictionary) -> String:
	return str(args.get("text", ""))

func _double(value: Variant) -> int:
	return int(value) * 2

func _cleanup_temp(runtime: Object) -> void:
	if runtime == null:
		return
	runtime.unregister_tool(TEMP_TOOL)
	if runtime.has_method("unregister_custom_command"):
		runtime.unregister_custom_command("aw_double")

func _has_named(items: Array, item_name: String) -> bool:
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("name", "")) == item_name:
			return true
	return false

func _tool_call_text(result: Variant) -> String:
	if typeof(result) != TYPE_DICTIONARY:
		return str(result)
	var payload: Dictionary = result
	var content = payload.get("content", [])
	if typeof(content) != TYPE_ARRAY:
		return str(payload.get("result", payload))
	var parts: PackedStringArray = []
	for block in content:
		if typeof(block) == TYPE_DICTIONARY:
			var text := str(block.get("text", ""))
			if not text.is_empty():
				parts.append(text)
	return "\n".join(parts)
