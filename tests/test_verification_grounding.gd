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
	var before = adapter.execute_tool_direct("blazium_project_map", {"budget": 2})
	assert_gt(int(before.get("count", 0)), 2, JSON.stringify(before))
	assert_eq((before.get("nodes", []) as Array).size(), 2, JSON.stringify(before))
	assert_true(before.has("autoloads") and before.has("input_map") and before.has("main_scene") and before.has("errors"), JSON.stringify(before))
	var grounding = adapter.execute_tool_direct("blazium_validate_scene_grounding", {})
	var grounding_text := JSON.stringify(grounding)
	assert_true(grounding_text.find("floating") >= 0, grounding_text)
	assert_true(grounding_text.find("missing collision") >= 0, grounding_text)
	var relations = adapter.execute_tool_direct("blazium_spatial_scene_relations", {})
	assert_true(JSON.stringify(relations).find("rests-on") >= 0, JSON.stringify(relations))
	var after = adapter.execute_tool_direct("blazium_project_map", {})
	assert_eq(int(before.get("count", 0)), int(after.get("count", -1)))
	var captured = adapter.execute_tool_direct("blazium_scene_diff", {"capture": true})
	assert_gt(int(captured.get("captured", 0)), 0, JSON.stringify(captured))
	var pocket := Node3D.new()
	pocket.name = "Pocket"
	root.add_child(pocket)
	crate.reparent(pocket)
	var diff = adapter.execute_tool_direct("blazium_scene_diff", {})
	var diff_text := JSON.stringify(diff)
	assert_true(diff_text.find("Pocket") >= 0, diff_text)
	assert_true(diff_text.find("reparented") >= 0 and diff_text.find("Crate") >= 0, diff_text)

	var huge := Node3D.new()
	huge.name = "Huge"
	huge.scale = Vector3(200, 1, 1)
	root.add_child(huge)
	var shape_a := CollisionShape3D.new()
	shape_a.name = "ShapeA"
	shape_a.position = Vector3(1, 0, 0)
	root.add_child(shape_a)
	var shape_b := CollisionShape3D.new()
	shape_b.name = "ShapeB"
	shape_b.position = Vector3(1.1, 0, 0)
	root.add_child(shape_b)
	var grounded = adapter.execute_tool_direct("blazium_validate_scene_grounding", {})
	var grounded_text := JSON.stringify(grounded)
	assert_true(grounded_text.find("extreme scale") >= 0, grounded_text)
	assert_true(grounded_text.find("overlapping collision") >= 0, grounded_text)

	adapter.set_test_scene_root(null)
	adapter.cleanup()

func test_import_and_script_conventions() -> void:
	if not _full_catalog():
		return
	var script_path := "res://tests/_agent_conv.gd"
	var script_file := FileAccess.open(script_path, FileAccess.WRITE)
	script_file.store_string("extends Node\nfunc _process(_delta):\n\tvar _node = Node.new()\n\tvar _text = \"a\" + \"b\"\nfunc _ready():\n\ttr(\"\")\n")
	script_file.close()
	var mesh_path := "res://tests/_agent_mesh.glb"
	var mesh_file := FileAccess.open(mesh_path, FileAccess.WRITE)
	mesh_file.store_string("mesh")
	mesh_file.close()
	var import_file := FileAccess.open(mesh_path + ".import", FileAccess.WRITE)
	import_file.store_string("[params]\nmeshes/scale=0.0\nnodes/root_bone=\"1bad\"\n")
	import_file.close()

	var adapter = MCPTestAdapter.create()
	var conventions = adapter.execute_tool_direct("blazium_validate_conventions", {"script": script_path})
	var convention_text := JSON.stringify(conventions)
	assert_true(convention_text.find("empty translation key") >= 0, convention_text)
	assert_true(convention_text.find("_process") >= 0, convention_text)
	var imported = adapter.execute_tool_direct("blazium_validate_import", {"path": mesh_path})
	var import_text := JSON.stringify(imported)
	assert_true(import_text.find("scale") >= 0, import_text)
	assert_true(import_text.find("bone") >= 0, import_text)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(script_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(mesh_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(mesh_path + ".import"))
	adapter.cleanup()

func _full_catalog() -> bool:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return false
	return true
