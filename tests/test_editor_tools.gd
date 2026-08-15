extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_editor_tools():
	const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Editor tools require the editor (headless -s exposes a reduced set)")
		return
	var root_node = Node2D.new()
	root_node.name = "EditorRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "editor_clear_output", "params": {}},
		{"tool": "editor_screenshot_game", "params": {"path": "res://test_screenshot.png"}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
		
	# Cleanup
	var dir = DirAccess.open("res://")
	if dir and dir.file_exists("test_screenshot.png"):
		dir.remove("test_screenshot.png")
	
	executor.set_test_scene_root(null)
