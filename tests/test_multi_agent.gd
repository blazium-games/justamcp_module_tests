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

func test_claim_prefix_and_foreign_session_are_rejected() -> void:
	if not _full_catalog():
		return
	MCPTestFixtures.ensure_fixture_files()
	var adapter = MCPTestAdapter.create()
	var first = adapter.execute_tool_direct("blazium_session_open", {"name": "PrefixA"})
	var second = adapter.execute_tool_direct("blazium_session_open", {"name": "PrefixB"})
	var id_a := str(first.get("session_id", ""))
	var id_b := str(second.get("session_id", ""))
	assert_true(adapter.execute_tool_direct("blazium_session_set_access", {"session_id": id_a, "mode": "write"}).get("ok", false))
	assert_true(adapter.execute_tool_direct("blazium_session_set_access", {"session_id": id_b, "mode": "write"}).get("ok", false))
	adapter.execute_tool_direct("blazium_session_capabilities", {"_session_id": id_a})
	adapter.execute_tool_direct("blazium_session_capabilities", {"_session_id": id_b})
	var denied = adapter.execute_tool_direct("blazium_session_set_access", {"_session_id": id_a, "session_id": id_b, "mode": "read"})
	assert_false(bool(denied.get("ok", true)), JSON.stringify(denied))
	var denied_close = adapter.execute_tool_direct("blazium_session_close", {"_session_id": id_a, "session_id": id_b})
	assert_false(bool(denied_close.get("ok", true)), JSON.stringify(denied_close))

	var nested := "res://tests/fixtures/sample.gd"
	var prefix_claim = adapter.execute_tool_direct("blazium_claim_subtree", {"_session_id": id_a, "path": "res://tests/fixt"})
	assert_true(prefix_claim.get("ok", false), JSON.stringify(prefix_claim))
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var not_covered = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": id_b, "path": nested})
	assert_false(bool(not_covered.get("queued", false)), JSON.stringify(not_covered))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 1)
	adapter.execute_tool_direct("blazium_release_claim", {"_session_id": id_a, "path": "res://tests/fixt"})

	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var real_claim = adapter.execute_tool_direct("blazium_claim_subtree", {"_session_id": id_a, "path": "res://tests/fixtures"})
	assert_true(real_claim.get("ok", false), JSON.stringify(real_claim))
	var queued_probe = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": id_b, "path": nested})
	assert_true(bool(queued_probe.get("queued", false)), JSON.stringify(queued_probe))
	var queued_knobs = adapter.execute_tool_direct("blazium_runtime_commit_knobs", {"_session_id": id_b, "path": nested, "knobs": {"queued_marker": 9}})
	assert_true(bool(queued_knobs.get("queued", false)), JSON.stringify(queued_knobs))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 0)
	var released = adapter.execute_tool_direct("blazium_release_claim", {"_session_id": id_a, "path": "res://tests/fixtures"})
	assert_true(released.get("ok", false), JSON.stringify(released))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 1)
	assert_true(JSON.stringify(released).find("queued_marker") >= 0, JSON.stringify(released))

	adapter.execute_tool_direct("blazium_session_close", {"session_id": id_b})
	var closed = adapter.execute_tool_direct("blazium_agent_probe_value", {"_session_id": id_b})
	assert_true(JSON.stringify(closed).find("closed") >= 0, JSON.stringify(closed))
	var reopened = adapter.execute_tool_direct("blazium_session_open", {"session_id": id_b, "name": "PrefixB"})
	assert_true(reopened.get("ok", false), JSON.stringify(reopened))
	adapter.execute_tool_direct("blazium_session_close", {"session_id": id_a})
	adapter.execute_tool_direct("blazium_session_close", {"session_id": id_b})
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
