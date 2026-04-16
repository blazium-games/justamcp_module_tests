extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_batch_tools():
	var root_node = Node2D.new()
	root_node.name = "BatchRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "find_nodes_by_type", "params": { "type": "Node2D", "node_path": "BatchRoot" }},
		{"tool": "find_signal_connections", "params": { "signal_name": "ready", "node_path": "BatchRoot" }},
		{"tool": "batch_set_property", "params": { "type": "Node2D", "property": "modulate", "value": Color(1, 1, 1) }},
		{"tool": "find_node_references", "params": { "pattern": "BatchRoot" }},
		{"tool": "cross_scene_set_property", "params": { "type": "Node2D", "property": "modulate", "value": Color(1, 1, 1), "path_filter": "res://", "exclude_addons": true }},
		{"tool": "get_scene_dependencies", "params": { "path": "res://test_scene.tscn" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
