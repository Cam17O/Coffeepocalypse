extends CanvasLayer

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

const RAW_BUY_AMOUNT := 10
const RAW_BUY_COST := 40.0
const RAW_UNIT_COST := RAW_BUY_COST / RAW_BUY_AMOUNT
const BUILD_COST_MACHINE := 240.0
const BUILD_COST_STORAGE := 180.0
const BUILD_COST_CAT_HOME := 320.0

enum Tab { MACHINES, STORAGES, CAT_HOMES, CATS, PLAYER }
var current_tab: Tab = Tab.MACHINES
var current_items: Array = []
var storage_products := [
	{"id": "raw_coffee", "name": "Cafe brut", "unit_cost": RAW_UNIT_COST}
]
var _pending_build_scene: PackedScene
var _pending_build_cost: float = 0.0
var _pending_build_name: String = ""
var _build_ghost: Node2D
const BUILD_SNAP_TOLERANCE := 8.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("phone_ui")
	labels.bbcode_enabled = true
	hide()

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
	if _pending_build_scene and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_pending_build()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_pending_build()
		return
	if event.is_action_pressed("toggle_phone"):
		_toggle_visibility()

func _process(_delta):
	if not visible:
		if _pending_build_scene:
			_update_build_ghost()
		return
	_refresh_header_stats()
	_refresh_footer()
	_refresh_selected_details()
	if _pending_build_scene:
		_update_build_ghost()

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
			labels.text = _machine_details(item)
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
			upgrade_button.text = "Ameliorer machine (" + str(int(_machine_upgrade_cost())) + ")"
		Tab.STORAGES:
			labels.text = _storage_details(item)
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
			upgrade_button.text = "Ameliorer stockage (" + str(int(_storage_upgrade_cost())) + ")"
		Tab.CATS:
			labels.text = _cat_details(item)
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
			labels.text = _cat_home_details(item)
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = false
			add_storage_button.visible = false
			add_cat_home_button.visible = true
			fill_button.visible = false
			upgrade_button.visible = true
			alt_button.visible = false
			buy_raw_button.visible = false
			upgrade_button.text = "Ameliorer cats house (" + str(int(_cat_home_upgrade_cost())) + ")"
		Tab.PLAYER:
			labels.text = _player_details()
			add_button.visible = false
			_set_storage_purchase_visible(false)
			add_machine_button.visible = false
			add_storage_button.visible = false
			add_cat_home_button.visible = false
			fill_button.visible = false
			upgrade_button.visible = true
			alt_button.visible = false
			buy_raw_button.visible = false
			upgrade_button.text = "Ameliorer peche (" + str(int(_fishing_upgrade_cost())) + ")"

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
		Tab.PLAYER:
			_upgrade_fishing()
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

func _machine_details(machine) -> String:
	if machine == null or not is_instance_valid(machine):
		return "Machine manquante"
	var lines = []
	lines.append("[b]Machine[/b]")
	lines.append("Stock: " + str(machine.current_coffee_stock) + " / " + str(machine.max_coffee_stock))
	lines.append("Temps infusion: " + str(snapped(machine.brewing_time, 0.1)) + "s")
	lines.append("Echec: " + str(int(machine.fail_chance * 100.0)) + "%")
	lines.append("Mauvais gout: " + str(int(machine.bad_taste_chance * 100.0)) + "%")
	lines.append("Prend argent si echec: " + str(int(machine.take_money_on_fail_chance * 100.0)) + "%")
	lines.append("Prix cafe: " + str(snapped(machine.coffee_price, 0.1)))
	lines.append("Satisfaction (+/-): " + str(snapped(machine.satisfaction_reward, 0.1)) + " / " + str(snapped(machine.satisfaction_penalty, 0.1)))
	lines.append("Boost peche: x" + str(snapped(machine.coffee_fishing_boost, 0.1)) + " pendant " + str(snapped(machine.coffee_energy_duration, 0.1)) + "s")
	var success_rate = max(0.0, 1.0 - machine.fail_chance)
	var expected_per_brew = machine.coffee_price * success_rate
	var expected_per_min = (60.0 / max(0.1, machine.brewing_time)) * expected_per_brew
	lines.append("Occupe: " + str(machine.is_busy))
	lines.append("Succes: " + str(int(success_rate * 100.0)) + "%")
	lines.append("Gain moyen / infusion: " + str(snapped(expected_per_brew, 0.1)))
	lines.append("Gain moyen / min: " + str(snapped(expected_per_min, 0.1)))
	return "\n".join(lines)

