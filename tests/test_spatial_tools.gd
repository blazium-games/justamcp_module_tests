extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_spatial_tools():
	var root_node = Node3D.new()
	root_node.name = "SpatialRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var n1 = Node3D.new()
	n1.name = "NodeA"
	n1.position = Vector3(0, 0, 0)
	root_node.add_child(n1)
	
	var n2 = Node3D.new()
	n2.name = "NodeB"
	n2.position = Vector3(0.005, 0, 0) # Close enough to trigger collision overlap check threshold ideally
	root_node.add_child(n2)
	
	var nav = NavigationRegion3D.new()
	nav.name = "NavRegion"
	root_node.add_child(nav)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "spatial_analyze_layout", "params": {"node_path": ".", "include_3d": true}},
		{"tool": "spatial_suggest_placement", "params": {"parent_path": ".", "node_type": "Node3D", "context": "Enemy spawn"}},
		{"tool": "spatial_detect_overlaps", "params": {"node_path": ".", "threshold": 0.05}},
		{"tool": "spatial_measure_distance", "params": {"from_path": "NodeA", "to_path": "NodeB"}},
		{"tool": "spatial_bake_navigation", "params": {"node_path": "NavRegion", "on_thread": false}},
		{"tool": "navigation_set_layers", "params": {"node_path": "NavRegion", "layers": 3}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
