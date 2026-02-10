extends StaticBody2D

const GameData = preload("res://code/global/GameData.gd")

@export var robot_type_id: String = "robot_storage"
var _action_timer: float = 0.0

func _ready():
	add_to_group("robots")
	if robot_type_id.is_empty():
		for rid in GameData.ROBOT_TYPES:
			if rid in Global.unlocked_talents:
				robot_type_id = rid
				break
	_apply_type_config()

func _apply_type_config():
	pass

func _process(delta: float):
	_action_timer += delta
	if _action_timer < 2.0:
		return
	_action_timer = 0.0
	if robot_type_id == "robot_storage":
		_do_storage_transport()
	elif robot_type_id == "robot_cleaner":
		_do_clean_machine()
	elif robot_type_id == "robot_reparateur":
		_do_repair_machine()

func _do_storage_transport():
	var storages = get_tree().get_nodes_in_group("storages")
	var machines = get_tree().get_nodes_in_group("machines")
	if storages.is_empty() or machines.is_empty():
		return
	var storage = storages[0]
	if storage.coffee_inventory <= 0:
		return
	var emptiest: Node = null
	var min_stock = 999999
	for m in machines:
		if m.current_coffee_stock < min_stock:
			min_stock = m.current_coffee_stock
			emptiest = m
	if not emptiest or emptiest.current_coffee_stock >= emptiest.max_coffee_stock:
		return
	var amount = mini(5, storage.coffee_inventory, emptiest.max_coffee_stock - emptiest.current_coffee_stock)
	storage.coffee_inventory -= amount
	emptiest.current_coffee_stock += amount

func _do_clean_machine():
	var machines = get_tree().get_nodes_in_group("machines")
	var dirtiest: Node = null
	var min_clean = 999999.0
	for m in machines:
		if m.has_method("needs_cleaning") and m.needs_cleaning():
			if m.cleanliness < min_clean:
				min_clean = m.cleanliness
				dirtiest = m
	if dirtiest and dirtiest.has_method("clean_machine"):
		dirtiest.clean_machine()

func _do_repair_machine():
	var machines = get_tree().get_nodes_in_group("machines")
	var worst: Node = null
	var min_dura = 999999.0
	for m in machines:
		if m.has_method("needs_repair") and m.needs_repair():
			if m.durability < min_dura:
				min_dura = m.durability
				worst = m
	if worst and worst.has_method("repair_machine"):
		worst.repair_machine()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var ui = get_tree().get_first_node_in_group("phone_ui")
		if ui and ui.has_method("open_tab"):
			ui.open_tab(ui.Tab.ROBOTS, self)
