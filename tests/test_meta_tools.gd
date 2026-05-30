extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_search_tools_and_guides_cover_new_catalog() -> void:
	var adapter = MCPTestAdapter.create()

	var search = adapter.execute_tool_direct("blazium_search_tools", {"query": "docs"})
	assert_true(search.get("ok", false), "search_tools should succeed")
	assert_eq(typeof(search.get("result", [])), TYPE_ARRAY, "search_tools result should be an array")
	assert_gt(search["result"].size(), 0, "search_tools should find documentation tools")

	var guide_list = adapter.execute_tool_direct("blazium_get_guide", {})
	assert_true(guide_list.get("ok", false), "get_guide should list topics")
	assert_true(guide_list.has("topics"), "get_guide should include topics")
	assert_true(guide_list["topics"].has("tool-index"), "Guide topics should include tool-index")

	var guide = adapter.execute_tool_direct("blazium_get_guide", {"topic": "tool-index"})
	assert_true(guide.get("ok", false), "get_guide should read tool-index")
	assert_true(guide.has("content"), "Guide should include compatibility content")
	assert_true(str(guide["content"]).contains("JustAMCP"), "Tool index guide should mention JustAMCP")

	adapter.cleanup()

func test_execute_tool_delegates_and_blocks_nested_batch() -> void:
	var adapter = MCPTestAdapter.create()

	var delegated = adapter.execute_tool_direct("blazium_execute_tool", {"tool_name": "get_guide", "arguments": ""})
	assert_true(delegated.get("ok", false), "execute_tool should delegate to get_guide with empty args")
	assert_true(delegated.has("topics"), "Delegated get_guide should return topics")

	var batch = adapter.execute_tool_direct("blazium_batch_execute", {
		"steps": [
			{"tool": "blazium_get_guide", "args": {"topic": "testing-loop"}},
			{"tool": "blazium_batch_execute", "args": {"steps": []}},
		],
		"stop_on_error": false,
	})
	assert_true(batch.get("ok", false), "batch_execute should return an aggregate result")
	assert_eq(batch.get("count", 0), 2, "batch_execute should evaluate both steps when stop_on_error=false")
	assert_eq(batch.get("completed", 0), 1, "Nested batch step should not count as completed")

	adapter.cleanup()
