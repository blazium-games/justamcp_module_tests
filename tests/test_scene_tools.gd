extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_scene_tools():
	var root_node = Node2D.new()
	root_node.name = "SceneRoot"
	
	var child = Node2D.new()
	child.name = "MyChild"
	root_node.add_child(child)
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "list_scene_nodes", "params": {"scene_path": "res://test_scene.tscn"}},
		{"tool": "create_scene", "params": {"scene_path": "res://test_created_scene.tscn", "nodes": []}},
		{"tool": "set_node_properties", "params": {"scene_path": "res://test_scene.tscn", "node_path": "MyChild", "properties": {"position": {"x": 10, "y": 10}}}},
		{"tool": "get_node_properties", "params": {"scene_path": "res://test_scene.tscn", "node_path": "MyChild"}},
		{"tool": "load_sprite", "params": {"scene_path": "res://test_scene.tscn", "node_path": "MyChild", "texture_path": "res://icon.svg"}},
		{"tool": "save_scene", "params": {"scene_path": "res://test_scene.tscn"}},
		{"tool": "list_connections", "params": {"scene_path": "res://test_scene.tscn", "node_path": "MyChild"}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok"), "Tool failed to return ok: " + t.tool)
	
	executor.set_test_scene_root(null)
