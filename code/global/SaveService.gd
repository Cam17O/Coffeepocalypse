extends RefCounted

var _global: Node

const SAVE_PATH := "user://save.json"
const EXPORT_PATH := "user://save_export.json"

func _init(global: Node):
	_global = global

func save_game():
	_write_save_file(SAVE_PATH, _collect_data())

func load_game():
	_load_from_path(SAVE_PATH)

func export_save():
	_write_save_file(EXPORT_PATH, _collect_data())

func import_save():
	_load_from_path(EXPORT_PATH)

func _collect_data() -> Dictionary:
	return {
		"money": _global.money,
		"raw_coffee_carried": _global.raw_coffee_carried,
		"max_coffee_capacity": _global.max_coffee_capacity,
		"global_satisfaction": _global.global_satisfaction,
		"machine_upgrade_level": _global.machine_upgrade_level,
		"storage_upgrade_level": _global.storage_upgrade_level,
		"cat_home_upgrade_level": _global.cat_home_upgrade_level,
		"unlocked_talents": _global.unlocked_talents
	}

func _write_save_file(path: String, data: Dictionary):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

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
	_apply_data(parsed)

func _apply_data(parsed: Dictionary):
	_global.money = parsed.get("money", _global.money)
	_global.raw_coffee_carried = parsed.get("raw_coffee_carried", _global.raw_coffee_carried)
	_global.max_coffee_capacity = parsed.get("max_coffee_capacity", _global.max_coffee_capacity)
	_global.global_satisfaction = parsed.get("global_satisfaction", _global.global_satisfaction)
	_global.machine_upgrade_level = parsed.get("machine_upgrade_level", _global.machine_upgrade_level)
	_global.storage_upgrade_level = parsed.get("storage_upgrade_level", _global.storage_upgrade_level)
	_global.cat_home_upgrade_level = parsed.get("cat_home_upgrade_level", _global.cat_home_upgrade_level)
	_global.unlocked_talents = parsed.get("unlocked_talents", _global.unlocked_talents)
	_global.queue_apply_upgrades()
