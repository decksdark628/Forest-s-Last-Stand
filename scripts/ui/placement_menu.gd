extends Control

@onready var menu_inicial: PanelContainer = $MenuInicial
@onready var menu_mejorado: PanelContainer = $MenuMejorado
var soldier_button: Button = null
var archer_button: Button = null
var mejorado_soldier_button: Button = null
var mejorado_archer_button: Button = null
var veteran_soldier_button: Button = null
var veteran_archer_button: Button = null
const UNIT_COSTS = {
	"soldier": {"gold": 15, "stone": 5},
	"archer": {"gold": 25, "wood": 10},
	"veteran_soldier": {"gold": 50, "stone": 15},
	"veteran_archer": {"gold": 70, "wood": 20}
}

func _ready() -> void:
	soldier_button = menu_inicial.find_child("SoldierButton", true, false)
	archer_button = menu_inicial.find_child("ArcherButton", true, false)
	mejorado_soldier_button = menu_mejorado.find_child("SoldierButton", true, false)
	mejorado_archer_button = menu_mejorado.find_child("ArcherButton", true, false)
	veteran_soldier_button = menu_mejorado.find_child("VeteranSoldierButton", true, false)
	veteran_archer_button = menu_mejorado.find_child("VeteranArcherButton", true, false)
	if soldier_button:
		soldier_button.disabled = false
	if archer_button:
		archer_button.disabled = false
	if mejorado_soldier_button:
		mejorado_soldier_button.disabled = false
	if mejorado_archer_button:
		mejorado_archer_button.disabled = false
	if veteran_soldier_button:
		veteran_soldier_button.disabled = false
	if veteran_archer_button:
		veteran_archer_button.disabled = false
	if soldier_button:
		soldier_button.pressed.connect(func(): _on_unit_button_pressed("soldier"))
	if archer_button:
		archer_button.pressed.connect(func(): _on_unit_button_pressed("archer"))
	if mejorado_soldier_button:
		mejorado_soldier_button.pressed.connect(func(): _on_unit_button_pressed("soldier"))
	if mejorado_archer_button:
		mejorado_archer_button.pressed.connect(func(): _on_unit_button_pressed("archer"))
	if veteran_soldier_button:
		veteran_soldier_button.pressed.connect(func(): _on_unit_button_pressed("veteran_soldier"))
	if veteran_archer_button:
		veteran_archer_button.pressed.connect(func(): _on_unit_button_pressed("veteran_archer"))
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm:
		if gm.has_signal("resources_updated"):
			gm.resources_updated.connect(_on_resources_updated)
	
	if Engine.has_meta("blacksmith_improvement_achieved") and Engine.get_meta("blacksmith_improvement_achieved"):
		_on_blacksmith_improvement_achieved()
	else:
		menu_inicial.visible = true
		menu_mejorado.visible = false
	
	await get_tree().process_frame 
	_update_button_states()

func _on_unit_button_pressed(unit_type: String) -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if not gm:
		return
	if gm.placement_manager:
		gm.placement_manager.cancel_placement()
	# Now start placement for the new unit
	if gm.has_method("start_unit_placement"):
		gm.start_unit_placement(unit_type)

func _on_blacksmith_improvement_achieved() -> void:
	menu_inicial.visible = false
	menu_mejorado.visible = true

func _on_resources_updated(_resources: Dictionary) -> void:
	_update_button_states()

func _get_resource_manager() -> Node:
	"""Helper function to get ResourceManager from various sources"""
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "resource_manager" in gm:
		return gm.resource_manager
	return get_tree().get_first_node_in_group("resource_manager")

func _update_button_states() -> void:
	var rm = _get_resource_manager()
	
	if not rm or not rm.has_method("has_enough_resources"):
		if soldier_button:
			soldier_button.disabled = false
		if archer_button:
			archer_button.disabled = false
		if mejorado_soldier_button:
			mejorado_soldier_button.disabled = false
		if mejorado_archer_button:
			mejorado_archer_button.disabled = false
		if veteran_soldier_button:
			veteran_soldier_button.disabled = false
		if veteran_archer_button:
			veteran_archer_button.disabled = false
		return
	if soldier_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["soldier"])
		soldier_button.disabled = not can_afford
	if archer_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["archer"])
		archer_button.disabled = not can_afford
	if mejorado_soldier_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["soldier"])
		mejorado_soldier_button.disabled = not can_afford
	if mejorado_archer_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["archer"])
		mejorado_archer_button.disabled = not can_afford
	if veteran_soldier_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["veteran_soldier"])
		veteran_soldier_button.disabled = not can_afford
	if veteran_archer_button:
		var can_afford = rm.has_enough_resources(UNIT_COSTS["veteran_archer"])
		veteran_archer_button.disabled = not can_afford

func _reset_menu_state():
	menu_inicial.visible = true
	menu_mejorado.visible = false
