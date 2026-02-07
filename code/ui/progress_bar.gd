extends ProgressBar

var target_node: Node2D

func _ready():
	hide()
	z_index = 10 # Toujours au-dessus
	# Optionnel : Personnalise le style ici ou dans l'inspecteur
	custom_minimum_size = Vector2(70, 6)
	size = Vector2(70, 6)

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
		global_position = target_node.global_position + Vector2(-35, -30)
		var ratio = 0.0
		if max_value > 0.0:
			ratio = value / max_value
		if ratio >= 0.66:
			modulate = Color(0.2, 0.9, 0.2)
		elif ratio >= 0.33:
			modulate = Color(0.95, 0.8, 0.2)
		else:
			modulate = Color(0.95, 0.25, 0.2)
