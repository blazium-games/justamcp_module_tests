extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_one_undo_reverts_a_multi_step_batch() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var batch = adapter.execute_tool_direct("blazium_batch_execute", {
		"steps": [
			{"tool": "blazium_agent_probe_increment", "args": {}},
			{"tool": "blazium_agent_probe_increment", "args": {}},
		],
	})
	assert_true(batch.get("ok", false), JSON.stringify(batch))
	assert_eq(int(batch.get("completed", 0)), 2)
	assert_eq(int(batch.get("undo_steps", 0)), 1, "A successful multi-step batch should collapse to one undo")
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	var value = adapter.execute_tool_direct("blazium_agent_probe_value", {})
	assert_eq(int(value.get("value", -1)), 0, "One editor_undo should revert both batch steps")
	adapter.cleanup()

func test_batch_property_undo_and_stale_before() -> void:
	if not _full_catalog():
		return
	var root := Node2D.new()
	root.name = "BatchRoot"
	add_child(root)
	autoqfree(root)
	var item := Polygon2D.new()
	item.name = "Patch"
	item.position = Vector2(1, 2)
	root.add_child(item)
	var adapter = MCPTestAdapter.create()
	adapter.set_test_scene_root(root)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var stale = adapter.execute_tool_direct("blazium_batch_set_property", {
		"type": "Polygon2D",
		"property": "position",
		"value": Vector2(9, 9),
		"before": Vector2(0, 0),
	})
	assert_false(bool(stale.get("ok", true)), JSON.stringify(stale))
	assert_eq(item.position, Vector2(1, 2))
	var applied = adapter.execute_tool_direct("blazium_batch_set_property", {
		"type": "Polygon2D",
		"property": "position",
		"value": Vector2(4, 5),
		"before": Vector2(1, 2),
	})
	assert_true(applied.get("ok", false), JSON.stringify(applied))
	assert_eq(item.position, Vector2(4, 5))
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_eq(item.position, Vector2(1, 2), JSON.stringify(undo))
	adapter.set_test_scene_root(null)
	adapter.cleanup()

