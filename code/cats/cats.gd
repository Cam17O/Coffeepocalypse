extends CharacterBody2D

enum State {WANDERING, SEEKING_COFFEE, WAITING_LINE, DRINKING}
var current_state = State.WANDERING

@export var max_health: int = 3
@export var max_energy: float = 14.0
@export var energy_drain_per_sec: float = 0.4
@export var wander_radius: float = 150.0
@export var stop_distance: float = 18.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var energy_bar = $ProgressBar

var target_machine: StaticBody2D
var home_position: Vector2
var speed = 60.0
var health: int
var energy: float
var is_ko: bool = false
var _wander_target: Vector2
var _waiting_time: float = 0.0
var _rescore_elapsed: float = 0.0
var _is_wait_registered: bool = false

const RESCORE_INTERVAL := 1.0
const SWITCH_WAIT_THRESHOLD := 4.0
const SWITCH_SCORE_MARGIN := 10.0

func _ready():
	add_to_group("cats")
	health = max_health
	energy = max_energy
	home_position = global_position
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_pick_new_wander_target()
	print("[Cat] Ready:", name, "energy", energy)

func _physics_process(delta):
	energy = max(0.0, energy - energy_drain_per_sec * delta)
	if energy <= 0.0 and current_state != State.SEEKING_COFFEE and current_state != State.WAITING_LINE and current_state != State.DRINKING:
		current_state = State.SEEKING_COFFEE
		print("[Cat] Energy empty -> seek coffee:", name)
		_pick_target_machine()
		_rescore_elapsed = 0.0

	match current_state:
		State.WANDERING:
			nav_agent.target_position = _wander_target
			_move_logic()
			if nav_agent.is_navigation_finished() or global_position.distance_to(_wander_target) < stop_distance:
				_pick_new_wander_target()

		State.SEEKING_COFFEE:
			if not is_instance_valid(target_machine):
				_pick_target_machine()
				if not is_instance_valid(target_machine):
					current_state = State.WANDERING
					_pick_new_wander_target()
					return
			nav_agent.target_position = target_machine.global_position + Vector2(0, 26)
			_move_logic()
			if nav_agent.is_navigation_finished() or global_position.distance_to(nav_agent.target_position) < stop_distance:
				current_state = State.WAITING_LINE
				_waiting_time = 0.0
				_register_waiter(target_machine)

		State.WAITING_LINE:
			_waiting_time += delta
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)
			if is_instance_valid(target_machine) and not target_machine.is_busy:
				if target_machine.current_coffee_stock > 0:
					var started = await target_machine.start_brewing(self)
					if started:
						current_state = State.DRINKING
						_unregister_waiter(target_machine)
						_waiting_time = 0.0
			_rescore_elapsed += delta
			if _rescore_elapsed >= RESCORE_INTERVAL:
				_rescore_elapsed = 0.0
				_try_switch_machine()

		State.DRINKING:
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)
			_waiting_time = 0.0

func _process(_delta):
	if energy_bar:
		energy_bar.show()
		energy_bar.max_value = max_energy
		energy_bar.value = energy
		energy_bar.global_position = global_position + Vector2(-25, -40)

func _move_logic():
	var next_pos = nav_agent.get_next_path_position()
	var new_vel = global_position.direction_to(next_pos) * speed
	nav_agent.set_velocity(new_vel)

func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

func _pick_target_machine():
	var best = _get_best_machine()
	if best:
		target_machine = best
		print("[Cat] Target machine:", name, target_machine.name)

func _get_best_machine() -> StaticBody2D:
	var machines = get_tree().get_nodes_in_group("machines")
	var best_machine: StaticBody2D
	var best_score = -INF
	for machine in machines:
		var score = _score_machine(machine)
		if score > best_score:
			best_score = score
			best_machine = machine
	return best_machine

func _score_machine(machine) -> float:
	if not machine or not is_instance_valid(machine):
		return -INF
	if machine.current_coffee_stock <= 0:
		return -10000.0
	var distance = global_position.distance_to(machine.global_position)
	var queue = machine.waiting_count
	var score = 100.0
	score += Global.machine_upgrade_level * 5.0
	score -= distance * 0.1
	score -= float(queue) * 15.0
	if machine.is_busy:
		score -= 8.0
	return score

func _try_switch_machine():
	if current_state != State.WAITING_LINE:
		return
	if not is_instance_valid(target_machine):
		return
	var current_score = _score_machine(target_machine)
	var best = _get_best_machine()
	if best and best != target_machine:
		var best_score = _score_machine(best)
		if _waiting_time >= SWITCH_WAIT_THRESHOLD and best_score > current_score + SWITCH_SCORE_MARGIN:
			_unregister_waiter(target_machine)
			target_machine = best
			current_state = State.SEEKING_COFFEE
			print("[Cat] Switch machine:", name, "->", target_machine.name)

func _register_waiter(machine):
	if not machine or _is_wait_registered:
		return
	if machine.has_method("register_waiter"):
		machine.register_waiter()
		_is_wait_registered = true

func _unregister_waiter(machine):
	if not machine or not _is_wait_registered:
		return
	if machine.has_method("unregister_waiter"):
		machine.unregister_waiter()
		_is_wait_registered = false

func _pick_new_wander_target():
	var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	var desired = home_position + offset
	var nav_map = get_world_2d().navigation_map
	if nav_map != RID():
		_wander_target = NavigationServer2D.map_get_closest_point(nav_map, desired)
	else:
		_wander_target = desired
	print("[Cat] Wander target:", name, _wander_target)

func on_coffee_received(data):
	Global.apply_satisfaction_delta(data.get("satisfaction_delta", 5.0), false)
	energy = max_energy
	print("[Cat] Coffee received:", name, "energy", energy)
	await get_tree().create_timer(0.8).timeout
	current_state = State.WANDERING
	_waiting_time = 0.0
	_pick_new_wander_target()

func on_coffee_failed(_reason, _took_money):
	Global.apply_satisfaction_delta(-10.0, true)
	print("[Cat] Coffee failed:", name)
	current_state = State.WANDERING
	_waiting_time = 0.0
	_pick_new_wander_target()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.CATS, self)

func get_target_machine() -> StaticBody2D:
	return target_machine

func get_waiting_time() -> float:
	return _waiting_time

func get_current_machine_score() -> float:
	return _score_machine(target_machine)

func get_best_machine() -> StaticBody2D:
	return _get_best_machine()

func get_best_machine_score() -> float:
	var best = _get_best_machine()
	return _score_machine(best)
