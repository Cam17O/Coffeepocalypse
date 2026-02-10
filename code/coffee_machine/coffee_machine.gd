extends StaticBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")

@onready var progress_bar = $ProgressBar

@export var machine_type_id: String = "machine_placeholder_1"
@export var brewing_time: float = GameConfig.MACHINE_BREWING_TIME
@export var current_coffee_stock: int = GameConfig.MACHINE_STARTING_STOCK
@export var max_coffee_stock: int = GameConfig.MACHINE_BASE_MAX_STOCK
@export var fail_chance: float = GameConfig.MACHINE_FAIL_CHANCE
@export var bad_taste_chance: float = GameConfig.MACHINE_BAD_TASTE_CHANCE
@export var take_money_on_fail_chance: float = GameConfig.MACHINE_TAKE_MONEY_ON_FAIL_CHANCE
@export var coffee_price: float = GameConfig.MACHINE_COFFEE_PRICE
@export var satisfaction_reward: float = GameConfig.MACHINE_SATISFACTION_REWARD
@export var satisfaction_penalty: float = GameConfig.MACHINE_SATISFACTION_PENALTY
@export var max_workers: int = GameConfig.MACHINE_BASE_MAX_WORKERS

## Propreté: 0-100, descend régulièrement, impacte satisfaction si bas
var cleanliness: float = 100.0
var cleanliness_max: float = 100.0
var cleanliness_decay_per_sec: float = 0.5
## Durabilité: 0-100, descend à chaque café, problèmes si bas (pas de café, eau seule)
var durability: float = 100.0
var durability_max: float = 100.0
var durability_decay_per_coffee: float = 2.0
var durability_problem_threshold: float = 30.0
var cleanliness_penalty_threshold: float = 30.0

var is_busy: bool = false
var is_player_nearby: bool = false
var waiting_count: int = 0
var upgrade_level: int = 0
var _cleanliness_timer: float = 0.0

var _base_brewing_time: float
var _base_max_stock: int
var _base_fail_chance: float
var _base_bad_taste_chance: float
var _base_satisfaction_reward: float
var _base_satisfaction_penalty: float
var _base_max_workers: int
var _workers: Array = []

func _ready():
	_base_brewing_time = brewing_time
	_base_max_stock = max_coffee_stock
	_base_fail_chance = fail_chance
	_base_bad_taste_chance = bad_taste_chance
	_base_satisfaction_reward = satisfaction_reward
	_base_satisfaction_penalty = satisfaction_penalty
	_base_max_workers = max_workers
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)
	apply_upgrade_level(upgrade_level)
	print("[Machine] Ready : ", name, ", stock : ", current_coffee_stock, "/", max_coffee_stock)

func _process(delta: float):
	_cleanliness_timer += delta
	if _cleanliness_timer >= 1.0:
		_cleanliness_timer = 0.0
		cleanliness = max(0.0, cleanliness - cleanliness_decay_per_sec)

