extends Node

const GameData = preload("res://code/global/GameData.gd")
const BoatScene = preload("res://scenes/boat.tscn")

@export var spawn_interval: float = 90.0
@export var spawn_offset: Vector2 = Vector2(-200, -150)
var _timer: float = 0.0

func _process(delta: float):
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_try_spawn_boat()

func _try_spawn_boat():
	var storages = get_tree().get_nodes_in_group("storages")
	if storages.is_empty():
		return
	var storage = storages[0]
	var boat = BoatScene.instantiate()
	boat.boat_type_id = "boat_placeholder_1"
	boat.storage_max = 20
	boat.travel_time = 60.0
	var cfg = GameData.BOAT_TYPES.get(boat.boat_type_id, {})
	boat.storage_max = cfg.get("base_storage", 20)
	boat.travel_time = cfg.get("travel_time", 60.0)
	var cost = boat.storage_max * GameData.RAW_COFFEE_UNIT_PRICE
	if Global.money >= cost:
		Global.add_money(-cost)
		boat.current_cargo = boat.storage_max
		boat.spawn_position = storage.global_position + spawn_offset
		boat.storage_position = storage.global_position + Vector2(0, 50)
		boat.global_position = boat.spawn_position
		get_parent().add_child(boat)
		boat.target_storage = storage
		boat.is_traveling_to_island = true
		boat.travel_progress = 0.0
