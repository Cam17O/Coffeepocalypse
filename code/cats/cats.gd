extends CharacterBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")

enum State {WANDERING, SEEKING_COFFEE, WAITING_LINE, DRINKING, SEEKING_WORK, WORKING}
enum WorkType {NONE, MACHINE, STORAGE, HOME}
var current_state = State.WANDERING

@export var max_health: int = GameConfig.CAT_MAX_HEALTH
@export var max_energy: float = GameConfig.CAT_MAX_ENERGY
@export var energy_drain_per_sec: float = GameConfig.CAT_ENERGY_DRAIN_PER_SEC
@export var wander_radius: float = GameConfig.CAT_WANDER_RADIUS
@export var stop_distance: float = GameConfig.CAT_STOP_DISTANCE

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var energy_bar = $ProgressBar

var target_machine: StaticBody2D
var target_work_building: Node2D
var work_type: WorkType = WorkType.NONE
var home_position: Vector2
var speed = GameConfig.CAT_MOVE_SPEED
var health: int
var energy: float
var is_ko: bool = false
var level: int = 1
var xp: float = 0.0
var xp_to_next_level: float = 10.0
var work_boost: float = 1.0
var _wander_target: Vector2
var _waiting_time: float = 0.0
var _rescore_elapsed: float = 0.0
var _is_wait_registered: bool = false
var _is_work_registered: bool = false

const RESCORE_INTERVAL := GameConfig.CAT_RESCORE_INTERVAL
const SWITCH_WAIT_THRESHOLD := GameConfig.CAT_SWITCH_WAIT_THRESHOLD
const SWITCH_SCORE_MARGIN := GameConfig.CAT_SWITCH_SCORE_MARGIN

func _ready():
	add_to_group("cats")
	name = random_name()
	health = max_health
	energy = max_energy
	home_position = global_position
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	_pick_new_wander_target()
	print("[Cat] Ready : ", name, " at ", home_position)

func _physics_process(delta):
	# Drain energy over time
	energy = max(0.0, energy - _get_energy_drain_per_sec() * delta)

	# If energy is empty, switch to seeking coffee state
	if energy <= 0.0 and current_state != State.SEEKING_COFFEE and current_state != State.WAITING_LINE and current_state != State.DRINKING:
		_stop_working()
		current_state = State.SEEKING_COFFEE
		print("[Cat] Energy empty -> seek coffee : ", name)
		_pick_target_machine()
		_rescore_elapsed = 0.0
	elif current_state == State.WANDERING and energy > GameConfig.CAT_WORK_MIN_ENERGY:
		_pick_work_target()
		if is_instance_valid(target_work_building):
			current_state = State.SEEKING_WORK

	match current_state:
		State.WANDERING:
			nav_agent.target_position = _wander_target
			_move_logic()
			# If reached wander target, pick a new one
			if nav_agent.is_navigation_finished() or global_position.distance_to(_wander_target) < stop_distance:
				_pick_new_wander_target()

		State.SEEKING_COFFEE:
			# If target machine is invalid (destroyed), pick a new one or switch to wandering
			if not is_instance_valid(target_machine):
				_pick_target_machine()
				if not is_instance_valid(target_machine):
					current_state = State.WANDERING
					_pick_new_wander_target()
					return
			nav_agent.target_position = target_machine.global_position + Vector2(0, 26)
			_move_logic()

			# If reached machine, switch to waiting in line
			if nav_agent.is_navigation_finished() or global_position.distance_to(nav_agent.target_position) < stop_distance:
				current_state = State.WAITING_LINE
				_waiting_time = 0.0
				_register_waiter(target_machine)

		State.WAITING_LINE:
			# Accumulate waiting time and periodically check if we should switch to a better machine
			_waiting_time += delta
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)

			# If machine becomes available and has stock, start brewing
			if is_instance_valid(target_machine) and not target_machine.is_busy:
				if target_machine.current_coffee_stock > 0:
					var started = await target_machine.start_brewing(self)
					if started:
						current_state = State.DRINKING
						_unregister_waiter(target_machine)
						_waiting_time = 0.0

			# Periodically check if we should switch to a better machine
			_rescore_elapsed += delta
			if _rescore_elapsed >= RESCORE_INTERVAL:
				_rescore_elapsed = 0.0
				_try_switch_machine()

		State.DRINKING:
			# Just wait for the coffee to be delivered
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)
			_waiting_time = 0.0

		State.SEEKING_WORK:
			if not is_instance_valid(target_work_building):
				_pick_work_target()
				if not is_instance_valid(target_work_building):
					current_state = State.WANDERING
					_pick_new_wander_target()
					return
			nav_agent.target_position = _get_work_target_position(target_work_building)
			_move_logic()
			if nav_agent.is_navigation_finished() or global_position.distance_to(nav_agent.target_position) < stop_distance:
				if _register_worker(target_work_building):
					current_state = State.WORKING
				else:
					_pick_work_target()

		State.WORKING:
			if not is_instance_valid(target_work_building):
				_stop_working()
				current_state = State.WANDERING
				_pick_new_wander_target()
				return
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)
			if not _is_work_registered:
				if not _register_worker(target_work_building):
					_stop_working()
					current_state = State.WANDERING
					_pick_new_wander_target()
			# Gain XP while working
			xp += delta * 0.5
			if xp >= xp_to_next_level:
				xp = 0.0
				level += 1
				xp_to_next_level = 10.0 + level * 5
				speed += 5
				max_health += 2
				health = min(health + 2, max_health)
				work_boost += 0.1

