extends AutoworkTest
class_name TestMCPIntegration

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_integration_flow():
	var adapter = MCPTestAdapter.create()

	var parsed = adapter.http_jsonrpc("initialize", {
		"clientInfo": {"name": "test_script", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 5000)
	if parsed.get("skipped", false):
		print("Skipping MCP integration HTTP assertions: MCP HTTP server is not connected.")
		adapter.cleanup()
		return
	assert_true(parsed.has("result"), "Initialize should succeed over HTTP")
	assert_true(parsed["result"].has("capabilities"), "Should map capabilities")

	var tools = adapter.http_jsonrpc("tools/list", {}, 5000)
	assert_false(tools.get("skipped", false), "tools/list should reach MCP server")
	assert_true(tools.has("result"), "Tools list should succeed over HTTP")
	assert_true(tools["result"].has("tools"), "Contains tools boundaries")
	assert_true(tools["result"]["tools"].size() > 0, "Tool list must naturally populate bounds natively")

	adapter.cleanup()
