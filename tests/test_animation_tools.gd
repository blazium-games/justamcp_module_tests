extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_animation_tools():
	var root_node = Node2D.new()
	root_node.name = "AnimationRoot"
	
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimPlayer"
	root_node.add_child(anim_player)
	
	var anim_lib = AnimationLibrary.new()
	var anim = Animation.new()
	anim_lib.add_animation("test_anim", anim)
	anim_player.add_animation_library("", anim_lib)
	
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.new()
	add_child(executor)
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "create_animation", "params": { "scenePath": "res://test_scene.tscn", "playerNodePath": "AnimPlayer", "animationName": "new_anim", "loopMode": "none" }},
		{"tool": "add_animation_track", "params": { "resource_path": "res://test_anim.tres", "animation_name": "new_anim", "track_type": "value", "node_path": "AnimPlayer" }},
		{"tool": "create_animation_tree", "params": { "scene_path": "res://test_scene.tscn", "parent_path": "AnimationRoot", "tree_name": "AnimTree" }},
		{"tool": "add_animation_state", "params": { "resource_path": "res://test_anim_tree.tres", "state_name": "Idle", "animation_name": "idle_anim" }},
		{"tool": "connect_animation_states", "params": { "resource_path": "res://test_anim_tree.tres", "from_state": "Start", "to_state": "Idle" }},
		{"tool": "create_navigation_region", "params": { "scene_path": "res://test_scene.tscn", "parent_path": "AnimationRoot", "region_name": "NavRegion" }},
		{"tool": "create_navigation_agent", "params": { "scene_path": "res://test_scene.tscn", "parent_path": "AnimationRoot", "agent_name": "NavAgent" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok"), "Tool failed to return ok: " + t.tool)
	
	executor.set_test_scene_root(null)