# Update energy bar position and value
func _process(_delta):
	if energy_bar:
		energy_bar.show()
		energy_bar.max_value = max_energy
		energy_bar.value = energy
		energy_bar.global_position = global_position + Vector2(-25, -40)

# Movement logic to set velocity towards the next path position
func _move_logic():
	var next_pos = nav_agent.get_next_path_position()
	var new_vel = global_position.direction_to(next_pos) * speed
	nav_agent.set_velocity(new_vel)

# Callback when the navigation agent computes a new velocity
func _on_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

# Logic to pick the best machine based on scoring
func _pick_target_machine():
	var best = _get_best_machine()
	if best:
		target_machine = best
		print("[Cat] : ", name, ", Target machine : ", target_machine.name)

# Get the best machine by scoring all machines in the scene
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

# Scoring function to evaluate how good a machine is for this cat
func _score_machine(machine) -> float:
	if not machine or not is_instance_valid(machine):
		return -INF

	if machine.current_coffee_stock <= 0:
		return GameConfig.CAT_MACHINE_OUT_OF_STOCK_SCORE
	
	var distance = global_position.distance_to(machine.global_position)
	var queue = machine.waiting_count

	var score = GameConfig.CAT_MACHINE_SCORE_BASE
	score += machine.get_upgrade_level() * GameConfig.CAT_MACHINE_SCORE_UPGRADE_BONUS if machine.has_method("get_upgrade_level") else 0
	score -= distance * GameConfig.CAT_MACHINE_SCORE_DISTANCE_WEIGHT
	score -= float(queue) * GameConfig.CAT_MACHINE_SCORE_QUEUE_WEIGHT

	if machine.is_busy:
		score -= GameConfig.CAT_MACHINE_SCORE_BUSY_PENALTY
	return score

# Logic to decide if we should switch to a better machine while waiting in line
func _try_switch_machine():
	if current_state != State.WAITING_LINE:
		return

	if not is_instance_valid(target_machine):
		return

	var current_score = _score_machine(target_machine)
	var best = _get_best_machine()

	# Only switch if we've been waiting for a while and the new machine has a significantly better score
	if best and best != target_machine:
		var best_score = _score_machine(best)
		if _waiting_time >= SWITCH_WAIT_THRESHOLD and best_score > current_score + SWITCH_SCORE_MARGIN:
			_unregister_waiter(target_machine)
			target_machine = best
			current_state = State.SEEKING_COFFEE
			print("[Cat] Switch machine:", name, "->", target_machine.name)

# Register as a waiter to the machine to get notified when it's our turn
func _register_waiter(machine):
	if not machine or _is_wait_registered:
		return

	if machine.has_method("register_waiter"):
		machine.register_waiter()
		_is_wait_registered = true

