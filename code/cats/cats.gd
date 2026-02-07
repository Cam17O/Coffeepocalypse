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

		State.WAITING_LINE:
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)
			if is_instance_valid(target_machine) and not target_machine.is_busy:
				target_machine.start_brewing(self)
				current_state = State.DRINKING

		State.DRINKING:
			velocity = Vector2.ZERO
			nav_agent.set_velocity(Vector2.ZERO)

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
	var machines = get_tree().get_nodes_in_group("machines")
	if machines.size() > 0:
		target_machine = machines.pick_random()
		print("[Cat] Target machine:", name, target_machine.name)

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
	_pick_new_wander_target()

func on_coffee_failed(_reason, _took_money):
	Global.apply_satisfaction_delta(-10.0, true)
	print("[Cat] Coffee failed:", name)
	current_state = State.WANDERING
	_pick_new_wander_target()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var ui = get_tree().get_first_node_in_group("phone_ui")
			if ui and ui.has_method("open_tab"):
				ui.open_tab(ui.Tab.CATS, self)
