extends Node2D

@onready var progress_bar = $ProgressBar

@export var cat_scene: PackedScene
@export var min_spawn_interval: float = 6.0
@export var max_spawn_interval: float = 12.0
@export var min_spawn_chance: float = 0.1
@export var max_spawn_chance: float = 0.6
@export var max_cats_alive: int = 4
@export var spawn_radius: float = 26.0

var upgrade_level: int = 0
var _base_max_cats: int
var _base_min_interval: float
var _base_max_interval: float

@onready var spawn_timer = $Timer

func _ready():
	add_to_group("cat_homes")
	_base_max_cats = max_cats_alive
	_base_min_interval = min_spawn_interval
	_base_max_interval = max_spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	apply_upgrade_level(Global.cat_home_upgrade_level)
	_reset_timer()
	print("[CatsHome] Ready:", name, "max", max_cats_alive)

func _process(_delta):
	if progress_bar and not spawn_timer.is_stopped():
		progress_bar.show()
		progress_bar.max_value = spawn_timer.wait_time
		progress_bar.value = spawn_timer.wait_time - spawn_timer.time_left
		progress_bar.global_position = global_position + Vector2(-25, -40)

func apply_upgrade_level(level: int):
	upgrade_level = level
	max_cats_alive = _base_max_cats + level * 2
	min_spawn_interval = max(0.8, _base_min_interval - 0.2 * level)
	max_spawn_interval = max(min_spawn_interval + 0.4, _base_max_interval - 0.3 * level)
	print("[CatsHome] Upgrade", name, "lvl", level, "max", max_cats_alive)

func _on_spawn_timer_timeout():
	_reset_timer()
	if not cat_scene:
		return
	if _count_cats() >= max_cats_alive:
		print("[CatsHome] Spawn blocked (max):", name)
		return

	var satisfaction_ratio = clamp(Global.global_satisfaction / 100.0, 0.0, 1.0)
	var chance = lerp(min_spawn_chance, max_spawn_chance, satisfaction_ratio)
	if randf() > chance:
		print("[CatsHome] Spawn roll failed:", name)
		return

	var new_cat = cat_scene.instantiate()
	new_cat.add_to_group("cats")
	get_tree().current_scene.add_child(new_cat)
	new_cat.global_position = _get_spawn_position()
	print("[CatsHome] Spawn cat:", name, "total", _count_cats())

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

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.CAT_HOMES, self)
