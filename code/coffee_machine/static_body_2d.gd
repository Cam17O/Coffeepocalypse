extends StaticBody2D

var is_player_nearby: bool = false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check if the event is a mouse click
	if event is InputEventMouseButton and event.pressed:
		# Only allow clicking if the player is within the Area2D range
		if is_player_nearby:
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("Left click detected: Opening action wheel!")
				open_action_wheel()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				print("Right click detected: Showing machine info")
				show_advanced_info()
		else:
			print("Too far away to interact!")

func open_action_wheel() -> void:
	# Placeholder for your radial menu logic
	pass

func show_advanced_info() -> void:
	# Placeholder for your upgrade/info panel logic
	pass

# --- Area2D Signals ---

func _on_interaction_area_body_entered(body: Node2D) -> void:
	# Make sure your player is named "CharacterBody2D" or is in a "player" group
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = true
		print("Player entered range")

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = false
		print("Player left range")


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
