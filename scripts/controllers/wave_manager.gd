class_name WaveManager
extends Node
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemies_remaining_updated(count: int)
signal enemy_died(enemy)
signal enemy_reached_end()
@export var max_enemies_allowed: int = 3
@export var time_between_waves: float = 30.0
@export var initial_wave_delay: float = 5.0
var current_wave: int = 0
var enemies_remaining: int = 0
var is_wave_active: bool = false
var wave_timer: float = 0.0
var spawners: Array = []
@onready var enemies_node: Node2D = get_node_or_null("../Enemies") as Node2D
var enemy_scenes: Dictionary = {}

func _ready() -> void:
	set_process(false)
	for enemy_type in EnemyConfig.ENEMIES:
		var path = EnemyConfig.ENEMIES[enemy_type].scene
		if not enemy_scenes.has(path):
			enemy_scenes[path] = load(path)
func start_wave_for_day(day: int) -> void:
	current_wave = day
	is_wave_active = true
	var data = load_wave_data(current_wave)
	enemies_remaining = data.enemy_count
	wave_started.emit(current_wave)
	enemies_remaining_updated.emit(enemies_remaining)
	var spawners = get_tree().get_nodes_in_group("spawn_points")
	if spawners.is_empty():
		push_error("No se encontraron nodos con el grupo 'spawn_points'")
		return

	var per_spawner = int(ceil(float(enemies_remaining) / spawners.size()))
	var remaining = enemies_remaining

	for spawner in spawners:
		var to_spawn = min(per_spawner, remaining)
		if to_spawn <= 0:
			break
		_configure_spawner(spawner, data, to_spawn)
		remaining -= to_spawn
func _spawn_enemies(count: int) -> void:
	var active_spawners = _get_active_spawners()
	if active_spawners.is_empty():
		push_error("No hay spawners activos")
		return
	
	for i in range(count):
		var spawner = active_spawners[randi() % active_spawners.size()]
		var enemy_type = _get_random_enemy_type()
		var enemy_scene = enemy_scenes[EnemyConfig.ENEMIES[enemy_type].scene]
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawner.global_position
		var config = EnemyConfig.ENEMIES[enemy_type]
		enemy.health = config.health
		enemy.speed = config.speed
		enemy.damage = config.damage
		enemy.gold_value = config.gold_drop
		enemy.set_meta("enemy_type", enemy_type)
		enemies_node.add_child(enemy)
		await get_tree().create_timer(0.5).timeout
func load_wave_data(wave: int) -> Dictionary:
	var types = EnemyConfig.types_for_wave(wave)
	var count = EnemyConfig.enemy_count_for_wave(wave)
	var rate = EnemyConfig.spawn_rate_for_wave(wave)
	return {"enemy_count": count, "enemy_types": types, "spawn_rate": rate}
func _configure_spawner(spawner, data: Dictionary, count: int) -> void:
	var enemy_type = data.enemy_types[randi() % data.enemy_types.size()]

	var scene_path = EnemyConfig.ENEMIES[enemy_type].scene
	if not enemy_scenes.has(scene_path):
		enemy_scenes[scene_path] = load(scene_path)

	spawner.enemy_scene = enemy_scenes[scene_path]
	spawner.spawn_delay = data.spawn_rate
	spawner.spawn_count = count
	if spawner.all_enemies_spawned.is_connected(_on_all_enemies_spawned):
		spawner.all_enemies_spawned.disconnect(_on_all_enemies_spawned)
	if spawner.enemy_died.is_connected(_on_spawner_enemy_died):
		spawner.enemy_died.disconnect(_on_spawner_enemy_died)
	if spawner.enemy_reached_end.is_connected(_on_spawner_enemy_reached_end):
		spawner.enemy_reached_end.disconnect(_on_spawner_enemy_reached_end)

	spawner.all_enemies_spawned.connect(_on_all_enemies_spawned.bind(spawner))
	spawner.enemy_died.connect(_on_spawner_enemy_died)
	spawner.enemy_reached_end.connect(_on_spawner_enemy_reached_end)

	spawner.start_spawning({
		"wave_number": current_wave,
		"enemy_count": count,
		"enemy_type": enemy_type
	})
func _get_random_enemy_type() -> String:
	var types = EnemyConfig.types_for_wave(current_wave)
	return EnemyConfig.random_type_weighted(types)
func _on_spawner_enemy_died(enemy: Node2D = null) -> void:
	if enemy != null:
		enemy_died.emit(enemy)
	enemies_remaining -= 1
	enemies_remaining_updated.emit(enemies_remaining)
	if enemies_remaining <= 0:
		_wave_completed()
func _on_spawner_enemy_reached_end() -> void:
	enemy_reached_end.emit()
	enemies_remaining -= 1
	enemies_remaining_updated.emit(enemies_remaining)
	if enemies_remaining <= 0:
		_wave_completed()
func _wave_completed() -> void:
	is_wave_active = false
	wave_timer = time_between_waves
	wave_completed.emit(current_wave)
func _get_active_spawners() -> Array:
	if spawners.is_empty():
		spawners = get_tree().get_nodes_in_group("spawn_points")
	return spawners

func _on_all_enemies_spawned(spawner) -> void:
	if spawner.all_enemies_spawned.is_connected(_on_all_enemies_spawned):
		spawner.all_enemies_spawned.disconnect(_on_all_enemies_spawned)
func reset() -> void:
	current_wave = 0
	enemies_remaining = 0
	is_wave_active = false
	wave_timer = initial_wave_delay
