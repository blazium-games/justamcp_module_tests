extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_extended_analysis_aggregate_tools() -> void:
	var root = Node2D.new()
	root.name = "AnalysisExtendedRoot"
	add_child(root)
	autoqfree(root)

	var adapter = MCPTestAdapter.new()
	add_child(adapter)
	adapter.setup_sync()
	adapter.set_test_scene_root(root)

	for item in [
		{"tool": "blazium_project_state", "params": {}},
		{"tool": "blazium_project_advise", "params": {}},
		{"tool": "blazium_runtime_diagnose", "params": {"limit": 5}},
		{"tool": "blazium_scene_validate", "params": {}},
		{"tool": "blazium_script_analyze", "params": {"query": "test", "path": "res://tests"}},
		{"tool": "blazium_project_symbol_search", "params": {"query": "test", "path": "res://tests"}},
		{"tool": "blazium_project_index", "params": {"lod": 0}},
		{"tool": "blazium_scene_dependency_graph", "params": {"path": "res://missing_scene_for_dependency_graph.tscn"}},
	]:
		var result = adapter.execute_tool_direct(item["tool"], item["params"])
		assert_true(result.has("ok") or result.has("error"), "Tool should return a structured result: " + item["tool"])
		if item["tool"] != "blazium_scene_dependency_graph":
			assert_true(result.get("ok", false), "Aggregate analysis tool should succeed: " + item["tool"])

	adapter.set_test_scene_root(null)
	adapter.queue_free()
