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

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
