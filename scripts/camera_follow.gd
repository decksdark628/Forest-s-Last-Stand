extends Camera2D

@export var follow_target: NodePath
@export var smoothing_enabled: bool = true
@export var smoothing_speed: float = 5.0
@export var tilemap: TileMapLayer

var target: Node2D = null

func _ready() -> void:
	add_to_group("camera")
	_acquire_target()
	_initialize_position()
	_setup_camera_limits()

func _acquire_target() -> void:
	target = get_node_or_null(follow_target) if follow_target else get_tree().get_first_node_in_group("player")

func _initialize_position() -> void:
	if target:
		global_position = target.global_position

func _setup_camera_limits() -> void:
	if is_instance_valid(tilemap):
		call_deferred("_apply_tilemap_camera_limits")

func _apply_tilemap_camera_limits() -> void:
	if not tilemap:
		return
	
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	
	limit_left = used_rect.position.x * tile_size.x
	limit_top = used_rect.position.y * tile_size.y
	limit_right = (used_rect.position.x + used_rect.size.x) * tile_size.x
	limit_bottom = (used_rect.position.y + used_rect.size.y) * tile_size.y

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	if smoothing_enabled:
		global_position = global_position.lerp(target.global_position, smoothing_speed * delta)
	else:
		global_position = target.global_position
