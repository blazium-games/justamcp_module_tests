extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

const EXPECTED_PROMPTS := [
	"blazium_context",
	"blazium_project_intake",
	"blazium_scene_build_workflow",
	"blazium_runtime_test_loop",
	"blazium_autowork_fix_loop",
	"blazium_diagnostics_triage",
	"project_info",
	"editor_state",
	"generate_autowork_test",
	"analyze_autowork_test_failures",
	"blazium_project_optimization",
	"blazium_scene_architect",
	"blazium_gdscript_linter",
	"blazium_multiplayer_architect",
	"blazium_ui_scaffolder",
	"blazium_shader_expert",
]

func _prompt_names(prompts: Array) -> Array:
	var names: Array = []
	for prompt in prompts:
		names.append(str(prompt.get("name", "")))
	return names

func test_all_sixteen_prompts_listed() -> void:
	var adapter = MCPTestAdapter.create()
	var listed = adapter.list_prompts()
	assert_true(listed.has("prompts"))
	var names = _prompt_names(listed["prompts"])
	assert_eq(names.size(), 16, "Should list exactly 16 prompts")
	for prompt_name in EXPECTED_PROMPTS:
		assert_true(names.has(prompt_name), "Missing prompt: " + prompt_name)
	adapter.cleanup()

func test_all_prompts_return_messages() -> void:
	var adapter = MCPTestAdapter.create()
	var args := {
		"target_script": "res://tests/fixtures/sample.gd",
		"functions": "fixture_method",
		"test_results": "1 failing Autowork assertion",
		"project_goal": "Verify prompt payload shape",
		"scene_goal": "Create a simple UI scene",
		"script_path": "res://tests/fixtures/sample.gd",
		"networking_goal": "Local multiplayer",
		"ui_goal": "Main menu",
		"shader_goal": "Pulse effect",
		"mode": "strict",
		"context_type": "strict",
		"feature": "Main menu UI",
		"scope": "all",
		"detail_level": "normal",
		"symptom": "Tool dispatch failure during validation",
		"test_output": "1 failing Autowork assertion in test_example",
		"target_mechanic": "Player movement",
		"ui_concept": "Main menu with three buttons",
		"networking_layer": "Player movement sync",
		"effect_description": "Pulse glow on sprite",
	}
	for prompt_name in EXPECTED_PROMPTS:
		var payload = adapter.get_prompt(prompt_name, args)
		assert_true(payload.get("ok", false), "Prompt should succeed: " + prompt_name + " error=" + str(payload.get("error", payload)))
		assert_true(payload.has("messages"), "Prompt should include messages: " + prompt_name)
		assert_gt(payload["messages"].size(), 0, "Prompt should include content: " + prompt_name)
	adapter.cleanup()

func test_blazium_context_completion() -> void:
	var adapter = MCPTestAdapter.create()
	var completion = adapter.complete_prompt({"name": "blazium_context"}, {"name": "mode", "value": "d"})
	assert_true(completion.has("completion"))
	var data = completion["completion"]
	assert_true(data.has("values"))
	assert_true(data["values"].has("debug"))
	adapter.cleanup()
