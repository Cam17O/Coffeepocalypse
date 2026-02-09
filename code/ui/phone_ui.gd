extends CanvasLayer

const GameConfig = preload("res://code/global/GameConfig.gd")
const PhoneUIBuildService = preload("res://code/ui/PhoneUIBuildService.gd")
const PhoneUIDetailsService = preload("res://code/ui/PhoneUIDetailsService.gd")

@onready var main_control = $MainControl
@onready var left_column = $MainControl/PhoneBody/ContentBox/LeftColumn
@onready var stats_label = $MainControl/PhoneBody/ContentBox/LeftColumn/StatsLabel
@onready var btn_machines = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnMachines
@onready var btn_storages = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnStorages
@onready var btn_spawners = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnSpawners
@onready var btn_cats = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnCats
@onready var btn_player = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnPlayer
@onready var item_list = $MainControl/PhoneBody/ContentBox/LeftColumn/ScrollContainer/ItemList
@onready var add_machine_button = $MainControl/PhoneBody/ContentBox/LeftColumn/AddMachineButton
@onready var add_storage_button = $MainControl/PhoneBody/ContentBox/LeftColumn/AddStorageButton
@onready var add_cat_home_button = $MainControl/PhoneBody/ContentBox/LeftColumn/AddCatHomeButton

@onready var labels = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/Labels
@onready var add_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/AddButton
@onready var products_label = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/ProductsLabel
@onready var products_list = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/ProductsList
@onready var buy_row = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/BuyRow
@onready var buy_1_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/BuyRow/Buy1Button
@onready var buy_10_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/BuyRow/Buy10Button
@onready var buy_max_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/BuyRow/BuyMaxButton
@onready var fill_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/FillButton
@onready var upgrade_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/UpgradeButton
@onready var alt_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/AltButton
@onready var buy_raw_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/FooterRow/BuyRawButton
@onready var close_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/FooterRow/CloseButton
@onready var info_label = $MainControl/PhoneBody/InfoLabel

const RAW_BUY_AMOUNT := GameConfig.RAW_BUY_AMOUNT
const RAW_BUY_COST := GameConfig.RAW_BUY_COST
const RAW_UNIT_COST := RAW_BUY_COST / RAW_BUY_AMOUNT
const BUILD_COST_MACHINE := GameConfig.BUILD_COST_MACHINE
const BUILD_COST_STORAGE := GameConfig.BUILD_COST_STORAGE
const BUILD_COST_CAT_HOME := GameConfig.BUILD_COST_CAT_HOME

