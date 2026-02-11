class_name DirectionUtils
extends RefCounted

enum Direction { E, SE, S, SW, W, NW, N, NE }

const DIRECTION_NAMES: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
static func vector_to_direction_name(dir: Vector2) -> String:
	if dir.length_squared() < 0.01:
		return "s"  # Default direction
	
	var angle = dir.angle()
	if angle < 0:
		angle += TAU
	var normalized_angle = fmod(angle + PI / 8, TAU)
	var index = int(normalized_angle / (PI / 4))
	
	return DIRECTION_NAMES[clampi(index, 0, 7)]
static func vector_to_direction(dir: Vector2) -> Direction:
	if dir.length_squared() < 0.01:
		return Direction.S
	
	var angle = dir.angle()
	if angle < 0:
		angle += TAU
	
	var normalized_angle = fmod(angle + PI / 8, TAU)
	var index = int(normalized_angle / (PI / 4))
	
	return index as Direction
static func get_animation_name(prefix: String, dir: Vector2) -> String:
	return "%s_%s" % [prefix, vector_to_direction_name(dir)]
