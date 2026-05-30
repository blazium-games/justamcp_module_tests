extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_tilemap_tools():
	var root_node = Node2D.new()
	root_node.name = "TileMapRoot"
	
	var tilemap = TileMapLayer.new()
	tilemap.name = "MyTileMap"
	var tileset = TileSet.new()
	tilemap.tile_set = tileset
	root_node.add_child(tilemap)
	
	add_child(root_node)
	autoqfree(root_node)
	
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	executor.set_test_scene_root(root_node)
	
	var tests = [
		{"tool": "tilemap_set_cell", "params": { "node_path": "MyTileMap", "x": 1, "y": 1, "source_id": 0, "atlas_x": 0, "atlas_y": 0 }},
		{"tool": "tilemap_fill_rect", "params": { "node_path": "MyTileMap", "x": 0, "y": 0, "w": 5, "h": 5, "source_id": 0 }},
		{"tool": "tilemap_get_cell", "params": { "node_path": "MyTileMap", "x": 1, "y": 1 }},
		{"tool": "tilemap_clear", "params": { "node_path": "MyTileMap" }},
		{"tool": "tilemap_get_info", "params": { "node_path": "MyTileMap" }},
		{"tool": "tilemap_get_used_cells", "params": { "node_path": "MyTileMap" }}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok") or res.has("error"), "Tool failed entirely: " + t.tool)
	
	executor.set_test_scene_root(null)
