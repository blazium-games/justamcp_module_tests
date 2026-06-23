extends SceneTree

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

const MAX_WAIT_FRAMES := 3600
const FRAMES_AFTER_MCP := 10

var _mcp_server: JustAMCPServer

func _initialize() -> void:
	MCPTestFixtures.enable_all_tool_categories()
	MCPTestFixtures.ensure_fixture_files()
	_bootstrap_and_run.call_deferred()

func _bootstrap_and_run() -> void:
	_mcp_server = get_root().find_child("JustAMCPServer", true, false) as JustAMCPServer
	if _mcp_server == null:
		_mcp_server = JustAMCPServer.new()
		_mcp_server.set_name("JustAMCPServer")
		get_root().add_child(_mcp_server)

	var ready_frames := 0
	var frames := 0
	while frames < MAX_WAIT_FRAMES:
		if _mcp_server != null and _mcp_server.is_server_started():
			ready_frames += 1
			if ready_frames >= FRAMES_AFTER_MCP:
				break
		else:
			ready_frames = 0
		frames += 1
		await process_frame

	if ready_frames < FRAMES_AFTER_MCP:
		push_error("Timed out waiting for JustAMCP server before module tests could run.")
		quit(1)
		return

	var autowork = ClassDB.instantiate("Autowork")
	get_root().add_child(autowork)
	autowork.run_tests()
