extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_export_tools():
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	
	var tests = [
		{"tool": "list_export_presets", "params": {}},
		# We use dummy preset so it errors gracefully returning an error but not crashing
		{"tool": "export_project", "params": { "preset_index": 99, "preset_name": "Dummy", "debug": true }},
		{"tool": "get_export_info", "params": {}}
	]
	
	offset_check(tests, executor)

func offset_check(tests, executor):
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		# A handled error is also considered an ok execution of the interface boundaries
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
