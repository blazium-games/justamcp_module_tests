extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _assert_structured(result: Dictionary, tool_name: String) -> void:
	assert_true(result.has("ok") or result.has("error"), "Tool should return a structured response: " + tool_name)

func test_blueprint_draw_environment_and_asset_tools_are_exercised() -> void:
	var root = Node3D.new()
	root.name = "SurfaceRoot"
	var particles = GPUParticles3D.new()
	particles.name = "Particles"
	root.add_child(particles)
	var mesh = MeshInstance3D.new()
	mesh.name = "Mesh"
	root.add_child(mesh)
	var camera = Camera3D.new()
	camera.name = "Camera"
	root.add_child(camera)
	var world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	root.add_child(world_environment)
	var control = Control.new()
	control.name = "Overlay"
	root.add_child(control)
	add_child(root)
	autoqfree(root)

	var adapter = MCPTestAdapter.new()
	add_child(adapter)
	adapter.setup_sync()
	adapter.set_test_scene_root(root)

	var smoke_tests = [
		{"tool": "blazium_blueprint_create_particle_preset", "params": {"path": "Particles", "preset": "fire", "is_3d": true}},
		{"tool": "blazium_blueprint_create_material_preset", "params": {"path": "Mesh", "preset": "metal"}},
		{"tool": "blazium_blueprint_setup_camera_preset", "params": {"path": "Camera", "preset": "cinematic"}},
		{"tool": "blazium_control_draw_recipe", "params": {"path": "Overlay", "ops": [{"type": "rect", "rect": Rect2(0, 0, 8, 8), "color": Color.RED}], "clear_existing": true}},
		{"tool": "blazium_environment_create", "params": {"path": "WorldEnvironment", "preset": "sunset", "sky": true}},
		{"tool": "blazium_asset_generate_2d_asset", "params": {"svg_code": "<svg xmlns='http://www.w3.org/2000/svg' width='8' height='8'><rect width='8' height='8' fill='red'/></svg>", "filename": "justamcp_asset_probe.png", "save_path": "res://generated_test_assets", "scale": 1.0}},
	]

	for item in smoke_tests:
		var result = adapter.execute_tool_direct(item["tool"], item["params"])
		_assert_structured(result, item["tool"])

	adapter.remove_file_if_exists("res://generated_test_assets/justamcp_asset_probe.png")
	adapter.set_test_scene_root(null)
	adapter.queue_free()
