extends Control

const HEAL_COOLDOWN: float = 6.0
const SHIELD_COOLDOWN: float = 7.0
const SLOW_COOLDOWN: float = 10.0
const SHIELD_DURATION: float = 4.0
const SLOW_SPEED_MULT: float = 1.0 / 3.0
const SLOW_ZONE_DURATION: float = 5.0
const BUFF_COOLDOWN: float = 10.0
const BUFF_DURATION: float = 4.0

const SPELLS_SCENE_PATH: String = "res://scenes/elements/spells.tscn"

enum SpellMode { NONE, HEAL_SELECT, SHIELD_SELECT, SLOW_PLACE, BUFF_SELECT }

var spell_mode: SpellMode = SpellMode.NONE
var heal_cooldown_left: float = 0.0
var shield_cooldown_left: float = 0.0
var slow_cooldown_left: float = 0.0
var buff_cooldown_left: float = 0.0
var slow_ghost: Node2D = null
var spells_scene: PackedScene = null

@onready var heal_btn: Button = find_child("HealButton", true, false)
@onready var shield_btn: Button = find_child("ShieldButton", true, false)
@onready var slow_btn: Button = find_child("SlowButton", true, false)
@onready var buff_btn: Button = find_child("BuffButton", true, false)

@onready var heal_cd_label: Label = find_child("HealCooldown", true, false)
@onready var shield_cd_label: Label = find_child("ShieldCooldown", true, false)
@onready var slow_cd_label: Label = find_child("SlowCooldown", true, false)
@onready var buff_cd_label: Label = find_child("BuffCooldown", true, false)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	spells_scene = load(SPELLS_SCENE_PATH) as PackedScene
	if heal_btn:
			heal_btn.pressed.connect(_on_heal_pressed)
	if shield_btn:
			shield_btn.pressed.connect(_on_shield_pressed)
	if slow_btn:
			slow_btn.pressed.connect(_on_slow_pressed)
	if buff_btn:
			buff_btn.pressed.connect(_on_buff_pressed)

func _process(delta: float) -> void:
	if heal_cooldown_left > 0:
			heal_cooldown_left -= delta
			if heal_cooldown_left <= 0 and heal_btn:
					heal_btn.disabled = false
	if heal_cd_label:
			heal_cd_label.visible = heal_cooldown_left > 0
			heal_cd_label.text = str(ceil(heal_cooldown_left))

	if shield_cooldown_left > 0:
			shield_cooldown_left -= delta
			if shield_cooldown_left <= 0 and shield_btn:
					shield_btn.disabled = false
	if shield_cd_label:
			shield_cd_label.visible = shield_cooldown_left > 0
			shield_cd_label.text = str(ceil(shield_cooldown_left))

	if slow_cooldown_left > 0:
			slow_cooldown_left -= delta
			if slow_cooldown_left <= 0 and slow_btn:
					slow_btn.disabled = false
	if slow_cd_label:
			slow_cd_label.visible = slow_cooldown_left > 0
			slow_cd_label.text = str(ceil(slow_cooldown_left))

	if buff_cooldown_left > 0:
			buff_cooldown_left -= delta
			if buff_cooldown_left <= 0 and buff_btn:
					buff_btn.disabled = false
	if buff_cd_label:
			buff_cd_label.visible = buff_cooldown_left > 0
			buff_cd_label.text = str(ceil(buff_cooldown_left))

	if spell_mode == SpellMode.SLOW_PLACE and slow_ghost and is_instance_valid(slow_ghost):
			var world_pos := _get_world_mouse_position()
			if world_pos != Vector2.INF:
					slow_ghost.global_position = GridUtils.snap_to_grid(world_pos, 16)

