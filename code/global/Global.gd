extends Node

const SaveService = preload("res://code/global/SaveService.gd")
const UpgradeService = preload("res://code/global/UpgradeService.gd")

var money: float = 0.0
var raw_coffee_carried: int = 0
var max_coffee_capacity: int = 12
var global_satisfaction: float = 100.0
var fishing_level: int = 1

var fishing_boost_multiplier: float = 1.0
var fishing_boost_time_left: float = 0.0
var fishing_tick_interval: float = 7.0
var _fishing_elapsed: float = 0.0
var _player_is_idle: bool = false

var machine_upgrade_level: int = 0
var storage_upgrade_level: int = 0
var fishing_upgrade_level: int = 0
var cat_home_upgrade_level: int = 0
var save_service: RefCounted
var upgrade_service: RefCounted

func _ready():
	save_service = SaveService.new(self)
	upgrade_service = UpgradeService.new(self)
	load_game()

func _process(delta):
	if fishing_boost_time_left > 0.0:
		fishing_boost_time_left = max(fishing_boost_time_left - delta, 0.0)
		if fishing_boost_time_left <= 0.0:
			fishing_boost_multiplier = 1.0

	if upgrade_service:
		upgrade_service.process()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func add_money(amount: float):
	money += amount

func apply_satisfaction_delta(amount: float, is_neg: bool, multiplier: float = 1.0):
	var final_change = amount * multiplier
	if is_neg and global_satisfaction < 50.0:
		final_change *= 1.5
	global_satisfaction = clamp(global_satisfaction + final_change, 0.0, 100.0)

func apply_coffee_effect(_energy, duration, boost):
	fishing_boost_multiplier = boost
	fishing_boost_time_left = duration

func set_player_idle(val: bool):
	_player_is_idle = val

func show_dialog(text: String):
	var ui = get_tree().get_first_node_in_group("phone_ui")
	if ui and ui.has_method("display_info"):
		ui.display_info(text)
	print(text)

func save_game():
	if save_service:
		save_service.save_game()

func export_save():
	if save_service:
		save_service.export_save()

func import_save():
	if save_service:
		save_service.import_save()

func apply_upgrades_if_ready():
	if upgrade_service:
		upgrade_service.apply_upgrades_if_ready()

func load_game():
	if save_service:
		save_service.load_game()

func queue_apply_upgrades():
	if upgrade_service:
		upgrade_service.queue_apply_upgrades()
