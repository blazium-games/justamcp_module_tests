extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _assert_structured_tool_result(result: Dictionary, tool_name: String) -> void:
	assert_true(result.has("ok") or result.has("error"), "Tool should return a structured result: " + tool_name)

func test_classdb_query_returns_node_contract() -> void:
	var adapter = MCPTestAdapter.create()

	var result = adapter.execute_tool_direct("blazium_classdb_query", {"class_name": "Node", "query": "name"})
	assert_true(result.get("ok", false), "ClassDB query for Node should succeed")
	assert_eq(result.get("class_name", ""), "Node", "ClassDB result should identify Node")
	assert_true(result.has("properties"), "ClassDB result should include properties")
	assert_true(result.has("methods"), "ClassDB result should include methods")
	assert_true(result.has("signals"), "ClassDB result should include signals")

	adapter.cleanup()

func test_documentation_tools_return_structured_payloads() -> void:
	var adapter = MCPTestAdapter.create()

	var list_result = adapter.execute_tool_direct("blazium_docs_list_classes", {"query": "Node", "limit": 5})
	_assert_structured_tool_result(list_result, "docs_list_classes")
	if list_result.get("ok", false):
		assert_true(list_result.has("classes"), "Class list should include classes")
		assert_true(list_result.get("count", 0) <= 5, "Class list should honor limit")

	var search_result = adapter.execute_tool_direct("blazium_docs_search", {"query": "Node", "limit": 5})
	_assert_structured_tool_result(search_result, "docs_search")
	if search_result.get("ok", false):
		assert_true(search_result.has("matches"), "Docs search should include matches")

	var class_result = adapter.execute_tool_direct("blazium_docs_get_class", {"class_name": "Node", "include_members": false})
	_assert_structured_tool_result(class_result, "docs_get_class")
	if class_result.get("ok", false):
		assert_true(class_result.has("class"), "Class docs should include class payload")

	var member_result = adapter.execute_tool_direct("blazium_docs_get_member", {"class_name": "Node", "member_type": "method", "member_name": "add_child"})
	_assert_structured_tool_result(member_result, "docs_get_member")
	if member_result.get("ok", false):
		assert_true(member_result.has("member"), "Member docs should include member payload")

	adapter.cleanup()
