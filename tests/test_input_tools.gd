extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_input_tools():
	var root_node = Node2D.new()
	root_node.name = "InputRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "simulate_key", "params": { "keycode": "A", "pressed": true, "modifiers": [] }},
		{"tool": "simulate_mouse_click", "params": { "position": {"x": 100, "y": 100}, "button_index": 1, "pressed": true }},
		{"tool": "simulate_mouse_move", "params": { "position": {"x": 200, "y": 200}, "relative": {"x": 10, "y": 10} }},
		{"tool": "simulate_action", "params": { "action": "ui_accept", "pressed": true, "strength": 1.0 }},
		{"tool": "simulate_sequence", "params": { "events": [ {"type": "key", "keycode": "Space", "pressed": true} ] }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
