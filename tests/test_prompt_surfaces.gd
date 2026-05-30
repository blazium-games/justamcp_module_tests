extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _prompt_names(prompts: Array) -> Array:
	var names: Array = []
	for prompt in prompts:
		names.append(str(prompt.get("name", "")))
	return names

func _assert_prompt_message_payload(payload: Dictionary, prompt_name: String) -> void:
	assert_true(payload.get("ok", false), "Prompt should return ok=true: " + prompt_name)
	assert_true(payload.has("messages"), "Prompt should include messages: " + prompt_name)
	assert_eq(typeof(payload["messages"]), TYPE_ARRAY, "Prompt messages should be an array: " + prompt_name)
	assert_gt(payload["messages"].size(), 0, "Prompt should include at least one message: " + prompt_name)

	var message = payload["messages"][0]
	assert_eq(typeof(message), TYPE_DICTIONARY, "Prompt message should be a dictionary: " + prompt_name)
	assert_true(message.has("role"), "Prompt message should include role: " + prompt_name)
	assert_true(message.has("content"), "Prompt message should include content: " + prompt_name)

func test_all_registered_prompts_are_listed_and_readable() -> void:
	var adapter = MCPTestAdapter.create()

	var listed = adapter.list_prompts()
	assert_true(listed.has("prompts"), "Prompt list should include prompts")
	var names = _prompt_names(listed["prompts"])

	var expected = [
		"blazium_context",
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

	for prompt_name in expected:
		assert_true(names.has(prompt_name), "Prompt list should include " + prompt_name)

	var prompt_args = {
		"target_script": "res://tests/fixtures/sample.gd",
		"functions": "fixture_method",
		"test_results": "1 failing Autowork assertion",
		"test_output": "1 failing Autowork assertion in test_example",
		"project_goal": "Verify prompt payload shape",
		"scene_goal": "Create a simple UI scene",
		"script_path": "res://tests/fixtures/sample.gd",
		"networking_goal": "Local multiplayer",
		"ui_goal": "Main menu",
		"shader_goal": "Pulse effect",
		"mode": "strict",
		"feature": "Main menu UI",
		"scope": "all",
		"detail_level": "normal",
		"target_mechanic": "Player movement",
		"ui_concept": "Main menu with three buttons",
		"networking_layer": "Player movement sync",
		"effect_description": "Pulse glow on sprite",
	}

	for prompt_name in expected:
		_assert_prompt_message_payload(adapter.get_prompt(prompt_name, prompt_args), prompt_name)

	adapter.cleanup()

func test_blazium_context_completion_matches_declared_argument() -> void:
	var adapter = MCPTestAdapter.create()

	var completion = adapter.complete_prompt({"name": "blazium_context"}, {"name": "mode", "value": "d"})
	assert_true(completion.has("completion"), "Completion response should include completion")
	var data = completion["completion"]
	assert_true(data.has("values"), "Completion should include values")
	assert_true(data["values"].has("debug"), "Mode completion should include debug")

	adapter.cleanup()
