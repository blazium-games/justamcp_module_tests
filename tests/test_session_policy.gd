extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_fresh_session_is_read_only_until_elevated() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var opened = adapter.execute_tool_direct("blazium_session_open", {"name": "ReadAgent"})
	var session_id := str(opened.get("session_id", ""))
	assert_false(session_id.is_empty(), JSON.stringify(opened))
	var denied = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": session_id})
	assert_true(JSON.stringify(denied).findn("read-only") >= 0, JSON.stringify(denied))
	var elevated = adapter.execute_tool_direct("blazium_session_set_access", {"session_id": session_id, "mode": "write"})
	assert_true(elevated.get("ok", false), JSON.stringify(elevated))
	var too_soon = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": session_id})
	assert_true(JSON.stringify(too_soon).findn("write-before-read") >= 0, JSON.stringify(too_soon))
	var read_state = adapter.execute_tool_direct("blazium_session_capabilities", {"_session_id": session_id})
	assert_true(read_state.get("ok", false), JSON.stringify(read_state))
	var first = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": session_id, "expected_revision": 0})
	assert_true(first.get("ok", false), JSON.stringify(first))
	var stale = adapter.execute_tool_direct("blazium_agent_probe_increment", {"_session_id": session_id, "expected_revision": 0})
	assert_true(JSON.stringify(stale).findn("expected_revision") >= 0, JSON.stringify(stale))
	adapter.cleanup()

func test_idempotency_key_does_not_double_apply() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	adapter.execute_tool_direct("blazium_agent_probe_reset", {})
	var first = adapter.execute_tool_direct("blazium_agent_probe_increment", {"idempotency_key": "once"})
	var second = adapter.execute_tool_direct("blazium_agent_probe_increment", {"idempotency_key": "once"})
	assert_eq(int(first.get("value", -1)), int(second.get("value", -2)))
	assert_true(bool(second.get("idempotent_replay", false)), JSON.stringify(second))
	assert_eq(int(adapter.execute_tool_direct("blazium_agent_probe_value", {}).get("value", -1)), 1)
	adapter.cleanup()

func test_tool_list_annotations_audit_and_bearer() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	var schema = adapter.find_tool_schema("blazium_add_node")
	var annotations: Dictionary = schema.get("annotations", {})
	assert_true(annotations.has("readOnlyHint"))
	assert_true(annotations.has("destructiveHint"))
	assert_true(annotations.has("idempotentHint"))
	assert_false(bool(annotations.get("readOnlyHint", true)))
	assert_false(JustAMCPToolExecutor.bearer_authorizes(""))
	assert_true(JustAMCPToolExecutor.bearer_authorizes("Bearer " + str(JustAMCPToolExecutor.instance_bearer())))
	var audit = adapter.execute_tool_direct("blazium_export_audit_log", {})
	assert_gt((audit.get("entries", []) as Array).size(), 0, JSON.stringify(audit))
	var usage = adapter.read_resource("blazium://session/usage")
	assert_true(usage.has("contents"), JSON.stringify(usage))
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
