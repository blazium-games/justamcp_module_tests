extends SceneTree

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func _initialize() -> void:
	MCPTestFixtures.enable_all_tool_categories()
	# Allow the editor plugin and JustAMCP HTTP server to finish starting before HTTP-based tests run.
	OS.delay_msec(12000)
	var autowork = ClassDB.instantiate("Autowork")
	root.add_child(autowork)
	autowork.run_tests()
	quit(autowork.get_fail_count())
