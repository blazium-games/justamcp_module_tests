extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_simulation_verify_ready_feel_and_ui() -> void:
	if not _full_catalog():
		return
	var root := Control.new()
	root.name = "UiRoot"
	add_child(root)
	autoqfree(root)
	var button := Button.new()
	button.name = "TinyTap"
	button.custom_minimum_size = Vector2(10, 10)
	button.size = Vector2(10, 10)
	root.add_child(button)

	var adapter = MCPTestAdapter.create()
	adapter.set_test_scene_root(root)
	var simulation = adapter.execute_tool_direct("blazium_run_simulation", {"steps": 3, "seed": 7})
	var summary: Dictionary = simulation.get("summary", {})
	assert_true(summary.has("steps") and summary.has("stable"), JSON.stringify(simulation))
	assert_true(bool(summary.get("stepped", false)), JSON.stringify(simulation))
	assert_true(bool(summary.get("inside_tree", false)), JSON.stringify(simulation))
	assert_eq(int(summary.get("seed", 0)), 7, JSON.stringify(simulation))
	var ready = adapter.execute_tool_direct("blazium_wait_until_ready", {})
	assert_true(bool(ready.get("ready", false)), JSON.stringify(ready))
	assert_true(int(ready.get("waited_ms", -1)) >= 0, JSON.stringify(ready))
	assert_true(int(ready.get("waited_ms", 99999)) <= 2000, JSON.stringify(ready))
	var passed = adapter.execute_tool_direct("blazium_verify_change", {"expected": "ok", "actual": "ok"})
	var failed = adapter.execute_tool_direct("blazium_verify_change", {"expected": "ok", "actual": "no"})
	assert_true(bool(passed.get("passed", false)), JSON.stringify(passed))
	assert_false(bool(failed.get("passed", true)), JSON.stringify(failed))
	var feel = adapter.execute_tool_direct("blazium_runtime_feel_metrics", {})
	var metrics: Dictionary = feel.get("metrics", {})
	assert_true(metrics.has("frame_ms"), JSON.stringify(feel))
	assert_true(metrics.has("available"), JSON.stringify(feel))
	assert_false(bool(metrics.get("input_latency_available", true)), JSON.stringify(feel))
	var integration = adapter.execute_tool_direct("blazium_runtime_integration_report", {})
	assert_eq(str(integration.get("scene", "")), "UiRoot", JSON.stringify(integration))
	assert_true(integration.has("error_count"), JSON.stringify(integration))
	assert_true((integration.get("metrics", {}) as Dictionary).has("frame_ms"), JSON.stringify(integration))
	var wide := ColorRect.new()
	wide.name = "OffScreen"
	wide.position = Vector2(4000, 4000)
	wide.size = Vector2(80, 80)
	root.add_child(wide)
	var sweep = adapter.execute_tool_direct("blazium_ui_resolution_sweep", {})
	var sweep_text := JSON.stringify(sweep)
	assert_true(sweep_text.find("44") >= 0, sweep_text)
	assert_true(sweep_text.find("overflow") >= 0, sweep_text)
	assert_true(sweep_text.find("off-screen") >= 0, sweep_text)
	assert_false(bool(sweep.get("safe_areas", true)), sweep_text)
	var knob_path := "res://tests/_agent_knobs.json"
	var knobs = adapter.execute_tool_direct("blazium_runtime_commit_knobs", {"path": knob_path, "knobs": {"time_scale": 1, "feel": 2}})
	assert_eq((knobs.get("knobs", {}) as Dictionary).get("time_scale", 0), 1)
	assert_eq(str(knobs.get("written", "")), knob_path, JSON.stringify(knobs))
	assert_true(FileAccess.get_file_as_string(knob_path).find("feel") >= 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(knob_path))
	var handoff = adapter.execute_tool_direct("blazium_playtest_handoff", {})
	assert_eq(str(handoff.get("scene", "")), "UiRoot", JSON.stringify(handoff))
	assert_false(str(handoff.get("what_to_try", "")).is_empty(), JSON.stringify(handoff))
	assert_true(handoff.has("error_count"), JSON.stringify(handoff))
	var rows = adapter.execute_tool_direct("blazium_run_simulation", {"steps": 3, "seed": 7, "runs": 3})
	var row_list: Array = rows.get("rows", [])
	assert_eq(row_list.size(), 3, JSON.stringify(rows))
	assert_eq(int((row_list[2] as Dictionary).get("seed", 0)), 9, JSON.stringify(rows))
	assert_true(bool((row_list[0] as Dictionary).get("stepped", false)), JSON.stringify(rows))
	assert_true(bool(passed.get("error_count", -1) >= 0))
	adapter.set_test_scene_root(null)
	adapter.cleanup()

func test_luau_parse_error_and_xr_disabled() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var luau = adapter.execute_tool_direct("blazium_create_script", {
		"path": "res://tests/_bad_agent.luau",
		"content": "function foo(\nend\n",
	})
	var luau_text := JSON.stringify(luau)
	assert_false(bool(luau.get("ok", true)), luau_text)
	assert_true(luau_text.findn("luau") >= 0 or luau_text.findn("parse") >= 0, luau_text)
	for tool_name in ["blazium_xr_set_head_pose", "blazium_xr_set_controller", "blazium_xr_capture"]:
		var xr = adapter.execute_tool_direct(tool_name, {})
		var xr_text := JSON.stringify(xr)
		assert_true(xr_text.find("XR not enabled") >= 0 or xr_text.find("unavailable") >= 0, tool_name + " " + xr_text)
		assert_false(bool(xr.get("available", true)), xr_text)
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
