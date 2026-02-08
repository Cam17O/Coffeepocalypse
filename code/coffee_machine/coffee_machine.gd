extends StaticBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")

@onready var progress_bar = $ProgressBar

@export var brewing_time: float = GameConfig.MACHINE_BREWING_TIME
@export var current_coffee_stock: int = GameConfig.MACHINE_STARTING_STOCK
@export var max_coffee_stock: int = GameConfig.MACHINE_BASE_MAX_STOCK
@export var fail_chance: float = GameConfig.MACHINE_FAIL_CHANCE
@export var bad_taste_chance: float = GameConfig.MACHINE_BAD_TASTE_CHANCE
@export var take_money_on_fail_chance: float = GameConfig.MACHINE_TAKE_MONEY_ON_FAIL_CHANCE
@export var coffee_price: float = GameConfig.MACHINE_COFFEE_PRICE
@export var satisfaction_reward: float = GameConfig.MACHINE_SATISFACTION_REWARD
@export var satisfaction_penalty: float = GameConfig.MACHINE_SATISFACTION_PENALTY

var is_busy: bool = false
var is_player_nearby: bool = false
var waiting_count: int = 0

var _base_brewing_time: float
var _base_max_stock: int
var _base_fail_chance: float
var _base_bad_taste_chance: float
var _base_satisfaction_reward: float
var _base_satisfaction_penalty: float

func _ready():
	_base_brewing_time = brewing_time
	_base_max_stock = max_coffee_stock
	_base_fail_chance = fail_chance
	_base_bad_taste_chance = bad_taste_chance
	_base_satisfaction_reward = satisfaction_reward
	_base_satisfaction_penalty = satisfaction_penalty
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)
	print("[Machine] Ready : ", name, ", stock : ", current_coffee_stock, "/", max_coffee_stock)

# Apply an upgrade level to adjust machine parameters
func apply_upgrade_level(level: int):
	max_coffee_stock = _base_max_stock * (level * GameConfig.MACHINE_STOCK_MULTIPLIER_PER_LEVEL)
	brewing_time = max(GameConfig.MACHINE_BREWING_TIME_MIN, _base_brewing_time - GameConfig.MACHINE_BREWING_TIME_DECREASE_PER_LEVEL * level)
	fail_chance = max(0.00, _base_fail_chance - GameConfig.MACHINE_FAIL_CHANCE_DECREASE_PER_LEVEL * level)
	bad_taste_chance = max(0.00, _base_bad_taste_chance - GameConfig.MACHINE_BAD_TASTE_CHANCE_DECREASE_PER_LEVEL * level)
	satisfaction_reward = _base_satisfaction_reward + GameConfig.MACHINE_SATISFACTION_REWARD_PER_LEVEL * level
	satisfaction_penalty = min(GameConfig.MACHINE_SATISFACTION_PENALTY_MAX, _base_satisfaction_penalty + GameConfig.MACHINE_SATISFACTION_PENALTY_PER_LEVEL * level)
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)
	print("[Machine] Upgrade : ", name, ", lvl : ", level, ", stock : ", max_coffee_stock, ", brew : ", brewing_time)

# Register a customer as waiting for this machine
func register_waiter():
	waiting_count += 1

# Unregister a customer from waiting for this machine
func unregister_waiter():
	waiting_count = max(0, waiting_count - 1)

#
func start_brewing(customer: Node2D) -> bool:
	# If the machine is already busy, we can't start brewing
	if is_busy:
		return false

	# Check if we have stock before starting to brew
	if current_coffee_stock <= 0:
		print("[Machine] Out of stock : ", name)
		_apply_failure(customer, "out_of_stock", false)
		return false

	# Start brewing
	is_busy = true
	print("[Machine] Start brew : ", name, ", stock : ", current_coffee_stock)
	if progress_bar:
		progress_bar.start(brewing_time, self )
	await get_tree().create_timer(brewing_time).timeout

	# After brewing time, determine if the brew was successful or if it failed
	var did_fail = randf() < fail_chance
	if did_fail:
		var took_money = randf() < take_money_on_fail_chance
		if took_money:
			Global.add_money(coffee_price)
		print("[Machine] Brew failed:", name, "took_money", took_money)
		_apply_failure(customer, "machine_failed", took_money)
		is_busy = false
		return false

	# If succeeded, reduce stock, add money
	current_coffee_stock -= 1
	Global.add_money(coffee_price)
	print("[Machine] Brew success:", name, "stock", current_coffee_stock)

	# Determine if the coffee tastes bad and apply satisfaction changes accordingly
	var taste_bad = randf() < bad_taste_chance
	var delta = satisfaction_reward
	if taste_bad:
		delta = satisfaction_penalty

	# Notify the customer of the result
	if customer.has_method("on_coffee_received"):
		customer.on_coffee_received({
			"taste_bad": taste_bad,
			"satisfaction_delta": delta,
			"took_money": true
		})

	# If the customer doesn't have the method, apply satisfaction change globally
	else:
		Global.apply_satisfaction_delta(delta, delta < 0)

	is_busy = false
	return true

# Internal function to apply failure consequences to the customer and global state
func _apply_failure(customer: Node2D, reason: String, took_money: bool):
	var penalty = satisfaction_penalty * 0.8
	if customer.has_method("on_coffee_failed"):
		customer.on_coffee_failed(reason, took_money)
	else:
		Global.apply_satisfaction_delta(penalty, true)

# Input event to handle player interactions with the machine
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# Right-click to open machine UI
		if event.button_index == MOUSE_BUTTON_RIGHT:

			# open phone UI with machine details
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.MACHINES, self )

		# Left-click to brew if player is nearby and machine is not busy
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if is_player_nearby and not is_busy and current_coffee_stock > 0:
				print("[Machine] Player brew:", name)
				_brew_for_player()

# Callbacks for player entering/exiting interaction area to track proximity for brewing
func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true
	if body.has_method("entrer_dans_zone_machine"):
		body.entrer_dans_zone_machine()

# Callback for when the player leaves the interaction area
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false

# Internal function to handle player brewing interaction
func _brew_for_player():
	is_busy = true
	print("[Machine] Player brewing : ", name)
	if progress_bar:
		progress_bar.start(brewing_time, self )
	await get_tree().create_timer(brewing_time).timeout
	if current_coffee_stock > 0:
		current_coffee_stock -= 1
		print("[Machine] Player received : ", name, ", stock : ", current_coffee_stock)
	is_busy = false
