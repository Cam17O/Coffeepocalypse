extends StaticBody2D

@export var brewing_time: float = 3.0
@export var current_coffee_stock: int = 6
@export var max_coffee_stock: int = 10
@export var fail_chance: float = 0.2
@export var bad_taste_chance: float = 0.35
@export var take_money_on_fail_chance: float = 0.4
@export var coffee_price: float = 10.0
@export var satisfaction_reward: float = 4.0
@export var satisfaction_penalty: float = -6.0
@export var coffee_energy_duration: float = 6.0
@export var coffee_fishing_boost: float = 1.5

var is_busy: bool = false
var is_player_nearby: bool = false

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

func apply_upgrade_level(level: int):
	max_coffee_stock = _base_max_stock + level * 2
	brewing_time = max(1.0, _base_brewing_time - 0.2 * level)
	fail_chance = max(0.05, _base_fail_chance - 0.03 * level)
	bad_taste_chance = max(0.1, _base_bad_taste_chance - 0.04 * level)
	satisfaction_reward = _base_satisfaction_reward + 0.5 * level
	satisfaction_penalty = min(-1.0, _base_satisfaction_penalty + 0.5 * level)
	current_coffee_stock = clamp(current_coffee_stock, 0, max_coffee_stock)

func start_brewing(customer: Node2D):
	if is_busy:
		return
	if current_coffee_stock <= 0:
		_apply_failure(customer, "out_of_stock", false)
		return

	is_busy = true
	await get_tree().create_timer(brewing_time).timeout

	var did_fail = randf() < fail_chance
	if did_fail:
		var took_money = randf() < take_money_on_fail_chance
		if took_money:
			Global.add_money(coffee_price)
		_apply_failure(customer, "machine_failed", took_money)
		is_busy = false
		return

	current_coffee_stock -= 1
	Global.add_money(coffee_price)

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

func _apply_failure(customer: Node2D, reason: String, took_money: bool):
	var penalty = satisfaction_penalty * 0.8
	if customer.has_method("on_coffee_failed"):
		customer.on_coffee_failed(reason, took_money)
	else:
		Global.apply_satisfaction_delta(penalty, true)

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and is_player_nearby:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var space = max_coffee_stock - current_coffee_stock
			if space > 0 and Global.raw_coffee_carried > 0:
				var transfer = min(space, Global.raw_coffee_carried)
				current_coffee_stock += transfer
				Global.raw_coffee_carried -= transfer
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not is_busy and current_coffee_stock > 0:
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
	await get_tree().create_timer(brewing_time).timeout
	if current_coffee_stock > 0:
		current_coffee_stock -= 1
		Global.apply_coffee_effect(1.0, coffee_energy_duration, coffee_fishing_boost)
		Global.apply_satisfaction_delta(1.0, false)
	is_busy = false
