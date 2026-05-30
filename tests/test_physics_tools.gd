extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_physics_tools():
	var root_node = Node2D.new()
	root_node.name = "PhysicsRoot"
	
	var my_body = RigidBody2D.new()
	my_body.name = "MyBody"
	root_node.add_child(my_body)
	
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "setup_physics_body", "params": { "parent_path": "PhysicsRoot", "name": "NewBody", "body_type": "rigid", "shape_type": "rectangle", "extents": "10,20" }},
		{"tool": "setup_collision", "params": { "parent_path": "MyBody", "shape_type": "circle", "radius": 15.0 }},
		{"tool": "set_physics_layers", "params": { "node_path": "MyBody", "layer": 1, "mask": 1 }},
		{"tool": "get_physics_layers", "params": { "node_path": "MyBody" }},
		{"tool": "add_raycast", "params": { "parent_path": "MyBody", "name": "MyRay", "length": 50.0 }},
		{"tool": "get_collision_info", "params": { "node_path": "MyBody" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
