extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_autowork_tools():
	if not ClassDB.class_exists("JustAMCPToolExecutor"):
		return
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	
	var tests = [
		{"tool": "autowork_run_test_by_name", "params": { "test_name": "non_existent_test_123" }},
		{"tool": "blazium_autowork_run_test_by_name", "params": { "test_name": "non_existent_test_123" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
		
		# If the module is enabled, it should return a successful ok = true and results dict
		if res.has("ok") and res["ok"] == true:
			assert_true(res.has("result"), "Result missing from successfully triggered autowork execute_tool")
			var data = res["result"]
			assert_true(data.has("pass_count"), "pass_count missing")
			assert_true(data.has("fail_count"), "fail_count missing")
			assert_true(data.has("assert_count"), "assert_count missing")
			assert_true(data.has("failures"), "failures missing")

	if executor:
		executor.cleanup()
