extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

func test_grounding_map_and_relations() -> void:
	if not _full_catalog():
		return
	var root := Node3D.new()
	root.name = "GroundRoot"
	add_child(root)
	autoqfree(root)
	var floor := Node3D.new()
	floor.name = "Floor"
	floor.position = Vector3(0, 0, 0)
	root.add_child(floor)
	var crate := Node3D.new()
	crate.name = "Crate"
	crate.position = Vector3(0, 1, 0)
	root.add_child(crate)
	var floater := Node3D.new()
	floater.name = "Floater"
	floater.position = Vector3(0, 80, 0)
	root.add_child(floater)
	var body := StaticBody3D.new()
	body.name = "BareBody"
	root.add_child(body)

	var adapter = MCPTestAdapter.create()
	adapter.set_test_scene_root(root)
	var before = adapter.execute_tool_direct("blazium_project_map", {})
	assert_gt(int(before.get("count", 0)), 0, JSON.stringify(before))
	var grounding = adapter.execute_tool_direct("blazium_validate_scene_grounding", {})
	var grounding_text := JSON.stringify(grounding)
	assert_true(grounding_text.find("floating") >= 0, grounding_text)
	assert_true(grounding_text.find("missing collision") >= 0, grounding_text)
	var relations = adapter.execute_tool_direct("blazium_spatial_scene_relations", {})
	assert_true(JSON.stringify(relations).find("rests-on") >= 0, JSON.stringify(relations))
	var after = adapter.execute_tool_direct("blazium_project_map", {})
	assert_eq(int(before.get("count", 0)), int(after.get("count", -1)))
	adapter.set_test_scene_root(null)
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
