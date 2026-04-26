extends AutoworkTest

const MCPTestAdapter = preload("res://tests/mcp_test_adapter.gd")

func _write_temp_script() -> String:
	var path = "res://tests/temp_script_tool_subject.gd"
	var file = FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file, "Temp script should be writable")
	file.store_string("extends Node\nsignal probe_signal\nconst PROBE_VALUE = 1\nvar probe_var := 2\nfunc probe_method() -> int:\n\treturn PROBE_VALUE\n")
	file.close()
	return path

func test_find_symbols_patch_validate_and_search_script_tools() -> void:
	var adapter = MCPTestAdapter.new()
	add_child(adapter)
	adapter.setup_sync()

	var path = _write_temp_script()

	var symbols = adapter.execute_tool_direct("blazium_find_script_symbols", {"path": path})
	assert_true(symbols.get("ok", false), "find_script_symbols should succeed")
	assert_true(symbols.get("result", {}).get("count", 0) >= 4, "find_script_symbols should detect symbols in the temp script")

	var patch = adapter.execute_tool_direct("blazium_patch_script", {
		"path": path,
		"anchor": "return PROBE_VALUE",
		"replacement": "return PROBE_VALUE + 1",
	})
	assert_true(patch.get("ok", false), "patch_script should replace the anchored text")

	var validation = adapter.execute_tool_direct("blazium_validate_script", {"path": path})
	assert_true(validation.has("ok"), "validate_script should return ok")

	var errors = adapter.execute_tool_direct("blazium_get_script_errors", {"path": path})
	assert_true(errors.has("ok"), "get_script_errors should return ok")

	var search = adapter.execute_tool_direct("blazium_search_in_scripts", {"query": "PROBE_VALUE + 1", "path": "res://tests", "max_results": 10})
	assert_true(search.has("ok"), "search_in_scripts should return ok")

	adapter.remove_file_if_exists(path)
	adapter.queue_free()
