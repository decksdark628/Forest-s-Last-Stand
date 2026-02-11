extends Node
class_name AggroComponent

@export var enemy_type: String = "basic"

var aggro_targets: Array = []
var current_aggro_target: Node2D = null

func set_aggro_target(unit: Node2D) -> void:
	if enemy_type == "explorer":
		return
	if not aggro_targets.has(unit):
		aggro_targets.append(unit)
		_update_current_target()

func clear_aggro_target(unit: Node2D) -> void:
	aggro_targets.erase(unit)
	_update_current_target()

func get_current_target() -> Node2D:
	_update_current_target()
	return current_aggro_target

func has_aggro_targets() -> bool:
	_update_current_target()
	return current_aggro_target != null

func _update_current_target() -> void:
	aggro_targets = aggro_targets.filter(func(t): return is_instance_valid(t))
	current_aggro_target = aggro_targets[0] if aggro_targets.size() > 0 else null
