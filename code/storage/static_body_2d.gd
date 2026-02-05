extends StaticBody2D

# Variables for storage state
var is_player_nearby: bool = false
var coffee_inventory: int = 100 # Total coffee available in storage
var storage_name: String = "Main Coffee Silo"

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Check for mouse clicks
	if event is InputEventMouseButton and event.pressed:
		if is_player_nearby:
			if event.button_index == MOUSE_BUTTON_LEFT:
				take_coffee(10)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				show_storage_details()
		else:
			print("Too far to reach the storage!")

# Action for Left Click
func take_coffee(amount: int) -> void:
	# On vérifie si le joueur a de la place
	if Global.raw_coffee_carried < Global.max_coffee_capacity:
		if coffee_inventory >= amount:
			coffee_inventory -= amount
			Global.raw_coffee_carried += amount
			print("Player now carries: ", Global.raw_coffee_carried)

# Action for Right Click (The "Modal" info)
func show_storage_details() -> void:
	print("--- STORAGE INFO ---")
	print("Name: ", storage_name)
	print("Current Stock: ", coffee_inventory, " units")
	print("Condition: Good")
	# Later, you will trigger your UI Modal here

# --- Area2D Signals ---
# Remember to connect these from the Area2D node!

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = true
		print("Player at storage")

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = false
		print("Player left storage")
