extends RefCounted
class_name MCPTestAdapter

static func create(_parent: Node = null):
	return load("res://tests/mcp_test_adapter.gd").new()

const PROTOCOL_VERSION := "2024-11-05"
const STREAMABLE_ACCEPT := "application/json, text/event-stream"

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

var streamable_session_id := ""
var streamable_get_client : HTTPClient
var streamable_get_buffer := ""

func setup_sync():
	mcp_server = JustAMCPServer.new()
	tool_executor = JustAMCPToolExecutor.new()
	prompt_executor = JustAMCPPromptExecutor.new()
	resource_executor = JustAMCPResourceExecutor.new()
	mcp_server.tool_requested.connect(_on_tool_requested)

	sse_client = HTTPClient.new()
	var err = sse_client.connect_to_host(host, port)
	if err != OK:
		print("Failed to initialize sync HTTP client")
		return

	while sse_client.get_status() == HTTPClient.STATUS_CONNECTING or sse_client.get_status() == HTTPClient.STATUS_RESOLVING:
		sse_client.poll()
		OS.delay_msec(1)

	if sse_client.get_status() != HTTPClient.STATUS_CONNECTED:
		return

	err = sse_client.request(HTTPClient.METHOD_GET, "/sse", ["Accept: text/event-stream"])
	if err != OK:
		print("Failed to request SSE Stream")
		return

	while sse_client.get_status() == HTTPClient.STATUS_REQUESTING:
		sse_client.poll()
		OS.delay_msec(1)

	if sse_client.get_status() != HTTPClient.STATUS_BODY:
		print("Failed asserting SSE Body natively: ", sse_client.get_status())
		return
	http_available = true

func cleanup() -> void:
	if streamable_get_client:
		streamable_get_client.close()
		streamable_get_client = null
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
	streamable_session_id = ""

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
	return http_jsonrpc_stateless(method, params, timeout_msec)

func http_jsonrpc_stateless(method: String, params: Dictionary = {}, timeout_msec: int = 1000) -> Dictionary:
	var client := HTTPClient.new()
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
	var headers := ["Content-Type: application/json"]
	err = client.request(HTTPClient.METHOD_POST, "/mcp", headers, JSON.stringify(payload))
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

func streamable_initialize(timeout_msec: int = 3000) -> Dictionary:
	var client := HTTPClient.new()
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
		"method": "initialize",
		"params": {
			"protocolVersion": PROTOCOL_VERSION,
			"capabilities": {},
			"clientInfo": {"name": "justamcp_module_tests", "version": "1.0"},
		},
	}
	var headers := [
		"Content-Type: application/json",
		"Accept: " + STREAMABLE_ACCEPT,
		"MCP-Protocol-Version: " + PROTOCOL_VERSION,
	]
	err = client.request(HTTPClient.METHOD_POST, "/mcp", headers, JSON.stringify(payload))
	if err != OK:
		client.close()
		return {"skipped": true, "error": "streamable initialize failed to start."}

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

	var session_id := _extract_header_value(client.get_response_headers(), "MCP-Session-Id")
	client.close()

	if session_id.is_empty():
		return {"skipped": true, "error": "initialize did not return MCP-Session-Id"}
	streamable_session_id = session_id

	if body.is_empty():
		return {"skipped": true, "error": "streamable initialize returned empty body."}
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "Invalid JSON-RPC response", "body": body.get_string_from_utf8()}
	return parsed

