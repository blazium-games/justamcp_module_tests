extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_profiling_tools():
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	
	var tests = [
		{"tool": "get_performance_monitors", "params": { "category": "memory" }},
		{"tool": "get_editor_performance", "params": {}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok"), "Tool failed to return ok: " + t.tool)
