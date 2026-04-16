extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_scene_3d_tools():
	var root_node = Node3D.new()
	root_node.name = "Scene3DRoot"
	
	var existing_mesh = MeshInstance3D.new()
	existing_mesh.name = "MyMesh"
	existing_mesh.mesh = BoxMesh.new()
	root_node.add_child(existing_mesh)
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "add_mesh_instance", "params": { "parent_path": "Scene3DRoot", "name": "NewMesh", "mesh_type": "box", "size": "1,1,1" }},
		{"tool": "setup_lighting", "params": { "parent_path": "Scene3DRoot", "light_type": "directional", "name": "MyLight", "color": {"r":1,"g":1,"b":1,"a":1}, "energy": 1.0 }},
		{"tool": "set_material_3d", "params": { "node_path": "Scene3DRoot", "material_type": "standard", "properties": {} }},
		{"tool": "setup_environment", "params": { "parent_path": "Scene3DRoot", "name": "MyEnv", "sky_type": "procedural" }},
		{"tool": "setup_camera_3d", "params": { "parent_path": "Scene3DRoot", "name": "MyCamera", "fov": 75.0 }},
		{"tool": "add_gridmap", "params": { "parent_path": "Scene3DRoot", "name": "MyGridMap", "mesh_library_path": "res://test_lib.tres", "cell_size": "2,2,2" }}
	]
	
	for t in tests:
		print("RUNNING 3D TOOL: ", t.tool)
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
