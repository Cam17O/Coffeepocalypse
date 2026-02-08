extends Node2D

const GameConfig = preload("res://code/global/GameConfig.gd")

@onready var progress_bar = $ProgressBar

@export var cat_scene: PackedScene
@export var spawn_interval: float = GameConfig.CAT_HOME_SPAWN_INTERVAL # time between spawn need to be fixed
@export var min_spawn_chance: float = GameConfig.CAT_HOME_MIN_SPAWN_CHANCE # spawn chance based on satisfaction, between min and max
@export var max_spawn_chance: float = GameConfig.CAT_HOME_MAX_SPAWN_CHANCE # spawn chance based on satisfaction, between min and max
@export var max_cats_alive: int = GameConfig.CAT_HOME_BASE_MAX_CATS
@export var spawn_radius: float = GameConfig.CAT_HOME_SPAWN_RADIUS

var upgrade_level: int = 0
var _base_max_cats: int
var _spawn_interval: float

@onready var spawn_timer = $Timer

func _ready():
	add_to_group("cat_homes")
	name = random_name()
	_base_max_cats = max_cats_alive
	_spawn_interval = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	apply_upgrade_level(Global.cat_home_upgrade_level)
	_reset_timer()
	print("[CatsHome] Ready : ", name, "max : ", max_cats_alive)

# Update the progress bar for the next spawn
func _process(_delta):
	if progress_bar and not spawn_timer.is_stopped():
		progress_bar.show()
		progress_bar.max_value = spawn_timer.wait_time
		progress_bar.value = spawn_timer.wait_time - spawn_timer.time_left
		progress_bar.global_position = global_position + Vector2(-25, -40)

# Apply an upgrade level to adjust spawn parameters
func apply_upgrade_level(level: int):
	upgrade_level = level
	max_cats_alive = _base_max_cats + level * GameConfig.CAT_HOME_MAX_CATS_PER_LEVEL
	print("[CatsHome] Upgrade", name, "lvl", level, "max", max_cats_alive)

# Timer callback to attempt spawning a new cat
func _on_spawn_timer_timeout():
	_reset_timer()
	if not cat_scene:
		return

	if _count_cats() >= max_cats_alive:
		print("[CatsHome] Spawn blocked (max) : ", name)
		return

	# Spawn chance based on global satisfaction level
	var satisfaction_ratio = clamp(Global.global_satisfaction / 100.0, 0.0, 1.0)
	var chance = lerp(min_spawn_chance, max_spawn_chance, satisfaction_ratio)
	if randf() > chance:
		print("[CatsHome] Spawn roll failed : ", name)
		return

	# Spawn the cat
	var new_cat = cat_scene.instantiate()
	new_cat.add_to_group("cats")
	get_tree().current_scene.add_child(new_cat)
	new_cat.global_position = _get_spawn_position()
	print("[CatsHome] Spawn cat : ", name, ", total : ", _count_cats())

# Reset the spawn timer with a new fixed interval
func _reset_timer():
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

# Count the number of cats currently alive in the scene
func _count_cats() -> int:
	return get_tree().get_nodes_in_group("cats").size()

# Get a random valid spawn position around the home within the radius
func _get_spawn_position() -> Vector2:
	var offset = Vector2(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
	var desired = global_position + offset
	var nav_map = get_world_2d().navigation_map

	if nav_map != RID():
		return NavigationServer2D.map_get_closest_point(nav_map, desired)

	return desired

# event to open phone UI with cat details when right-clicked
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.CAT_HOMES, self)

# Utility function to generate a random cat name
func random_name() -> String:
	var names = ["salade", "griffe d'or", "cerf d'aigle", "bouf tout"]
	return names[randi() % names.size()]
