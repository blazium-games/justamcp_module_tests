extends AutoworkTest

func test_disabled_category_filters_tools_list() -> void:
	var category := "shader_tools"
	var cat_key := "blazium/justamcp/tools/" + category
	var original: Variant = ProjectSettings.get_setting(cat_key)

	ProjectSettings.set_setting(cat_key, false)
	var disabled_schemas = JustAMCPToolExecutor.get_tool_schemas()
	var disabled_names := _names(disabled_schemas)
	assert_false(disabled_names.has("blazium_create_shader"), "Disabled category should filter shader tools")
	assert_false(disabled_names.has("blazium_read_shader"), "Disabled category should filter shader tools")

	ProjectSettings.set_setting(cat_key, true)
	var enabled_schemas = JustAMCPToolExecutor.get_tool_schemas()
	var enabled_names := _names(enabled_schemas)
	assert_true(enabled_names.size() >= disabled_names.size(), "Re-enabling category should restore tools")

	if original != null:
		ProjectSettings.set_setting(cat_key, original)

func test_override_editor_settings_key_exists() -> void:
	assert_true(ProjectSettings.has_setting("blazium/justamcp/override_editor_settings"))

func _names(schemas: Array) -> Array:
	var names: Array = []
	for schema in schemas:
		names.append(str(schema.get("name", "")))
	return names
