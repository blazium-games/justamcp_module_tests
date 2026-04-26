extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _resource_uris(resources: Array) -> Array:
	var uris: Array = []
	for resource in resources:
		uris.append(str(resource.get("uri", "")))
	return uris

func _template_uris(templates: Array) -> Array:
	var uris: Array = []
	for template in templates:
		uris.append(str(template.get("uriTemplate", "")))
	return uris

func _assert_readable(adapter: MCPTestAdapter, uri: String) -> Dictionary:
	var result = adapter.read_resource(uri)
	assert_true(result.has("contents"), "Resource should return contents: " + uri)
	assert_eq(typeof(result["contents"]), TYPE_ARRAY, "Resource contents should be an array: " + uri)
	assert_gt(result["contents"].size(), 0, "Resource should return at least one content item: " + uri)
	return result

func test_resource_catalog_includes_new_blazium_surfaces() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)

	var listed = adapter.list_resources()
	assert_true(listed.has("resources"), "Resource list should include resources")
	var uris = _resource_uris(listed["resources"])
	for uri in [
		"blazium://scene/current",
		"blazium://scene/hierarchy",
		"blazium://selection/current",
		"blazium://project/info",
		"blazium://project/settings",
		"blazium://logs/recent",
		"blazium://materials",
		"blazium://input_map",
		"blazium://performance",
		"blazium://docs/classes",
		"blazium://guide/testing-loop",
		"blazium://guide/scene-editing",
		"blazium://guide/asset-generation",
		"blazium://guide/troubleshooting",
		"blazium://guide/tool-index",
		"autowork://latest_results",
		"video://recordings",
	]:
		assert_true(uris.has(uri), "Resource catalog should include " + uri)

	var templates = adapter.list_resource_templates()
	assert_true(templates.has("resourceTemplates"), "Resource template list should include templates")
	var template_uris = _template_uris(templates["resourceTemplates"])
	for uri_template in [
		"res://{path}",
		"blazium://node/{path}/properties",
		"blazium://node/{path}/children",
		"blazium://node/{path}/groups",
		"blazium://script/{path}",
		"blazium://docs/search/{query}",
		"blazium://docs/class/{class_name}",
		"blazium://docs/member/{class_name}/{member_type}/{member_name}",
	]:
		assert_true(template_uris.has(uri_template), "Resource templates should include " + uri_template)

	adapter.queue_free()

func test_static_resources_guides_and_compatibility_uris_are_readable() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)

	for uri in [
		"blazium://project/info",
		"blazium://logs/recent",
		"blazium://docs/classes",
		"blazium://guide/tool-index",
		"autowork://latest_results",
		"video://recordings",
		"godot://system/logs",
		"godot-mcp://guide/tool-index",
		"blazium://system/logs",
		"blazium://editor/state",
		"blazium://test/results",
	]:
		_assert_readable(adapter, uri)

	adapter.queue_free()

func test_dynamic_script_and_docs_resources_are_readable() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)

	var script_path = "res://tests/temp_resource_surface_subject.gd"
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	assert_not_null(file, "Temp script should be writable")
	file.store_string("extends Node\nfunc resource_surface_subject() -> void:\n\tpass\n")
	file.close()

	_assert_readable(adapter, "blazium://script/tests/temp_resource_surface_subject.gd")
	_assert_readable(adapter, "godot://script/tests/temp_resource_surface_subject.gd")
	_assert_readable(adapter, "blazium://docs/search/Node")
	_assert_readable(adapter, "blazium://docs/class/Node")

	adapter.remove_file_if_exists(script_path)
	adapter.queue_free()
