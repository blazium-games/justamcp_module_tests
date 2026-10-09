extends Node2D

signal fixture_ready

func fixture_method() -> void:
	fixture_ready.emit()
