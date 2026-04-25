extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_runtime_tools():
	var root_node = Node3D.new()
	root_node.name = "VideoRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "runtime_capture_output", "params": {"lines": 50}},
		{"tool": "runtime_compare_screenshots", "params": {"path_a": "res://icon.png", "path_b": "res://icon.png", "threshold": 0.01}},
		{"tool": "runtime_record_video", "params": {"action": "start"}},
		{"tool": "runtime_record_video", "params": {"action": "stop"}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
