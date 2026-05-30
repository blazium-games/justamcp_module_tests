extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func _tool_names() -> Array:
	MCPTestFixtures.enable_all_tool_categories()
	var adapter = MCPTestAdapter.create()
	var names = adapter.get_tool_names()
	adapter.cleanup()
	return names

func _assert_has_tools(names: Array, expected: Array) -> void:
	for tool_name in expected:
		assert_true(names.has(tool_name), "Expected tool schema to include " + str(tool_name))

func _assert_missing_tools(names: Array, unexpected: Array) -> void:
	for tool_name in unexpected:
		assert_false(names.has(tool_name), "Tool schema should not include removed duplicate " + str(tool_name))

func test_new_tool_schema_contracts() -> void:
	var names = _tool_names()
	assert_gt(names.size(), 100, "JustAMCP should expose the expanded MCP tool catalog")

	_assert_has_tools(names, [
		"blazium_search_tools",
		"blazium_execute_tool",
		"blazium_get_guide",
		"blazium_docs_list_classes",
		"blazium_docs_search",
		"blazium_docs_get_class",
		"blazium_docs_get_member",
		"blazium_classdb_query",
		"blazium_logs_read",
		"blazium_batch_execute",
		"blazium_project_map_project",
		"blazium_project_map_scenes",
		"blazium_project_list_settings",
		"blazium_project_update_settings",
		"blazium_project_manage_autoloads",
		"blazium_project_get_collision_layers",
		"blazium_project_state",
		"blazium_project_advise",
		"blazium_runtime_diagnose",
		"blazium_scene_validate",
		"blazium_scene_analyze",
		"blazium_script_analyze",
		"blazium_project_symbol_search",
		"blazium_project_index",
		"blazium_scene_dependency_graph",
		"blazium_blueprint_create_particle_preset",
		"blazium_blueprint_create_material_preset",
		"blazium_blueprint_setup_camera_preset",
		"blazium_control_draw_recipe",
		"blazium_environment_create",
		"blazium_asset_generate_2d_asset",
		"blazium_audio_get_players_info",
		"blazium_create_shader_template",
		"blazium_runtime_get_autoload",
		"blazium_runtime_find_nodes_by_script",
		"blazium_runtime_batch_get_properties",
		"blazium_runtime_find_ui_elements",
		"blazium_runtime_click_button_by_text",
		"blazium_runtime_move_node",
		"blazium_runtime_monitor_properties",
	])

	if ClassDB.class_exists("Autowork"):
		_assert_has_tools(names, [
			"blazium_autowork_run_all_tests",
			"blazium_autowork_run_tests_in_directory",
			"blazium_autowork_run_test_script",
			"blazium_autowork_run_test_by_name",
		])

func test_removed_duplicate_tool_schemas_stay_removed() -> void:
	var names = _tool_names()
	_assert_missing_tools(names, [
		"blazium_set_node_property",
		"blazium_get_project_settings",
		"blazium_update_project_settings",
		"blazium_get_input_map",
		"blazium_configure_input_map",
	])

func test_tool_schema_names_are_unique() -> void:
	var seen := {}
	for tool_name in _tool_names():
		assert_false(seen.has(tool_name), "Duplicate tool schema name found: " + str(tool_name))
		seen[tool_name] = true
