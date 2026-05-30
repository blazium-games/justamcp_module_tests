extends SceneTree

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func _initialize() -> void:
	MCPTestFixtures.enable_all_tool_categories()
	var autowork = ClassDB.instantiate("Autowork")
	root.add_child(autowork)
	autowork.run_tests()
	quit(autowork.get_fail_count())
