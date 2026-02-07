extends StaticBody2D

@onready var progress_bar = $ProgressBar

@export var coffee_inventory: int = 24
@export var max_inventory: int = 45
@export var arrival_interval: float = 10.0
@export var arrival_amount: int = 3
@export var auto_fill_cost_per_unit: float = 3.0

var is_player_nearby: bool = false
var _arrival_timer: Timer
var _base_max_inventory: int
var _base_arrival_amount: int
var auto_fill_enabled: bool = true

func _ready():
	_base_max_inventory = max_inventory
	_base_arrival_amount = arrival_amount
	_arrival_timer = Timer.new()
	_arrival_timer.wait_time = arrival_interval
	_arrival_timer.one_shot = false
	_arrival_timer.autostart = true
	add_child(_arrival_timer)
	_arrival_timer.timeout.connect(_on_arrival_timeout)
	print("[Storage] Ready:", name, "stock", coffee_inventory, "/", max_inventory)

func _process(_delta):
	if progress_bar and not _arrival_timer.is_stopped():
		progress_bar.show()
		progress_bar.max_value = _arrival_timer.wait_time
		progress_bar.value = _arrival_timer.wait_time - _arrival_timer.time_left
		progress_bar.global_position = global_position + Vector2(-25, -40)

func apply_upgrade_level(level: int):
	max_inventory = _base_max_inventory + level * 10
	arrival_amount = _base_arrival_amount + level
	coffee_inventory = min(coffee_inventory, max_inventory)
	print("[Storage] Upgrade", name, "lvl", level, "cap", max_inventory, "arrive", arrival_amount)

func _on_arrival_timeout():
	if not auto_fill_enabled:
		return
	if coffee_inventory < max_inventory:
		var space = max_inventory - coffee_inventory
		var amount = min(space, arrival_amount)
		var total_cost = amount * auto_fill_cost_per_unit
		if Global.money >= total_cost:
			Global.add_money(-total_cost)
			coffee_inventory += amount
			print("[Storage] Auto fill:", name, "+", amount, "cost", total_cost)
		else:
			print("[Storage] Auto fill blocked (money):", name)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and is_player_nearby:
			if Global.raw_coffee_carried < Global.max_coffee_capacity and coffee_inventory > 0:
				var amount = min(10, coffee_inventory, Global.max_coffee_capacity - Global.raw_coffee_carried)
				coffee_inventory -= amount
				Global.raw_coffee_carried += amount
				print("[Storage] Take:", name, "-", amount, "stock", coffee_inventory)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var did_deposit = false
			if is_player_nearby and Global.raw_coffee_carried > 0 and coffee_inventory < max_inventory:
				var space = max_inventory - coffee_inventory
				var amount = min(10, space, Global.raw_coffee_carried)
				coffee_inventory += amount
				Global.raw_coffee_carried -= amount
				did_deposit = true
				print("[Storage] Deposit:", name, "+", amount, "stock", coffee_inventory)
			if not did_deposit:
				var ui = get_tree().get_first_node_in_group("phone_ui")
				if ui and ui.has_method("open_tab"):
					ui.open_tab(ui.Tab.STORAGES, self)

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
