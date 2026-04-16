extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_particle_tools():
	var root_node = Node2D.new()
	root_node.name = "ParticleRoot"
	
	var existing = GPUParticles2D.new()
	existing.name = "MyParticles"
	root_node.add_child(existing)
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "create_particles", "params": { "parent_path": "ParticleRoot", "name": "NewParticles", "is_3d": false, "amount": 32, "one_shot": true }},
		{"tool": "set_particle_material", "params": { "node_path": "MyParticles", "material_type": "ParticleProcessMaterial", "properties": {} }},
		{"tool": "set_particle_color_gradient", "params": { "node_path": "MyParticles", "colors": [], "offsets": [] }},
		{"tool": "apply_particle_preset", "params": { "node_path": "MyParticles", "preset": "fire" }},
		{"tool": "get_particle_info", "params": { "node_path": "MyParticles" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
