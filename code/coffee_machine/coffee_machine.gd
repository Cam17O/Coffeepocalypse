extends StaticBody2D

@onready var progress_bar = $ProgressBar

@export var current_coffee_stock: int = 10
@export var max_coffee_stock: int = 15
var local_level: int = 1
var is_busy: bool = false
var is_player_nearby: bool = false

func _ready():
	add_to_group("machines")

# Cette fonction est appelée par le téléphone
func upgrade_this_machine():
	local_level += 1
	max_coffee_stock += 5 # On augmente la capacité
	# On peut aussi réduire le temps de craft ici
	# brewing_time = max(1.0, brewing_time - 0.2)
	return local_level

func start_brewing(customer):
	if is_busy or current_coffee_stock <= 0: return
	is_busy = true
	if progress_bar: progress_bar.start(3.0, self)
	await get_tree().create_timer(3.0).timeout
	
	current_coffee_stock -= 1
	Global.add_money(10)
	customer.on_coffee_received({"satisfaction_delta": 5.0})
	is_busy = false

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("ui_layer")
			if ui: ui.toggle_phone("machines", self)
