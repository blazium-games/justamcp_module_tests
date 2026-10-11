extends AutoworkTest

const FILES := [
	"res://tests/fixtures/bench/world2d.tscn",
	"res://tests/fixtures/bench/world3d.tscn",
	"res://tests/fixtures/bench/sample_script.gd",
	"res://tests/fixtures/bench/sample_shader.gdshader",
	"res://tests/fixtures/bench/sample_theme.tres",
	"res://tests/fixtures/bench/sample_material.tres",
	"res://tests/fixtures/bench/sample_tileset.tres",
	"res://tests/fixtures/bench/icon.png",
	"res://tests/fixtures/bench/bench_paths.json",
]

func test_bench_files_exist() -> void:
	for path in FILES:
		assert_true(FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path), "missing " + path)

func test_bench_scenes_instantiate() -> void:
	for path in ["res://tests/fixtures/bench/world2d.tscn", "res://tests/fixtures/bench/world3d.tscn"]:
		var packed := load(path) as PackedScene
		assert_not_null(packed, path)
		var node := packed.instantiate()
		assert_not_null(node, path)
		node.free()

func test_bench_paths_point_at_files() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/bench/bench_paths.json"))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var paths := parsed as Dictionary
	assert_true(paths.has("scene_path"))
	assert_true(paths.has("script_path"))
	assert_true(paths.has("shader_path"))
	for key in paths.keys():
		var value := str(paths[key])
		if value.begins_with("res://") and not value.contains("/scratch/") and (value.ends_with(".gd") or value.ends_with(".tscn") or value.ends_with(".tres") or value.ends_with(".gdshader") or value.ends_with(".png") or value.ends_with(".json")):
			assert_true(FileAccess.file_exists(value), key + " -> " + value)
