extends AutoworkTest

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_tool_catalog_has_expected_count_and_shape() -> void:
	MCPTestFixtures.ensure_fixture_files()
	var schemas = MCPTestFixtures.all_tool_schemas()
	if schemas.size() < 50:
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	assert_eq(typeof(schemas), TYPE_ARRAY)
	assert_gte(schemas.size(), 300, "JustAMCP should expose at least 300 tool schemas")

	var seen := {}
	for schema in schemas:
		assert_eq(typeof(schema), TYPE_DICTIONARY)
		assert_true(schema.has("name"), "Schema must include name")
		assert_true(schema.has("description"), "Schema must include description")
		assert_true(schema.has("inputSchema"), "Schema must include inputSchema")

		var tool_name := str(schema["name"])
		assert_true(tool_name.begins_with("blazium_"), "Tool names should be blazium-prefixed: " + tool_name)
		assert_false(seen.has(tool_name), "Duplicate tool name: " + tool_name)
		seen[tool_name] = true

		var input_schema = schema["inputSchema"] as Dictionary
		assert_eq(str(input_schema.get("type", "")), "object")
		if input_schema.has("properties"):
			assert_eq(typeof(input_schema["properties"]), TYPE_DICTIONARY)
		if input_schema.has("required"):
			assert_eq(typeof(input_schema["required"]), TYPE_ARRAY)

	assert_gte(seen.size(), 300, "Unique tool count should be at least 300")

func test_project_settings_list_the_full_server_catalog() -> void:
	assert_false(bool(ProjectSettings.get_setting("blazium/justamcp/enable_toolset_discovery", true)), "Toolset discovery should stay off so every tool is listed")
	var listed = JustAMCPToolExecutor.get_tool_schemas()
	assert_gte(listed.size(), 390, "The module-test project should expose the full JustAMCP catalog")

func test_meta_tools_always_present() -> void:
	var names := _tool_names()
	for tool_name in ["blazium_search_tools", "blazium_execute_tool", "blazium_get_guide"]:
		assert_true(names.has(tool_name), "Meta tool should be present: " + tool_name)

func test_optional_task_support_on_long_running_tools() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var optional_tools := [
		"blazium_batch_execute",
		"blazium_editor_reload_project",
		"blazium_editor_play_scene",
	]
	for tool_name in optional_tools:
		var schema := _find_schema(tool_name)
		assert_false(schema.is_empty(), "Expected tool schema: " + tool_name)
		var execution = schema.get("execution", {}) as Dictionary
		assert_eq(str(execution.get("taskSupport", "")), "optional", tool_name + " should allow task-augmented execution")

func test_forbidden_task_support_on_fast_tools() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var schema := _find_schema("blazium_project_list_settings")
	assert_false(schema.is_empty(), "project_list_settings should exist")
	if schema.has("execution"):
		var execution = schema["execution"] as Dictionary
		assert_ne(str(execution.get("taskSupport", "forbidden")), "optional", "Fast tools should not be optional-task by default")

func _find_schema(tool_name: String) -> Dictionary:
	for schema in MCPTestFixtures.all_tool_schemas():
		if str(schema.get("name", "")) == tool_name:
			return schema
	return {}

func _tool_names() -> Array:
	var names: Array = []
	for schema in MCPTestFixtures.all_tool_schemas():
		names.append(str(schema.get("name", "")))
	return names
