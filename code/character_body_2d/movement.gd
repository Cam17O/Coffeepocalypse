#extends CharacterBody2D
#
#
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
#
#
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
	
extends CharacterBody2D

@export var speed = 200.0

@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	
	move_and_slide()

	if direction != Vector2.ZERO:
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				anim_player.play("walk_right")
			else:
				anim_player.play("walk_left")
		else:
			if direction.y > 0:
				anim_player.play("walk_down")
			else:
				anim_player.play("walk_up")
				
	else:
		anim_player.stop()
