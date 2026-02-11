extends Node
class_name HealthComponent

@export var max_health: int = 100
@onready var current_health: int = max_health

signal health_changed(new_health: int, max_health: int)
signal died

func _ready():
	health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)
