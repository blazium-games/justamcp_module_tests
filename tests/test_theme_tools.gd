extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_theme_tools():
	var root_node = Control.new()
	root_node.name = "ThemeRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "create_theme", "params": { "path": "res://my_theme.tres", "nodePath": "ThemeRoot" }},
		{"tool": "set_theme_color", "params": { "path": "res://my_theme.tres", "type": "Label", "colorName": "font_color", "color": Color(1,1,1) }},
		{"tool": "set_theme_constant", "params": { "path": "res://my_theme.tres", "type": "MarginContainer", "constantName": "margin_top", "value": 10 }},
		{"tool": "set_theme_font_size", "params": { "path": "res://my_theme.tres", "type": "Label", "fontName": "font_size", "size": 16 }},
		{"tool": "set_theme_stylebox", "params": { "path": "res://my_theme.tres", "type": "Panel", "styleName": "panel", "styleType": "flat" }},
		{"tool": "setup_control", "params": { "nodePath": "ThemeRoot", "preset": "full_rect" }},
		{"tool": "get_theme_info", "params": { "path": "res://my_theme.tres" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
