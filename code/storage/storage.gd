extends StaticBody2D

@onready var progress_bar = $ProgressBar

@export var coffee_inventory: int = 40
@export var max_inventory: int = 60
@export var arrival_interval: float = 6.0
@export var arrival_amount: int = 5

var is_player_nearby: bool = false
var _arrival_timer: Timer

func _ready():
	_arrival_timer = Timer.new()
	_arrival_timer.wait_time = arrival_interval
	_arrival_timer.autostart = true
	add_child(_arrival_timer)
	_arrival_timer.timeout.connect(_on_arrival_timeout)

func _on_arrival_timeout():
	coffee_inventory = min(max_inventory, coffee_inventory + arrival_amount)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# On demande à l'UI de s'ouvrir sur cet objet précis
			var ui = get_tree().get_first_node_in_group("ui_layer")
			if ui:
				var category = "storages" if is_in_group("storages") else "storages"
				ui.toggle_phone(category, self)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"): is_player_nearby = true
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"): is_player_nearby = false
