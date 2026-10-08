extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_guides_clients_conventions_and_editorhelp_instructions() -> void:
	if not _full_catalog():
		return
	var adapter = MCPTestAdapter.create()
	for uri in [
		"blazium://guide/data-handling",
		"blazium://guide/opt-in",
		"blazium://guide/engine-docs",
		"blazium://guide/multi-agent",
		"blazium://reference/tools",
		"blazium://mcp/clients",
		"blazium://mcp/compatibility",
		"blazium://project/conventions",
	]:
		var result = adapter.read_resource(uri)
		assert_true(result.has("contents"), uri)
		var text := str((result.get("contents", []) as Array)[0].get("text", ""))
		assert_false(text.is_empty(), uri)
	var docs = adapter.read_resource("blazium://guide/engine-docs")
	var docs_text := str((docs.get("contents", []) as Array)[0].get("text", ""))
	assert_true(docs_text.find("EditorHelp") >= 0, docs_text)
	assert_true(docs_text.find("blazium://docs/class/") >= 0, docs_text)
	assert_true(docs_text.find("training data") >= 0, docs_text)

	var prompt = adapter.get_prompt("blazium_context", {})
	var prompt_text := JSON.stringify(prompt)
	assert_true(prompt_text.find("EditorHelp") >= 0, prompt_text)
	assert_true(prompt_text.find("training data") >= 0, prompt_text)

	var unknown = adapter.execute_tool_direct("blazium_add_nod", {})
	assert_true(JSON.stringify(unknown).find("add_node") >= 0, JSON.stringify(unknown))

	var config = adapter.execute_tool_direct("blazium_client_config", {"client": "cursor"})
	var config_text := str(config.get("config", ""))
	assert_true(config_text.find("/mcp") >= 0, config_text)
	assert_true(config_text.find("Bearer") >= 0 or config_text.find("bearer") >= 0, config_text)
	var written = adapter.execute_tool_direct("blazium_write_client_config", {"client": "codex", "path": "res://tests/_agent_client.toml"})
	assert_true(bool(written.get("ping_ok", false)), JSON.stringify(written))
	assert_true(str(written.get("config", "")).find("[mcp_servers.blazium]") >= 0, JSON.stringify(written))

	var bad_bone = adapter.execute_tool_direct("blazium_validate_conventions", {"bone": "1bad bone"})
	assert_false(bool(bad_bone.get("ok", true)), JSON.stringify(bad_bone))

	var stuck := {}
	for _i in 3:
		stuck = adapter.execute_tool_direct("blazium_not_a_real_tool_zzz", {})
	assert_true(bool(stuck.get("stuck", false)), JSON.stringify(stuck))
	assert_false(str(stuck.get("checkpoint_id", "")).is_empty(), JSON.stringify(stuck))
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