enum Tab { MACHINES, STORAGES, CAT_HOMES, CATS, PLAYER }
var current_tab: Tab = Tab.MACHINES
var current_items: Array = []
var storage_products := [
	{"id": "raw_coffee", "name": "Cafe brut", "unit_cost": RAW_UNIT_COST}
]
var build_service: RefCounted
var details_service: RefCounted

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("phone_ui")
	labels.bbcode_enabled = true
	hide()
	build_service = PhoneUIBuildService.new(self)
	details_service = PhoneUIDetailsService.new(self)

	btn_machines.pressed.connect(func(): _set_tab(Tab.MACHINES))
	btn_storages.pressed.connect(func(): _set_tab(Tab.STORAGES))
	btn_spawners.pressed.connect(func(): _set_tab(Tab.CAT_HOMES))
	btn_cats.pressed.connect(func(): _set_tab(Tab.CATS))
	btn_player.pressed.connect(func(): _set_tab(Tab.PLAYER))
	add_machine_button.pressed.connect(func(): _start_build("res://scenes/coffee_machine.tscn", BUILD_COST_MACHINE, "machine"))
	add_storage_button.pressed.connect(func(): _start_build("res://scenes/stockage.tscn", BUILD_COST_STORAGE, "stockage"))
	add_cat_home_button.pressed.connect(func(): _start_build("res://scenes/cats_home.tscn", BUILD_COST_CAT_HOME, "cats house"))

	item_list.item_selected.connect(_on_item_selected)
	fill_button.pressed.connect(_on_fill_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	alt_button.pressed.connect(_on_alt_pressed)
	buy_raw_button.pressed.connect(_on_buy_raw_pressed)
	add_button.pressed.connect(_on_add_pressed)
	products_list.item_selected.connect(_on_product_selected)
	buy_1_button.pressed.connect(func(): _buy_selected_product(1))
	buy_10_button.pressed.connect(func(): _buy_selected_product(10))
	buy_max_button.pressed.connect(func(): _buy_selected_product(-1))
	close_button.pressed.connect(_on_close_pressed)

	_setup_labels()
	_set_tab(Tab.MACHINES)

func _unhandled_input(event):
	if build_service and build_service.handle_unhandled_input(event):
		return
	if event.is_action_pressed("toggle_phone"):
		_toggle_visibility()

func _process(_delta):
	if not visible:
		if build_service:
			build_service.process()
		return
	_refresh_header_stats()
	_refresh_footer()
	_refresh_selected_details()
	if build_service:
		build_service.process()

func _toggle_visibility():
	visible = not visible
	get_tree().paused = visible
	if visible:
		_set_tab(Tab.MACHINES)

func _setup_labels():
	btn_machines.text = "Machines"
	btn_storages.text = "Stockage"
	btn_spawners.text = "Cats house"
	btn_cats.text = "Chats"
	btn_player.text = "Joueur"
	add_machine_button.text = "+ Ajouter machine (" + str(int(BUILD_COST_MACHINE)) + ")"
	add_storage_button.text = "+ Ajouter stockage (" + str(int(BUILD_COST_STORAGE)) + ")"
	add_cat_home_button.text = "+ Ajouter cats house (" + str(int(BUILD_COST_CAT_HOME)) + ")"
	stats_label.text = "Or: 0 | Satisfaction: 100"
	fill_button.text = "Action"
	upgrade_button.text = "Ameliorer"
	alt_button.text = "Action 2"
	add_button.text = "+ Ajouter"
	buy_raw_button.text = "Acheter cafe brut x" + str(RAW_BUY_AMOUNT)
	buy_raw_button.visible = false
	products_label.text = "Produits"
	close_button.text = "Fermer"
	info_label.text = "P pour ouvrir/fermer"

func _set_tab(tab: Tab):
	current_tab = tab
	item_list.clear()
	current_items.clear()
	_refresh_list()
	_refresh_selected_details()
	left_column.visible = true

func _refresh_list():
	item_list.clear()
	current_items.clear()
	match current_tab:
		Tab.MACHINES:
			var machines = get_tree().get_nodes_in_group("machines")
			for i in machines.size():
				var machine = machines[i]
				current_items.append(machine)
				item_list.add_item("Machine " + str(i + 1))
		Tab.STORAGES:
			var storages = get_tree().get_nodes_in_group("storages")
			for i in storages.size():
				var storage = storages[i]
				current_items.append(storage)
				item_list.add_item("Stockage " + str(i + 1))
		Tab.CATS:
			var cats = get_tree().get_nodes_in_group("cats")
			for i in cats.size():
				var cat = cats[i]
				current_items.append(cat)
				item_list.add_item("Chat " + str(i + 1))
		Tab.CAT_HOMES:
			var homes = get_tree().get_nodes_in_group("cat_homes")
			for i in homes.size():
				var home = homes[i]
				current_items.append(home)
				item_list.add_item("Cats house " + str(i + 1))
		Tab.PLAYER:
			current_items.append(null)
	if item_list.item_count > 0:
		item_list.select(0)

func _on_item_selected(index: int):
	_show_details(index)

func _refresh_selected_details():
	if current_tab == Tab.PLAYER:
		_show_details(0)
		return
	if item_list.item_count <= 0:
		return
	var selected = item_list.get_selected_items()
	if selected.size() == 0:
		return
	_show_details(selected[0])

func _show_details(index: int):
	var item = current_items[index] if index < current_items.size() else null
	match current_tab:
		Tab.MACHINES:
			labels.text = details_service.machine_details(item) if details_service else ""
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = true
			add_storage_button.visible = false
			add_cat_home_button.visible = false
			fill_button.visible = true
			upgrade_button.visible = true
			alt_button.visible = false
			buy_raw_button.visible = false
			fill_button.text = "Remplir (sac -> machine)"
			upgrade_button.text = "Ameliorer machine (" + str(int(_machine_upgrade_cost(item))) + ")"
		Tab.STORAGES:
			labels.text = details_service.storage_details(item) if details_service else ""
			add_button.visible = true
			add_button.text = "Auto remplissage: " + ("ON" if item and item.auto_fill_enabled else "OFF")
			_set_storage_purchase_visible(true)
			add_machine_button.visible = false
			add_storage_button.visible = true
			add_cat_home_button.visible = false
			fill_button.visible = true
			upgrade_button.visible = true
			alt_button.visible = true
			buy_raw_button.visible = false
			fill_button.text = "Prendre x10"
			alt_button.text = "Deposer x10"
			upgrade_button.text = "Ameliorer stockage (" + str(int(_storage_upgrade_cost(item))) + ")"
		Tab.CATS:
			labels.text = details_service.cat_details(item) if details_service else ""
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = false
			add_storage_button.visible = false
			add_cat_home_button.visible = false
			fill_button.visible = false
			upgrade_button.visible = false
			alt_button.visible = false
			buy_raw_button.visible = false
		Tab.CAT_HOMES:
			labels.text = details_service.cat_home_details(item) if details_service else ""
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = false
			add_storage_button.visible = false
			add_cat_home_button.visible = true
			fill_button.visible = false
			upgrade_button.visible = true
			alt_button.visible = false
			buy_raw_button.visible = false
			upgrade_button.text = "Ameliorer cats house (" + str(int(_cat_home_upgrade_cost(item))) + ")"
		Tab.PLAYER:
			labels.text = details_service.player_details() if details_service else ""
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = false
			add_storage_button.visible = false
			add_cat_home_button.visible = false
			fill_button.visible = false
			upgrade_button.visible = false
			alt_button.visible = false
			buy_raw_button.visible = false

func _on_fill_pressed():
	var item = _get_selected_item()
	match current_tab:
		Tab.MACHINES:
			_fill_machine(item)
		Tab.STORAGES:
			_take_from_storage(item)
		Tab.PLAYER:
			pass
		_:
			pass
	_refresh_selected_details()

func _on_upgrade_pressed():
	match current_tab:
		Tab.MACHINES:
			_upgrade_machine()
		Tab.STORAGES:
			_upgrade_storage()
		Tab.CAT_HOMES:
			_upgrade_cat_home()
		_:
			pass
	_refresh_selected_details()

func _on_alt_pressed():
	var item = _get_selected_item()
	match current_tab:
		Tab.STORAGES:
			_deposit_to_storage(item)
		_:
			pass
	_refresh_selected_details()

func _on_product_selected(_index: int):
	pass

func _on_add_pressed():
	match current_tab:
		Tab.STORAGES:
			var storage = _get_selected_item()
			if storage and is_instance_valid(storage):
				storage.auto_fill_enabled = not storage.auto_fill_enabled
				_refresh_selected_details()
		_:
			pass

func _get_selected_item():
	var selected = item_list.get_selected_items()
	if selected.size() == 0:
		return null
	var index = selected[0]
	return current_items[index] if index < current_items.size() else null

func _refresh_footer():
	buy_raw_button.text = "Acheter cafe brut x" + str(RAW_BUY_AMOUNT) + " (" + str(int(RAW_BUY_COST)) + ")"

func _refresh_header_stats():
	stats_label.text = "Or: " + str(int(Global.money)) + " | Satisfaction: " + str(int(Global.global_satisfaction))

func _machine_upgrade_cost(machine) -> float:
	if machine == null or not is_instance_valid(machine):
		return GameConfig.UPGRADE_MACHINE_BASE_COST
	var level = machine.get_upgrade_level() if machine.has_method("get_upgrade_level") else 0
	return GameConfig.UPGRADE_MACHINE_BASE_COST + level * GameConfig.UPGRADE_MACHINE_PER_LEVEL_COST

func _storage_upgrade_cost(storage) -> float:
	if storage == null or not is_instance_valid(storage):
		return GameConfig.UPGRADE_STORAGE_BASE_COST
	var level = storage.get_upgrade_level() if storage.has_method("get_upgrade_level") else 0
	return GameConfig.UPGRADE_STORAGE_BASE_COST + level * GameConfig.UPGRADE_STORAGE_PER_LEVEL_COST

func _cat_home_upgrade_cost(home) -> float:
	if home == null or not is_instance_valid(home):
		return GameConfig.UPGRADE_CAT_HOME_BASE_COST
	var level = home.get_upgrade_level() if home.has_method("get_upgrade_level") else 0
	return GameConfig.UPGRADE_CAT_HOME_BASE_COST + level * GameConfig.UPGRADE_CAT_HOME_PER_LEVEL_COST

func _upgrade_machine():
	var machine = _get_selected_item()
	if machine == null or not is_instance_valid(machine):
		return
	var cost = _machine_upgrade_cost(machine)
	if Global.money < cost:
		print("[PhoneUI] Upgrade machine failed: not enough money")
		return
	Global.add_money(-cost)
	var level = machine.get_upgrade_level() if machine.has_method("get_upgrade_level") else 0
	level += 1
	if machine.has_method("apply_upgrade_level"):
		machine.apply_upgrade_level(level)
	print("[PhoneUI] Upgrade machine lvl", level)

func _upgrade_storage():
	var storage = _get_selected_item()
	if storage == null or not is_instance_valid(storage):
		return
	var cost = _storage_upgrade_cost(storage)
	if Global.money < cost:
		print("[PhoneUI] Upgrade storage failed: not enough money")
		return
	Global.add_money(-cost)
	var level = storage.get_upgrade_level() if storage.has_method("get_upgrade_level") else 0
	level += 1
	if storage.has_method("apply_upgrade_level"):
		storage.apply_upgrade_level(level)
	print("[PhoneUI] Upgrade storage lvl", level)

func _upgrade_cat_home():
	var home = _get_selected_item()
	if home == null or not is_instance_valid(home):
		return
	var cost = _cat_home_upgrade_cost(home)
	if Global.money < cost:
		print("[PhoneUI] Upgrade cats house failed: not enough money")
		return
	Global.add_money(-cost)
	var level = home.get_upgrade_level() if home.has_method("get_upgrade_level") else 0
	level += 1
	if home.has_method("apply_upgrade_level"):
		home.apply_upgrade_level(level)
	print("[PhoneUI] Upgrade cats house lvl", level)

func _fill_machine(machine):
	if machine == null or not is_instance_valid(machine):
		return
	var space = machine.max_coffee_stock - machine.current_coffee_stock
	if space <= 0 or Global.raw_coffee_carried <= 0:
		return
	var transfer = min(space, Global.raw_coffee_carried)
	machine.current_coffee_stock += transfer
	Global.raw_coffee_carried -= transfer

func _take_from_storage(storage):
	if storage == null or not is_instance_valid(storage):
		return
	if Global.raw_coffee_carried >= Global.max_coffee_capacity or storage.coffee_inventory <= 0:
		return
	var amount = min(GameConfig.STORAGE_TRANSFER_AMOUNT, storage.coffee_inventory, Global.max_coffee_capacity - Global.raw_coffee_carried)
	storage.coffee_inventory -= amount
	Global.raw_coffee_carried += amount

func _deposit_to_storage(storage):
	if storage == null or not is_instance_valid(storage):
		return
	if Global.raw_coffee_carried <= 0 or storage.coffee_inventory >= storage.max_inventory:
		return
	var space = storage.max_inventory - storage.coffee_inventory
	var amount = min(GameConfig.STORAGE_TRANSFER_AMOUNT, space, Global.raw_coffee_carried)
	storage.coffee_inventory += amount
	Global.raw_coffee_carried -= amount

func _on_buy_raw_pressed():
	if Global.money < RAW_BUY_COST:
		print("[PhoneUI] Buy raw failed: not enough money")
		return
	if _total_storage_space() <= 0:
		print("[PhoneUI] Buy raw failed: storage full")
		return
	Global.add_money(-RAW_BUY_COST)
	print("[PhoneUI] Buy raw:", RAW_BUY_AMOUNT)
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

func _refresh_storage_products():
	products_list.clear()
	var lines = details_service.storage_product_list_text(storage_products) if details_service else []
	for line in lines:
		products_list.add_item(line)
	if products_list.item_count > 0:
		products_list.select(0)

func _set_storage_purchase_visible(is_visible: bool):
	products_label.visible = is_visible
	products_list.visible = is_visible
	buy_row.visible = is_visible
	if is_visible:
		_refresh_storage_products()

func _buy_selected_product(amount: int):
	if current_tab != Tab.STORAGES:
		return
	var storage = _get_selected_item()
	if storage == null or not is_instance_valid(storage):
		return
	if products_list.item_count == 0:
		return
	var selected = products_list.get_selected_items()
	if selected.size() == 0:
		return
	var product = storage_products[selected[0]]
	var unit_cost = float(product["unit_cost"])
	var space = storage.max_inventory - storage.coffee_inventory
	if space <= 0:
		display_info("Stockage plein")
		return
	var max_affordable = int(Global.money / unit_cost)
	var desired = amount
	if amount < 0:
		desired = space
	var final_amount = min(space, desired, max_affordable)
	if final_amount <= 0:
		display_info("Pas assez d'argent")
		return
	Global.add_money(-final_amount * unit_cost)
	if product["id"] == "raw_coffee":
		storage.coffee_inventory += final_amount
		display_info("Achete x" + str(final_amount))

func _start_build(scene_path: String, cost: float, label: String):
	if build_service:
		build_service.start_build(scene_path, cost, label)

func _on_close_pressed():
	_toggle_visibility()

func open_tab(tab: Tab, target: Node = null):
	if not visible:
		visible = true
		get_tree().paused = true
	_refresh_list()
	_set_tab(tab)
	if target:
		for i in range(item_list.item_count):
			if current_items[i] == target:
				item_list.select(i)
				_show_details(i)
				break

func display_info(msg: String):
	info_label.text = msg

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
