extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _assert_runtime_bridge_response(result: Dictionary, tool_name: String) -> void:
	assert_true(result.has("ok") or result.has("type") or result.has("message") or result.has("error"), "Runtime bridge tool should return a structured response: " + tool_name)

func test_runtime_status_log_and_bridge_dependent_tools_are_structured() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)
	adapter.setup_sync()

	var status = adapter.execute_tool_direct("blazium_get_runtime_status", {})
	assert_true(status.get("ok", false), "get_runtime_status should always succeed")
	assert_true(status.has("runtime_available"), "Runtime status should report bridge availability")

	var log = adapter.execute_tool_direct("blazium_get_runtime_log", {"limit": 5})
	assert_true(log.get("ok", false), "get_runtime_log should always succeed")
	assert_true(log.has("logs"), "Runtime log should include logs array")

	for tool_name in [
		"blazium_runtime_get_autoload",
		"blazium_runtime_find_nodes_by_script",
		"blazium_runtime_batch_get_properties",
		"blazium_runtime_find_ui_elements",
		"blazium_runtime_click_button_by_text",
		"blazium_runtime_move_node",
		"blazium_runtime_monitor_properties",
	]:
		var schema = adapter.find_tool_schema(tool_name)
		assert_false(schema.is_empty(), "Runtime bridge schema should be exposed: " + tool_name)
		assert_true(schema.has("inputSchema"), "Runtime bridge schema should include inputSchema: " + tool_name)

	adapter.queue_free()
