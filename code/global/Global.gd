extends Node

const GameConfig = preload("res://code/global/GameConfig.gd")

const SaveService = preload("res://code/global/SaveService.gd")
const UpgradeService = preload("res://code/global/UpgradeService.gd")

var money: float = GameConfig.GLOBAL_STARTING_MONEY
var raw_coffee_carried: int = GameConfig.GLOBAL_STARTING_RAW_COFFEE
var max_coffee_capacity: int = GameConfig.GLOBAL_MAX_COFFEE_CAPACITY
var global_satisfaction: float = GameConfig.GLOBAL_STARTING_SATISFACTION

var machine_upgrade_level: int = 0
var storage_upgrade_level: int = 0
var cat_home_upgrade_level: int = 0
var save_service: RefCounted
var upgrade_service: RefCounted

func _ready():
	save_service = SaveService.new(self)
	upgrade_service = UpgradeService.new(self)
	# load_game()

func _process(_delta: float) -> void:
	if upgrade_service:
		upgrade_service.process()

## Global functions to be called by other nodes
# add money to tnhe player total
func add_money(amount: float):
	money += amount

# final satisfaction level change (more important if low satisfaction)
func apply_satisfaction_delta(amount: float, is_neg: bool, multiplier: float = 1.0):
	var final_change = amount * multiplier
	if is_neg and global_satisfaction < 50.0:
		final_change *= 1.5
	global_satisfaction = clamp(global_satisfaction + final_change, 0.0, 100.0)

# show phone ui
func show_dialog(text: String):
	var ui = get_tree().get_first_node_in_group("phone_ui")
	if ui and ui.has_method("display_info"):
		ui.display_info(text)
	print(text)

# save game
func save_game():
	if save_service:
		save_service.save_game()

# export save
func export_save():
	if save_service:
		save_service.export_save()

# import save
func import_save():
	if save_service:
		save_service.import_save()

# apply upgrades if ready
func apply_upgrades_if_ready():
	if upgrade_service:
		upgrade_service.apply_upgrades_if_ready()

# load game data
func load_game():
	if save_service:
		save_service.load_game()

# queue applying upgrades
func queue_apply_upgrades():
	if upgrade_service:
		upgrade_service.queue_apply_upgrades()
