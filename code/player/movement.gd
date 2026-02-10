extends CharacterBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")
const DepositPopup = preload("res://scenes/deposit_popup.tscn")

@export var speed = GameConfig.PLAYER_MOVE_SPEED
@onready var anim_player = $AnimationPlayer
@onready var carry_label = $CarryLabel

var machine_nearby: Node = null
var storage_nearby: Node = null
var is_immobilized: bool = false
var _deposit_popup: PopupPanel

func _ready():
	_deposit_popup = DepositPopup.instantiate()
	get_tree().current_scene.add_child(_deposit_popup)

func _physics_process(_delta):
	if is_immobilized:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Handle player movement input
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()

	# Update animation based on movement direction
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			anim_player.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			anim_player.play("walk_down" if direction.y > 0 else "walk_up")
	else:
		anim_player.play("RESET")

	# Update carry label visibility and text based on carried coffee amount
	if carry_label:
		var amount = Global.raw_coffee_carried
		carry_label.visible = amount > 0
		if amount > 0:
			carry_label.text = str(amount) + " cafe brut"

func _unhandled_input(event):
	if event.is_action_pressed("deposit_coffee"):
		if machine_nearby and is_instance_valid(machine_nearby):
			if _deposit_popup and _deposit_popup.has_method("open"):
				_deposit_popup.open(machine_nearby)

func entrer_dans_zone_machine(machine: Node):
	machine_nearby = machine

func sortir_depuis_zone_machine(machine: Node):
	if machine_nearby == machine:
		machine_nearby = null

func entrer_dans_zone_storage(storage: Node):
	storage_nearby = storage

func sortir_depuis_zone_storage(storage: Node):
	if storage_nearby == storage:
		storage_nearby = null

func set_immobilized(value: bool):
	is_immobilized = value
