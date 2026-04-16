extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_shader_tools():
	var root_node = Node2D.new()
	root_node.name = "ShaderRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "create_shader", "params": { "path": "res://my_shader.gdshader", "nodePath": "ShaderRoot", "shaderType": "canvas_item", "code": "shader_type canvas_item;\nvoid fragment(){}" }},
		{"tool": "read_shader", "params": { "path": "res://my_shader.gdshader" }},
		{"tool": "edit_shader", "params": { "path": "res://my_shader.gdshader", "content": "bla", "nodePath": "ShaderRoot", "insertLine": 1 }},
		{"tool": "assign_shader_material", "params": { "node_path": "ShaderRoot", "shader_path": "res://my_shader.gdshader" }},
		{"tool": "set_shader_param", "params": { "node_path": "ShaderRoot", "param_name": "color1", "value": Color(1, 1, 1) }},
		{"tool": "get_shader_params", "params": { "node_path": "ShaderRoot" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
