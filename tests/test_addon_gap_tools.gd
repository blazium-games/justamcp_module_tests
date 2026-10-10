extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")
const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

const GAP_TOOLS := [
	"blazium_save_branch_as_scene",
	"blazium_replace_node_type",
	"blazium_set_unique_name",
	"blazium_add_timer",
	"blazium_align_nodes",
	"blazium_distribute_nodes",
	"blazium_set_node_transform_2d",
	"blazium_set_node_transform_3d",
	"blazium_look_at_node",
	"blazium_batch_get_properties",
	"blazium_set_property_across_scenes",
	"blazium_add_sprite",
	"blazium_add_animated_sprite",
	"blazium_add_canvas_modulate",
	"blazium_add_light_2d",
	"blazium_add_light_occluder_2d",
	"blazium_create_placeholder_texture",
	"blazium_set_camera_limits",
	"blazium_add_ui_control",
	"blazium_add_ui_container",
	"blazium_add_progress_bar",
	"blazium_add_ui_dialog",
	"blazium_configure_popup_menu",
	"blazium_configure_menu_bar",
	"blazium_set_item_list_items",
	"blazium_set_option_button_items",
	"blazium_set_texture_rect",
	"blazium_set_control_icon",
	"blazium_load_font",
	"blazium_set_control_style",
	"blazium_wire_button",
	"blazium_add_marker",
	"blazium_add_remote_transform",
	"blazium_add_path",
	"blazium_add_path_follow",
	"blazium_add_visibility_notifier",
	"blazium_add_decal",
	"blazium_add_reflection_probe",
	"blazium_add_subviewport",
	"blazium_add_bone_attachment_3d",
	"blazium_add_text_mesh",
	"blazium_add_spring_arm",
	"blazium_add_global_illumination",
	"blazium_create_material_preset",
	"blazium_set_material_property",
	"blazium_set_csg_operation",
	"blazium_gridmap_set_cell",
	"blazium_paint_gridmap_region",
	"blazium_create_terrain",
	"blazium_scatter_multimesh",
	"blazium_configure_tileset_layers",
	"blazium_configure_tileset_terrains",
	"blazium_set_tileset_tile_data",
	"blazium_tilemap_paint_terrain",
	"blazium_tilemap_set_cells",
	"blazium_assign_theme",
	"blazium_merge_theme",
	"blazium_configure_theme",
	"blazium_add_shader_preset",
	"blazium_create_visual_shader",
	"blazium_add_visual_shader_node",
	"blazium_connect_visual_shader_nodes",
	"blazium_disconnect_visual_shader_nodes",
	"blazium_remove_visual_shader_node",
	"blazium_set_visual_shader_node_property",
	"blazium_get_visual_shader_info",
	"blazium_add_bone",
	"blazium_set_bone_rest",
	"blazium_set_bone_pose",
	"blazium_reset_bone_poses",
	"blazium_get_skeleton_info",
	"blazium_set_blend_shape",
	"blazium_get_mesh_info",
	"blazium_list_model_animations",
	"blazium_create_skeleton_2d",
	"blazium_create_bone_map",
	"blazium_auto_bone_map",
	"blazium_add_ik_chain",
	"blazium_add_look_at_modifier",
	"blazium_rename_animation",
	"blazium_list_animation_tracks",
	"blazium_configure_animation_track",
	"blazium_remove_animation_track",
	"blazium_set_animation_keyframes",
	"blazium_remove_animation_keyframe",
	"blazium_connect_animation_blend_nodes",
	"blazium_remove_animation_blend_node",
	"blazium_add_collision_polygon",
	"blazium_add_mesh_collision",
	"blazium_add_shape_cast",
	"blazium_set_physics_material",
	"blazium_set_collision_layers_by_name",
	"blazium_add_particle_collision",
	"blazium_set_particle_process",
	"blazium_create_audio_randomizer",
	"blazium_save_bus_layout",
	"blazium_add_navigation_obstacle",
	"blazium_add_navigation_link",
	"blazium_list_plugins",
	"blazium_enable_plugin",
	"blazium_set_import_options",
	"blazium_get_image_info",
	"blazium_diff_images",
	"blazium_check_all_scripts",
	"blazium_project_health_report",
	"blazium_describe_scene_visual",
	"blazium_add_translation",
	"blazium_set_locale",
	"blazium_create_export_preset",
]

func test_addon_gap_schemas_exist() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var adapter = MCPTestAdapter.create()
	var names = adapter.get_tool_names()
	for tool_name in GAP_TOOLS:
		assert_true(names.has(tool_name), "Missing schema: " + tool_name)
	adapter.cleanup()

func test_addon_gap_scene_edits() -> void:
	if MCPTestFixtures.is_reduced_headless_catalog():
		pending("Full JustAMCP tool catalog requires the editor (headless -s exposes a reduced set)")
		return
	var root_node := Node2D.new()
	root_node.name = "World2D"
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.position = Vector2(10, 4)
	root_node.add_child(sprite)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position = Vector2(40, 4)
	root_node.add_child(camera)
	var button := Button.new()
	button.name = "Button"
	root_node.add_child(button)
	add_child(root_node)
	autoqfree(root_node)

	var adapter = MCPTestAdapter.create()
	adapter.setup_sync()
	adapter.set_test_scene_root(root_node)

	var added = adapter.execute_tool_direct("blazium_add_sprite", {})
	assert_true(added.get("ok", false), str(added.get("error", added)))
	assert_true(root_node.get_node_or_null(NodePath(str(added.get("node_path", "")))) is Sprite2D)

	var timer = adapter.execute_tool_direct("blazium_add_timer", {"wait_time": 2.5, "autostart": true})
	assert_true(timer.get("ok", false), str(timer.get("error", timer)))
	var timer_node = root_node.get_node_or_null(NodePath(str(timer.get("node_path", ""))))
	assert_true(timer_node is Timer)
	assert_eq(timer_node.wait_time, 2.5)
	assert_true(timer_node.autostart)

	var aligned = adapter.execute_tool_direct("blazium_align_nodes", {"node_paths": ["Sprite2D", "Camera2D"], "axis": "y"})
	assert_true(aligned.get("ok", false), str(aligned.get("error", aligned)))
	assert_eq(sprite.position.y, camera.position.y)

	var unique = adapter.execute_tool_direct("blazium_set_unique_name", {"node_path": "Sprite2D", "unique": true})
	assert_true(unique.get("ok", false), str(unique.get("error", unique)))
	assert_true(sprite.unique_name_in_owner)

	var bad = adapter.execute_tool_direct("blazium_save_branch_as_scene", {"node_path": "Missing", "dest_path": "user://bad.txt"})
	assert_false(bad.get("ok", true))
	assert_true(str(bad.get("error", "")).length() > 0)

	var image = adapter.execute_tool_direct("blazium_create_placeholder_texture", {})
	assert_true(image.get("ok", false), str(image.get("error", image)))
	var info = adapter.execute_tool_direct("blazium_get_image_info", {"path": image.get("path", "")})
	assert_true(info.get("ok", false), str(info.get("error", info)))
	assert_eq(info.get("width", 0), 8)
	var missing = adapter.execute_tool_direct("blazium_get_image_info", {"path": "user://justamcp_gap_does_not_exist.png"})
	assert_false(missing.get("ok", true))

	adapter.set_test_scene_root(null)
	adapter.cleanup()