func _storage_details(storage) -> String:
	if storage == null or not is_instance_valid(storage):
		return "Stockage manquant"
	var lines = []
	lines.append("[b]Stockage[/b]")
	lines.append("Stock: " + str(storage.coffee_inventory) + " / " + str(storage.max_inventory))
	lines.append("Arrivage: +" + str(storage.arrival_amount) + " / " + str(snapped(storage.arrival_interval, 0.1)) + "s")
	lines.append("Auto remplissage: " + ("ON" if storage.auto_fill_enabled else "OFF"))
	lines.append("Cout auto: " + str(snapped(storage.auto_fill_cost_per_unit, 0.1)) + " / unite")
	lines.append("Capacite sac: " + str(Global.max_coffee_capacity))
	lines.append("Sac actuel: " + str(Global.raw_coffee_carried))
	var free_space = max(0, storage.max_inventory - storage.coffee_inventory)
	var fill_time = 0.0
	if storage.arrival_amount > 0:
		fill_time = (free_space / float(storage.arrival_amount)) * storage.arrival_interval
	lines.append("Place libre: " + str(free_space))
	lines.append("Temps pour remplir: " + str(snapped(fill_time, 0.1)) + "s")
	return "\n".join(lines)

func _cat_details(cat) -> String:
	if cat == null or not is_instance_valid(cat):
		return "Chat manquant"
	var is_special = cat.get("is_special")
	var health = cat.get("health")
	var energy = cat.get("energy")
	var max_energy = cat.get("max_energy")
	var lines = []
	lines.append("[b]Chat[/b]")
	lines.append("Special: " + str(is_special))
	lines.append("Vie: " + str(health))
	lines.append("Energie: " + str(int(energy)) + " / " + str(int(max_energy)))
	var state_label = str(cat.current_state)
	if cat.current_state == 0:
		state_label = "Balade"
	elif cat.current_state == 1:
		state_label = "Cherche cafe"
	elif cat.current_state == 2:
		state_label = "Attente"
	elif cat.current_state == 3:
		state_label = "Boit"
	lines.append("Etat: " + state_label)
	return "\n".join(lines)

func _storage_product_list_text() -> Array:
	var result = []
	for product in storage_products:
		var name = product["name"]
		var unit = product["unit_cost"]
		result.append(name + " (" + str(snapped(unit, 0.1)) + "$)")
	return result

func _cat_home_details(home) -> String:
	if home == null or not is_instance_valid(home):
		return "Cats house manquante"
	var lines = []
	lines.append("[b]Cats house[/b]")
	lines.append("Niveau: " + str(home.upgrade_level))
	lines.append("Chats max: " + str(home.max_cats_alive))
	lines.append("Spawn: " + str(snapped(home.min_spawn_interval, 0.1)) + "s - " + str(snapped(home.max_spawn_interval, 0.1)) + "s")
	lines.append("Chance: " + str(int(home.min_spawn_chance * 100.0)) + "% - " + str(int(home.max_spawn_chance * 100.0)) + "%")
	var current = get_tree().get_nodes_in_group("cats").size()
	var capacity_rate = 0.0
	if home.max_cats_alive > 0:
		capacity_rate = float(current) / float(home.max_cats_alive)
	lines.append("Chats actuels: " + str(current))
	lines.append("Occupation: " + str(int(capacity_rate * 100.0)) + "%")
	return "\n".join(lines)

