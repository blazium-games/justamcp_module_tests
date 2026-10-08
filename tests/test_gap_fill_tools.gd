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
	"blazium_export_smoke",
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

func test_godot3_script_write_names_the_replacement() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_gap_godot3.gd"
	_delete_script(path)
	var adapter = MCPTestAdapter.create()
	var refused = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "extends KinematicBody2D\nfunc _ready() -> void:\n\tpass\n"})
	_assert_refused(refused, "CharacterBody2D")
	assert_false(FileAccess.file_exists(path), "A Godot 3 script should not be written")
	var forced = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "extends Node\nfunc _ready() -> void:\n\tyield(get_tree(), \"idle_frame\")\n", "validate": false})
	assert_true(bool(forced.get("ok", false)), JSON.stringify(forced))
	assert_true(FileAccess.file_exists(path))
	_delete_script(path)
	adapter.cleanup()

func test_script_write_reports_class_index() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_gap_class_index.gd"
	_delete_script(path)
	var adapter = MCPTestAdapter.create()
	var created = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "extends Node\nclass_name JustAMCPGapClassZZZ\nfunc _ready() -> void:\n\tpass\n"})
	assert_true(bool(created.get("ok", false)), JSON.stringify(created))
	var created_index := str(created.get("class_index", ""))
	assert_true(created_index == "pending" or created_index == "registered", JSON.stringify(created))
	var removed = adapter.execute_tool_direct("blazium_delete_script", {"path": path})
	assert_true(bool(removed.get("ok", false)), JSON.stringify(removed))
	var index := str(removed.get("class_index", ""))
	assert_true(index == "pending" or index == "registered", JSON.stringify(removed))
	_delete_script(path)
	adapter.cleanup()

func test_csharp_script_is_written_as_given() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_gap_plain.cs"
	_delete_script(path)
	var adapter = MCPTestAdapter.create()
	var created = adapter.execute_tool_direct("blazium_create_script", {"path": path, "content": "public class Gap { }\n"})
	assert_true(bool(created.get("ok", false)), JSON.stringify(created))
	assert_false(created.has("class_index"), JSON.stringify(created))
	_delete_script(path)
	adapter.cleanup()

func test_raw_scene_text_refuses_invented_structure() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_gap_scene.tscn"
	_delete_script(path)
	var adapter = MCPTestAdapter.create()
	var invented = adapter.execute_tool_direct("blazium_create_file", {"file_path": path, "content": "[gd_scene load_steps=1 format=3 uid=\"uid://abc\"]\n"})
	_assert_refused(invented, "uid://")
	assert_false(FileAccess.file_exists(path))
	var plain := "[gd_scene format=3]\n\n[node name=\"Root\" type=\"Node2D\"]\nposition = Vector2(0, 0)\n"
	var created = adapter.execute_tool_direct("blazium_create_file", {"file_path": path, "content": plain})
	assert_true(bool(created.get("ok", false)), JSON.stringify(created))
	var moved = adapter.execute_tool_direct("blazium_edit_file", {"file_path": path, "search_text": "Vector2(0, 0)", "replace_text": "Vector2(1, 0)"})
	assert_true(bool(moved.get("ok", false)), JSON.stringify(moved))
	var connected = adapter.execute_tool_direct("blazium_edit_file", {"file_path": path, "search_text": "Vector2(1, 0)", "replace_text": "Vector2(1, 0)\n\n[connection signal=\"pressed\" from=\".\" to=\".\" method=\"_on_pressed\"]"})
	assert_true(bool(connected.get("ok", false)), JSON.stringify(connected))
	var uid_edit = adapter.execute_tool_direct("blazium_edit_file", {"file_path": path, "search_text": "format=3", "replace_text": "format=3 uid=\"uid://abc\""})
	_assert_refused(uid_edit, "uid://")
	_delete_script(path)
	adapter.cleanup()

func test_export_smoke_schema_and_main_thread_scheduling() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var schema = adapter.find_tool_schema("blazium_export_smoke")
	var input_schema: Dictionary = schema.get("inputSchema", {})
	assert_true((input_schema.get("required", []) as Array).has("path"))
	assert_true((input_schema.get("properties", {}) as Dictionary).has("timeout_ms"))
	var execution: Dictionary = schema.get("execution", {})
	assert_eq(str(execution.get("taskSupport", "")), "required")
	var smoke = adapter.execute_tool_direct("blazium_export_smoke", {"path": "res://tests/_gap_missing.exe", "timeout_ms": 10})
	var smoke_text := JSON.stringify(smoke)
	assert_false(bool(smoke.get("ok", true)), smoke_text)
	assert_true(smoke_text.findn("async") >= 0 or smoke_text.findn("not found") >= 0, smoke_text)
	var export_result = adapter.execute_tool_direct("blazium_export_project", {"preset_name": "Dummy", "debug": true})
	var export_text := JSON.stringify(export_result)
	assert_false(export_text.findn("not supported") >= 0, export_text)
	assert_true(export_text.findn("async") >= 0 or export_text.findn("exit_code") >= 0 or export_text.findn("preset") >= 0 or export_text.findn("export_presets") >= 0, export_text)
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