func streamable_jsonrpc(method: String, params: Dictionary = {}, timeout_msec: int = 5000, use_sse_response: bool = false) -> Dictionary:
	if streamable_session_id.is_empty():
		var init_res = streamable_initialize(timeout_msec)
		if init_res.get("skipped", false) or init_res.has("error"):
			return init_res

	var client := HTTPClient.new()
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
	var headers := [
		"Content-Type: application/json",
		"MCP-Session-Id: " + streamable_session_id,
		"MCP-Protocol-Version: " + PROTOCOL_VERSION,
	]
	if use_sse_response:
		headers.append("Accept: " + STREAMABLE_ACCEPT)
	else:
		headers.append("Accept: application/json")

	err = client.request(HTTPClient.METHOD_POST, "/mcp", headers, JSON.stringify(payload))
	if err != OK:
		client.close()
		return {"skipped": true, "error": "streamable request failed to start."}

	while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	var body := PackedByteArray()
	var sse_acc := ""
	while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_BODY:
		client.poll()
		var chunk = client.read_response_body_chunk()
		if chunk.size() > 0:
			var text = chunk.get_string_from_utf8()
			body.append_array(chunk)
			if use_sse_response or text.contains("data:"):
				sse_acc += text
		else:
			OS.delay_msec(5)

	var session_hdr := _extract_header_value(client.get_response_headers(), "MCP-Session-Id")
	if not session_hdr.is_empty():
		streamable_session_id = session_hdr
	client.close()

	if not sse_acc.is_empty():
		var rpc = _parse_sse_jsonrpc_for_id(sse_acc, req_id)
		if rpc != null:
			return rpc

	if body.is_empty():
		return {"skipped": true, "error": "streamable response was empty."}

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"error": "Invalid JSON-RPC response", "body": body.get_string_from_utf8()}
	return parsed

func streamable_send_notification(method: String, params: Dictionary = {}) -> Dictionary:
	return streamable_jsonrpc(method, params, 2000, false)

func streamable_open_get_stream(last_event_id: String = "", timeout_msec: int = 3000) -> Dictionary:
	if streamable_session_id.is_empty():
		var init_res = streamable_initialize(timeout_msec)
		if init_res.get("skipped", false) or init_res.has("error"):
			return init_res

	if streamable_get_client:
		streamable_get_client.close()
	streamable_get_client = HTTPClient.new()
	streamable_get_buffer = ""

	var err = streamable_get_client.connect_to_host(host, port)
	if err != OK:
		return {"skipped": true, "error": "GET stream connect failed."}

	var deadline = Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline and (streamable_get_client.get_status() == HTTPClient.STATUS_CONNECTING or streamable_get_client.get_status() == HTTPClient.STATUS_RESOLVING):
		streamable_get_client.poll()
		OS.delay_msec(5)

	if streamable_get_client.get_status() != HTTPClient.STATUS_CONNECTED:
		streamable_get_client.close()
		streamable_get_client = null
		return {"skipped": true, "error": "GET stream not connected."}

	var headers := [
		"Accept: text/event-stream",
		"MCP-Session-Id: " + streamable_session_id,
		"MCP-Protocol-Version: " + PROTOCOL_VERSION,
	]
	if not last_event_id.is_empty():
		headers.append("Last-Event-ID: " + last_event_id)

	err = streamable_get_client.request(HTTPClient.METHOD_GET, "/mcp", headers)
	if err != OK:
		streamable_get_client.close()
		streamable_get_client = null
		return {"skipped": true, "error": "GET /mcp request failed."}

	while Time.get_ticks_msec() < deadline and streamable_get_client.get_status() == HTTPClient.STATUS_REQUESTING:
		streamable_get_client.poll()
		OS.delay_msec(5)

	if streamable_get_client.get_status() != HTTPClient.STATUS_BODY:
		streamable_get_client.close()
		streamable_get_client = null
		return {"skipped": true, "error": "GET stream did not enter body state."}

	return {"ok": true}

func streamable_poll_get_events(timeout_msec: int = 2000) -> Dictionary:
	if not streamable_get_client or streamable_get_client.get_status() != HTTPClient.STATUS_BODY:
		return {"events": [], "raw": ""}

	var deadline = Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline:
		streamable_get_client.poll()
		var chunk = streamable_get_client.read_response_body_chunk()
		if chunk.size() > 0:
			streamable_get_buffer += chunk.get_string_from_utf8()
		else:
			OS.delay_msec(5)

	return _parse_sse_events(streamable_get_buffer)