func _stats_details() -> String:
	var lines = []
	lines.append("[b]Stats[/b]")
	lines.append("Argent: " + str(snapped(Global.money, 0.1)))
	lines.append("Satisfaction: " + str(int(Global.global_satisfaction)))
	lines.append("Cafe brut sac: " + str(Global.raw_coffee_carried) + " / " + str(Global.max_coffee_capacity))
	lines.append("Stock zone: " + str(_total_storage_stock()))
	lines.append("Chats: " + str(get_tree().get_nodes_in_group("cats").size()))
	return "\n".join(lines)

func _player_details() -> String:
	var lines = []
	lines.append("[b]Joueur[/b]")
	lines.append("Peche lvl: " + str(Global.fishing_level))
	lines.append("Argent: " + str(snapped(Global.money, 0.1)))
	lines.append("Cafe brut sac: " + str(Global.raw_coffee_carried) + " / " + str(Global.max_coffee_capacity))
	lines.append("Boost peche: x" + str(snapped(Global.fishing_boost_multiplier, 0.1)) + " (" + str(snapped(Global.fishing_boost_time_left, 0.1)) + "s)")
	lines.append("Tick peche: " + str(snapped(Global.fishing_tick_interval, 0.1)) + "s")
	lines.append("Gain moyen / min: " + str(snapped((60.0 / max(0.1, Global.fishing_tick_interval)) * (1.0 * Global.fishing_boost_multiplier), 0.1)))
	return "\n".join(lines)

func _refresh_footer():
	buy_raw_button.text = "Acheter cafe brut x" + str(RAW_BUY_AMOUNT) + " (" + str(int(RAW_BUY_COST)) + ")"

func _refresh_header_stats():
	stats_label.text = "Or: " + str(int(Global.money)) + " | Satisfaction: " + str(int(Global.global_satisfaction))

func _machine_upgrade_cost() -> float:
	return 40.0 + Global.machine_upgrade_level * 25.0

func _storage_upgrade_cost() -> float:
	return 30.0 + Global.storage_upgrade_level * 20.0

func _fishing_upgrade_cost() -> float:
	return 25.0 + Global.fishing_upgrade_level * 15.0

func _cat_home_upgrade_cost() -> float:
	return 35.0 + Global.cat_home_upgrade_level * 25.0

func _upgrade_machine():
	var cost = _machine_upgrade_cost()
	if Global.money < cost:
		print("[PhoneUI] Upgrade machine failed: not enough money")
		return
	Global.add_money(-cost)
	Global.machine_upgrade_level += 1
	print("[PhoneUI] Upgrade machine lvl", Global.machine_upgrade_level)
	for machine in get_tree().get_nodes_in_group("machines"):
		if machine.has_method("apply_upgrade_level"):
			machine.apply_upgrade_level(Global.machine_upgrade_level)

func _upgrade_storage():
	var cost = _storage_upgrade_cost()
	if Global.money < cost:
		print("[PhoneUI] Upgrade storage failed: not enough money")
		return
	Global.add_money(-cost)
	Global.storage_upgrade_level += 1
	print("[PhoneUI] Upgrade storage lvl", Global.storage_upgrade_level)
	for storage in get_tree().get_nodes_in_group("storages"):
		if storage.has_method("apply_upgrade_level"):
			storage.apply_upgrade_level(Global.storage_upgrade_level)

func _upgrade_cat_home():
	var cost = _cat_home_upgrade_cost()
	if Global.money < cost:
		print("[PhoneUI] Upgrade cats house failed: not enough money")
		return
	Global.add_money(-cost)
	Global.cat_home_upgrade_level += 1
	print("[PhoneUI] Upgrade cats house lvl", Global.cat_home_upgrade_level)
	for home in get_tree().get_nodes_in_group("cat_homes"):
		if home.has_method("apply_upgrade_level"):
			home.apply_upgrade_level(Global.cat_home_upgrade_level)

