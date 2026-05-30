extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_script_tools():
	var root_node = Node2D.new()
	root_node.name = "ScriptRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "list_scripts", "params": { "path": "res://", "recursive": true }},
		{"tool": "read_script", "params": { "path": "res://test_script.gd" }},
		{"tool": "create_script", "params": { "path": "res://test_created_script.gd", "content": "extends Node", "extends": "Node", "class_name": "TestClass" }},
		{"tool": "edit_script", "params": { "path": "res://test_created_script.gd", "content": "", "insert_at_line": 2, "text": "var i = 0", "replacements": [] }},
		{"tool": "attach_script", "params": { "node_path": "ScriptRoot", "script_path": "res://test_created_script.gd" }},
		{"tool": "get_open_scripts", "params": {}},
		{"tool": "validate_script", "params": { "path": "res://test_created_script.gd" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
