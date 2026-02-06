extends Node

var money: float = 0.0
var raw_coffee_carried: int = 0
var max_coffee_capacity: int = 20
var global_satisfaction: float = 100.0
var fishing_level: int = 1

var fishing_boost_multiplier: float = 1.0
var fishing_boost_time_left: float = 0.0
var fishing_tick_interval: float = 4.0
var _fishing_elapsed: float = 0.0
var _player_is_idle: bool = false

var machine_upgrade_level: int = 0
var storage_upgrade_level: int = 0
var fishing_upgrade_level: int = 0

func _process(delta):
	# Gestion du boost café
	if fishing_boost_time_left > 0:
		fishing_boost_time_left -= delta
	else:
		fishing_boost_multiplier = 1.0

	# Pêche passive si le joueur ne bouge pas
	if _player_is_idle:
		_fishing_elapsed += delta
		if _fishing_elapsed >= (fishing_tick_interval / (1.0 + (fishing_level * 0.1))):
			_fishing_elapsed = 0
			add_money(1.0 * fishing_boost_multiplier)

func add_money(amount: float):
	money += amount

func apply_satisfaction_delta(amount: float, is_neg: bool, multiplier: float = 1.0):
	var final_change = amount * multiplier
	if is_neg and global_satisfaction < 50: final_change *= 1.5 # Malus pire si mécontents
	global_satisfaction = clamp(global_satisfaction + final_change, 0, 100)

func apply_coffee_effect(_energy, duration, boost):
	fishing_boost_multiplier = boost
	fishing_boost_time_left = duration

func set_player_idle(val: bool):
	_player_is_idle = val

func show_dialog(text: String):
	# On cherche un label dans la scène actuelle pour afficher l'info
	var ui = get_tree().get_first_node_in_group("ui_layer")
	if ui and ui.has_method("display_info"):
		ui.display_info(text)
	print(text) # Backup console
