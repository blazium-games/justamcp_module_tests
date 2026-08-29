# Justamcp Module Tests

A test suite and example project for the **Justamcp** module built for the Blazium Engine.

## Features

- Fully integrated with the native C++ **Autowork** testing framework.
- Executes tests in headless mode.
- Covers editor MCP on port **6506** and project-owned tools registered from `res://mcp`.
- Documents the game HTTP host on **6507** (editor port + 1) and the opt-in `--enable-mcp` flags.

## Running Tests

To run the test suite natively:

```bash
blazium --headless -s run_tests.gd
```

Autowork (`--aw-*`), `--test`, and `--export*` skip MCP unless you also pass `--enable-mcp` or `--enable-mcp-game-control`. This project's runner starts the editor host itself when needed.

## Project-owned MCP tools

JustAMCP loads `register.gd` and/or `register.luau` from `blazium/justamcp/project_mcp_dir` (default `res://mcp`) when the **game** HTTP host starts. Scripts implement `register()` and call:

```gdscript
extends Node

func register() -> void:
    JustAMCPRuntime.register_tool("echo", "Echo text", {
        "type": "object",
        "properties": {"text": {"type": "string"}},
    }, func(args):
        return args.get("text", "")
    )
    JustAMCPRuntime.register_prompt("hello", "Greet the player", func(args):
        return "hello " + str(args.get("name", "world"))
    )
```

`register_custom_command` stays on the TCP game-control bridge. MCP clients should point the editor host at `http://127.0.0.1:6506/mcp` and the game host at `http://127.0.0.1:6507/mcp`.
