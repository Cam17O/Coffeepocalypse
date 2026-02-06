extends ProgressBar

var target_node: Node2D

func _ready():
	hide()
	z_index = 10 # Toujours au-dessus
	# Optionnel : Personnalise le style ici ou dans l'inspecteur

func start(duration: float, node: Node2D):
	target_node = node
	max_value = duration
	value = 0
	show()
	
	var tween = create_tween()
	tween.tween_property(self, "value", duration, duration)
	await tween.finished
	hide()

func _process(_delta):
	if visible and is_instance_valid(target_node):
		# Positionne la barre au-dessus de l'objet
		global_position = target_node.global_position + Vector2(-25, -50)
