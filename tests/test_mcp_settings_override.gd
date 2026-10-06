extends AutoworkTest

func test_disabled_category_filters_tools_list() -> void:
	var category := "shader_tools"
	var cat_key := "blazium/justamcp/tools/" + category
	var original: Variant = ProjectSettings.get_setting(cat_key)

	ProjectSettings.set_setting(cat_key, false)
	var disabled_schemas = JustAMCPToolExecutor.get_tool_schemas(false, false, false)
	var disabled_names := _names(disabled_schemas)
	assert_false(disabled_names.has("blazium_create_shader"), "Disabled category should filter shader tools")
	assert_false(disabled_names.has("blazium_read_shader"), "Disabled category should filter shader tools")

	ProjectSettings.set_setting(cat_key, true)
	var enabled_schemas = JustAMCPToolExecutor.get_tool_schemas(false, false, false)
	var enabled_names := _names(enabled_schemas)
	assert_true(enabled_names.size() >= disabled_names.size(), "Re-enabling category should restore tools")

	if original != null:
		ProjectSettings.set_setting(cat_key, original)

func test_override_editor_settings_key_exists() -> void:
	assert_true(ProjectSettings.has_setting("blazium/justamcp/override_editor_settings"))

func test_runtime_export_settings_exist() -> void:
	assert_true(ProjectSettings.has_setting("blazium/justamcp/export_port"))
	assert_true(ProjectSettings.has_setting("blazium/justamcp/project_mcp_dir"))
	assert_true(ProjectSettings.has_setting("blazium/justamcp/server_port"))
	var editor_port := int(ProjectSettings.get_setting("blazium/justamcp/server_port", 6506))
	var export_port := int(ProjectSettings.get_setting("blazium/justamcp/export_port", 0))
	if export_port != 0:
		assert_ne(export_port, editor_port, "Game MCP port must not reuse the editor port")

func _names(schemas: Array) -> Array:
	var names: Array = []
	for schema in schemas:
		names.append(str(schema.get("name", "")))
	return names
