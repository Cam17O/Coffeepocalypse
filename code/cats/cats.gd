extends CharacterBody2D

enum State {MOVING_TO_SHOP, WAITING_LINE, DRINKING, GOING_HOME}
var current_state = State.MOVING_TO_SHOP

@export var max_health: int = 3
@export var special_chance: float = 0.01
@export var special_multiplier: float = 4.0
@export var forced_purchase_reward: float = 8.0
@export var stop_distance: float = 18.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var target_machine: StaticBody2D
var home_position: Vector2
var speed = 50.0
var est_devant_machine: bool = false
var is_special: bool = false
var health: int
var is_ko: bool = false

func _ready():
	health = max_health
	is_special = randf() < special_chance
	if is_special:
		speed *= 2

	home_position = global_position
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	await get_tree().physics_frame # Attendre que la navigation soit prête
	_pick_target_machine()

func _physics_process(_delta):
	if not _is_machine_valid(target_machine) and current_state != State.GOING_HOME:
		_pick_target_machine()

	match current_state:
		State.MOVING_TO_SHOP:
			if not _is_machine_valid(target_machine):
				return
			nav_agent.target_position = target_machine.global_position + Vector2(0, 26)
			setup_movement()
			if _is_close_to_machine() or nav_agent.is_navigation_finished():
				velocity = Vector2.ZERO
				est_devant_machine = true
				current_state = State.WAITING_LINE

		State.WAITING_LINE:
			if not _is_machine_valid(target_machine):
				current_state = State.GOING_HOME
				return
			if not target_machine.is_busy:
				target_machine.start_brewing(self)
				current_state = State.DRINKING

		State.DRINKING:
			velocity = Vector2.ZERO

		State.GOING_HOME:
			nav_agent.target_position = home_position
			setup_movement()
			if nav_agent.is_navigation_finished():
				queue_free()

func setup_movement():
	if nav_agent.is_navigation_finished():
		return
	var next_path_pos = nav_agent.get_next_path_position()
	var new_velocity = global_position.direction_to(next_path_pos) * speed
	nav_agent.set_velocity(new_velocity)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var player = _get_player()
		if player and player.global_position.distance_to(global_position) <= 40.0:
			_on_hit_by_player()

func _get_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _on_hit_by_player():
	if is_ko:
		return
	health -= 1
	var impact = special_multiplier if is_special else 1.0
	Global.apply_satisfaction_delta(-10.0, true, impact)
	if health <= 0:
		is_ko = true
		Global.add_money(forced_purchase_reward)
		Global.apply_satisfaction_delta(-15.0, true, impact)
		current_state = State.GOING_HOME

func entrer_dans_zone_machine():
	est_devant_machine = true

func on_coffee_received(data := {}):
	var impact = special_multiplier if is_special else 1.0
	var delta = data.get("satisfaction_delta", 3.0)
	if delta < 0:
		Global.apply_satisfaction_delta(delta, true, impact)
	else:
		Global.apply_satisfaction_delta(delta, false, impact)

	await get_tree().create_timer(1.5).timeout
	est_devant_machine = false
	current_state = State.GOING_HOME

func on_coffee_failed(reason: String, took_money: bool):
	var impact = special_multiplier if is_special else 1.0
	var penalty = -8.0
	if reason == "out_of_stock":
		penalty = -6.0
	if took_money:
		penalty = -10.0
	Global.apply_satisfaction_delta(penalty, true, impact)
	await get_tree().create_timer(1.0).timeout
	est_devant_machine = false
	current_state = State.GOING_HOME

func _pick_target_machine():
	var machines = get_tree().get_nodes_in_group("machines")
	var best: StaticBody2D = null
	var best_dist := INF
	for machine in machines:
		if not _is_machine_valid(machine):
			continue
		var dist = global_position.distance_to(machine.global_position)
		if dist < best_dist:
			best_dist = dist
			best = machine
	target_machine = best

func _is_machine_valid(machine) -> bool:
	return machine != null and is_instance_valid(machine)

func _is_close_to_machine() -> bool:
	if not _is_machine_valid(target_machine):
		return false
	return global_position.distance_to(target_machine.global_position) <= stop_distance
