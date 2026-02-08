extends StaticBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")

@onready var progress_bar = $ProgressBar

@export var coffee_inventory: int = GameConfig.STORAGE_STARTING_INVENTORY
@export var max_inventory: int = GameConfig.STORAGE_BASE_MAX_INVENTORY
@export var arrival_interval: float = GameConfig.STORAGE_ARRIVAL_INTERVAL
@export var arrival_amount: int = GameConfig.STORAGE_BASE_ARRIVAL_AMOUNT
@export var auto_fill_cost_per_unit: float = GameConfig.STORAGE_AUTO_FILL_COST_PER_UNIT # need to be price of raw coffee + some margin

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
	print("[Storage] Ready : ", name, ", stock : ", coffee_inventory, "/", max_inventory)

func _process(_delta):
	if progress_bar and not _arrival_timer.is_stopped():
		progress_bar.show()
		progress_bar.max_value = _arrival_timer.wait_time
		progress_bar.value = _arrival_timer.wait_time - _arrival_timer.time_left
		progress_bar.global_position = global_position + Vector2(-25, -40)

# Apply an upgrade level to adjust storage parameters
func apply_upgrade_level(level: int):
	max_inventory = _base_max_inventory + level * GameConfig.STORAGE_MAX_INVENTORY_PER_LEVEL
	arrival_amount = _base_arrival_amount + level * GameConfig.STORAGE_ARRIVAL_AMOUNT_PER_LEVEL
	coffee_inventory = min(coffee_inventory, max_inventory)
	print("[Storage] Upgrade : ", name, ", lvl : ", level, ", cap : ", max_inventory, ", arrive : ", arrival_amount)

# Timer callback to simulate coffee arrival
func _on_arrival_timeout():
	if not auto_fill_enabled:
		return

	if coffee_inventory < max_inventory:
		var space = max_inventory - coffee_inventory
		var amount = min(space, arrival_amount)
		var total_cost = amount * auto_fill_cost_per_unit # need to be price of raw coffee + some margin
		if Global.money >= total_cost:
			Global.add_money(-total_cost)
			coffee_inventory += amount
			print("[Storage] Auto fill : ", name, " + ", amount, ", cost : ", total_cost)
		else:
			print("[Storage] Auto fill blocked (money) : ", name)

# Handle player interactions
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# Right-click to open phone ui
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.STORAGES, self)