func _input(event: InputEvent) -> void:
	if spell_mode == SpellMode.NONE:
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			spell_mode = SpellMode.NONE
			_remove_slow_ghost()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			spell_mode = SpellMode.NONE
			_remove_slow_ghost()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos: Vector2 = _get_world_position_from_event(event)
			if world_pos == Vector2.INF:
					return
			if spell_mode == SpellMode.HEAL_SELECT or spell_mode == SpellMode.SHIELD_SELECT or spell_mode == SpellMode.BUFF_SELECT:
					var unit := _get_friendly_unit_at_position(world_pos)
					if unit:
							_apply_unit_spell(unit)
							spell_mode = SpellMode.NONE
							get_viewport().set_input_as_handled()
			elif spell_mode == SpellMode.SLOW_PLACE:
					_place_slow_zone(world_pos)
					_remove_slow_ghost()
					spell_mode = SpellMode.NONE
					get_viewport().set_input_as_handled()
func _get_world_mouse_position() -> Vector2:
		var world = get_tree().current_scene
		if world:
				var vp = world.get_viewport()
				if vp:
						var mouse_screen = vp.get_mouse_position()
						var canvas_transform = vp.get_canvas_transform()
						var result = canvas_transform.affine_inverse() * mouse_screen
						return result
		var player = get_tree().get_first_node_in_group("player")
		if player and player is Node2D:
				return (player as Node2D).get_global_mouse_position()
		
		return Vector2.INF

func _get_world_position_from_event(_event: InputEventMouseButton) -> Vector2:
		return _get_world_mouse_position()

const UNIT_CLICK_RADIUS: float = 32.0  # Radio de detección al hacer click en una unidad (aprox tamaño sprite)

func _get_friendly_unit_at_position(world_pos: Vector2) -> Node2D:
		var friendly_units = get_tree().get_nodes_in_group("friendly_units")
		var player = get_tree().get_first_node_in_group("player")
		
		var best_unit: Node2D = null
		var best_dist: float = UNIT_CLICK_RADIUS
		for unit in friendly_units:
				if not is_instance_valid(unit) or not unit is Node2D:
						continue
				if "is_dying" in unit and unit.is_dying:
						continue
				if not unit.has_method("full_heal"):
						continue
				
				var dist = (unit as Node2D).global_position.distance_to(world_pos)
				if dist < best_dist:
						best_dist = dist
						best_unit = unit
		if player and is_instance_valid(player) and player is Node2D and player.has_method("full_heal"):
				var dist = (player as Node2D).global_position.distance_to(world_pos)
				if dist < best_dist:
						best_dist = dist
						best_unit = player
		
		return best_unit

func _play_spell_animation_on_unit(anim_name: String, unit: Node2D) -> void:
		if not spells_scene:
				return
		var spells = spells_scene.instantiate()
		var anim_node = spells.get_node_or_null(anim_name)
		if not anim_node:
				spells.queue_free()
				return
		var original_sprite: AnimatedSprite2D = anim_node.get_node_or_null("AnimatedSprite2D")
		if not original_sprite:
				spells.queue_free()
				return
		
		var world = get_tree().current_scene
		if not world is Node2D:
				spells.queue_free()
				return
		var target_pos: Vector2 = unit.global_position
		match anim_name:
				"Heal":
						target_pos.y -= 10 
				"Shield":
						pass  
		var sprite: AnimatedSprite2D = original_sprite.duplicate() as AnimatedSprite2D
		sprite.name = anim_name + "Effect"
		(world as Node2D).add_child(sprite)
		sprite.global_position = target_pos
		sprite.z_index = 100 
		
		sprite.play("Animation")
		var duration: float = _get_animation_duration(sprite)
		get_tree().create_timer(duration).timeout.connect(func():
				if is_instance_valid(sprite):
						sprite.queue_free()
		)
		spells.queue_free()

func _get_animation_duration(sprite: AnimatedSprite2D) -> float:
		if not sprite or not sprite.sprite_frames:
				return 1.5
		var anim_name = sprite.animation
		if not sprite.sprite_frames.has_animation(anim_name):
				return 1.5
		var frame_count = sprite.sprite_frames.get_frame_count(anim_name)
		var fps = sprite.sprite_frames.get_animation_speed(anim_name)
		if fps <= 0:
				fps = 10.0
		var total_duration: float = 0.0
		for i in range(frame_count):
				total_duration += sprite.sprite_frames.get_frame_duration(anim_name, i) / fps
		return total_duration

