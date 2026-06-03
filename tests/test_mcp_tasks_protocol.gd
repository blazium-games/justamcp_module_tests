extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _init_session(adapter: MCPTestAdapter) -> bool:
	var init_res = adapter.http_jsonrpc_stateless("initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	}, 3000)
	return not init_res.get("skipped", false) and init_res.has("result")

func test_task_augmented_batch_execute_lifecycle() -> void:
	var adapter = MCPTestAdapter.create()
	if not _init_session(adapter):
		adapter.cleanup()
		return

	var call_res = adapter.call_tool_task_augmented("blazium_batch_execute", {"steps": []}, {}, 20000)
	if call_res.get("skipped", false):
		adapter.cleanup()
		return

	assert_true(call_res.has("result"), "task-augmented tools/call should return result")
	var task_block: Dictionary = call_res["result"].get("task", {})
	var task_id := str(task_block.get("taskId", ""))
	assert_false(task_id.is_empty(), "create task result should include taskId")

	var terminal = ["completed", "failed", "cancelled"]
	var status := "working"
	var guard := 0
	while not terminal.has(status) and guard < 60:
		guard += 1
		OS.delay_msec(200)
		var get_res = adapter.http_jsonrpc_stateless("tasks/get", {"taskId": task_id}, 5000)
		if get_res.has("result"):
			status = str(get_res["result"].get("status", status))

	assert_true(terminal.has(status), "task should reach terminal state: " + status)

	if status == "completed":
		var result_res = adapter.http_jsonrpc_stateless("tasks/result", {"taskId": task_id}, 10000)
		assert_true(result_res.has("result"), "tasks/result should succeed for completed task")

	adapter.cleanup()

func test_task_param_forbidden_on_fast_tool() -> void:
	var adapter = MCPTestAdapter.create()
	if not _init_session(adapter):
		adapter.cleanup()
		return

	var call_res = adapter.http_jsonrpc_stateless("tools/call", {
		"name": "blazium_project_list_settings",
		"arguments": {},
		"task": {},
	}, 5000)
	if call_res.get("skipped", false):
		adapter.cleanup()
		return

	assert_true(call_res.has("error"), "task param on forbidden tool should error")
	assert_eq(int(call_res["error"].get("code", 0)), -32601)

	adapter.cleanup()

func test_task_max_concurrent_limit() -> void:
	var original_max = ProjectSettings.get_setting("blazium/justamcp/task_max_concurrent")
	ProjectSettings.set_setting("blazium/justamcp/task_max_concurrent", 2)

	var adapter = MCPTestAdapter.create()
	if not _init_session(adapter):
		if original_max != null:
			ProjectSettings.set_setting("blazium/justamcp/task_max_concurrent", original_max)
		adapter.cleanup()
		return

	var task_ids: Array = []
	for i in range(3):
		var call_res = adapter.call_tool_task_augmented("blazium_batch_execute", {"steps": []}, {"ttl": 120000}, 8000)
		if call_res.get("skipped", false):
			break
		if call_res.has("result"):
			var tid := str(call_res["result"].get("task", {}).get("taskId", ""))
			if not tid.is_empty():
				task_ids.append(tid)
		elif call_res.has("error"):
			assert_eq(int(call_res["error"].get("code", 0)), -32003, "Third task should hit concurrency limit")
			break

	if original_max != null:
		ProjectSettings.set_setting("blazium/justamcp/task_max_concurrent", original_max)
	adapter.cleanup()

func test_tasks_cancel() -> void:
	var adapter = MCPTestAdapter.create()
	if not _init_session(adapter):
		adapter.cleanup()
		return

	var call_res = adapter.call_tool_task_augmented("blazium_editor_play_scene", {}, {"ttl": 120000}, 8000)
	if call_res.get("skipped", false):
		adapter.cleanup()
		return
	if not call_res.has("result"):
		adapter.cleanup()
		return

	var task_id := str(call_res["result"].get("task", {}).get("taskId", ""))
	assert_false(task_id.is_empty(), "reload task should be created")

	var cancel_res = adapter.http_jsonrpc_stateless("tasks/cancel", {"taskId": task_id}, 5000)
	assert_true(cancel_res.has("result"), "tasks/cancel should return result")
	var status := str(cancel_res["result"].get("status", ""))
	assert_true(status == "cancelled" or status == "completed", "cancel should end task")

	adapter.cleanup()
