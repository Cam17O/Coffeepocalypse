extends CharacterBody2D

enum State {MOVING_TO_SHOP, WAITING_LINE, DRINKING, GOING_HOME}
var current_state = State.MOVING_TO_SHOP

@export var max_health: int = 3
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var target_machine: StaticBody2D
var home_position: Vector2
var speed = 60.0
var health: int
var is_ko: bool = false

func _ready():
	add_to_group("cats")
	health = max_health
	home_position = global_position
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_pick_target_machine()

func _physics_process(_delta):
	match current_state:
		State.MOVING_TO_SHOP:
			if is_instance_valid(target_machine):
				nav_agent.target_position = target_machine.global_position + Vector2(0, 30)
				_move_logic()
				if nav_agent.is_navigation_finished() or global_position.distance_to(nav_agent.target_position) < 20:
					current_state = State.WAITING_LINE
			else: _pick_target_machine()

		State.WAITING_LINE:
			velocity = Vector2.ZERO
			if is_instance_valid(target_machine) and not target_machine.is_busy:
				target_machine.start_brewing(self)
				current_state = State.DRINKING

		State.GOING_HOME:
			nav_agent.target_position = home_position
			_move_logic()
			if nav_agent.is_navigation_finished(): queue_free()

func _move_logic():
	var next_pos = nav_agent.get_next_path_position()
	var new_vel = global_position.direction_to(next_pos) * speed
	nav_agent.set_velocity(new_vel)

func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func _pick_target_machine():
	var machines = get_tree().get_nodes_in_group("machines")
	if machines.size() > 0: target_machine = machines.pick_random()

func on_coffee_received(data):
	Global.apply_satisfaction_delta(data.get("satisfaction_delta", 5.0), false)
	await get_tree().create_timer(1.0).timeout
	current_state = State.GOING_HOME

func on_coffee_failed(_reason, _took_money):
	Global.apply_satisfaction_delta(-10.0, true)
	current_state = State.GOING_HOME

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# On demande à l'UI de s'ouvrir sur cet objet précis
			var ui = get_tree().get_first_node_in_group("ui_layer")
			if ui:
				var category = "cats" if is_in_group("cats") else "cats"
				ui.toggle_phone(category, self)
