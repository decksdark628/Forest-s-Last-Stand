extends Node
class_name AnimationComponent

@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path) if has_node(animated_sprite_path) else get_parent().get_node_or_null("AnimatedSprite2D")

var last_direction: Vector2 = Vector2(0, 1)
var is_casting: bool = false
var is_dying: bool = false

const ANIMATION_DIRECTION_SUFFIXES: PackedStringArray = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
const ANIMATION_DEFAULT_DURATION: float = 0.6

func update_animation(direction: Vector2, is_attacking: bool = false, attack_target: Node2D = null) -> void:
	if not animated_sprite or is_casting or is_dying:
		return
	if direction.length() > 0:
		last_direction = direction
	var animation_name = _get_animation_name(direction, is_attacking, attack_target)
	_play_animation(animation_name)

func _get_animation_name(direction: Vector2, is_attacking: bool, attack_target: Node2D) -> String:
	if is_attacking:
		return _get_attack_animation_name(direction, attack_target)
	if direction.length() > 0:
		return _get_movement_animation_name(direction)
	return _get_idle_animation_name(last_direction)

func _get_idle_animation_name(direction: Vector2) -> String:
	var suffix = get_direction_suffix(direction)
	var animation_name = "idle_" + suffix
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		animation_name = "idle" if animated_sprite.sprite_frames.has_animation("idle") else "idle_s"
	return animation_name

func _get_movement_animation_name(direction: Vector2) -> String:
	return "walk_" + get_direction_suffix(direction)

func _get_attack_animation_name(direction: Vector2, attack_target: Node2D) -> String:
	var attack_dir = direction
	if attack_target and is_instance_valid(attack_target):
		attack_dir = (attack_target.global_position - get_parent().global_position).normalized()
	elif direction.length() == 0:
		attack_dir = last_direction
	
	var attack_suffix = get_direction_suffix(attack_dir)
	var animation_name = "attack_" + attack_suffix
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		animation_name = "attack_s" if animated_sprite.sprite_frames.has_animation("attack_s") else animation_name
	return animation_name

func _play_animation(animation_name: String) -> void:
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)

func play_death() -> void:
	if not animated_sprite:
		return
	is_dying = true
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.stop()
		animated_sprite.play("death")
		await animated_sprite.animation_finished

func play_cast(direction: Vector2) -> void:
	if not animated_sprite:
		return
	is_casting = true
	
	var suffix = get_direction_suffix(direction)
	var anim_name = "cast_" + suffix
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "attack_" + suffix
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var duration = _calculate_animation_duration(anim_name)
		await get_tree().create_timer(duration).timeout
	else:
		await get_tree().create_timer(ANIMATION_DEFAULT_DURATION).timeout
	
	is_casting = false
	update_animation(direction if direction.length() > 0 else last_direction)

func get_direction_suffix(angle_or_vector) -> String:
	var angle = _extract_angle(angle_or_vector)
	return ANIMATION_DIRECTION_SUFFIXES[_get_direction_index(angle)]

func _extract_angle(angle_or_vector) -> float:
	if angle_or_vector is Vector2:
		return angle_or_vector.angle()
	elif angle_or_vector is float or angle_or_vector is int:
		return float(angle_or_vector)
	return 0.0

func _get_direction_index(angle: float) -> int:
	var normalized_angle = fmod(angle + PI / 8, 2 * PI)
	if normalized_angle < 0:
		normalized_angle += 2 * PI
	var index = int(normalized_angle / (PI / 4))
	return index % 8

func _calculate_animation_duration(anim_name: String) -> float:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return ANIMATION_DEFAULT_DURATION
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return ANIMATION_DEFAULT_DURATION
	
	var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
	var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
	if fps <= 0:
		fps = 5.0
	
	var total_duration: float = 0.0
	for i in range(frame_count):
		total_duration += animated_sprite.sprite_frames.get_frame_duration(anim_name, i) / fps
	return total_duration
