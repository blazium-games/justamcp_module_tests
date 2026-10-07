extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

const GAP_TOOLS := [
	"blazium_runtime_freeze",
	"blazium_runtime_step",
	"blazium_runtime_step_until",
	"blazium_runtime_set_time_scale",
	"blazium_runtime_click_world",
	"blazium_editor_get_camera",
	"blazium_editor_set_camera",
	"blazium_editor_list_dialogs",
	"blazium_editor_dismiss_dialog",
	"blazium_editor_list_actions",
	"blazium_editor_invoke_action",
	"blazium_editor_unsaved_state",
	"blazium_editor_save_all",
	"blazium_scene3d_render_probe",
	"blazium_scene3d_set_debug_draw",
	"blazium_spatial_snap_to_surface",
	"blazium_spatial_repeat_along",
	"blazium_export_patch_pck",
	"blazium_asset_lib_search",
	"blazium_asset_lib_info",
	"blazium_asset_lib_install",
]

const OPTIONAL_TOOLS := [
	"blazium_remote_control_run_headless_script",
]

func test_gap_fill_schemas_exist() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var adapter = MCPTestAdapter.create()
	var names = adapter.get_tool_names()
	for tool_name in GAP_TOOLS:
		assert_true(names.has(tool_name), "Missing schema: " + tool_name)
		var schema = adapter.find_tool_schema(tool_name)
		assert_eq(typeof(schema.get("inputSchema", null)), TYPE_DICTIONARY)
	for tool_name in OPTIONAL_TOOLS:
		if names.has(tool_name):
			var schema = adapter.find_tool_schema(tool_name)
			assert_eq(typeof(schema.get("inputSchema", null)), TYPE_DICTIONARY)
	adapter.cleanup()

func test_runtime_step_refuses_invalid_frames_without_waiting() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_step", {"duration_ms": 16, "frames": 1}), "not both")
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_step", {"frames": 0}), "frames")
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_step", {"frames": 121}), "frames")
	adapter.cleanup()

func test_runtime_step_until_refuses_bad_expr() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_step_until", {}), "expr")
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_step_until", {"expr": "x".repeat(600)}), "512")
	adapter.cleanup()

func test_time_scale_and_play_fps_are_capped() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	_assert_refused(adapter.execute_tool_direct("blazium_runtime_set_time_scale", {"time_scale": 17}), "16")
	_assert_refused(adapter.execute_tool_direct("blazium_editor_play_scene", {"fixed_fps": 0}), "fixed_fps")
	_assert_refused(adapter.execute_tool_direct("blazium_editor_play_scene", {"fixed_fps": 999}), "fixed_fps")
	adapter.cleanup()

func test_create_script_validation_does_not_leave_a_broken_file() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_gap_invalid.gd"
	_delete_script(path)
	var adapter = MCPTestAdapter.create()
	var invalid = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "func broken("})
	assert_false(bool(invalid.get("ok", true)))
	assert_true(JSON.stringify(invalid).contains("validation"), JSON.stringify(invalid))
	assert_false(FileAccess.file_exists(path), "Invalid script should not be written")
	var forced = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "func broken(", "validate": false})
	assert_false(JSON.stringify(forced).contains("validation"), JSON.stringify(forced))
	_delete_script(path)
	adapter.cleanup()

func test_patch_pack_refuses_hostile_paths() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	_assert_refused(adapter.execute_tool_direct("blazium_export_patch_pck", {"output": "C:/Windows/Temp/evil.pck", "files": ["res://project.godot"]}), "res://")
	_assert_refused(adapter.execute_tool_direct("blazium_export_patch_pck", {"output": "res://../outside.pck", "files": ["res://project.godot"]}), "sandbox")
	_assert_refused(adapter.execute_tool_direct("blazium_export_patch_pck", {"output": "res://tests/_gap_refused.pck", "files": ["C:/Windows/win.ini"]}), "res://")
	assert_false(FileAccess.file_exists("res://tests/_gap_refused.pck"))
	adapter.cleanup()

func test_headless_script_refuses_unsafe_source() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	if not adapter.get_tool_names().has("blazium_remote_control_run_headless_script"):
		adapter.cleanup()
		return
	_assert_refused(adapter.execute_tool_direct("blazium_remote_control_run_headless_script", {"source": "extends Node\nfunc _initialize():\n\tpass"}), "SceneTree")
	_assert_refused(adapter.execute_tool_direct("blazium_remote_control_run_headless_script", {"source": "extends SceneTree\nfunc _initialize():\n\tOS.execute(\"cmd\", [])"}), "os.execute")
	_assert_refused(adapter.execute_tool_direct("blazium_remote_control_run_headless_script", {"source": "extends SceneTree\nfunc _initialize():\n\tOS.create_process(\"cmd\", [])"}), "os.create_process")
	adapter.cleanup()

func test_repeat_count_and_dialog_title_are_refused() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	_assert_refused(adapter.execute_tool_direct("blazium_spatial_repeat_along", {"node_path": ".", "count": 0}), "count")
	_assert_refused(adapter.execute_tool_direct("blazium_spatial_repeat_along", {"node_path": ".", "count": 100}), "count")
	_assert_refused(adapter.execute_tool_direct("blazium_editor_dismiss_dialog", {"title": ""}), "title")
	adapter.cleanup()

func test_dialog_and_play_clock_resources_are_json_objects() -> void:
	var adapter = MCPTestAdapter.create()
	for uri in ["blazium://editor/dialogs", "blazium://play/clock"]:
		var result = adapter.read_resource(uri)
		assert_true(result.has("contents"), uri)
		var contents: Array = result["contents"]
		assert_gt(contents.size(), 0, uri)
		var parsed = JSON.parse_string(str(contents[0].get("text", "")))
		assert_eq(typeof(parsed), TYPE_DICTIONARY, uri + " should be a JSON object")
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true

func _assert_refused(result: Dictionary, needle: String) -> void:
	assert_eq(typeof(result), TYPE_DICTIONARY)
	assert_false(bool(result.get("ok", true)), JSON.stringify(result))
	assert_true(JSON.stringify(result).findn(needle) >= 0, JSON.stringify(result))

func _delete_script(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
