extends AutoworkTest
class_name TestMCPIntegration

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_integration_flow():
	var adapter = MCPTestAdapter.new()
	add_child(adapter)
	adapter.setup_sync()

	if not adapter.http_available:
		print("Skipping MCP integration HTTP assertions: MCP HTTP server is not connected.")
		adapter.queue_free()
		return

	var parsed = await adapter.http_jsonrpc("initialize", {
		"clientInfo": {"name": "test_script", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 1)
	assert_true(parsed.get("ok", false), "Initialize should succeed over HTTP")
	assert_true(parsed.has("result"), "Init should have result block")
	assert_true(parsed["result"].has("capabilities"), "Should map capabilities")

	var tools = await adapter.http_jsonrpc("tools/list", {}, 2)
	assert_true(tools.get("ok", false), "Tools list should succeed over HTTP")
	assert_true(tools.get("result", {}).has("tools"), "Contains tools boundaries")
	assert_true(tools["result"]["tools"].size() > 0, "Tool list must naturally populate bounds natively")

	adapter.queue_free()