func _play_spell_animation_at_position(anim_name: String, pos: Vector2) -> void:
		if not spells_scene:
				return
		var spells = spells_scene.instantiate()
		var anim_node = spells.get_node_or_null(anim_name)
		if not anim_node:
				spells.queue_free()
				return
		var dup: Node = anim_node.duplicate()
		var world = get_tree().current_scene
		if not world is Node2D:
				spells.queue_free()
				return
		var container = Node2D.new()
		container.name = anim_name + "AreaEffect"
		container.add_child(dup)
		(world as Node2D).add_child(container)
		container.global_position = pos
		
		var sprite: AnimatedSprite2D = dup.get_node_or_null("AnimatedSprite2D")
		if sprite:
				sprite.play("Animation")
				var duration: float = _get_animation_duration(sprite)
				get_tree().create_timer(duration).timeout.connect(func():
						if is_instance_valid(container):
								container.queue_free()
				)
		else:
				get_tree().create_timer(2.0).timeout.connect(func():
						if is_instance_valid(container):
								container.queue_free()
				)
		spells.queue_free()

func _trigger_player_cast() -> void:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("play_cast_spell"):
				var mouse_pos = _get_world_mouse_position()
				var dir: Vector2 = mouse_pos - player.global_position
				if dir.length_squared() > 0.01:
						dir = dir.normalized()
				else:
						dir = Vector2.DOWN
				player.play_cast_spell(dir)

func _apply_unit_spell(unit: Node2D) -> void:
		if spell_mode == SpellMode.HEAL_SELECT:
				if unit.has_method("full_heal"):
						unit.full_heal()
				_play_spell_animation_on_unit("Heal", unit)
				_play_heal_sound()
				heal_cooldown_left = HEAL_COOLDOWN
				if heal_btn:
						heal_btn.disabled = true
		elif spell_mode == SpellMode.SHIELD_SELECT:
				if unit.has_method("set_invulnerable"):
						unit.set_invulnerable(SHIELD_DURATION)
				_play_spell_animation_on_unit("Shield", unit)
				_play_shield_sound()
				shield_cooldown_left = SHIELD_COOLDOWN
				if shield_btn:
						shield_btn.disabled = true
		elif spell_mode == SpellMode.BUFF_SELECT:
				if unit.has_method("set_buff"):
						unit.set_buff(BUFF_DURATION)
				_play_spell_animation_on_unit("Buff", unit)
				_play_buff_sound()
				buff_cooldown_left = BUFF_COOLDOWN
				if buff_btn:
						buff_btn.disabled = true
		_trigger_player_cast()

func _cancel_current_spell_mode() -> void:
		if spell_mode == SpellMode.SLOW_PLACE:
				_remove_slow_ghost()
		spell_mode = SpellMode.NONE

func _on_heal_pressed() -> void:
		if heal_cooldown_left > 0:
				return
		if spell_mode != SpellMode.NONE:
				_cancel_current_spell_mode()
		spell_mode = SpellMode.HEAL_SELECT

func _on_shield_pressed() -> void:
		if shield_cooldown_left > 0:
				return
		if spell_mode != SpellMode.NONE:
				_cancel_current_spell_mode()
		spell_mode = SpellMode.SHIELD_SELECT

func _on_buff_pressed() -> void:
		if buff_cooldown_left > 0:
				return
		if spell_mode != SpellMode.NONE:
				_cancel_current_spell_mode()
		spell_mode = SpellMode.BUFF_SELECT

func _on_slow_pressed() -> void:
		if slow_cooldown_left > 0:
				return
		if spell_mode != SpellMode.NONE:
				_cancel_current_spell_mode()
		spell_mode = SpellMode.SLOW_PLACE
		_show_slow_ghost()

