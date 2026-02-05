extends Node

var money: float = 0.0
var raw_coffee_carried: int = 0
var max_coffee_capacity: int = 20
var fishing_level: int = 1
var global_satisfaction: float = 100.0

var fishing_boost_multiplier: float = 1.0
var fishing_boost_time_left: float = 0.0
var fishing_tick_interval: float = 4.0
var _fishing_elapsed: float = 0.0
var _player_is_idle: bool = false

var machine_upgrade_level: int = 0
var storage_upgrade_level: int = 0
var fishing_upgrade_level: int = 0
var _pending_apply_upgrades: bool = false

const SAVE_PATH := "user://save.json"
const EXPORT_PATH := "user://save_export.json"

func _ready():
	load_game()

func _process(delta: float):
	if fishing_boost_time_left > 0.0:
		fishing_boost_time_left = max(fishing_boost_time_left - delta, 0.0)
		if fishing_boost_time_left <= 0.0:
			fishing_boost_multiplier = 1.0
	if _player_is_idle:
		_fishing_elapsed += delta
		if _fishing_elapsed >= fishing_tick_interval:
			_fishing_elapsed -= fishing_tick_interval
			var income = 2.0 * fishing_level * fishing_boost_multiplier
			add_money(income)
	if _pending_apply_upgrades:
		_try_apply_upgrades()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func set_player_idle(is_idle: bool):
	_player_is_idle = is_idle
	if not is_idle:
		_fishing_elapsed = 0.0

func add_money(amount: float):
	money += amount
	print("Argent: ", money)

func add_satisfaction(amount: float):
	global_satisfaction = clamp(global_satisfaction + amount, 0.0, 100.0)

func lose_satisfaction(amount: float):
	global_satisfaction = clamp(global_satisfaction - amount, 0.0, 100.0)

func get_penalty_multiplier() -> float:
	if global_satisfaction >= 60.0:
		return 1.0
	if global_satisfaction >= 30.0:
		return 1.5
	return 2.0

func apply_satisfaction_delta(amount: float, is_negative: bool, impact_multiplier: float = 1.0):
	var final_amount = amount * impact_multiplier
	if is_negative:
		final_amount *= get_penalty_multiplier()
	global_satisfaction = clamp(global_satisfaction + final_amount, 0.0, 100.0)

func apply_coffee_effect(energy_amount: float, duration: float, fishing_boost: float):
	if fishing_boost > fishing_boost_multiplier:
		fishing_boost_multiplier = fishing_boost
	fishing_boost_time_left = max(fishing_boost_time_left, duration)

func save_game():
	var data = {
		"money": money,
		"raw_coffee_carried": raw_coffee_carried,
		"max_coffee_capacity": max_coffee_capacity,
		"fishing_level": fishing_level,
		"global_satisfaction": global_satisfaction,
		"machine_upgrade_level": machine_upgrade_level,
		"storage_upgrade_level": storage_upgrade_level,
		"fishing_upgrade_level": fishing_upgrade_level
	}
	_write_save_file(SAVE_PATH, data)

func export_save():
	var data = {
		"money": money,
		"raw_coffee_carried": raw_coffee_carried,
		"max_coffee_capacity": max_coffee_capacity,
		"fishing_level": fishing_level,
		"global_satisfaction": global_satisfaction,
		"machine_upgrade_level": machine_upgrade_level,
		"storage_upgrade_level": storage_upgrade_level,
		"fishing_upgrade_level": fishing_upgrade_level
	}
	_write_save_file(EXPORT_PATH, data)

func import_save():
	_load_from_path(EXPORT_PATH)

func apply_upgrades_if_ready():
	_try_apply_upgrades()

func _write_save_file(path: String, data: Dictionary):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game():
	_load_from_path(SAVE_PATH)

func _load_from_path(path: String):
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	money = parsed.get("money", money)
	raw_coffee_carried = parsed.get("raw_coffee_carried", raw_coffee_carried)
	max_coffee_capacity = parsed.get("max_coffee_capacity", max_coffee_capacity)
	fishing_level = parsed.get("fishing_level", fishing_level)
	global_satisfaction = parsed.get("global_satisfaction", global_satisfaction)
	machine_upgrade_level = parsed.get("machine_upgrade_level", machine_upgrade_level)
	storage_upgrade_level = parsed.get("storage_upgrade_level", storage_upgrade_level)
	fishing_upgrade_level = parsed.get("fishing_upgrade_level", fishing_upgrade_level)
	_pending_apply_upgrades = true

func _try_apply_upgrades():
	if get_tree().current_scene == null:
		return
	var machines = get_tree().get_nodes_in_group("machines")
	var storages = get_tree().get_nodes_in_group("storages")
	if machines.is_empty() and storages.is_empty():
		return
	_apply_upgrades_to_world(machines, storages)
	_pending_apply_upgrades = false

func _apply_upgrades_to_world(machines: Array, storages: Array):
	fishing_tick_interval = max(1.5, 4.0 - 0.2 * fishing_upgrade_level)
	for machine in machines:
		if machine.has_method("apply_upgrade_level"):
			machine.apply_upgrade_level(machine_upgrade_level)
	for storage in storages:
		if storage.has_method("apply_upgrade_level"):
			storage.apply_upgrade_level(storage_upgrade_level)
