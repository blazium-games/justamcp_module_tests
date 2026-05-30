extends AutoworkTest

const MCPTestFixtures = preload("res://tests/mcp_test_fixtures.gd")

var executor: Object

func _before_each():
	executor = JustAMCPToolExecutor.new()
	

func test_executor_schemas():
	assert_not_null(executor)
	
	var schemas = MCPTestFixtures.all_tool_schemas()
	assert_eq(typeof(schemas), TYPE_ARRAY)
	assert_gt(schemas.size(), 0, "Tool schemas array should not be empty")

	for schema in schemas:
		assert_eq(typeof(schema), TYPE_DICTIONARY)
		assert_true(schema.has("name"))
		assert_true(schema.has("description"))
		assert_true(schema.has("inputSchema"))
		
		var inputSchema = schema["inputSchema"]
		assert_eq(typeof(inputSchema), TYPE_DICTIONARY)
		assert_true(inputSchema.has("type"))
		assert_eq(str(inputSchema["type"]), "object")
		if inputSchema.has("properties"):
			assert_eq(typeof(inputSchema["properties"]), TYPE_DICTIONARY)
		if inputSchema.has("required"):
			assert_eq(typeof(inputSchema["required"]), TYPE_ARRAY)
