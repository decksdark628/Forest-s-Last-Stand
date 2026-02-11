class_name GridUtils
extends RefCounted
static func snap_to_grid(pos: Vector2, grid_size: int) -> Vector2:
	var gx := float(grid_size)
	return Vector2(
		floor(pos.x / gx) * gx + gx * 0.5,
		floor(pos.y / gx) * gx + gx * 0.5
	)
static func snap_to_grid_corner(pos: Vector2, grid_size: int) -> Vector2:
	var gx := float(grid_size)
	return Vector2(
		floor(pos.x / gx) * gx,
		floor(pos.y / gx) * gx
	)
static func world_to_cell(pos: Vector2, grid_size: int) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / grid_size)),
		int(floor(pos.y / grid_size))
	)
static func cell_to_world(cell: Vector2i, grid_size: int) -> Vector2:
	return Vector2(
		cell.x * grid_size + grid_size * 0.5,
		cell.y * grid_size + grid_size * 0.5
	)