func _show_slow_ghost() -> void:
		if not spells_scene:
				return
		var spells = spells_scene.instantiate()
		var slow_node = spells.get_node_or_null("Slow")
		if not slow_node:
				spells.queue_free()
				return
		var original_sprite: AnimatedSprite2D = slow_node.get_node_or_null("AnimatedSprite2D")
		if not original_sprite:
				spells.queue_free()
				return
		
		var world = get_tree().current_scene
		if not world is Node2D:
				spells.queue_free()
				return
		var ghost_sprite: AnimatedSprite2D = original_sprite.duplicate() as AnimatedSprite2D
		ghost_sprite.name = "SlowGhost"
		ghost_sprite.modulate = Color(0.5, 1.0, 0.5, 0.5)  # Verde semi-transparente
		ghost_sprite.z_index = 100
		(world as Node2D).add_child(ghost_sprite)
		var initial_pos: Vector2 = GridUtils.snap_to_grid(_get_world_mouse_position(), 16)
		ghost_sprite.global_position = initial_pos
		ghost_sprite.play("Animation")
		
		slow_ghost = ghost_sprite
		spells.queue_free()


func _remove_slow_ghost() -> void:
		if slow_ghost and is_instance_valid(slow_ghost):
				slow_ghost.queue_free()
		slow_ghost = null

func _place_slow_zone(pos: Vector2) -> void:
		if not spells_scene:
				return
		var spells = spells_scene.instantiate()
		var slow_node = spells.get_node_or_null("Slow")
		if not slow_node:
				spells.queue_free()
				return
		
		var world = get_tree().current_scene
		if not world is Node2D:
				spells.queue_free()
				return
		var container = Node2D.new()
		container.name = "SlowZone"
		var original_sprite: AnimatedSprite2D = slow_node.get_node_or_null("AnimatedSprite2D")
		var sprite: AnimatedSprite2D = null
		if original_sprite:
				sprite = original_sprite.duplicate() as AnimatedSprite2D
				sprite.modulate = Color(1, 0.5, 1, 0.8)
				sprite.z_index = 50
				container.add_child(sprite)
		var original_aoe: Area2D = slow_node.get_node_or_null("AreaOfEffect")
		var aoe: Area2D = null
		if original_aoe:
				aoe = original_aoe.duplicate() as Area2D
				container.add_child(aoe)
		(world as Node2D).add_child(container)
		var final_pos = GridUtils.snap_to_grid(pos, 16)
		container.global_position = final_pos
		if aoe:
				aoe.body_entered.connect(_on_slow_zone_body_entered.bind(aoe))
				aoe.body_exited.connect(_on_slow_zone_body_exited.bind(container))
		
		if sprite:
				sprite.play("Animation")
		_play_slow_sound()
		_schedule_slow_zone_removal(container, sprite, SLOW_ZONE_DURATION)
		slow_cooldown_left = SLOW_COOLDOWN
		if slow_btn:
				slow_btn.disabled = true
		_trigger_player_cast()
		spells.queue_free()

func _schedule_slow_zone_removal(container: Node2D, sprite: AnimatedSprite2D, duration: float) -> void:
	var tween = create_tween()
	var fade_start = duration - 1.0
	if fade_start < 0:
			fade_start = duration * 0.8
	tween.tween_interval(fade_start)
	if sprite:
			tween.tween_property(sprite, "modulate:a", 0.0, duration - fade_start)
	tween.tween_callback(func():
			if is_instance_valid(container):
					for child in container.get_children():
							if child is Area2D:
									var aoe: Area2D = child as Area2D
									for body in aoe.get_overlapping_bodies():
											if is_instance_valid(body) and body.is_in_group("enemies") and body.has_method("set_speed_modifier"):
													body.set_speed_modifier(1.0)
									break
					container.queue_free()
	)

func _on_slow_zone_body_entered(body: Node2D, _area: Area2D) -> void:
	if body and body.is_in_group("enemies") and body.has_method("set_speed_modifier"):
			body.set_speed_modifier(SLOW_SPEED_MULT)

func _on_slow_zone_body_exited(body: Node2D, _container: Node2D) -> void:
	if is_instance_valid(body) and body.is_in_group("enemies") and body.has_method("set_speed_modifier"):
			body.set_speed_modifier(1.0)

func _play_heal_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/heal.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_shield_sound():
	var sound_path ="res://assets/sound/attacks_and_mosnters/shield.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_slow_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/slow.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_buff_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/buff.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
