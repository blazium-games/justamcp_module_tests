extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_list_tools_pagination_unit() -> void:
	var page1 = JustAMCPToolExecutor.list_tools("")
	assert_true(page1.get("ok", false), "First tools page should succeed")
	assert_true(page1.has("tools"), "Page should include tools key")
	assert_lte(page1["tools"].size(), 5, "Page size should respect list_page_size=5")

	var all_names := {}
	for tool in page1["tools"]:
		all_names[str((tool as Dictionary).get("name", ""))] = true

	var cursor := str(page1.get("nextCursor", ""))
	var guard := 0
	while not cursor.is_empty() and guard < 200:
		guard += 1
		var page = JustAMCPToolExecutor.list_tools(cursor)
		assert_true(page.get("ok", false), "Paginated tools page should succeed")
		for tool in page.get("tools", []):
			var name := str((tool as Dictionary).get("name", ""))
			assert_false(all_names.has(name), "Duplicate tool across pages: " + name)
			all_names[name] = true
		cursor = str(page.get("nextCursor", ""))

	var full = JustAMCPToolExecutor.get_tool_schemas()
	assert_eq(all_names.size(), full.size(), "Paginated union should match full catalog")

func test_list_tools_invalid_cursor_unit() -> void:
	var bad = JustAMCPToolExecutor.list_tools("not-a-valid-cursor!!!")
	assert_false(bad.get("ok", true), "Invalid cursor should fail")

func test_http_list_methods_paginate_without_duplicates() -> void:
	var adapter = MCPTestAdapter.create()
	for spec in [
		{"method": "tools/list", "key": "tools", "id_key": "name"},
		{"method": "prompts/list", "key": "prompts", "id_key": "name"},
		{"method": "resources/list", "key": "resources", "id_key": "uri"},
		{"method": "resources/templates/list", "key": "resourceTemplates", "id_key": "uriTemplate"},
	]:
		var collected = adapter.collect_all_pages(spec["method"], spec["key"], spec["id_key"], 12000)
		if collected.get("skipped", false):
			print("Skipping pagination HTTP test: " + str(collected.get("error", "")))
			continue
		assert_false(collected.has("error"), "Pagination walk failed for " + spec["method"])
		assert_gt(collected.get("count", 0), 0, "Should collect at least one item for " + spec["method"])
	adapter.cleanup()
