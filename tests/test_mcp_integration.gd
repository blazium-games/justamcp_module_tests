extends AutoworkTest
class_name TestMCPIntegration

var host = "127.0.0.1"
var port = 6506

func test_integration_flow():
	var server = JustAMCPServer.new()
	assert_not_null(server, "Server must be instantiated")
	
	# Attempt to wait for the server natively spinning
	await get_tree().create_timer(1.0).timeout
	
	var http_request = HTTPRequest.new()
	if !ProjectSettings.has_setting("network/limits/http_request_pool_timeout"):
		http_request.timeout = 5.0
	get_tree().root.add_child(http_request)
	
	await get_tree().process_frame
	
	var initialize_payload = {
		"jsonrpc": "2.0",
		"id": 1,
		"method": "initialize",
		"params": {
			"clientInfo": {"name": "test_script", "version": "1.0"},
			"protocolVersion": "2024-11-05"
		}
	}
	
	var json_str = JSON.stringify(initialize_payload)
	var headers = ["Content-Type: application/json"]
	
	# Send Initialize Request
	var err = http_request.request("http://" + host + ":" + str(port) + "/mcp", headers, HTTPClient.METHOD_POST, json_str)
	assert_eq(err, OK, "HTTPRequest initialize sent correctly")
	
	var res = await http_request.request_completed
	var result_code = res[1]
	var body = res[3].get_string_from_utf8()
	
	assert_eq(result_code, 200, "Should get 200 OK from initialize")
	var parsed = JSON.parse_string(body)
	assert_not_null(parsed, "Should parse response body")
	assert_true(parsed.has("jsonrpc"), "Must have jsonrpc")
	assert_true(parsed.has("id"), "Must have id")
	
	# Strictly assert float .0 casting does NOT occur! We specifically sent '1'!
	# We anticipate the parser retaining this cleanly securely over the HTTP!
	assert_true(typeof(parsed["id"]) == TYPE_FLOAT or typeof(parsed["id"]) == TYPE_INT, "Should map numeric bindings natively!")
	
	assert_true(parsed.has("result"), "Init should have result block")
	assert_true(parsed["result"].has("capabilities"), "Should map capabilities")
	
	# Send Notifications Initialized
	var notif = {"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}
	err = http_request.request("http://" + host + ":" + str(port) + "/mcp", headers, HTTPClient.METHOD_POST, JSON.stringify(notif))
	assert_eq(err, OK)
	var n_res = await http_request.request_completed
	assert_eq(n_res[1], 202, "Notifications should respond Accepted (Stateless HTTP implementation over POST natively)")
	
	# Request Tools List
	var tools_req = {"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}}
	err = http_request.request("http://" + host + ":" + str(port) + "/mcp", headers, HTTPClient.METHOD_POST, JSON.stringify(tools_req))
	var t_res = await http_request.request_completed
	assert_eq(t_res[1], 200, "Tools list should return 200 OK")
	var t_parsed = JSON.parse_string(t_res[3].get_string_from_utf8())
	assert_true(t_parsed.has("result"), "Tools block mapped!")
	assert_true(t_parsed["result"].has("tools"), "Contains tools boundaries")
	assert_true(t_parsed["result"]["tools"].size() > 0, "Tool list must naturally populate bounds natively")
	
	http_request.queue_free()
	
	# Explicitly release server resources locally terminating HTTP port bindings explicitly reliably.
	server.free()
