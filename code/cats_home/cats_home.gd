extends Node2D

@export var cat_scene: PackedScene
@export var min_spawn_interval: float = 2.5
@export var max_spawn_interval: float = 6.0
@export var min_spawn_chance: float = 0.2
@export var max_spawn_chance: float = 0.9
@export var max_cats_alive: int = 6
@export var spawn_radius: float = 26.0

@onready var spawn_timer = $Timer

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _on_spawn_timer_timeout():
	_reset_timer()
	if not cat_scene:
		return
	if _count_cats() >= max_cats_alive:
		return

	var satisfaction_ratio = clamp(Global.global_satisfaction / 100.0, 0.0, 1.0)
	var chance = lerp(min_spawn_chance, max_spawn_chance, satisfaction_ratio)
	if randf() > chance:
		return

	var new_cat = cat_scene.instantiate()
	new_cat.add_to_group("cats")
	get_tree().current_scene.add_child(new_cat)
	new_cat.global_position = _get_spawn_position()

func _reset_timer():
	spawn_timer.wait_time = randf_range(min_spawn_interval, max_spawn_interval)
	spawn_timer.start()

func _count_cats() -> int:
	return get_tree().get_nodes_in_group("cats").size()

func _get_spawn_position() -> Vector2:
	var offset = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	var desired = global_position + offset
	var nav_map = get_world_2d().navigation_map
	if nav_map != RID():
		return NavigationServer2D.map_get_closest_point(nav_map, desired)
	return desired
