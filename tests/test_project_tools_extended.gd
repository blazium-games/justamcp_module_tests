extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_project_mapping_settings_and_layer_tools() -> void:
	var adapter = MCPTestAdapter.create()
	adapter.setup_sync()

	var project_map = adapter.execute_tool_direct("blazium_project_map_project", {"lod": 0, "include_addons": false})
	assert_true(project_map.has("ok") or project_map.has("scripts"), "project_map_project should return structured project data")

	var scene_map = adapter.execute_tool_direct("blazium_project_map_scenes", {"include_addons": false})
	assert_true(scene_map.has("ok") or scene_map.has("scenes"), "project_map_scenes should return structured scene data")

	var settings = adapter.execute_tool_direct("blazium_project_list_settings", {"prefix": "application/config", "limit": 20})
	assert_true(settings.has("ok") or settings.has("settings"), "project_list_settings should return settings data")

	var collision_layers = adapter.execute_tool_direct("blazium_project_get_collision_layers", {})
	assert_true(collision_layers.has("ok") or collision_layers.has("layers"), "project_get_collision_layers should return layer data")

	var autoload_list = adapter.execute_tool_direct("blazium_project_manage_autoloads", {"action": "list"})
	assert_true(autoload_list.has("ok") or autoload_list.has("autoloads"), "project_manage_autoloads list should be structured")

	adapter.cleanup()
