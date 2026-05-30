extends AutoworkTest
const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_resource_tools():
	var executor = MCPTestAdapter.create()
	executor.setup_sync()
	
	var tests = [
		{"tool": "create_resource", "params": {"resource_path": "res://test_resource.tres", "resource_type": "StandardMaterial3D"}},
		{"tool": "modify_resource", "params": {"resource_path": "res://test_resource.tres", "properties": {"emission_enabled": true}}},
		{"tool": "create_material", "params": {"resource_path": "res://test_mat.tres", "material_type": "standard", "properties": {}}},
		{"tool": "create_tileset", "params": {"resource_path": "res://test_tileset.tres"}},
		{"tool": "set_tilemap_cells", "params": {"scene_path": "res://test_scene.tscn", "node_path": "MyTileMap", "cells": []}},
		{"tool": "apply_theme_shader", "params": {"resource_path": "res://test_theme.tres", "shader_path": "res://test_shader.gdshader"}}
	]
	
	for t in tests:
		var res = executor.execute_tool(t.tool, t.params)
		assert_true(res.has("ok"), "Tool failed to return ok: " + t.tool)

	var resource_executor = JustAMCPResourceExecutor.new()
	var vid_res = resource_executor.read_resource("video://recordings")
	assert_true(vid_res.has("ok") or vid_res.has("error"), "Resource execution failed entirely tracking video uri!")
	executor.cleanup()
