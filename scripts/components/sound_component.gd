extends Node2D
class_name SoundComponent

@export var attack_sound: AudioStream
@export var death_sound: AudioStream
@export var hit_sound: AudioStream
@export var walk_sound: AudioStream

const PITCH_VARIATION_MIN: float = 0.9
const PITCH_VARIATION_MAX: float = 1.1
const DEFAULT_SFX_BUS: String = "SFX"

@onready var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

func _ready() -> void:
	add_child(audio_player)
	audio_player.bus = DEFAULT_SFX_BUS

func play_attack() -> void:
	if attack_sound:
		play_sound(attack_sound)

func play_death() -> void:
	if death_sound:
		play_sound(death_sound)

func play_hit() -> void:
	if hit_sound:
		play_sound(hit_sound)

func play_walk() -> void:
	if walk_sound and not audio_player.playing:
		play_sound(walk_sound, PITCH_VARIATION_MIN, PITCH_VARIATION_MAX)

func play_custom(stream: AudioStream) -> void:
	play_sound(stream)

func play_sound(stream: AudioStream, min_pitch: float = PITCH_VARIATION_MIN, max_pitch: float = PITCH_VARIATION_MAX) -> void:
	if stream:
		audio_player.stream = stream
		audio_player.pitch_scale = randf_range(min_pitch, max_pitch)
		audio_player.play()
