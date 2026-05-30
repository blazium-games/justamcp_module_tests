extends AutoworkTest

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

var executor: Object

func _before_each():
	executor = JustAMCPToolExecutor.new()
	

func test_executor_tools_argument_validation():
	var schemas = MCPTestFixtures.all_tool_schemas()
	for schema in schemas:
		var command_name = str(schema["name"])
		# If the command has required arguments, passing {} should yield an error
		var input_schema = schema.get("inputSchema", {}) as Dictionary
		var required_args = input_schema.get("required", []) as Array
		
		if required_args.size() > 0:
			print("Executing tool to check boundaries: " + command_name)
			var res = executor.execute_tool(command_name, {})
			assert_false(res.get("ok", true), "Command " + command_name + " should not succeed with missing required arguments")
			assert_true(res.has("error"))
			var err = res.get("error", {})
			if typeof(err) == TYPE_DICTIONARY:
				var code = int(err.get("code", 0))
				assert_true(code == -32602 or code == -32000, "Expected -32602 or -32000 for " + command_name + " but got " + str(code))
		else:
			assert_true(input_schema.has("type"), "Schema for " + command_name + " should expose an input type")
