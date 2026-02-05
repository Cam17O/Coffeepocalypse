extends Control

@onready var panel = $Panel
@onready var money_label = $Panel/VBoxContainer/MoneyLabel
@onready var satisfaction_label = $Panel/VBoxContainer/SatisfactionLabel
@onready var raw_coffee_label = $Panel/VBoxContainer/RawCoffeeLabel
@onready var storage_label = $Panel/VBoxContainer/StorageLabel
@onready var fishing_label = $Panel/VBoxContainer/FishingLabel

@onready var upgrade_machine_button = $Panel/VBoxContainer/UpgradeMachineButton
@onready var upgrade_storage_button = $Panel/VBoxContainer/UpgradeStorageButton
@onready var upgrade_fishing_button = $Panel/VBoxContainer/UpgradeFishingButton
@onready var buy_raw_button = $Panel/VBoxContainer/BuyRawCoffeeButton
@onready var export_button = $Panel/VBoxContainer/ExportSaveButton
@onready var import_button = $Panel/VBoxContainer/ImportSaveButton
@onready var close_button = $Panel/VBoxContainer/CloseButton

const RAW_BUY_AMOUNT := 10
const RAW_BUY_COST := 25.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	upgrade_machine_button.pressed.connect(_on_upgrade_machine_pressed)
	upgrade_storage_button.pressed.connect(_on_upgrade_storage_pressed)
	upgrade_fishing_button.pressed.connect(_on_upgrade_fishing_pressed)
	buy_raw_button.pressed.connect(_on_buy_raw_pressed)
	export_button.pressed.connect(_on_export_pressed)
	import_button.pressed.connect(_on_import_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("toggle_phone"):
		_toggle_visibility()

func _process(_delta):
	if not visible:
		return
	_refresh_labels()

func _toggle_visibility():
	visible = not visible
	get_tree().paused = visible

func _refresh_labels():
	money_label.text = "Argent: " + str(snapped(Global.money, 0.1))
	satisfaction_label.text = "Satisfaction: " + str(int(Global.global_satisfaction))
	raw_coffee_label.text = "Cafe brut: " + str(Global.raw_coffee_carried) + " / " + str(Global.max_coffee_capacity)
	storage_label.text = "Stock zone: " + str(_total_storage_stock())
	fishing_label.text = "Peche lvl: " + str(Global.fishing_level)

	upgrade_machine_button.text = "Ameliorer machine (" + str(int(_machine_upgrade_cost())) + ")"
	upgrade_storage_button.text = "Ameliorer stockage (" + str(int(_storage_upgrade_cost())) + ")"
	upgrade_fishing_button.text = "Ameliorer peche (" + str(int(_fishing_upgrade_cost())) + ")"
	buy_raw_button.text = "Acheter cafe brut x" + str(RAW_BUY_AMOUNT) + " (" + str(int(RAW_BUY_COST)) + ")"

func _machine_upgrade_cost() -> float:
	return 40.0 + Global.machine_upgrade_level * 25.0

func _storage_upgrade_cost() -> float:
	return 30.0 + Global.storage_upgrade_level * 20.0

func _fishing_upgrade_cost() -> float:
	return 25.0 + Global.fishing_upgrade_level * 15.0

func _on_upgrade_machine_pressed():
	var cost = _machine_upgrade_cost()
	if Global.money < cost:
		return
	Global.add_money(-cost)
	Global.machine_upgrade_level += 1
	for machine in get_tree().get_nodes_in_group("machines"):
		if machine.has_method("apply_upgrade_level"):
			machine.apply_upgrade_level(Global.machine_upgrade_level)

func _on_upgrade_storage_pressed():
	var cost = _storage_upgrade_cost()
	if Global.money < cost:
		return
	Global.add_money(-cost)
	Global.storage_upgrade_level += 1
	for storage in get_tree().get_nodes_in_group("storages"):
		if storage.has_method("apply_upgrade_level"):
			storage.apply_upgrade_level(Global.storage_upgrade_level)

func _on_upgrade_fishing_pressed():
	var cost = _fishing_upgrade_cost()
	if Global.money < cost:
		return
	Global.add_money(-cost)
	Global.fishing_upgrade_level += 1
	Global.fishing_level += 1
	Global.fishing_tick_interval = max(1.5, Global.fishing_tick_interval - 0.2)

func _on_buy_raw_pressed():
	if Global.money < RAW_BUY_COST:
		return
	if _total_storage_space() <= 0:
		return
	Global.add_money(-RAW_BUY_COST)
	var remaining = RAW_BUY_AMOUNT
	for storage in get_tree().get_nodes_in_group("storages"):
		var space = storage.max_inventory - storage.coffee_inventory
		if space <= 0:
			continue
		var add = min(space, remaining)
		storage.coffee_inventory += add
		remaining -= add
		if remaining <= 0:
			return

func _on_export_pressed():
	Global.export_save()

func _on_import_pressed():
	Global.import_save()
	Global.apply_upgrades_if_ready()

func _on_close_pressed():
	_toggle_visibility()

func _total_storage_stock() -> int:
	var total = 0
	for storage in get_tree().get_nodes_in_group("storages"):
		total += storage.coffee_inventory
	return total

func _total_storage_space() -> int:
	var total = 0
	for storage in get_tree().get_nodes_in_group("storages"):
		total += max(0, storage.max_inventory - storage.coffee_inventory)
	return total
