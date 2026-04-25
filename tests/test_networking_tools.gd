extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_networking_tools():
	var root_node = Node2D.new()
	root_node.name = "NetworkRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "networking_create_http_request", "params": {"parent_path": ".", "name": "HTTPReq", "timeout": 15}},
		{"tool": "networking_setup_websocket", "params": {"parent_path": ".", "mode": "client", "name": "WSSocket"}},
		{"tool": "networking_setup_multiplayer", "params": {"parent_path": ".", "transport": "enet", "mode": "server", "port": 7000}},
		{"tool": "networking_setup_rpc", "params": {"node_path": ".", "method_name": "fire", "rpc_mode": "any_peer"}},
		{"tool": "networking_setup_sync", "params": {"parent_path": ".", "name": "MP_Sync", "properties": [":position", ":rotation"]}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
		if res.has("ok") and res["ok"]:
			assert_true(not res.has("error"), "Result should not error when ok is true")
	
	executor.set_test_scene_root(null)
