extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_project_tools():
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	
	var tests = [
		{"tool": "get_project_info", "params": {}},
		{"tool": "get_filesystem_tree", "params": { "path": "res://", "filter": "*.gd", "max_depth": 1 }},
		{"tool": "search_files", "params": { "query": "test", "path": "res://", "file_type": "scene", "max_results": 10 }},
		{"tool": "search_in_files", "params": { "query": "GutTest", "path": "res://", "max_results": 10, "regex": false, "file_type": "script" }},
		{"tool": "get_project_settings", "params": { "section": "application", "key": "config/name" }},
		{"tool": "set_project_setting", "params": { "key": "application/config/test_mock", "value": "test" }},
		{"tool": "uid_to_project_path", "params": { "uid": "uid://test" }},
		{"tool": "project_path_to_uid", "params": { "path": "res://test_scene.tscn" }},
		{"tool": "add_autoload", "params": { "name": "MyAutoLoad", "path": "res://test_autorun.gd" }},
		{"tool": "remove_autoload", "params": { "name": "MyAutoLoad" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok"), "Tool failed to return ok: " + t.tool)
