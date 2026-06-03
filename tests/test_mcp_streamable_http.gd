extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func test_streamable_initialize_returns_session() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.streamable_initialize(5000)
	if init_res.get("skipped", false):
		print("Skipping streamable HTTP tests: " + str(init_res.get("error", "")))
		adapter.cleanup()
		return

	assert_false(adapter.streamable_session_id.is_empty(), "streamable initialize should set session id")
	assert_true(init_res.has("result"), "streamable initialize should return JSON-RPC result")
	adapter.cleanup()

func test_streamable_get_stream_receives_events() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.streamable_initialize(5000)
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	adapter.streamable_send_notification("notifications/initialized", {})

	var open_res = adapter.streamable_open_get_stream("", 5000)
	if open_res.get("skipped", false):
		adapter.cleanup()
		return

	var polled = adapter.streamable_poll_get_events(3000)
	var events: Array = polled.get("events", [])
	assert_gt(events.size(), 0, "GET /mcp stream should deliver at least one SSE event")

	adapter.cleanup()

func test_streamable_delete_session_invalidates_session() -> void:
	var adapter = MCPTestAdapter.create()
	var init_res = adapter.streamable_initialize(5000)
	if init_res.get("skipped", false):
		adapter.cleanup()
		return

	var session_id: String = adapter.streamable_session_id
	var del_res = adapter.streamable_delete_session(3000)
	assert_true(del_res.get("ok", false), "DELETE /mcp should complete")

	var client := HTTPClient.new()
	client.connect_to_host(adapter.host, adapter.port)
	var deadline = Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline and (client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING):
		client.poll()
		OS.delay_msec(5)

	if client.get_status() == HTTPClient.STATUS_CONNECTED:
		var payload = JSON.stringify({
			"jsonrpc": "2.0",
			"id": 99,
			"method": "ping",
			"params": {},
		})
		var headers := [
			"Content-Type: application/json",
			"Accept: application/json, text/event-stream",
			"MCP-Session-Id: " + session_id,
			"MCP-Protocol-Version: 2024-11-05",
		]
		client.request(HTTPClient.METHOD_POST, "/mcp", headers, payload)
		while Time.get_ticks_msec() < deadline and client.get_status() == HTTPClient.STATUS_REQUESTING:
			client.poll()
			OS.delay_msec(5)
		var status_code := client.get_response_code()
		assert_true(status_code == 404 or status_code == 400, "Stale session should be rejected")
	client.close()

	adapter.cleanup()
