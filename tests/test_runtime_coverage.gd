extends AutoworkTest

var runtime: Object

func _before_each():
	runtime = Engine.get_singleton("JustAMCPRuntime")

func test_ping():
	var res = runtime.execute_command("ping", {})
	assert_true(res.has("type"))
	assert_eq(str(res["type"]), "pong")
	assert_true(res.has("timestamp"))

func test_get_metrics():
	var res = runtime.execute_command("get_metrics", {})
	assert_true(res.has("type") and res["type"] == "metrics")
	assert_true(res.has("data"))
	var data = res["data"]
	assert_true(data.has("fps"))
	assert_true(data.has("memory_static"))

func test_capture_screenshot():
	var res = runtime.execute_command("capture_screenshot", {})
	assert_true(res.has("type") and res["type"] == "error")

func test_capture_viewport():
	var res = runtime.execute_command("capture_viewport", {})
	assert_true(res.has("type") and res["type"] == "error")

func test_inject_inputs():
	for cmd in ["inject_action", "inject_key", "inject_mouse_click", "inject_mouse_motion"]:
		var res = runtime.execute_command(cmd, {})
		assert_true(res.has("type") and res["type"] == "error")

func test_watch_signals():
	for cmd in ["watch_signal", "unwatch_signal"]:
		var res = runtime.execute_command(cmd, {})
		assert_true(res.has("type") and res["type"] == "error")

func test_get_tree_depth():
	var root_node = Node.new()
	root_node.name = "RootDepth"
	var child1 = Node.new()
	child1.name = "Child1"
	var child2 = Node.new()
	child2.name = "Child2"
	root_node.add_child(child1)
	child1.add_child(child2)
	add_child(root_node)
	root_node.queue_free()

	var params = {
		"root": str(root_node.get_path()),
		"depth": 1,
		"include_properties": true
	}
	var res = runtime.execute_command("get_tree", params)
	assert_true(res.has("type") and res["type"] == "tree")
	assert_true(res.has("root"))
	
	var r = res["root"]
	assert_eq(str(r["name"]), "RootDepth")
	assert_true(r.has("children"))
	assert_eq(r["children"].size(), 1)
	assert_eq(str(r["children"][0]["name"]), "Child1")
	# Since depth is 1, Child2 should not be listed as children of Child1
	assert_false(r["children"][0].has("children"))
