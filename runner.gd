extends SceneTree
func _initialize() -> void:
	print("Starting GUT...")
	# Make sure class names are cached
	var gut = load("res://addons/gut/gut.gd").new()
	root.add_child(gut)
	gut.add_directory("res://tests")
	gut.test_scripts()
	var fail_count = gut.get_fail_count()
	print("Failed tests: ", fail_count)
	quit(fail_count)