func streamable_delete_session(timeout_msec: int = 2000) -> Dictionary:
	if streamable_session_id.is_empty():
		return {"skipped": true, "error": "No streamable session."}

	var client := HTTPClient.new()
	var err = client.connect_to_host(host, port)
	if err != OK:
		return {"skipped": true, "error": "DELETE connect failed."}

	var deadline = Time.get_ticks_msec() + timeout_msec
	while Time.get_ticks_msec() < deadline and (client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING):
		client.poll()
		OS.delay_msec(5)

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.close()
		return {"skipped": true, "error": "DELETE not connected."}

	var headers := [
		"MCP-Session-Id: " + streamable_session_id,
		"MCP-Protocol-Version: " + PROTOCOL_VERSION,
	]
	err = client.request(HTTPClient.METHOD_DELETE, "/mcp", headers)
	if err != OK:
		client.close()
		return {"skipped": true, "error": "DELETE request failed."}

	while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		OS.delay_msec(5)

	var status_code := client.get_response_code()
	client.close()
	streamable_session_id = ""
	return {"ok": true, "status_code": status_code}

func collect_all_pages(method: String, result_key: String, id_key: String = "name", timeout_msec: int = 8000) -> Dictionary:
	var all_items: Array = []
	var seen_ids := {}
	var cursor := ""

	while true:
		var params := {}
		if not cursor.is_empty():
			params["cursor"] = cursor
		var response = http_jsonrpc_stateless(method, params, timeout_msec)
		if response.get("skipped", false):
			return response
		if response.has("error"):
			return response
		if not response.has("result"):
			return {"error": "missing result for " + method}

		var result: Dictionary = response["result"]
		var page: Array = result.get(result_key, [])
		for item in page:
			var item_dict = item as Dictionary
			var item_id := str(item_dict.get(id_key, item_dict.get("uri", item_dict.get("taskId", ""))))
			if not seen_ids.has(item_id):
				seen_ids[item_id] = true
				all_items.append(item)

		if not result.has("nextCursor") or str(result["nextCursor"]).is_empty():
			break
		cursor = str(result["nextCursor"])

	return {"ok": true, "items": all_items, "count": all_items.size()}

func call_tool_task_augmented(tool_name: String, args: Dictionary = {}, task_opts: Dictionary = {}, timeout_msec: int = 15000) -> Dictionary:
	var params := {
		"name": tool_name,
		"arguments": args,
		"task": task_opts,
	}
	return http_jsonrpc_stateless("tools/call", params, timeout_msec)

func remove_file_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		var dir_path = path.get_base_dir()
		var file_name = path.get_file()
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.remove(file_name)

func _extract_header_value(headers: PackedStringArray, header_name: String) -> String:
	var prefix := header_name + ":"
	for i in range(headers.size()):
		var line := str(headers[i])
		if line.begins_with(prefix):
			return line.substr(prefix.length()).strip_edges()
	return ""

func _parse_sse_jsonrpc_for_id(raw: String, target_id: int):
	var lines = raw.split("\n", false)
	for line in lines:
		line = line.strip_edges()
		if line.begins_with("data: "):
			var json_str = line.substr(6).strip_edges()
			if json_str.is_empty():
				continue
			var res = JSON.parse_string(json_str)
			if res is Dictionary and res.has("jsonrpc"):
				if res.has("id") and int(res["id"]) == target_id:
					return res
	return null

func _parse_sse_events(raw: String) -> Dictionary:
	var events: Array = []
	var current_id := ""
	var current_type := ""
	var current_data := ""

	for line in raw.split("\n", false):
		line = line.strip_edges()
		if line.is_empty():
			if not current_data.is_empty() or not current_id.is_empty():
				events.append({
					"id": current_id,
					"event": current_type,
					"data": current_data,
				})
			current_id = ""
			current_type = ""
			current_data = ""
			continue
		if line.begins_with("id:"):
			current_id = line.substr(3).strip_edges()
		elif line.begins_with("event:"):
			current_type = line.substr(6).strip_edges()
		elif line.begins_with("data:"):
			var chunk = line.substr(5).strip_edges()
			if not current_data.is_empty():
				current_data += "\n"
			current_data += chunk

	if not current_data.is_empty() or not current_id.is_empty():
		events.append({
			"id": current_id,
			"event": current_type,
			"data": current_data,
		})

	return {"events": events, "raw": raw}

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
						sse_buffer = ""
						if res.has("result"):
							return {"ok": true, "result": res["result"]}
						elif res.has("error"):
							return {"error": true, "message": str(res["error"])}
	return null
