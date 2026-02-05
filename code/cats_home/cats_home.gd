extends Node2D

@export var cat_scene: PackedScene
@onready var spawn_timer = $Timer # Assure-toi que le nom correspond dans l'arbre

func _ready():
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
		adjust_spawn_rate()

func _on_spawn_timer_timeout():
	var spawn_chance = Global.global_satisfaction / 100.0
	if randf() < spawn_chance:
		spawn_cat()
	adjust_spawn_rate()

func spawn_cat():
	if cat_scene == null: 
		print("Oubli de la scène dans l'inspecteur !")
		return

	var new_cat = cat_scene.instantiate()
	
	# On l'ajoute à la scène AVANT de modifier ses variables
	get_tree().current_scene.add_child(new_cat)
	
	# On vérifie si c'est bien notre chat qui a la variable home_position
	if "home_position" in new_cat:
		new_cat.global_position = global_position
		new_cat.home_position = global_position
	else:
		# Si on arrive ici, c'est que le script n'est pas attaché 
		# au nœud racine de ta scène CatCustomer
		print("Erreur : Le chat instancié n'a pas de script avec 'home_position'")

func adjust_spawn_rate():
	var base_time = 10.0
	var satisfaction_factor = clamp(100.0 / (Global.global_satisfaction + 1.0), 1.0, 10.0)
	spawn_timer.wait_time = base_time * satisfaction_factor
	spawn_timer.start()
