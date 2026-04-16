extends AutoworkTest

func test_task_manager():
	var manager = JustAMCPTaskManager.new()
	assert_not_null(manager, "TaskManager should instantiate correctly")
	
	# Create Task
	var t = manager.create_task("test_task_123", 100000)
	assert_true(t.has("ok"), "Create task should return an ok dictionary")
	assert_true(t["ok"], "Task should be created successfully")
	assert_true(t.has("task"), "Task dict should be present")
	assert_eq(t["task"]["taskId"], "test_task_123", "taskId should match")
	assert_eq(t["task"]["status"], "working", "status should be working")
	
	# Duplicate fails
	var t2 = manager.create_task("test_task_123", 100000)
	assert_false(t2["ok"], "Creating a duplicate task should fail")
	
	# List Tasks
	var list_t = manager.list_tasks()
	assert_true(list_t.has("tasks"), "Listing should return tasks array")
	assert_eq(list_t["tasks"].size(), 1, "There should be 1 active task")
	
	# Get Task
	var gt = manager.get_task("test_task_123")
	assert_true(gt["ok"], "Getting task should succeed")
	assert_eq(gt["status"], "working", "Status is working")
	
	# Result fails because it's not completed
	var rt = manager.get_task_result("test_task_123")
	assert_false(rt["ok"], "Result should fail while working")
	
	# Complete Task
	manager.complete_task("test_task_123", {"content": [{"type": "text", "text": "done!"}]})
	var gt_completed = manager.get_task("test_task_123")
	assert_eq(gt_completed["status"], "completed", "Status updated to completed")
	
	# Result succeeds
	var rt_completed = manager.get_task_result("test_task_123")
	assert_true(rt_completed["ok"], "Result fetching must succeed")
	assert_true(rt_completed.has("content"), "Content arrays exist")
	
	# Cancel Task
	var cx = manager.create_task("task_cancel", 900)
	assert_true(cx["ok"], "Created cancellation task")
	var cxr = manager.cancel_task("task_cancel")
	assert_true(cxr["ok"], "Cancelled task")
	assert_eq(cxr["status"], "cancelled", "Status must equal cancelled")

func test_resource_executor():
	var res = JustAMCPResourceExecutor.new()
	assert_not_null(res, "ResourceExecutor should instantiate correctly")
	
	var rlist = res.list_resources()
	assert_true(rlist.has("resources"), "Resources map directly.")
	
	var rtemp = res.list_resource_templates()
	assert_true(rtemp.has("resourceTemplates"), "Templates mapped.")
	
	var rrd = res.read_resource("godot://system/logs")
	assert_true(rrd.has("contents"), "System resource read successful!")
	var err_rd = res.read_resource("fake://invalid_path.res")
	assert_true(err_rd.has("error"), "Expected failure on incorrect paths")

func test_prompt_executor():
	var prmpt = JustAMCPPromptExecutor.new()
	assert_not_null(prmpt, "PromptExecutor must instantiate successfully")
	
	var plist = prmpt.list_prompts()
	assert_true(plist.has("prompts"), "Prompts mapped properly.")
	
	var ref_dict = {"name": "blazium_context"}
	var arg_dict = {"name": "context_type", "value": "au"}
	var autocomplete = prmpt.complete_prompt(ref_dict, arg_dict)
	assert_true(autocomplete.has("completion"), "Autocomplete resolves mapping arrays correctly")
	
func test_ping_and_server():
	var server = JustAMCPServer.new()
	assert_not_null(server, "Server binds effectively")
