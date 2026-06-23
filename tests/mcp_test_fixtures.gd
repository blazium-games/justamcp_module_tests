extends RefCounted
class_name MCPTestFixtures

static func enable_all_tool_categories() -> void:
	var manifest_path := "res://tests/mcp_tool_manifest.json"
	if not FileAccess.file_exists(manifest_path):
		JustAMCPToolExecutor.get_tool_schemas(true)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	for category in manifest.keys():
		if str(category) == "meta":
			continue
		var cat_key := "blazium/justamcp/tools/" + str(category)
		ProjectSettings.set_setting(cat_key, true)
		for internal_name in manifest[category]:
			var tool_key := cat_key + "/blazium_" + str(internal_name)
			ProjectSettings.set_setting(tool_key, true)

static func all_tool_schemas() -> Array:
	enable_all_tool_categories()
	return JustAMCPToolExecutor.get_tool_schemas(false, false)

static func minimal_args_from_schema(schema: Dictionary) -> Dictionary:
	var args := {}
	var input_schema = schema.get("inputSchema", {}) as Dictionary
	var properties = input_schema.get("properties", {}) as Dictionary
	var required = input_schema.get("required", []) as Array

	for key in required:
		var prop_name := str(key)
		if properties.has(prop_name):
			args[prop_name] = _default_value_for_property(properties[prop_name] as Dictionary, prop_name)
		else:
			args[prop_name] = _fallback_for_name(prop_name)

	return args

static func _default_value_for_property(prop: Dictionary, prop_name: String) -> Variant:
	var prop_type := str(prop.get("type", "string"))
	match prop_type:
		"string":
			return _fallback_for_name(prop_name)
		"number", "integer":
			return 0
		"boolean":
			return false
		"object":
			return {}
		"array":
			return _default_array_value(prop_name)
		_:
			return _fallback_for_name(prop_name)

static func _default_array_value(prop_name: String) -> Array:
	if prop_name.contains("node_paths") or prop_name.contains("paths"):
		return ["."]
	if prop_name.contains("steps") or prop_name.contains("events") or prop_name.contains("cells"):
		return []
	if prop_name.contains("properties"):
		return []
	return []

static func _fallback_for_name(prop_name: String) -> String:
	match prop_name:
		"query", "test_name", "directory_path", "topic", "slug":
			return "test"
		"script_path", "target_script":
			return "res://tests/fixtures/sample.gd"
		"code", "snippet":
			return "extends Node\nfunc _ready() -> void:\n\tpass"
		"expr", "expression":
			return "1 + 1"
		"test_results", "test_output":
			return "1 failing Autowork assertion in test_example"
		"tool_name":
			return "get_guide"
		"arguments":
			return "{}"
		"path", "scene_path", "resource_path", "shader_path", "base_scene_path", "new_scene_path", "node_path", "parent_path", "from_path", "to_path", "new_parent_path", "texture_path", "mesh_library_path", "save_path", "filename", "svg_code", "content", "class_name", "setting", "key", "section", "name", "bus_name", "action", "method_name", "param_name", "type", "screen_name", "preset", "body_type", "shape_type", "material_type", "resource_type", "shaderType", "styleType", "styleName", "colorName", "constantName", "fontName", "file_type", "uid", "source", "context", "node_type", "networking_goal", "ui_goal", "shader_goal", "project_goal", "scene_goal", "mode", "functions", "test_results", "target_script", "feature", "root", "target", "value":
			return _default_path_or_name(prop_name)
		_:
			return "res://tests/fixtures/sample.gd"

static func _default_path_or_name(prop_name: String) -> String:
	if prop_name.ends_with("_path") or prop_name == "path":
		return "res://tests/fixtures/sample.tscn"
	if prop_name == "filename":
		return "test.png"
	if prop_name == "svg_code":
		return "<svg xmlns='http://www.w3.org/2000/svg' width='8' height='8'><rect width='8' height='8' fill='red'/></svg>"
	if prop_name == "content":
		return "extends Node"
	if prop_name == "uid":
		return "uid://test"
	if prop_name == "type" or prop_name == "node_type":
		return "Node2D"
	if prop_name == "name":
		return "TestNode"
	if prop_name == "action":
		return "ui_accept"
	if prop_name == "mode":
		return "strict"
	if prop_name == "feature":
		return "Sample UI feature"
	if prop_name == "value":
		return "sample"
	if prop_name == "root" or prop_name == "target":
		return "res://"
	return "res://tests/fixtures/sample.gd"

static func is_dispatch_failure(result: Dictionary) -> bool:
	if not result.has("ok"):
		return false
	if result.get("ok", false):
		return false
	var err = result.get("error", null)
	if typeof(err) == TYPE_STRING:
		var msg: String = err
		return msg.contains("Unknown tool") or msg.contains("Tools not initialized")
	if typeof(err) == TYPE_DICTIONARY:
		var msg: String = str(err.get("message", ""))
		return msg.contains("Unknown tool") or msg.contains("Tools not initialized")
	return false

static func assert_tool_dispatched(test: AutoworkTest, result: Dictionary, tool_name: String) -> void:
	test.assert_false(is_dispatch_failure(result), "Tool should dispatch (not unknown/disabled): " + tool_name)

static func build_scene_tree(parent: Node) -> Node2D:
	var root := Node2D.new()
	root.name = "FixtureRoot"
	parent.add_child(root)

	var child := Node2D.new()
	child.name = "FixtureChild"
	root.add_child(child)

	return root

static func ensure_fixture_files() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/fixtures")
	var script_path := "res://tests/fixtures/sample.gd"
	if not FileAccess.file_exists(script_path):
		var file = FileAccess.open(script_path, FileAccess.WRITE)
		if file:
			file.store_string("extends Node\nfunc fixture_method() -> void:\n\tpass\n")
			file.close()
	var scene_path := "res://tests/fixtures/sample.tscn"
	if not FileAccess.file_exists(scene_path):
		var packed := PackedScene.new()
		var node := Node2D.new()
		node.name = "Sample"
		packed.pack(node)
		ResourceSaver.save(packed, scene_path)
		node.free()
	var test_scene_path := "res://test_scene.tscn"
	if not FileAccess.file_exists(test_scene_path):
		var test_scene := PackedScene.new()
		var root := Node2D.new()
		root.name = "TestSceneRoot"
		var child := Node2D.new()
		child.name = "MyChild"
		root.add_child(child)
		test_scene.pack(root)
		ResourceSaver.save(test_scene, test_scene_path)
		child.free()
		root.free()
