extends AutoworkTest

var runtime: Object

func _before_each():
	runtime = Engine.get_singleton("JustAMCPRuntime")

func test_runtime_instantiation():
	assert_not_null(runtime)
	assert_true(runtime.has_method("execute_command"))

func test_runtime_invalid_command():
	var result = runtime.execute_command("some_non_existent", {})
	assert_true(result.has("type"))
	assert_eq(str(result["type"]), "error")
	assert_true(str(result.get("message", "")).begins_with("Unknown command"))

func test_execute_node_validation():
	# get_node requires 'path'
	var result = runtime.execute_command("get_node", {})
	assert_true(result.has("type"))
	assert_eq(str(result["type"]), "error")
	assert_true(str(result.get("message", "")).contains("Node path required"))
