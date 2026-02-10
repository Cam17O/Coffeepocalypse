extends StaticBody2D

const GameData = preload("res://code/global/GameData.gd")

@export var boat_type_id: String = "boat_placeholder_1"
@export var storage_max: int = 20
@export var speed: float = 1.0
@export var travel_time: float = 60.0

var current_cargo: int = 0
var travel_progress: float = 0.0
var is_traveling_to_island: bool = false
var _deposit_timer: float = 0.0
var is_at_storage: bool = false
var target_storage: Node = null
var spawn_position: Vector2
var storage_position: Vector2

func _ready():
	add_to_group("boats")
	_apply_type_config()
	if target_storage == null or not is_instance_valid(target_storage):
		var storages = get_tree().get_nodes_in_group("storages")
		if not storages.is_empty():
			target_storage = storages[0]
			spawn_position = global_position
			storage_position = target_storage.global_position + Vector2(0, 50)
			current_cargo = storage_max
			is_traveling_to_island = true
			travel_progress = 0.0

func _apply_type_config():
	if GameData.BOAT_TYPES.has(boat_type_id):
		var cfg = GameData.BOAT_TYPES[boat_type_id]
		storage_max = cfg.get("base_storage", storage_max)
		speed = cfg.get("base_speed", speed)
		travel_time = cfg.get("travel_time", travel_time)

func _process(delta: float):
	if is_traveling_to_island:
		travel_progress += delta / travel_time
		global_position = spawn_position.lerp(storage_position, min(1.0, travel_progress))
		if travel_progress >= 1.0:
			_arrive_at_island()
	elif is_at_storage and target_storage and is_instance_valid(target_storage):
		_deposit_timer += delta
		if _deposit_timer >= 0.5:
			_deposit_timer = 0.0
			_deposit_loop()


func _arrive_at_island():
	is_traveling_to_island = false
	is_at_storage = true

func _deposit_loop():
	if target_storage.coffee_inventory >= target_storage.max_inventory:
		return
	if current_cargo <= 0:
		_return_to_sea()
		return
	var space = target_storage.max_inventory - target_storage.coffee_inventory
	var amount = mini(mini(1, space), current_cargo)
	target_storage.coffee_inventory += amount
	current_cargo -= amount
	if current_cargo <= 0:
		_return_to_sea()

func _return_to_sea():
	queue_free()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var ui = get_tree().get_first_node_in_group("phone_ui")
		if ui and ui.has_method("open_tab"):
			ui.open_tab(ui.Tab.BOATS, self)
