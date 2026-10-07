extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

const SENSITIVE_TOOLS := [
	"blazium_editor_play_scene",
	"blazium_editor_play_main",
	"blazium_editor_run_scene",
	"blazium_remote_control_run_headless_script",
	"blazium_asset_lib_install",
	"blazium_editor_invoke_action",
	"blazium_runtime_quit",
]

func test_every_schema_is_named_object() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var adapter = MCPTestAdapter.create()
	for schema in MCPTestFixtures.all_tool_schemas():
		assert_eq(typeof(schema), TYPE_DICTIONARY)
		assert_eq(typeof(schema.get("name", null)), TYPE_STRING)
		assert_false(str(schema.get("name", "")).is_empty(), "Schema name should be a non-empty string")
		var input_schema = schema.get("inputSchema", null)
		assert_eq(typeof(input_schema), TYPE_DICTIONARY, "inputSchema should be an object for " + str(schema.get("name", "")))
		assert_eq(str(input_schema.get("type", "")), "object")
	adapter.cleanup()

func test_required_tools_refuse_empty_args_and_others_survive_hostile_payloads() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var adapter = MCPTestAdapter.create()
	var schemas = MCPTestFixtures.all_tool_schemas()
	for schema in schemas:
		var tool_name := str(schema.get("name", ""))
		var input_schema: Dictionary = schema.get("inputSchema", {})
		var required: Array = input_schema.get("required", [])
		if required.size() > 0 and not _is_sensitive(tool_name):
			var empty_result = adapter.execute_tool_direct(tool_name, {})
			assert_eq(typeof(empty_result), TYPE_DICTIONARY, tool_name + " empty call should return a dictionary")
			assert_false(bool(empty_result.get("ok", true)), tool_name + " should refuse empty arguments")
			continue
		for payload in [_hostile(-1), _hostile(99999)]:
			var result = adapter.execute_tool_direct(tool_name, payload)
			assert_eq(typeof(result), TYPE_DICTIONARY, tool_name + " hostile call should return a dictionary: " + str(result))
	adapter.cleanup()

func _is_sensitive(tool_name: String) -> bool:
	if SENSITIVE_TOOLS.has(tool_name):
		return true
	var bare := tool_name.trim_prefix("blazium_")
	return bare.begins_with("export_") or bare.begins_with("deploy_")

func _hostile(magnitude: int) -> Dictionary:
	return {
		"path": "C:/Windows/system32",
		"scene_path": "res://../outside.gd",
		"script": "C:/Windows/system32",
		"source": "C:/Windows/system32",
		"output": "//server/share",
		"destination": "C:/Windows/system32",
		"node_path": "res://../outside.gd",
		"files": ["C:/Windows/win.ini"],
		"title": "",
		"name": "",
		"expr": "",
		"count": magnitude,
		"frames": magnitude,
		"fixed_fps": magnitude,
		"duration_ms": magnitude,
		"scale": magnitude,
		"time_scale": magnitude,
	}
