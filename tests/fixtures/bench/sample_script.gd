@tool
extends Node2D

signal fixture_ready

func fixture_method() -> void:
	fixture_ready.emit()

func _ready() -> void:
	if Engine.has_singleton("JustAMCPRuntime"):
		Engine.get_singleton("JustAMCPRuntime").register_custom_command("TestNode", _bench_command)

func _bench_command(_value = null) -> Dictionary:
	return {"ok": true}
