extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_autowork_directory_and_script_tools() -> void:
	if not ClassDB.class_exists("Autowork"):
		print("Autowork module unavailable; skipping JustAMCP Autowork tool expansion test.")
		return

	var adapter = MCPTestAdapter.create()
	adapter.setup_sync()

	var by_script_validation = adapter.execute_tool_direct("blazium_autowork_run_test_script", {"script_path": "res://tests/test_autowork_tools_extended.gd"})
	assert_false(by_script_validation.get("ok", true), "run_test_script should block nested Autowork execution")
	assert_true(str(by_script_validation.get("error", "")).contains("already running"), "run_test_script should explain nested execution was blocked")

	var by_directory_validation = adapter.execute_tool_direct("blazium_autowork_run_tests_in_directory", {"directory_path": "res://tests"})
	assert_false(by_directory_validation.get("ok", true), "run_tests_in_directory should block nested Autowork execution")
	assert_true(str(by_directory_validation.get("error", "")).contains("already running"), "run_tests_in_directory should explain nested execution was blocked")

	adapter.cleanup()
