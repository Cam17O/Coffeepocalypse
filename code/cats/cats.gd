extends CharacterBody2D

enum State {MOVING_TO_SHOP, WAITING_LINE, DRINKING, GOING_HOME}
var current_state = State.MOVING_TO_SHOP

var target_machine: StaticBody2D
var home_position: Vector2
var speed = 100.0

func _ready():
	# On récupère tous les nœuds du groupe
	var machines = get_tree().get_nodes_in_group("machines")
	
	if machines.size() > 0:
		# On utilise 'as StaticBody2D' pour confirmer le type à Godot
		target_machine = machines[0] as StaticBody2D
	else:
		print("ERREUR : Aucune machine trouvée dans le groupe 'machines' !")
		
	home_position = global_position

func _physics_process(_delta):
	if not target_machine: return
	
	match current_state:
		State.MOVING_TO_SHOP:
			var target_pos = target_machine.global_position + Vector2(0, 40)
			move_towards(target_pos)
			# On s'arrête un peu avant (distance de 10 pixels)
			if global_position.distance_to(target_pos) < 10:
				velocity = Vector2.ZERO # Stop net
				current_state = State.WAITING_LINE
		
		State.WAITING_LINE:
			if not target_machine.is_busy:
				target_machine.start_brewing(self)
				current_state = State.DRINKING
				
		State.DRINKING:
			velocity = Vector2.ZERO # On ne bouge pas pendant qu'on boit
			
		State.GOING_HOME:
			move_towards(home_position)
			if global_position.distance_to(home_position) < 15:
				queue_free()

func move_towards(pos: Vector2):
	var dir = global_position.direction_to(pos)
	velocity = dir * speed
	move_and_slide()
	# Ici, tu peux ajouter tes animations selon la direction

func on_coffee_received():
	# Le café est prêt, le chat attend un peu (plaisir) puis part
	await get_tree().create_timer(1.0).timeout
	current_state = State.GOING_HOME
