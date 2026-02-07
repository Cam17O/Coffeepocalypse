extends StaticBody2D

@onready var progress_bar = $ProgressBar

@export var brewing_time: float = 6.0
@export var current_coffee_stock: int = 3
@export var max_coffee_stock: int = 6
@export var fail_chance: float = 0.22
@export var bad_taste_chance: float = 0.3
@export var take_money_on_fail_chance: float = 0.35
@export var coffee_price: float = 10.0
@export var satisfaction_reward: float = 2.0
@export var satisfaction_penalty: float = -5.0
@export var coffee_energy_duration: float = 7.0
@export var coffee_fishing_boost: float = 1.3

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
	print("[Machine] Ready:", name, "stock", current_coffee_stock, "/", max_coffee_stock)

func apply_upgrade_level(level: int):
	max_coffee_stock = _base_max_stock + level * 2
	brewing_time = max(1.0, _base_brewing_time - 0.2 * level)
	fail_chance = max(0.05, _base_fail_chance - 0.03 * level)
	bad_taste_chance = max(0.1, _base_bad_taste_chance - 0.04 * level)
	satisfaction_reward = _base_satisfaction_reward + 0.5 * level
	satisfaction_penalty = min(-1.0, _base_satisfaction_penalty + 0.5 * level)
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)
	print("[Machine] Upgrade", name, "lvl", level, "stock", max_coffee_stock, "brew", brewing_time)

func register_waiter():
	waiting_count += 1

func unregister_waiter():
	waiting_count = max(0, waiting_count - 1)

func start_brewing(customer: Node2D) -> bool:
	if is_busy:
		return false
	if current_coffee_stock <= 0:
		print("[Machine] Out of stock:", name)
		_apply_failure(customer, "out_of_stock", false)
		return false

	is_busy = true
	print("[Machine] Start brew:", name, "stock", current_coffee_stock)
	if progress_bar:
		progress_bar.start(brewing_time, self)
	await get_tree().create_timer(brewing_time).timeout

	var did_fail = randf() < fail_chance
	if did_fail:
		var took_money = randf() < take_money_on_fail_chance
		if took_money:
			Global.add_money(coffee_price)
		print("[Machine] Brew failed:", name, "took_money", took_money)
		_apply_failure(customer, "machine_failed", took_money)
		is_busy = false
		return false

	current_coffee_stock -= 1
	Global.add_money(coffee_price)
	print("[Machine] Brew success:", name, "stock", current_coffee_stock)

	var taste_bad = randf() < bad_taste_chance
	var delta = satisfaction_reward
	if taste_bad:
		delta = satisfaction_penalty

	if customer.has_method("on_coffee_received"):
		customer.on_coffee_received({
			"taste_bad": taste_bad,
			"satisfaction_delta": delta,
			"took_money": true
		})
	else:
		Global.apply_satisfaction_delta(delta, delta < 0)

	is_busy = false
	return true

func _apply_failure(customer: Node2D, reason: String, took_money: bool):
	var penalty = satisfaction_penalty * 0.8
	if customer.has_method("on_coffee_failed"):
		customer.on_coffee_failed(reason, took_money)
	else:
		Global.apply_satisfaction_delta(penalty, true)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var did_refill = false
			if is_player_nearby:
				var space = max_coffee_stock - current_coffee_stock
				if space > 0 and Global.raw_coffee_carried > 0:
					var transfer = min(space, Global.raw_coffee_carried)
					current_coffee_stock += transfer
					Global.raw_coffee_carried -= transfer
					did_refill = true
					print("[Machine] Refill:", name, "+", transfer, "stock", current_coffee_stock)
			if not did_refill:
				var ui = get_tree().get_first_node_in_group("phone_ui")
				if ui and ui.has_method("open_tab"):
					ui.open_tab(ui.Tab.MACHINES, self)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if is_player_nearby and not is_busy and current_coffee_stock > 0:
				print("[Machine] Player brew:", name)
				_brew_for_player()

func _on_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		is_player_nearby = true
	if body.has_method("entrer_dans_zone_machine"):
		body.entrer_dans_zone_machine()

func _on_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		is_player_nearby = false

func _brew_for_player():
	is_busy = true
	print("[Machine] Player brewing:", name)
	if progress_bar:
		progress_bar.start(brewing_time, self)
	await get_tree().create_timer(brewing_time).timeout
	if current_coffee_stock > 0:
		current_coffee_stock -= 1
		Global.apply_coffee_effect(1.0, coffee_energy_duration, coffee_fishing_boost)
		Global.apply_satisfaction_delta(1.0, false)
		print("[Machine] Player received:", name, "stock", current_coffee_stock)
	is_busy = false
