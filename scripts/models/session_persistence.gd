extends Node
var _cached_units_state: Array = []
func save(location: String, game_state: Dictionary, units_state: Array) -> void:
	var st = Engine.get_main_loop() as SceneTree
	if not st:
		return
	st.set_meta("location", location)
	st.set_meta("game_state", game_state)
	st.set_meta("units_state", units_state)
func load_session() -> Dictionary:
	var st = Engine.get_main_loop() as SceneTree
	var out := {
		"location": "",
		"game_state": null,
		"units_state": null
	}
	if not st:
		return out

	if st.has_meta("location"):
		out.location = String(st.get_meta("location"))
		st.remove_meta("location")

	if st.has_meta("game_state"):
		var data = st.get_meta("game_state")
		if typeof(data) == TYPE_DICTIONARY:
			out.game_state = data
		st.remove_meta("game_state")

	if st.has_meta("units_state"):
		var units = st.get_meta("units_state")
		if typeof(units) == TYPE_ARRAY:
			out.units_state = units
			_cached_units_state = units.duplicate()
		st.remove_meta("units_state")

	return out
func get_cached_units_state() -> Array:
	return _cached_units_state.duplicate()
func clear_cached_units_state() -> void:
	_cached_units_state.clear()
