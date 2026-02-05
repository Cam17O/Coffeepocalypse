extends StaticBody2D

@export var coffee_inventory: int = 40
@export var max_inventory: int = 60
@export var arrival_interval: float = 6.0
@export var arrival_amount: int = 5

var is_player_nearby: bool = false
var _arrival_timer: Timer
var _base_max_inventory: int
var _base_arrival_amount: int

func _ready():
	_base_max_inventory = max_inventory
	_base_arrival_amount = arrival_amount
	_arrival_timer = Timer.new()
	_arrival_timer.wait_time = arrival_interval
	_arrival_timer.one_shot = false
	_arrival_timer.autostart = true
	add_child(_arrival_timer)
	_arrival_timer.timeout.connect(_on_arrival_timeout)

func apply_upgrade_level(level: int):
	max_inventory = _base_max_inventory + level * 10
	arrival_amount = _base_arrival_amount + level
	coffee_inventory = min(coffee_inventory, max_inventory)

func _on_arrival_timeout():
	if coffee_inventory < max_inventory:
		coffee_inventory = min(max_inventory, coffee_inventory + arrival_amount)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and is_player_nearby:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Global.raw_coffee_carried < Global.max_coffee_capacity and coffee_inventory > 0:
				var amount = min(10, coffee_inventory, Global.max_coffee_capacity - Global.raw_coffee_carried)
				coffee_inventory -= amount
				Global.raw_coffee_carried += amount
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if Global.raw_coffee_carried > 0 and coffee_inventory < max_inventory:
				var space = max_inventory - coffee_inventory
				var amount = min(10, space, Global.raw_coffee_carried)
				coffee_inventory += amount
				Global.raw_coffee_carried -= amount

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
