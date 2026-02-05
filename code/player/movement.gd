extends CharacterBody2D

@export var speed = 200.0
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite2D

var machine_proche = null 

func _physics_process(_delta):
	# 1. MOUVEMENT
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()

	# 2. ANIMATIONS
	if direction != Vector2.ZERO:
		anim_player.speed_scale = 2.0 
		
		if abs(direction.x) > abs(direction.y):
			anim_player.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			anim_player.play("walk_down" if direction.y > 0 else "walk_up")
	else:
		anim_player.speed_scale = 1.0
		anim_player.play("RESET")