# Unregister from the machine if we switch away or get our coffee
func _unregister_waiter(machine):
	if not machine or not _is_wait_registered:
		return

	if machine.has_method("unregister_waiter"):
		machine.unregister_waiter()
		_is_wait_registered = false

# Logic to pick a new random wander target within the radius around home position
func _pick_new_wander_target():
	var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	var desired = home_position + offset
	var nav_map = get_world_2d().navigation_map

	# If we have a valid navigation map, find the closest navigable point to the desired wander target
	if nav_map != RID():
		_wander_target = NavigationServer2D.map_get_closest_point(nav_map, desired)
	else:
		_wander_target = desired
	print("[Cat] Wander target:", name,", ", _wander_target)

# Callbacks for coffee events from the machine
func on_coffee_received(data):
	# Apply satisfaction boost from coffee, with a default value if not provided
	Global.apply_satisfaction_delta(data.get("satisfaction_delta", GameConfig.CAT_DEFAULT_SATISFACTION_BOOST), false)

	energy = max_energy
	print("[Cat] Coffee received:", name, ", energy : ", energy)
	await get_tree().create_timer(0.8).timeout # need to use machine brew time to sync satisfaction boost with coffee delivery
	current_state = State.SEEKING_WORK
	_waiting_time = 0.0
	_pick_work_target()

# If brewing fails, apply a satisfaction penalty and go back to wandering
func on_coffee_failed(_reason, _took_money):
	Global.apply_satisfaction_delta(GameConfig.CAT_COFFEE_FAIL_PENALTY, true)
	print("[Cat] Coffee failed : ", name)
	current_state = State.SEEKING_WORK
	_waiting_time = 0.0
	_pick_work_target()

# Right-click interaction to open phone UI with cat details
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.CATS, self)

func random_name() -> String:
	var names = ["Bob", "Mittens", "Shadow", "Simba", "Luna", "Oliver", "Chloe", "Leo", "Bella", "Charlie"]
	return names[randi() % names.size()]

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

func _pick_work_target():
	var best = _get_best_work_building()
	target_work_building = best
	work_type = _get_work_type(best)
	if best:
		print("[Cat] : ", name, ", Target work : ", best.name)

func _get_best_work_building() -> Node2D:
	var candidates: Array = []
	candidates.append_array(get_tree().get_nodes_in_group("machines"))
	candidates.append_array(get_tree().get_nodes_in_group("storages"))
	candidates.append_array(get_tree().get_nodes_in_group("cat_homes"))
	var best: Node2D
	var best_score = -INF
	for building in candidates:
		if not is_instance_valid(building):
			continue
		if not building.has_method("register_worker"):
			continue
		if building.has_method("has_free_worker_slot") and not building.has_free_worker_slot():
			continue
		var distance = global_position.distance_to(building.global_position)
		var score = -distance
		if score > best_score:
			best_score = score
			best = building
	return best

func _get_work_type(building: Node) -> WorkType:
	if building == null:
		return WorkType.NONE
	if building.is_in_group("machines"):
		return WorkType.MACHINE
	if building.is_in_group("storages"):
		return WorkType.STORAGE
	if building.is_in_group("cat_homes"):
		return WorkType.HOME
	return WorkType.NONE

func _get_work_target_position(building: Node2D) -> Vector2:
	return building.global_position + Vector2(0, 26)

func _register_worker(building: Node) -> bool:
	if not building or _is_work_registered:
		return false
	if building.has_method("register_worker"):
		var ok = building.register_worker(self)
		_is_work_registered = ok
		return ok
	return false

func _stop_working():
	if target_work_building and is_instance_valid(target_work_building):
		if target_work_building.has_method("unregister_worker"):
			target_work_building.unregister_worker(self)
	_is_work_registered = false
	target_work_building = null
	work_type = WorkType.NONE

func _get_energy_drain_per_sec() -> float:
	if current_state == State.WORKING:
		match work_type:
			WorkType.MACHINE:
				return GameConfig.CAT_ENERGY_DRAIN_WORKING_MACHINE
			WorkType.STORAGE:
				return GameConfig.CAT_ENERGY_DRAIN_WORKING_STORAGE
			WorkType.HOME:
				return GameConfig.CAT_ENERGY_DRAIN_WORKING_HOME
	return energy_drain_per_sec
