extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _request_or_skip(adapter: MCPTestAdapter, method: String, params: Dictionary = {}, timeout_msec: int = 2000) -> Dictionary:
	var response = adapter.http_jsonrpc_stateless(method, params, timeout_msec)
	if response.get("skipped", false):
		print("Skipping MCP capability test: " + str(response.get("error", "")))
	return response

func test_initialize_exposes_tasks_and_logging() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = _request_or_skip(adapter, "initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	})
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	assert_true(init_res.has("result"), "initialize should return result")
	var caps: Dictionary = init_res["result"].get("capabilities", {})
	assert_true(caps.has("logging"), "capabilities should include logging")
	assert_true(caps.has("tasks"), "capabilities should include tasks")

	var tasks_cap: Dictionary = caps["tasks"]
	assert_true(tasks_cap.has("list"), "tasks capability should include list")
	assert_true(tasks_cap.has("cancel"), "tasks capability should include cancel")
	var requests: Dictionary = tasks_cap.get("requests", {})
	var tools_req: Dictionary = requests.get("tools", {})
	assert_true(tools_req.has("call"), "tasks.requests.tools should include call")

	adapter.cleanup()

func test_logging_set_level_and_tasks_list_idle() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = _request_or_skip(adapter, "initialize", {
		"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		"protocolVersion": "2024-11-05",
	})
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	var debug_level = _request_or_skip(adapter, "logging/setLevel", {"level": "debug"})
	assert_false(debug_level.get("skipped", false))
	assert_true(debug_level.has("result"), "logging/setLevel debug should succeed")

	var info_level = _request_or_skip(adapter, "logging/setLevel", {"level": "info"})
	assert_true(info_level.has("result"), "logging/setLevel info should succeed")

	var bad_level = _request_or_skip(adapter, "logging/setLevel", {"level": "not-a-real-level"})
	assert_true(bad_level.has("error"), "invalid logging level should error")

	var tasks_list = _request_or_skip(adapter, "tasks/list", {})
	assert_true(tasks_list.has("result"), "tasks/list should return result")
	assert_true(tasks_list["result"].has("tasks"), "tasks/list should include tasks array")
	assert_eq(typeof(tasks_list["result"]["tasks"]), TYPE_ARRAY)

	adapter.cleanup()
