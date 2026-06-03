extends AutoworkTest

func test_task_manager_list_api() -> void:
	var manager = JustAMCPTaskManager.new()
	assert_not_null(manager, "TaskManager should instantiate correctly")
	var list_t = manager.list_tasks()
	assert_true(list_t.has("tasks"), "list_tasks should return tasks array")
	assert_eq(typeof(list_t["tasks"]), TYPE_ARRAY, "tasks should be an array")
	assert_eq(list_t["tasks"].size(), 0, "No HTTP-created tasks in unit test")

	var missing = manager.get_task("nonexistent-task-id")
	assert_false(missing.get("ok", true), "get_task should fail for unknown id")

func test_resource_executor() -> void:
	var res = JustAMCPResourceExecutor.new()
	assert_not_null(res, "ResourceExecutor should instantiate correctly")

	var rlist = res.list_resources()
	assert_true(rlist.has("resources"), "Resources map directly.")

	var rtemp = res.list_resource_templates()
	assert_true(rtemp.has("resourceTemplates"), "Templates mapped.")

	var rrd = res.read_resource("godot://system/logs")
	assert_true(rrd.has("contents") or rrd.has("error"), "System resource read should return contents or error")
	var err_rd = res.read_resource("fake://invalid_path.res")
	assert_true(err_rd.has("error"), "Expected failure on incorrect paths")

func test_prompt_executor() -> void:
	var prmpt = JustAMCPPromptExecutor.new()
	assert_not_null(prmpt, "PromptExecutor must instantiate successfully")

	var plist = prmpt.list_prompts()
	assert_true(plist.has("prompts"), "Prompts mapped properly.")

	var ref_dict = {"name": "blazium_context"}
	var arg_dict = {"name": "context_type", "value": "au"}
	var autocomplete = prmpt.complete_prompt(ref_dict, arg_dict)
	assert_true(autocomplete.has("completion"), "Autocomplete resolves mapping arrays correctly")

func test_ping_and_server() -> void:
	var server = JustAMCPServer.new()
	assert_not_null(server, "Server binds effectively")
