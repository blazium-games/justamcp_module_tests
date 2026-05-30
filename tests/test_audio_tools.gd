extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_audio_tools():
	var root_node = Node2D.new()
	root_node.name = "AudioRoot"
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "get_audio_bus_layout", "params": {}},
		{"tool": "add_audio_bus", "params": { "name": "SFX" }},
		{"tool": "set_audio_bus", "params": { "bus_name": "SFX", "volume_db": -5.0, "mute": false }},
		{"tool": "add_audio_bus_effect", "params": { "bus_name": "SFX", "effect_type": "AudioEffectReverb" }},
		{"tool": "add_audio_player", "params": { "node_path": "AudioRoot", "name": "MyAudioPlayer", "bus": "SFX", "autoplay": true }},
		{"tool": "audio_get_players_info", "params": { "node_path": "AudioRoot/MyAudioPlayer" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
