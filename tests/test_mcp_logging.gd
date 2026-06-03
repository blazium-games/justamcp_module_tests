extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_logs_read_tool_returns_payload() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.http_jsonrpc_stateless("initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 3000)
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	var call_res = adapter.http_jsonrpc_stateless("tools/call", {
		"name": "blazium_logs_read",
		"arguments": {"limit": 5},
	}, 10000)
	if call_res.get("skipped", false):
		adapter.cleanup()
		return

	assert_true(call_res.has("result"), "logs_read should return MCP result")
	adapter.cleanup()

func test_mcp_log_resource_pagination_template() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.http_jsonrpc_stateless("initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 3000)
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	var templates = adapter.http_jsonrpc_stateless("resources/templates/list", {}, 5000)
	if templates.get("skipped", false):
		adapter.cleanup()
		return

	var found_mcp_log := false
	for tmpl in templates.get("result", {}).get("resourceTemplates", []):
		var uri_template := str((tmpl as Dictionary).get("uriTemplate", ""))
		if uri_template.contains("blazium://logs/mcp/"):
			found_mcp_log = true
			break
	assert_true(found_mcp_log, "resource templates should include MCP log pagination URI")

	var read_res = adapter.http_jsonrpc_stateless("resources/read", {"uri": "blazium://logs/mcp/start"}, 5000)
	assert_true(read_res.has("result") or read_res.has("error"), "MCP log resource read should respond")

	adapter.cleanup()
