extends Node2D

@onready var progress_bar = $ProgressBar
@export var cat_scene: PackedScene
@onready var spawn_timer = $Timer

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_reset_timer()

func _process(_delta):
	# Met à jour la barre de progression du spawn en temps réel
	if progress_bar and not spawn_timer.is_stopped():
		progress_bar.show()
		progress_bar.max_value = spawn_timer.wait_time
		progress_bar.value = spawn_timer.wait_time - spawn_timer.time_left
		progress_bar.global_position = global_position + Vector2(-25, -40)

func _on_spawn_timer_timeout():
	var new_cat = cat_scene.instantiate()
	get_tree().current_scene.add_child(new_cat)
	new_cat.global_position = global_position
	_reset_timer()

func _reset_timer():
	spawn_timer.wait_time = randf_range(5.0, 10.0)
	spawn_timer.start()
	
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# On demande à l'UI de s'ouvrir sur cet objet précis
			var ui = get_tree().get_first_node_in_group("ui_layer")
			if ui:
				var category = "spawners" if is_in_group("spawners") else "spawners"
				ui.toggle_phone(category, self)
