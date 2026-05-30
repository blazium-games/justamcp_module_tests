extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_batch_add_nodes_and_execute_key_variants() -> void:
	var root = Node2D.new()
	root.name = "BatchExtendedRoot"
	add_child(root)
	autoqfree(root)

	var adapter = MCPTestAdapter.create()
	adapter.setup_sync()
	adapter.set_test_scene_root(root)

	var add_result = adapter.execute_tool_direct("blazium_batch_add_nodes", {
		"nodes": [
			{"type": "Node2D", "name": "BatchChildA", "parent_path": "."},
			{"node_type": "Node2D", "name": "BatchChildB", "parentPath": "."},
		],
	})
	assert_true(add_result.get("ok", false), "batch_add_nodes should succeed against the test scene root")
	assert_eq(add_result.get("result", {}).get("count", 0), 2, "batch_add_nodes should create both nodes")

	var execute_result = adapter.execute_tool_direct("blazium_batch_execute", {
		"steps": [
			{"tool": "blazium_find_nodes_by_type", "args": {"type": "Node2D", "recursive": true}},
			{"tool_name": "blazium_get_guide", "arguments": {"topic": "scene-editing"}},
		],
		"stop_on_error": true,
	})
	assert_true(execute_result.get("ok", false), "batch_execute should succeed")
	assert_eq(execute_result.get("count", 0), 2, "batch_execute should run two steps")
	assert_eq(execute_result.get("completed", 0), 2, "batch_execute should complete both safe steps")

	adapter.set_test_scene_root(null)
	adapter.cleanup()