func test_shader_edit_undo_restores_the_file() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_agent_undo.gdshader"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("shader_type canvas_item;\n")
	file.close()
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var edited = adapter.execute_tool_direct("blazium_edit_shader", {"path": path, "content": "shader_type spatial;\n"})
	assert_true(edited.get("ok", false), JSON.stringify(edited))
	assert_true(FileAccess.get_file_as_string(path).find("spatial") >= 0)
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_true(FileAccess.get_file_as_string(path).find("canvas_item") >= 0, FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_shader_template_undo_restores_the_file() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_agent_template.gdshader"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("shader_type canvas_item;\n")
	file.close()
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var created = adapter.execute_tool_direct("blazium_create_shader_template", {"shaderPath": path, "shaderType": "spatial", "code": "shader_type spatial;\n"})
	assert_true(created.get("ok", false), JSON.stringify(created))
	assert_true(FileAccess.get_file_as_string(path).find("spatial") >= 0)
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_true(FileAccess.get_file_as_string(path).find("canvas_item") >= 0, FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_patch_script_undo_restores_the_file() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_agent_patch.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("extends Node\nfunc _ready() -> void:\n\tpass\n")
	file.close()
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var patched = adapter.execute_tool_direct("blazium_patch_script", {"path": path, "anchor": "pass", "replacement": "return"})
	assert_true(patched.get("ok", false), JSON.stringify(patched))
	assert_true(FileAccess.get_file_as_string(path).find("return") >= 0)
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_true(FileAccess.get_file_as_string(path).find("pass") >= 0, FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_edit_file_undo_restores_the_file() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_agent_edit.txt"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("alpha beta")
	file.close()
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var edited = adapter.execute_tool_direct("blazium_edit_file", {"file_path": path, "search_text": "beta", "replace_text": "gamma"})
	assert_true(edited.get("ok", false), JSON.stringify(edited))
	assert_true(FileAccess.get_file_as_string(path).find("gamma") >= 0)
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_true(FileAccess.get_file_as_string(path).find("beta") >= 0, FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_edit_file_change_plan_applies_and_reverts() -> void:
	if not _full_catalog():
		return
	var path := "res://tests/_agent_plan.txt"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("alpha beta")
	file.close()
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var dry = adapter.execute_tool_direct("blazium_edit_file", {"file_path": path, "search_text": "beta", "replace_text": "gamma", "dry_run": true})
	assert_true(bool(dry.get("dry_run", false)), JSON.stringify(dry))
	assert_true(FileAccess.get_file_as_string(path).find("beta") >= 0)
	var applied = adapter.execute_tool_direct("blazium_apply_change_plan", {"plan_id": str(dry.get("plan_id", ""))})
	assert_true(applied.get("ok", false), JSON.stringify(applied))
	assert_true(FileAccess.get_file_as_string(path).find("gamma") >= 0, FileAccess.get_file_as_string(path))
	var reverted = adapter.execute_tool_direct("blazium_revert_change_plan", {"plan_id": str(dry.get("plan_id", ""))})
	assert_true(reverted.get("ok", false), JSON.stringify(reverted))
	assert_false(bool(reverted.get("mismatch", true)))
	assert_true(FileAccess.get_file_as_string(path).find("beta") >= 0, FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_checkpoint_diffs_and_restores_a_script_snapshot() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var path := "res://tests/_agent_ckpt.txt"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("original")
	file.close()
	var created = adapter.execute_tool_direct("blazium_checkpoint", {"paths": [path]})
	assert_true(created.get("ok", false), JSON.stringify(created))
	var checkpoint_id := str(created.get("checkpoint_id", ""))
	assert_false(checkpoint_id.is_empty())
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("changed")
	file.close()
	var diff = adapter.execute_tool_direct("blazium_diff_checkpoint", {"checkpoint_id": checkpoint_id})
	assert_gt((diff.get("changed", []) as Array).size(), 0, JSON.stringify(diff))
	var restored = adapter.execute_tool_direct("blazium_restore_checkpoint", {"checkpoint_id": checkpoint_id})
	assert_true(restored.get("ok", false), JSON.stringify(restored))
	assert_eq(FileAccess.get_file_as_string(path), "original")
	adapter.cleanup()

func test_dry_run_does_not_apply_and_revert_reports_mismatch() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var dry = adapter.execute_tool_direct("blazium_agent_probe_increment", {"dry_run": true})
	assert_true(bool(dry.get("dry_run", false)), JSON.stringify(dry))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 0)
	var applied = adapter.execute_tool_direct("blazium_apply_change_plan", {"plan_id": str(dry.get("plan_id", ""))})
	assert_true(applied.get("ok", false), JSON.stringify(applied))
	assert_eq(int(applied.get("value", 0)), 1)
	adapter.execute_tool_direct("blazium_agent_probe_increment", {})
	var reverted = adapter.execute_tool_direct("blazium_revert_change_plan", {"plan_id": str(dry.get("plan_id", ""))})
	assert_true(bool(reverted.get("mismatch", false)), JSON.stringify(reverted))
	adapter.cleanup()

func test_move_copy_and_binary_undo_restore_files() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var moved := "res://tests/_agent_move.txt"
	var moved_dest := "res://tests/_agent_move_dst.txt"
	var copied := "res://tests/_agent_copy.txt"
	var copied_dest := "res://tests/_agent_copy_dst.txt"
	var scene_src := "res://tests/_agent_dup.tscn"
	var scene_dest := "res://tests/_agent_dup_copy.tscn"
	var binary := "res://tests/_agent_bin.png"
	var binary_dest := "res://tests/_agent_bin_dst.png"
	_write_text(moved, "moved-body")
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var move_result = adapter.execute_tool_direct("blazium_move_file", {"from": moved, "to": moved_dest})
	assert_true(move_result.get("ok", false), JSON.stringify(move_result))
	assert_false(FileAccess.file_exists(moved))
	assert_true(FileAccess.file_exists(moved_dest))
	var move_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(move_undo.get("ok", false), JSON.stringify(move_undo))
	assert_eq(FileAccess.get_file_as_string(moved), "moved-body")
	assert_false(FileAccess.file_exists(moved_dest))
	_write_text(copied, "copy-body")
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var copy_result = adapter.execute_tool_direct("blazium_copy_file", {"from": copied, "to": copied_dest})
	assert_true(copy_result.get("ok", false), JSON.stringify(copy_result))
	assert_true(FileAccess.file_exists(copied_dest))
	var copy_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(copy_undo.get("ok", false), JSON.stringify(copy_undo))
	assert_eq(FileAccess.get_file_as_string(copied), "copy-body")
	assert_false(FileAccess.file_exists(copied_dest))
	_write_text(scene_src, "[gd_scene format=3]\n\n[node name=\"Root\" type=\"Node\"]\n")
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var duplicated = adapter.execute_tool_direct("blazium_scene_duplicate_file", {"source_path": scene_src, "dest_path": scene_dest})
	assert_true(duplicated.get("ok", false), JSON.stringify(duplicated))
	assert_true(FileAccess.file_exists(scene_dest))
	var duplicate_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(duplicate_undo.get("ok", false), JSON.stringify(duplicate_undo))
	assert_true(FileAccess.file_exists(scene_src))
	assert_false(FileAccess.file_exists(scene_dest))
	var binary_file := FileAccess.open(binary, FileAccess.WRITE)
	var binary_bytes := PackedByteArray([0xff, 0xfe, 0x00, 0x81])
	binary_file.store_buffer(binary_bytes)
	binary_file.close()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var binary_move = adapter.execute_tool_direct("blazium_move_file", {"from": binary, "to": binary_dest})
	assert_true(binary_move.get("ok", false), JSON.stringify(binary_move))
	var binary_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(binary_undo.get("ok", false), JSON.stringify(binary_undo))
	assert_eq(FileAccess.get_file_as_bytes(binary), binary_bytes)
	assert_false(FileAccess.file_exists(binary_dest))
	for path in [moved, moved_dest, copied, copied_dest, scene_src, scene_dest, binary, binary_dest]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_recipe_apply_undo_removes_the_player() -> void:
	if not _full_catalog():
		return
	var root := Node2D.new()
	root.name = "RecipeRoot"
	add_child(root)
	autoqfree(root)
	var adapter = MCPTestAdapter.create()
	adapter.set_test_scene_root(root)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var applied = adapter.execute_tool_direct("blazium_recipe_add_player_controller", {"apply": true})
	assert_true(applied.get("ok", false), JSON.stringify(applied))
	var player := root.get_node_or_null("Player")
	assert_not_null(player)
	assert_not_null(player.get_node_or_null("CollisionShape2D"))
	assert_not_null(player.get_node_or_null("Camera2D"))
	var undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(undo.get("ok", false), JSON.stringify(undo))
	assert_null(root.get_node_or_null("Player"))
	adapter.set_test_scene_root(null)
	adapter.cleanup()

func test_theme_and_import_copy_undo_restore_files() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var theme := "res://tests/_agent_theme.tres"
	var original := "[gd_resource type=\"Resource\" format=3]\n"
	_write_text(theme, original)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var created = adapter.execute_tool_direct("blazium_create_theme", {"path": theme})
	assert_true(bool(created.get("ok", false)), JSON.stringify(created))
	assert_ne(FileAccess.get_file_as_string(theme), original)
	var theme_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(theme_undo.get("ok", false)), JSON.stringify(theme_undo))
	assert_eq(FileAccess.get_file_as_string(theme), original)
	var source := "res://tests/_agent_import_src.txt"
	var imported := "res://tests/_agent_import_dst.txt"
	_write_text(source, "source-body")
	_write_text(imported, "dest-body")
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var copied = adapter.execute_tool_direct("blazium_import_asset_copy", {"source_path": source, "dest_path": imported})
	assert_true(bool(copied.get("ok", false)), JSON.stringify(copied))
	assert_eq(FileAccess.get_file_as_string(imported), "source-body")
	var copy_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(copy_undo.get("ok", false)), JSON.stringify(copy_undo))
	assert_eq(FileAccess.get_file_as_string(source), "source-body")
	assert_eq(FileAccess.get_file_as_string(imported), "dest-body")
	for path in [theme, source, imported]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_game_shot_and_client_config_undo_restore_files() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var shot := "res://tests/_agent_game_shot.png"
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 1))
	image.save_png(shot)
	var shot_original := FileAccess.get_file_as_bytes(shot)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var captured = adapter.execute_tool_direct("blazium_editor_screenshot_game", {"path": shot})
	assert_true(bool(captured.get("ok", false)), JSON.stringify(captured))
	assert_ne(FileAccess.get_file_as_bytes(shot), shot_original)
	var shot_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(shot_undo.get("ok", false)), JSON.stringify(shot_undo))
	assert_eq(FileAccess.get_file_as_bytes(shot), shot_original)
	var config := "res://tests/_agent_client_undo.toml"
	var config_original := "kept-config\n"
	_write_text(config, config_original)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var written = adapter.execute_tool_direct("blazium_write_client_config", {"client": "cursor", "path": config})
	assert_true(bool(written.get("ok", false)), JSON.stringify(written))
	assert_ne(FileAccess.get_file_as_string(config), config_original)
	var config_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(config_undo.get("ok", false)), JSON.stringify(config_undo))
	assert_eq(FileAccess.get_file_as_string(config), config_original)
	for path in [shot, config]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func test_verify_game_change_does_not_pass_without_play() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var checked = adapter.execute_tool_direct("blazium_verify_game_change", {"scene_path": "res://tests/_missing_play.tscn", "duration_ms": 50})
	assert_false(bool(checked.get("ok", true)), JSON.stringify(checked))
	assert_false(bool(checked.get("played", true)), JSON.stringify(checked))
	assert_false(bool(checked.get("passed", true)), JSON.stringify(checked))
	adapter.cleanup()

