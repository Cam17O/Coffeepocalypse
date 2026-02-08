extends CharacterBody2D

const GameConfig = preload("res://code/global/GameConfig.gd")

@export var speed = GameConfig.PLAYER_MOVE_SPEED
@onready var anim_player = $AnimationPlayer
@onready var carry_label = $CarryLabel

func _physics_process(_delta):

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
