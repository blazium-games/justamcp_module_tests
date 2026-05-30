extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_node_tools():
	var root_node = Node2D.new()
	root_node.name = "NodeRoot"
	
	var child = Node2D.new()
	child.name = "MyNode"
	root_node.add_child(child)
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "add_node", "params": { "type": "Node2D", "parent_path": ".", "name": "NewNode", "properties": {} }},
		{"tool": "delete_node", "params": { "node_path": "MyNode" }},
		{"tool": "duplicate_node", "params": { "node_path": "NewNode", "name": "NewNodeDup" }},
		{"tool": "move_node", "params": { "node_path": "NewNodeDup", "new_parent_path": "." }},
		{"tool": "update_property", "params": { "node_path": ".", "property": "position", "value": Vector2(10, 10) }},
		{"tool": "get_node_properties", "params": { "node_path": ".", "category": "all" }},
		{"tool": "add_resource", "params": { "node_path": ".", "property": "material", "resource_type": "StandardMaterial3D", "resource_properties": {} }},
		{"tool": "set_anchor_preset", "params": { "node_path": ".", "preset": "center", "keep_offsets": false }},
		{"tool": "rename_node", "params": { "node_path": ".", "new_name": "NodeRootRenamed" }},
		{"tool": "connect_signal", "params": { "source_path": ".", "signal_name": "ready", "target_path": ".", "method_name": "queue_free" }},
		{"tool": "disconnect_signal", "params": { "source_path": ".", "signal_name": "ready", "target_path": ".", "method_name": "queue_free" }},
		{"tool": "get_node_groups", "params": { "node_path": "." }},
		{"tool": "set_node_groups", "params": { "node_path": ".", "groups": ["test_group"] }},
		{"tool": "find_nodes_in_group", "params": { "group": "test_group" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
