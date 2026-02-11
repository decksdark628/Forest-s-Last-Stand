extends Area2D

@export var speed: float = 800.0
@export var damage: int = 10
@export var max_distance: float = 1500.0

@onready var lifetime_timer: Timer = $LifetimeTimer

var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO
var has_hit: bool = false

func _ready() -> void:
	add_to_group("projectiles")
	await get_tree().process_frame
	_initialize_projectile()
	_connect_signals()

func _initialize_projectile() -> void:
	start_position = global_position
	direction = Vector2.RIGHT.rotated(rotation)
	velocity = direction * speed

func _connect_signals() -> void:
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	if _exceeded_max_distance():
		queue_free()

func _exceeded_max_distance() -> bool:
	return global_position.distance_to(start_position) > max_distance

func _on_lifetime_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node) -> void:
	if has_hit:
		return
	_handle_body_collision(body)

func _handle_body_collision(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		has_hit = true
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group("player") and not body.is_in_group("projectiles"):
		has_hit = true
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	_handle_area_collision(area)

func _handle_area_collision(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage"):
		has_hit = true
		parent.take_damage(damage)
		queue_free()
