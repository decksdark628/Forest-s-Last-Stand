extends CharacterBody2D

@export var speed: float = 90.0
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 0.75
@export var attack_animation_duration: float = 0.2
@export var shooting_speed_multiplier: float = 0.5

@export var muzzle_path: NodePath = NodePath("Muzzle")
@export var animation_component_path: NodePath = NodePath("AnimationComponent")
@export var shoot_timer_path: NodePath = NodePath("ShootTimer")
@export var sound_component_path: NodePath = NodePath("SoundComponent")

@onready var muzzle: Marker2D = get_node_or_null(muzzle_path) if has_node(muzzle_path) else null
@onready var animation_component: AnimationComponent = get_node_or_null(animation_component_path)
@onready var shoot_timer: Timer = get_node_or_null(shoot_timer_path)
@onready var sound_component: SoundComponent = get_node_or_null(sound_component_path)

var can_shoot: bool = true
var is_shooting: bool = false
var attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	if shoot_timer:
		shoot_timer.timeout.connect(_on_shoot_cooldown_timeout)

func _physics_process(delta: float) -> void:
	var input_vector = _get_movement_input()
	var current_speed = speed if not is_shooting else speed * shooting_speed_multiplier
	velocity = input_vector * current_speed
	move_and_slide()
	
	_update_attack_state(delta)
	_update_animation(input_vector)
	
	#if Input.is_action_pressed("shoot") and can_shoot and not _is_ui_hovered():
		#shoot()

func _get_movement_input() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return input_vector.normalized()

func _update_attack_state(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
		is_shooting = true
	else:
		is_shooting = false

func _update_animation(input_vector: Vector2) -> void:
	if not animation_component:
		return
	
	var anim_direction = input_vector
	if is_shooting:
		anim_direction = (get_global_mouse_position() - global_position).normalized()
	
	animation_component.update_animation(anim_direction, is_shooting)

func shoot() -> void:
	if not projectile_scene:
		return
	
	if sound_component:
		sound_component.play_attack()
	
	attack_timer = attack_animation_duration
	
	var shoot_direction = (get_global_mouse_position() - global_position).normalized()
	_spawn_projectile(shoot_direction)
	
	can_shoot = false
	shoot_timer.start()

func _spawn_projectile(direction: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = muzzle.global_position if muzzle else global_position
	projectile.rotation = direction.angle()
	_configure_projectile_collision(projectile)

func _configure_projectile_collision(projectile: Node2D) -> void:
	projectile.set_collision_layer_value(1, false)
	projectile.set_collision_mask_value(1, false)
	projectile.set_collision_mask_value(2, true)

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("shoot") and can_shoot and _can_shoot() and not _is_ui_hovered():
		#shoot()

func _can_shoot() -> bool:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		return true
	if gm.current_location != "world":
		return false
	if gm.placement_manager and gm.placement_manager.is_placing:
		return false
	return true

func _is_ui_hovered() -> bool:
	var viewport = get_viewport()
	return viewport and viewport.gui_get_hovered_control() != null

func play_cast_spell(direction: Vector2) -> void:
	if animation_component:
		animation_component.play_cast(direction)
