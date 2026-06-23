extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_manifest_matches_live_tool_catalog() -> void:
	var schemas = MCPTestFixtures.all_tool_schemas()
	var live := {}
	for schema in schemas:
		live[str(schema.get("name", ""))] = true

	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/mcp_tool_manifest.json"))
	assert_not_null(manifest)
	var expected := 0
	for category in manifest.keys():
		for internal_name in manifest[category]:
			expected += 1
			var full_name := "blazium_" + str(internal_name)
			assert_true(live.has(full_name), "Live catalog missing manifest tool: " + full_name)

	assert_gte(expected, 300)
	assert_gte(live.size(), 300)

func test_required_argument_tools_are_registered_not_unknown() -> void:
	var adapter = MCPTestAdapter.create()
	var failures: Array = []
	for schema in MCPTestFixtures.all_tool_schemas():
		var tool_name := str(schema.get("name", ""))
		if tool_name.is_empty():
			continue
		var required = (schema.get("inputSchema", {}) as Dictionary).get("required", []) as Array
		if required.is_empty():
			continue
		var result = adapter.execute_tool_direct(tool_name, {})
		if MCPTestFixtures.is_dispatch_failure(result):
			failures.append(tool_name + ": " + str(result.get("error", "dispatch failure")))
	adapter.cleanup()
	assert_eq(failures.size(), 0, "Required-arg tools should register handlers:\n" + "\n".join(failures))
