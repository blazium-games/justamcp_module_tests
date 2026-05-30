extends AutoworkTest

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_tool_catalog_has_expected_count_and_shape() -> void:
	MCPTestFixtures.ensure_fixture_files()
	var schemas = MCPTestFixtures.all_tool_schemas()
	assert_eq(typeof(schemas), TYPE_ARRAY)
	assert_gte(schemas.size(), 305, "JustAMCP should expose at least 305 tool schemas")

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

	assert_gte(seen.size(), 305, "Unique tool count should be at least 305")

func test_meta_tools_always_present() -> void:
	var names := _tool_names()
	for tool_name in ["blazium_search_tools", "blazium_execute_tool", "blazium_get_guide"]:
		assert_true(names.has(tool_name), "Meta tool should be present: " + tool_name)

func _tool_names() -> Array:
	var names: Array = []
	for schema in MCPTestFixtures.all_tool_schemas():
		names.append(str(schema.get("name", "")))
	return names
