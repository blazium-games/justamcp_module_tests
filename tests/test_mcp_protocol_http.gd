extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _request_or_skip(adapter: MCPTestAdapter, method: String, params: Dictionary = {}) -> Dictionary:
	var response = adapter.http_jsonrpc(method, params, 1500)
	if response.get("skipped", false):
		print("Skipping guarded MCP HTTP protocol assertions: " + str(response.get("error", "")))
	return response

func test_guarded_mcp_http_protocol_endpoints() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)

	var initialize = _request_or_skip(adapter, "initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	})
	if initialize.get("skipped", false):
		adapter.queue_free()
		return
	assert_true(initialize.has("result"), "initialize should return result")
	assert_true(initialize["result"].has("capabilities"), "initialize should expose capabilities")

	for item in [
		{"method": "ping", "params": {}},
		{"method": "tools/list", "params": {}},
		{"method": "prompts/list", "params": {}},
		{"method": "prompts/get", "params": {"name": "blazium_context", "arguments": {"mode": "strict"}}},
		{"method": "resources/list", "params": {}},
		{"method": "resources/templates/list", "params": {}},
		{"method": "resources/read", "params": {"uri": "blazium://guide/tool-index"}},
	]:
		var response = _request_or_skip(adapter, item["method"], item["params"])
		assert_false(response.get("skipped", false), "HTTP server should remain reachable after initialize")
		assert_true(response.has("result") or response.has("error"), "JSON-RPC endpoint should return result or error: " + item["method"])

	adapter.queue_free()
