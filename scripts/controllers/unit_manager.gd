class_name UnitManager
extends Node

@export var archer_scene: PackedScene = preload("res://scenes/units/archer.tscn")
@export var soldier_scene: PackedScene = preload("res://scenes/units/soldier.tscn")
@export var veteran_archer_scene: PackedScene = preload("res://scenes/units/veteran_archer.tscn")
@export var veteran_soldier_scene: PackedScene = preload("res://scenes/units/veteran_soldier.tscn")

var _units_node: Node2D
var _resource_manager: Node

func _ready() -> void:
	add_to_group("unit_manager")
	_units_node = _get_or_create_units_node()
	_resource_manager = get_parent().get_node_or_null("ResourceManager")

func _get_or_create_units_node() -> Node2D:
	if has_node("Units"):
		return get_node("Units")
	var units_container = Node2D.new()
	units_container.name = "Units"
	add_child(units_container)
	return units_container

func get_units_node() -> Node2D:
	return _units_node

func recruit_unit(unit_type: String, spawn_position: Vector2) -> bool:
	if not _resource_manager:
		return false
	if not _resource_manager.purchase_unit(unit_type):
		return false
	var scene = _scene_for_type(unit_type)
	if not scene:
		return false
	var unit = _create_and_setup_unit(scene, unit_type, spawn_position)
	if unit:
		_units_node.add_child(unit)
	return unit != null

func register_placed_unit(unit: Node2D, unit_type: String) -> void:
	if not is_instance_valid(unit):
		return
	if unit.get_parent() != _units_node:
		var pos = unit.global_position
		unit.get_parent().remove_child(unit)
		_units_node.add_child(unit)
		unit.global_position = pos
	_configure_unit_metadata(unit, unit_type)
	_apply_projectile_to_archer(unit, unit_type)

func heal_all_units(heal_percentage: float) -> void:
	if not is_instance_valid(_units_node):
		return
	for unit in _units_node.get_children():
		if unit.has_method("heal"):
			unit.heal(heal_percentage)

func save_state() -> Array:
	var state: Array = []
	for unit in _units_node.get_children():
		if unit is Node2D:
			var unit_type = unit.get_meta("unit_type") if unit.has_meta("unit_type") else ""
			if not unit_type.is_empty():
				state.append({
					"type": unit_type,
					"position": unit.global_position
				})
	return state

func restore_state(units_state: Array, clear_existing: bool = true) -> void:
	if not is_instance_valid(_units_node):
		return
	if clear_existing:
		for child in _units_node.get_children():
			child.queue_free()
	
	for unit_data in units_state:
		if unit_data is Dictionary:
			_restore_unit_from_data(unit_data)

func _restore_unit_from_data(unit_data: Dictionary) -> void:
	var unit_type = unit_data.get("type", "")
	var position = unit_data.get("position", Vector2.ZERO)
	var scene = _scene_for_type(unit_type)
	if not scene:
		return
	var unit = _create_and_setup_unit(scene, unit_type, position)
	if unit:
		_units_node.add_child(unit)

func _scene_for_type(unit_type: String) -> PackedScene:
	match unit_type:
		"archer":
			return archer_scene
		"soldier":
			return soldier_scene
		"veteran_archer":
			return veteran_archer_scene
		"veteran_soldier":
			return veteran_soldier_scene
	return null

func _create_and_setup_unit(scene: PackedScene, unit_type: String, position: Vector2) -> Node2D:
	var unit = scene.instantiate() as Node2D
	if not unit:
		return null
	unit.global_position = position
	_configure_unit_metadata(unit, unit_type)
	_apply_projectile_to_archer(unit, unit_type)
	return unit

func _configure_unit_metadata(unit: Node, unit_type: String) -> void:
	unit.set_meta("unit_type", unit_type)
	unit.add_to_group("friendly_units")
	if unit_type == "soldier":
		unit.add_to_group("soldiers")

func _apply_projectile_to_archer(unit: Node, unit_type: String) -> void:
	if unit_type != "archer" or not "projectile_scene" in unit:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and "projectile_scene" in player and player.projectile_scene:
		unit.projectile_scene = player.projectile_scene