# Apply an upgrade level to adjust machine parameters
func apply_upgrade_level(level: int):
	upgrade_level = level
	max_coffee_stock = _base_max_stock + level * GameConfig.MACHINE_STOCK_MULTIPLIER_PER_LEVEL
	brewing_time = max(GameConfig.MACHINE_BREWING_TIME_MIN, _base_brewing_time - GameConfig.MACHINE_BREWING_TIME_DECREASE_PER_LEVEL * level)
	fail_chance = max(0.00, _base_fail_chance - GameConfig.MACHINE_FAIL_CHANCE_DECREASE_PER_LEVEL * level)
	bad_taste_chance = max(0.00, _base_bad_taste_chance - GameConfig.MACHINE_BAD_TASTE_CHANCE_DECREASE_PER_LEVEL * level)
	satisfaction_reward = _base_satisfaction_reward + GameConfig.MACHINE_SATISFACTION_REWARD_PER_LEVEL * level
	satisfaction_penalty = min(GameConfig.MACHINE_SATISFACTION_PENALTY_MAX, _base_satisfaction_penalty + GameConfig.MACHINE_SATISFACTION_PENALTY_PER_LEVEL * level)
	max_workers = _base_max_workers + level * GameConfig.MACHINE_MAX_WORKERS_PER_LEVEL
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)
	_cleanup_workers()
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
		progress_bar.start(_get_effective_brewing_time(), self )
	await get_tree().create_timer(_get_effective_brewing_time()).timeout

	# Durabilité: problème si très bas (prend argent sans café, ou eau seule)
	var durability_fail = durability < durability_problem_threshold and randf() < 0.5
	if durability_fail:
		var took_money = randf() < 0.6
		if took_money:
			Global.add_money(coffee_price)
		var water_only = randf() < 0.5
		if water_only:
			if customer.has_method("on_coffee_received"):
				customer.on_coffee_received({"taste_bad": true, "satisfaction_delta": satisfaction_penalty, "took_money": false})
			else:
				Global.apply_satisfaction_delta(satisfaction_penalty * 0.5, true)
		else:
			_apply_failure(customer, "no_coffee", took_money)
		durability = max(0.0, durability - durability_decay_per_coffee)
		is_busy = false
		return false

	# Propreté: impacte satisfaction si en dessous du seuil
	var satisfaction_mult = 1.0
	if cleanliness < cleanliness_penalty_threshold:
		satisfaction_mult = 0.5 + (cleanliness / cleanliness_penalty_threshold) * 0.5
		if randf() < 0.3:
			satisfaction_mult *= 0.5

	# After brewing time, determine if the brew was successful or if it failed
	var effective_fail = fail_chance
	if durability < 50.0:
		effective_fail += 0.2
	var did_fail = randf() < effective_fail
	if did_fail:
		durability = max(0.0, durability - durability_decay_per_coffee)
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

	# Decay cleanliness and durability on successful brew
	cleanliness = max(0.0, cleanliness - 0.2)
	durability = max(0.0, durability - durability_decay_per_coffee)

	# Determine if the coffee tastes bad and apply satisfaction changes accordingly
	var taste_bad = randf() < bad_taste_chance
	var delta = satisfaction_reward * satisfaction_mult
	if taste_bad:
		delta = satisfaction_penalty * satisfaction_mult

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
		body.entrer_dans_zone_machine(self)

# Callback for when the player leaves the interaction area
func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false
	if body.has_method("sortir_depuis_zone_machine"):
		body.sortir_depuis_zone_machine(self)

# Internal function to handle player brewing interaction (bloque mouvement)
func _brew_for_player():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_immobilized"):
		player.set_immobilized(true)
	is_busy = true
	print("[Machine] Player brewing : ", name)
	if progress_bar:
		progress_bar.start(_get_effective_brewing_time(), self)
	await get_tree().create_timer(_get_effective_brewing_time()).timeout
	if current_coffee_stock > 0:
		current_coffee_stock -= 1
		print("[Machine] Player received : ", name, ", stock : ", current_coffee_stock)
	is_busy = false
	if player and player.has_method("set_immobilized"):
		player.set_immobilized(false)

func has_free_worker_slot() -> bool:
	_cleanup_workers()
	return _workers.size() < max_workers

func register_worker(worker: Node) -> bool:
	if not worker or _workers.has(worker):
		return false
	_cleanup_workers()
	if _workers.size() >= max_workers:
		return false
	_workers.append(worker)
	return true

func unregister_worker(worker: Node):
	if _workers.has(worker):
		_workers.erase(worker)
		_cleanup_workers()

func get_worker_count() -> int:
	_cleanup_workers()
	return _workers.size()

func _cleanup_workers():
	var valid_workers := []
	for worker in _workers:
		if is_instance_valid(worker):
			valid_workers.append(worker)
	_workers = valid_workers
	if _workers.size() > max_workers:
		_workers.resize(max_workers)

func _get_effective_brewing_time() -> float:
	var bonus = GameConfig.MACHINE_WORK_PRODUCTIVITY_PER_CAT * float(get_worker_count())
	var multiplier = 1.0 / (1.0 + bonus)
	return max(GameConfig.MACHINE_BREWING_TIME_MIN, brewing_time * multiplier)

func get_upgrade_level() -> int:
	return upgrade_level

func get_effective_brewing_time() -> float:
	return _get_effective_brewing_time()

func clean_machine():
	cleanliness = cleanliness_max

func repair_machine():
	durability = durability_max

func needs_cleaning() -> bool:
	return cleanliness < cleanliness_penalty_threshold

func needs_repair() -> bool:
	return durability < durability_problem_threshold
