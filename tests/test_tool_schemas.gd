extends AutoworkTest

var executor: Object

func _before_each():
	executor = JustAMCPToolExecutor.new()
	

func test_executor_schemas():
	assert_not_null(executor)
	
	var schemas = JustAMCPToolExecutor.get_tool_schemas()
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
		assert_true(inputSchema.has("properties"))
		assert_true(inputSchema.has("required"))
