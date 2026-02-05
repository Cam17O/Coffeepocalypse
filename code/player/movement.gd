extends CharacterBody2D

@export var speed = 200.0
@onready var anim_player = $AnimationPlayer

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()
	Global.set_player_idle(direction == Vector2.ZERO)

	if direction != Vector2.ZERO:
		anim_player.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		anim_player.play("RESET")
