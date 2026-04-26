extends Node
class_name MCPTestAdapter

func _exit_tree() -> void:
	cleanup()

var host = "127.0.0.1"
var port = 6506
var mcp_server : JustAMCPServer
var tool_executor : JustAMCPToolExecutor
var prompt_executor : JustAMCPPromptExecutor
var resource_executor : JustAMCPResourceExecutor
var sse_client : HTTPClient
var sse_buffer : String = ""
var http_available := false

var current_request_id = 1
var registered_results = {}

func setup_sync():
	mcp_server = JustAMCPServer.new()
	tool_executor = JustAMCPToolExecutor.new()
	prompt_executor = JustAMCPPromptExecutor.new()
	resource_executor = JustAMCPResourceExecutor.new()
	mcp_server.tool_requested.connect(_on_tool_requested)
	
	# Open an SSE connection explicitly synchronously
	sse_client = HTTPClient.new()
	var err = sse_client.connect_to_host(host, port)
	if err != OK:
		print("Failed to initialize sync HTTP client")
		return
		
	# Wait until connection drops from resolving
	while sse_client.get_status() == HTTPClient.STATUS_CONNECTING or sse_client.get_status() == HTTPClient.STATUS_RESOLVING:
		sse_client.poll()
		OS.delay_msec(1)
		
	if sse_client.get_status() != HTTPClient.STATUS_CONNECTED:
		return
		
	# Initiate the SSE Request 
	err = sse_client.request(HTTPClient.METHOD_GET, "/sse", ["Accept: text/event-stream"])
	if err != OK:
		print("Failed to request SSE Stream")
		return
		
	# Wait for stream to establish explicitly natively
	while sse_client.get_status() == HTTPClient.STATUS_REQUESTING:
		sse_client.poll()
		OS.delay_msec(1)
		
	if sse_client.get_status() != HTTPClient.STATUS_BODY:
		print("Failed asserting SSE Body natively: ", sse_client.get_status())
		return
	http_available = true

func cleanup() -> void:
	if sse_client:
		sse_client.close()
		sse_client = null
	if mcp_server:
		mcp_server.free()
		mcp_server = null
	if tool_executor:
		tool_executor.free()
		tool_executor = null
	if prompt_executor:
		prompt_executor.free()
		prompt_executor = null
	if resource_executor:
		resource_executor.free()
		resource_executor = null

func set_test_scene_root(root_node: Node) -> void:
	if tool_executor:
		tool_executor.set_test_scene_root(root_node)

func _on_tool_requested(p_request_id: String, p_tool_name: String, p_params: Dictionary) -> void:
	var result = tool_executor.execute_tool(p_tool_name, p_params)
	if result.has("ok") and result["ok"]:
		var payload = result.get("result", {})
		mcp_server.send_tool_result(p_request_id, true, payload, "")
	else:
		var error_msg = result.get("error", "Unknown error")
		var payload = result.get("error", null)
		mcp_server.send_tool_result(p_request_id, false, payload, error_msg)

func execute_tool_direct(tool_name: String, params: Dictionary = {}) -> Dictionary:
	if not tool_executor:
		tool_executor = JustAMCPToolExecutor.new()
	return tool_executor.execute_tool(tool_name, params)

func execute_tool(tool_name: String, params: Dictionary) -> Dictionary:
	if not http_available or not sse_client:
		return execute_tool_direct(tool_name, params)

	var req_id = current_request_id
	current_request_id += 1
	var payload = {
		"jsonrpc": "2.0",
		"id": req_id,
		"method": "tools/call",
		"params": {
			"name": tool_name,
			"arguments": params
		}
	}
	
	var r_client = HTTPClient.new()
	r_client.connect_to_host(host, port)
	while r_client.get_status() == HTTPClient.STATUS_CONNECTING or r_client.get_status() == HTTPClient.STATUS_RESOLVING:
		r_client.poll()
		OS.delay_msec(1)
	if r_client.get_status() != HTTPClient.STATUS_CONNECTED:
		r_client.close()
		return execute_tool_direct(tool_name, params)
		
	r_client.request(HTTPClient.METHOD_POST, "/mcp", ["Content-Type: application/json"], JSON.stringify(payload))
	
	while r_client.get_status() == HTTPClient.STATUS_REQUESTING:
		r_client.poll()
		OS.delay_msec(1)
		
	# Now pump SSE wait bounds
	var end_time = Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < end_time:
		sse_client.poll()
		if sse_client.get_status() == HTTPClient.STATUS_BODY:
			var chunk = sse_client.read_response_body_chunk()
			if chunk.size() > 0:
				sse_buffer += chunk.get_string_from_utf8()
				var opt_res = _process_sse_buffer(req_id)
				if opt_res != null:
					return opt_res
					
		# Since JustAMCPServer invokes UI execution via call_deferred("emit_signal"), 
		# we MUST pump the main Godot iterations locally safely because we block the thread!
		# The only strictly correct way natively available outside `await get_tree().process_frame`:
		OS.delay_msec(5)
		
	return {"error": "Timeout", "message": "Failed waiting for asynchronous response mapping locally"}

