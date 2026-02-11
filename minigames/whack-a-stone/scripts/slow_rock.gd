extends Rock

const APPEAR_ANIM_TIME:float = 2.0
const WAITING_TIME:float = 1.5
const START_POS:Vector2 = Vector2(124, 290)
const END_POS:Vector2 = Vector2(124, 164)
const MAX_HP:int = 10

@onready var hb_top: CollisionShape2D = $Hitbox/Area2D/HBTop
@onready var hb_bottom: CollisionShape2D = $Hitbox/Area2D/HBBottom

func _ready() -> void:
	hp = MAX_HP
	var tw = create_tween()
	tw.tween_property(
		visuals,
		"position:y",
		END_POS.y,
		APPEAR_ANIM_TIME
	)
	tw.tween_interval(WAITING_TIME)
	tw.tween_property(
		visuals,
		"position:y",
		START_POS.y,
		APPEAR_ANIM_TIME
	)
	
	var rand_wait:float = randf_range(2, 7)
	await get_tree().create_timer(rand_wait).timeout
	_free_hole()
	queue_free()
