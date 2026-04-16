extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_analysis_tools():
	var root_node = Node2D.new()
	root_node.name = "AnalysisRoot"
	var child = Node2D.new()
	child.name = "ChildNode"
	root_node.add_child(child)
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "find_unused_resources", "params": { "path": "res://" }},
		{"tool": "analyze_signal_flow", "params": {}},
		{"tool": "analyze_scene_complexity", "params": { "scene_path": "res://test_scene.tscn" }},
		{"tool": "find_script_references", "params": { "query": "test" }},
		{"tool": "detect_circular_dependencies", "params": { "path": "res://" }},
		{"tool": "get_project_statistics", "params": {}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