func _upgrade_fishing():
	var cost = _fishing_upgrade_cost()
	if Global.money < cost:
		return
	Global.add_money(-cost)
	Global.fishing_upgrade_level += 1
	Global.fishing_level += 1
	Global.fishing_tick_interval = max(1.5, Global.fishing_tick_interval - 0.2)

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
	var amount = min(10, storage.coffee_inventory, Global.max_coffee_capacity - Global.raw_coffee_carried)
	storage.coffee_inventory -= amount
	Global.raw_coffee_carried += amount

func _deposit_to_storage(storage):
	if storage == null or not is_instance_valid(storage):
		return
	if Global.raw_coffee_carried <= 0 or storage.coffee_inventory >= storage.max_inventory:
		return
	var space = storage.max_inventory - storage.coffee_inventory
	var amount = min(10, space, Global.raw_coffee_carried)
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
	for line in _storage_product_list_text():
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
	if Global.money < cost:
		display_info("Pas assez d'argent")
		return
	_pending_build_scene = load(scene_path)
	_pending_build_cost = cost
	_pending_build_name = label
	visible = false
	get_tree().paused = false
	_create_build_ghost()
	print("[Build] Start:", label, "cost", cost)

func _place_pending_build():
	if not _pending_build_scene:
		return
	if Global.money < _pending_build_cost:
		display_info("Pas assez d'argent")
		_cancel_pending_build()
		return
	var world_pos = _get_mouse_world_position()
	var instance = _pending_build_scene.instantiate()
	instance.global_position = world_pos
	var parent = get_tree().current_scene
	var nav = parent.get_node_or_null("NavigationRegion2D")
	if nav:
		nav.add_child(instance)
	else:
		parent.add_child(instance)
	Global.add_money(-_pending_build_cost)
	print("[Build] Placed:", _pending_build_name, "at", world_pos)
	_cancel_pending_build()

func _cancel_pending_build():
	_pending_build_scene = null
	_pending_build_cost = 0.0
	_pending_build_name = ""
	if _build_ghost and is_instance_valid(_build_ghost):
		_build_ghost.queue_free()
	_build_ghost = null

func _create_build_ghost():
	if not _pending_build_scene:
		return
	if _build_ghost and is_instance_valid(_build_ghost):
		_build_ghost.queue_free()
	_build_ghost = _pending_build_scene.instantiate()
	_build_ghost.modulate = Color(1, 1, 1, 0.5)
	_build_ghost.process_mode = Node.PROCESS_MODE_DISABLED
	var parent = get_tree().current_scene
	var nav = parent.get_node_or_null("NavigationRegion2D")
	if nav:
		nav.add_child(_build_ghost)
	else:
		parent.add_child(_build_ghost)
	_update_build_ghost()

func _update_build_ghost():
	if not _build_ghost or not is_instance_valid(_build_ghost):
		return
	var pos = _get_mouse_world_position()
	_build_ghost.global_position = pos
	var ok = _is_valid_build_position(pos)
	if ok:
		_build_ghost.modulate = Color(0.2, 1.0, 0.2, 0.5)
	else:
		_build_ghost.modulate = Color(1.0, 0.2, 0.2, 0.5)

func _get_mouse_world_position() -> Vector2:
	var mouse_pos = get_viewport().get_mouse_position()
	return get_viewport().get_canvas_transform().affine_inverse() * mouse_pos

func _is_valid_build_position(world_pos: Vector2) -> bool:
	var parent = get_tree().current_scene
	if not parent:
		return true
	var world = parent.get_world_2d()
	if not world:
		return true
	var nav_map = world.navigation_map
	if nav_map == RID():
		return true
	var closest = NavigationServer2D.map_get_closest_point(nav_map, world_pos)
	return world_pos.distance_to(closest) <= BUILD_SNAP_TOLERANCE

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
