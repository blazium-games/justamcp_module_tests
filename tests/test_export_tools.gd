extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_export_tools():
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	
	var tests = [
		{"tool": "list_export_presets", "params": {}},
		# We use dummy preset so it errors gracefully returning an error but not crashing
		{"tool": "export_project", "params": { "preset_index": 99, "preset_name": "Dummy", "debug": true }},
		{"tool": "get_export_info", "params": {}}
	]
	
	offset_check(tests, executor)
	var export_result = executor.execute_tool("export_project", { "preset_index": 99, "preset_name": "Dummy", "debug": true })
	var export_text := JSON.stringify(export_result)
	assert_false(export_text.findn("not supported") >= 0, export_text)
	assert_true(export_text.findn("async") >= 0 or export_text.findn("exit_code") >= 0 or export_text.findn("export_presets") >= 0 or export_text.findn("preset") >= 0, export_text)

func offset_check(tests, executor):
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		# A handled error is also considered an ok execution of the interface boundaries
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
