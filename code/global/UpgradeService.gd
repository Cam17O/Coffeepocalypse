extends RefCounted

var _global: Node
var _pending_apply_upgrades: bool = false

func _init(global: Node):
	_global = global

func queue_apply_upgrades():
	_pending_apply_upgrades = true

func process():
	if _pending_apply_upgrades:
		_try_apply_upgrades()

func apply_upgrades_if_ready():
	_try_apply_upgrades()

func _try_apply_upgrades():
	if _global.get_tree().current_scene == null:
		return
	var machines = _global.get_tree().get_nodes_in_group("machines")
	var storages = _global.get_tree().get_nodes_in_group("storages")
	var homes = _global.get_tree().get_nodes_in_group("cat_homes")
	if machines.is_empty() and storages.is_empty() and homes.is_empty():
		return
	_apply_upgrades_to_world(machines, storages, homes)
	_pending_apply_upgrades = false

func _apply_upgrades_to_world(machines: Array, storages: Array, homes: Array):
	_global.fishing_tick_interval = max(1.5, 4.0 - 0.2 * _global.fishing_upgrade_level)
	for machine in machines:
		if machine.has_method("apply_upgrade_level"):
			machine.apply_upgrade_level(_global.machine_upgrade_level)
	for storage in storages:
		if storage.has_method("apply_upgrade_level"):
			storage.apply_upgrade_level(_global.storage_upgrade_level)
	for home in homes:
		if home.has_method("apply_upgrade_level"):
			home.apply_upgrade_level(_global.cat_home_upgrade_level)
