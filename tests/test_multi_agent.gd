extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_two_agents_share_the_server_and_queue_claims() -> void:
	if not _full_catalog():
		return
	MCPTestFixtures.ensure_fixture_files()
	var adapter = MCPTestAdapter.create()
	var first = adapter.execute_tool_direct("blazium_session_open", {"name": "AgentA"})
	var second = adapter.execute_tool_direct("blazium_session_open", {"name": "AgentB"})
	var id_a := str(first.get("session_id", ""))
	var id_b := str(second.get("session_id", ""))
	assert_false(id_a.is_empty() or id_b.is_empty())
	assert_true(adapter.execute_tool_direct("blazium_session_set_access", {"session_id": id_a, "mode": "write"}).get("ok", false))
	assert_true(adapter.execute_tool_direct("blazium_session_set_access", {"session_id": id_b, "mode": "write"}).get("ok", false))
	adapter.execute_tool_direct("blazium_session_capabilities", {"_session_id": id_a})
	adapter.execute_tool_direct("blazium_session_capabilities", {"_session_id": id_b})

	var listed = adapter.read_resource("blazium://sessions")
	var listed_text := JSON.stringify(listed)
	assert_true(listed_text.find("AgentA") >= 0, listed_text)
	assert_true(listed_text.find("AgentB") >= 0, listed_text)

	var path := "res://tests/fixtures/sample.gd"
	var claim = adapter.execute_tool_direct("blazium_claim_scene", {"_session_id": id_a, "path": path})
	assert_true(claim.get("ok", false), JSON.stringify(claim))
	var other = adapter.execute_tool_direct("blazium_claim_scene", {"_session_id": id_b, "path": path})
	assert_true(JSON.stringify(other).find("AgentA") >= 0, JSON.stringify(other))

	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var queued = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": id_b, "path": path})
	assert_true(bool(queued.get("queued", false)), JSON.stringify(queued))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 0)
	var released = adapter.execute_tool_direct("blazium_release_claim", {"_session_id": id_a, "path": path})
	assert_true(released.get("ok", false), JSON.stringify(released))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 1)

	ProjectSettings.set_setting("blazium/justamcp/claim_wait_ms", 0)
	var reclaimed = adapter.execute_tool_direct("blazium_claim_scene", {"_session_id": id_a, "path": path})
	assert_true(reclaimed.get("ok", false), JSON.stringify(reclaimed))
	var timed_out = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": id_b, "path": path})
	var timeout_text := JSON.stringify(timed_out)
	assert_true(timeout_text.findn("timeout") >= 0, timeout_text)
	assert_true(timeout_text.find("AgentA") >= 0, timeout_text)
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 1)

	adapter.execute_tool_direct("blazium_session_close", {"session_id": id_a})
	var claims = adapter.execute_tool_direct("blazium_list_claims", {})
	assert_false(JSON.stringify(claims).find(path) >= 0, JSON.stringify(claims))
	ProjectSettings.set_setting("blazium/justamcp/claim_wait_ms", 30000)
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
