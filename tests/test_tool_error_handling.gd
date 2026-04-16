extends AutoworkTest

var executor: Object

func _before_each():
	executor = JustAMCPToolExecutor.new()
	

func test_executor_tools_argument_validation():
	var schemas = JustAMCPToolExecutor.get_tool_schemas()
	for schema in schemas:
		var command_name = str(schema["name"])
		# If the command has required arguments, passing {} should yield an error
		var required_args = schema["inputSchema"]["required"] as Array
		
		print("Executing tool to check boundaries: " + command_name)
		var res = executor.execute_tool(command_name, {})
		
		if required_args.size() > 0:
			assert_false(res["ok"], "Command " + command_name + " should not succeed with missing required arguments")
			assert_true(res.has("error"))
			var err = res.get("error", {})
			if typeof(err) == TYPE_DICTIONARY:
				var code = int(err.get("code", 0))
				assert_true(code == -32602 or code == -32000, "Expected -32602 or -32000 for " + command_name + " but got " + str(code))
		else:
			if not res["ok"]:
				if res.has("error") and typeof(res["error"]) == TYPE_DICTIONARY:
					var code = int(res["error"].get("code", 0))
					assert_true(code == -32602 or code == -32000 or code == -32601, "Expected predictable error for " + command_name + " but got " + str(code))
