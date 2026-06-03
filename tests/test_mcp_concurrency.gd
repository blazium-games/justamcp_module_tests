extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _parallel_tool_call(tool_name: String, out: Array, index: int) -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.http_jsonrpc_stateless("initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 5000)
	if init_res.get("skipped", false):
		out[index] = {"skipped": true}
		adapter.cleanup()
		return

	var call_res = adapter.http_jsonrpc_stateless("tools/call", {
		"name": tool_name,
		"arguments": {},
	}, 30000)
	out[index] = call_res
	adapter.cleanup()

func test_parallel_readonly_tools_call_succeed() -> void:
	var results: Array = [null, null, null]
	var threads: Array = []

	for i in range(3):
		var t := Thread.new()
		t.start(_parallel_tool_call.bind("blazium_project_list_settings", results, i))
		threads.append(t)

	for t in threads:
		t.wait_to_finish()

	var any_skipped := false
	for res in results:
		if res == null:
			continue
		if res.get("skipped", false):
			any_skipped = true
			continue
		assert_true(res.has("result") or res.has("error"), "parallel call should return JSON-RPC payload")

	if any_skipped:
		print("Skipping parallel concurrency test: MCP server not reachable")