func test_pixel_art_and_knob_undo_restore_files() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var source := "res://tests/_agent_pixel_src.png"
	var dest_name := "_agent_pixel_dst.png"
	var dest := "res://assets/generated/" + dest_name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/generated"))
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 1, 0))
	image.save_png(dest)
	var original := FileAccess.get_file_as_bytes(dest)
	image.fill(Color(1, 0, 0))
	image.save_png(source)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var saved = adapter.execute_tool_direct("blazium_save_pixel_art", {"source_path": source, "filename": dest_name})
	assert_true(bool(saved.get("ok", false)), JSON.stringify(saved))
	assert_ne(FileAccess.get_file_as_bytes(dest), original)
	var pixel_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(pixel_undo.get("ok", false)), JSON.stringify(pixel_undo))
	assert_eq(FileAccess.get_file_as_bytes(dest), original)
	var knobs := "res://tests/_agent_knobs.json"
	var knob_original := "{\"kept\":true}\n"
	_write_text(knobs, knob_original)
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var committed = adapter.execute_tool_direct("blazium_runtime_commit_knobs", {"path": knobs, "time_scale": 1.0})
	assert_true(bool(committed.get("ok", false)), JSON.stringify(committed))
	assert_ne(FileAccess.get_file_as_string(knobs), knob_original)
	var knob_undo = adapter.execute_tool_direct("blazium_editor_undo", {})
	assert_true(bool(knob_undo.get("ok", false)), JSON.stringify(knob_undo))
	assert_eq(FileAccess.get_file_as_string(knobs), knob_original)
	for path in [source, dest, knobs]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	adapter.cleanup()

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
