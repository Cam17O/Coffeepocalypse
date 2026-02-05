extends StaticBody2D

# --- Machine Stats ---
@export var machine_name: String = "Shitty coffee maker"
@export var level: int = 1
@export var max_coffee_capacity: int = 500
@export var current_coffee_stock: int = 500
@export var brewing_time: float = 3.0

# --- Probabilities ---
@export var failure_chance: float = 0.20 # 20% chance to steal money and fail
@export var bad_taste_chance: float = 0.20 # 20% chance to reduce satisfaction

var is_player_nearby: bool = false
var is_busy: bool = false

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if is_player_nearby:
			if event.button_index == MOUSE_BUTTON_LEFT:
				open_action_wheel()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				show_advanced_info()
		else:
			print("Too far to reach the machine!")

# --- Cat & Player Interaction Logic ---

# Cette fonction est celle que le chat appellera
func start_brewing(customer: Node2D) -> void:
	if is_busy:
		return
	
	if current_coffee_stock <= 0:
		print("Machine is empty! Customer leaves disappointed.")
		Global.lose_satisfaction(5)
		if customer.has_method("on_coffee_received"):
			customer.on_coffee_received() # On le renvoie chez lui
		return

	is_busy = true
	print("Machine is brewing coffee... please wait.")
	
	# Attente du temps de préparation
	await get_tree().create_timer(brewing_time).timeout
	
	# Servir le café (logique de prix et probabilités)
	serve_coffee_to_cat()
	
	is_busy = false
	
	# Prévenir le client que c'est fini
	if customer.has_method("on_coffee_received"):
		customer.on_coffee_received()

# --- Internal Actions ---

func fill_machine(amount: int) -> void:
	var space_left = max_coffee_capacity - current_coffee_stock
	var amount_to_add = min(amount, space_left)
	
	if amount_to_add > 0:
		current_coffee_stock += amount_to_add
		Global.raw_coffee_carried -= amount_to_add
		print("Machine refilled. Current stock: ", current_coffee_stock)
	else:
		print("Machine is already full!")

func serve_coffee_to_cat() -> void:
	current_coffee_stock -= 1
	var price = 5.0 + (level * 2.0)
	
	if randf() < failure_chance:
		Global.add_money(price)
		Global.lose_satisfaction(15)
		print("SCAM: Machine took money but broke down!")
	else:
		Global.add_money(price)
		if randf() < bad_taste_chance:
			print("Coffee served, but it tastes like mud...")
			Global.add_satisfaction(1)
		else:
			print("Decent coffee served.")
			Global.add_satisfaction(5)

# --- UI & Info ---

func open_action_wheel() -> void:
	print("--- ACTION WHEEL ---")
	if Global.raw_coffee_carried >= 10:
		fill_machine(10)
	else:
		print("You need 10 raw coffee to refill!")

func show_advanced_info() -> void:
	print("--- ", machine_name, " (Level ", level, ") ---")
	print("Stock: ", current_coffee_stock, "/", max_coffee_capacity)
	print("Status: ", "BUSY" if is_busy else "READY")

# --- Signals ---

func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = true

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "CharacterBody2D":
		is_player_nearby = false