func get_tool_names() -> Array:
	var names: Array = []
	for schema in JustAMCPToolExecutor.get_tool_schemas():
		names.append(str(schema.get("name", "")))
	return names

func find_tool_schema(tool_name: String) -> Dictionary:
	for schema in JustAMCPToolExecutor.get_tool_schemas():
		if str(schema.get("name", "")) == tool_name:
			return schema
	return {}

func read_resource(uri: String) -> Dictionary:
	if not resource_executor:
		resource_executor = JustAMCPResourceExecutor.new()
	return resource_executor.read_resource(uri)

func list_resources() -> Dictionary:
	if not resource_executor:
		resource_executor = JustAMCPResourceExecutor.new()
	return resource_executor.list_resources()

func list_resource_templates() -> Dictionary:
	if not resource_executor:
		resource_executor = JustAMCPResourceExecutor.new()
	return resource_executor.list_resource_templates()

func get_prompt(prompt_name: String, args: Dictionary = {}) -> Dictionary:
	if not prompt_executor:
		prompt_executor = JustAMCPPromptExecutor.new()
	return prompt_executor.get_prompt(prompt_name, args)

func list_prompts() -> Dictionary:
	if not prompt_executor:
		prompt_executor = JustAMCPPromptExecutor.new()
	return prompt_executor.list_prompts()

func complete_prompt(ref: Dictionary, argument: Dictionary) -> Dictionary:
	if not prompt_executor:
		prompt_executor = JustAMCPPromptExecutor.new()
	return prompt_executor.complete_prompt(ref, argument)

func http_jsonrpc(method: String, params: Dictionary = {}, timeout_msec: int = 1000) -> Dictionary:
	var client = HTTPClient.new()
	var err = client.connect_to_host(host, port)
	if err != OK:
		return {"skipped": true, "error": "MCP HTTP server is not reachable."}

	var deadline = Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline and (client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING):
		client.poll()
		OS.delay_msec(5)

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.close()
		return {"skipped": true, "error": "MCP HTTP server is not connected."}

	var req_id = current_request_id
	current_request_id += 1
	var payload = {
		"jsonrpc": "2.0",
		"id": req_id,
		"method": method,
		"params": params,
	}
	err = client.request(HTTPClient.METHOD_POST, "/mcp", ["Content-Type: application/json"], JSON.stringify(payload))
	if err != OK:
		client.close()
		return {"skipped": true, "error": "MCP HTTP request failed to start."}

	while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	var body := PackedByteArray()
	while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk = client.read_response_body_chunk()
		if chunk.size() > 0:
			body.append_array(chunk)
		else:
			OS.delay_msec(5)

	client.close()
	if body.is_empty():
		return {"skipped": true, "error": "MCP HTTP response was empty."}

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "Invalid JSON-RPC response", "body": body.get_string_from_utf8()}
	return parsed

func remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir_path = path.get_base_dir()
		var file_name = path.get_file()
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.remove(file_name)

func _process_sse_buffer(target_id: int):
	var lines = sse_buffer.split("\n", false)
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		if line.begins_with("data: "):
			var json_str = line.substr(6).strip_edges()
			if json_str.length() > 0:
				var res = JSON.parse_string(json_str)
				if res and res is Dictionary and res.has("jsonrpc") and res.has("id"):
					if int(res["id"]) == target_id:
						# Found it! Flush line locally.
						sse_buffer = ""
						if res.has("result"):
							return {"ok": true, "result": res["result"]}
						elif res.has("error"):
							return {"error": true, "message": str(res["error"])}
	return null
