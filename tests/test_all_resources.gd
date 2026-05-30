extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

const STATIC_URIS := [
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
	"blazium://system/logs",
	"blazium://editor/state",
	"blazium://test/results",
]

const TEMPLATE_URIS := [
	"res://{path}",
	"blazium://node/{path}/properties",
	"blazium://node/{path}/children",
	"blazium://node/{path}/groups",
	"blazium://script/{path}",
	"blazium://docs/search/{query}",
	"blazium://docs/class/{class_name}",
	"blazium://docs/member/{class_name}/{member_type}/{member_name}",
]

func test_resource_catalog_lists_all_static_and_templates() -> void:
	var adapter = MCPTestAdapter.create()
	var listed = adapter.list_resources()
	assert_true(listed.has("resources"))
	var uris := _resource_uris(listed["resources"])
	for uri in STATIC_URIS:
		assert_true(uris.has(uri), "Missing static resource: " + uri)

	var templates = adapter.list_resource_templates()
	assert_true(templates.has("resourceTemplates"))
	var template_uris := _template_uris(templates["resourceTemplates"])
	for uri_template in TEMPLATE_URIS:
		assert_true(template_uris.has(uri_template), "Missing template: " + uri_template)
	adapter.cleanup()

func test_all_static_resources_are_readable() -> void:
	MCPTestFixtures.ensure_fixture_files()
	var adapter = MCPTestAdapter.create()
	for uri in STATIC_URIS:
		_assert_readable(adapter, uri)
	for alias in ["godot://system/logs", "godot-mcp://guide/tool-index"]:
		_assert_readable(adapter, alias)
	adapter.cleanup()

func test_dynamic_resource_templates_are_readable() -> void:
	MCPTestFixtures.ensure_fixture_files()
	var adapter = MCPTestAdapter.create()
	_assert_readable(adapter, "blazium://script/tests/fixtures/sample.gd")
	_assert_readable(adapter, "godot://script/tests/fixtures/sample.gd")
	_assert_readable(adapter, "blazium://docs/search/Node")
	_assert_readable(adapter, "blazium://docs/class/Node")
	adapter.cleanup()

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

func _assert_readable(adapter: MCPTestAdapter, uri: String) -> void:
	var result = adapter.read_resource(uri)
	assert_true(result.has("contents"), "Resource should return contents: " + uri)
	assert_eq(typeof(result["contents"]), TYPE_ARRAY)
	assert_gt(result["contents"].size(), 0, "Resource should not be empty: " + uri)
