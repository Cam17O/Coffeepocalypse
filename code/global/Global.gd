extends Node

# --- JOUEUR (Ressources et Stats) ---
var money: float = 0.0
var raw_coffee_carried: int = 0
var max_coffee_capacity: int = 20 # Capacité de transport du joueur
var fishing_level: int = 1

# --- SATISFACTION GLOBALE (Système de Chats) ---
var global_satisfaction: float = 100.0
var total_cats_on_island: int = 5

# --- ÉCONOMIE / PROGRESSION ---
var coffee_stock_total: int = 100 # Dans la zone de stockage
var max_stock_storage: int = 500

# --- SYSTÈME DE SAUVEGARDE (Local) ---
const SAVE_PATH = "user://savegame.save"

func add_money(amount: float):
	money += amount
	print("Money: ", money)

func add_satisfaction(amount: float):
	global_satisfaction = clamp(global_satisfaction + amount, 0, 100)
	
func lose_satisfaction(amount: float):
	# Si la satisfaction est basse, les problèmes ont plus d'impact
	var impact_multiplier = 1.0
	if global_satisfaction < 30:
		impact_multiplier = 2.0
	
	global_satisfaction = clamp(global_satisfaction - (amount * impact_multiplier), 0, 100)

# --- SAUVEGARDE / IMPORT / EXPORT ---

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data = {
		"money": money,
		"global_satisfaction": global_satisfaction,
		"fishing_level": fishing_level,
		"coffee_stock": coffee_stock_total
	}
	file.store_var(data)
	print("Game Saved!")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	
	money = data.get("money", 0.0)
	global_satisfaction = data.get("global_satisfaction", 100.0)
	fishing_level = data.get("fishing_level", 1)
	coffee_stock_total = data.get("coffee_stock", 100)
	print("Game Loaded!")
