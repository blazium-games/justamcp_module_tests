extends AutoworkTest

const SERVER_SETTINGS := [
	"blazium/justamcp/server_enabled",
	"blazium/justamcp/server_port",
	"blazium/justamcp/oauth_enabled",
	"blazium/justamcp/client_id",
	"blazium/justamcp/client_secret",
	"blazium/justamcp/enable_debug_logging",
	"blazium/justamcp/bind_to_localhost_only",
	"blazium/justamcp/override_editor_settings",
]

func test_server_settings_exist() -> void:
	for key in SERVER_SETTINGS:
		assert_true(ProjectSettings.has_setting(key), "ProjectSettings should define " + key)

func test_tool_category_and_per_tool_settings_registered() -> void:
	JustAMCPToolExecutor.get_tool_schemas(true)
	var manifest_path := "res://tests/mcp_tool_manifest.json"
	assert_true(FileAccess.file_exists(manifest_path), "Tool manifest should exist")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	assert_not_null(manifest)

	var missing: Array = []
	for category in manifest.keys():
		if str(category) == "meta":
			continue
		var cat_key := "blazium/justamcp/tools/" + str(category)
		if not ProjectSettings.has_setting(cat_key):
			missing.append("category: " + cat_key)
		for internal_name in manifest[category]:
			var full_name := "blazium_" + str(internal_name)
			var tool_key := cat_key + "/" + full_name
			if not ProjectSettings.has_setting(tool_key):
				missing.append("tool: " + tool_key)

	assert_eq(missing.size(), 0, "Missing tool settings keys:\n" + "\n".join(missing))
