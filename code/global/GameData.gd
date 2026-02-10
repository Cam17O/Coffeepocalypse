extends RefCounted

## Registry des types de jeu (placeholders - à remplacer plus tard)
## Sprites: réutiliser icon.svg ou Chest.png avec noms différents

# Types de machines à café (id -> config)
const MACHINE_TYPES := {
	"machine_placeholder_1": {
		"name": "Machine Placeholder 1",
		"scene": "res://scenes/coffee_machine.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 0,
		"build_cost": 200,
		"base_brewing_time": 10.0,
		"base_max_stock": 10,
		"base_price": 10.0,
		"base_satisfaction": 5.0,
	},
	"machine_placeholder_2": {
		"name": "Machine Placeholder 2",
		"scene": "res://scenes/coffee_machine.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 500,
		"build_cost": 400,
		"base_brewing_time": 8.0,
		"base_max_stock": 15,
		"base_price": 12.0,
		"base_satisfaction": 6.0,
	},
	"machine_placeholder_3": {
		"name": "Machine Placeholder 3",
		"scene": "res://scenes/coffee_machine.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 1500,
		"build_cost": 800,
		"base_brewing_time": 6.0,
		"base_max_stock": 20,
		"base_price": 15.0,
		"base_satisfaction": 8.0,
	},
}

# Types de storage (id -> config)
const STORAGE_TYPES := {
	"storage_placeholder_1": {
		"name": "Storage Placeholder 1",
		"scene": "res://scenes/stockage.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 0,
		"build_cost": 0,
		"base_max_inventory": 40,
		"base_arrival_amount": 5,
		"base_arrival_interval": 60.0,
	},
	"storage_placeholder_2": {
		"name": "Pile of Box Placeholder",
		"scene": "res://scenes/stockage.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 300,
		"build_cost": 500,
		"base_max_inventory": 80,
		"base_arrival_amount": 8,
		"base_arrival_interval": 50.0,
	},
	"storage_placeholder_3": {
		"name": "Building Placeholder",
		"scene": "res://scenes/stockage.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 1000,
		"build_cost": 1200,
		"base_max_inventory": 150,
		"base_arrival_amount": 12,
		"base_arrival_interval": 40.0,
	},
}

# Types de boats (id -> config)
const BOAT_TYPES := {
	"boat_placeholder_1": {
		"name": "Boat Placeholder 1",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 0,
		"build_cost": 100,
		"base_storage": 20,
		"base_speed": 1.0,
		"travel_time": 60.0,
	},
	"boat_placeholder_2": {
		"name": "Boat Placeholder 2",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 400,
		"build_cost": 300,
		"base_storage": 40,
		"base_speed": 1.5,
		"travel_time": 45.0,
	},
}

# Types de cat house (id -> config)
const CAT_HOUSE_TYPES := {
	"cat_house_placeholder_1": {
		"name": "Cat House Placeholder 1",
		"scene": "res://scenes/cats_home.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 0,
		"build_cost": 150,
		"base_max_cats": 3,
		"base_spawn_interval": 30.0,
	},
	"cat_house_placeholder_2": {
		"name": "Cat House Placeholder 2",
		"scene": "res://scenes/cats_home.tscn",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 600,
		"build_cost": 350,
		"base_max_cats": 5,
		"base_spawn_interval": 25.0,
	},
}

# Types de robots (id -> config)
const ROBOT_TYPES := {
	"robot_storage": {
		"name": "Robot Storage Placeholder",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 800,
		"build_cost": 600,
		"type": "storage",
	},
	"robot_cleaner": {
		"name": "Robot Cleaner Placeholder",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 600,
		"build_cost": 450,
		"type": "cleaner",
	},
	"robot_reparateur": {
		"name": "Robot Réparateur Placeholder",
		"sprite": "res://Sprout Lands - Sprites - Basic pack/Objects/Chest.png",
		"unlock_cost": 700,
		"build_cost": 500,
		"type": "reparateur",
	},
}

# Arbre des talents (id -> config)
const TALENTS := {
	"talent_machine_2": {"name": "Machine Placeholder 2", "cost": 500, "unlocks": "machine_placeholder_2"},
	"talent_machine_3": {"name": "Machine Placeholder 3", "cost": 1500, "unlocks": "machine_placeholder_3"},
	"talent_storage_2": {"name": "Storage Placeholder 2", "cost": 300, "unlocks": "storage_placeholder_2"},
	"talent_storage_3": {"name": "Storage Placeholder 3", "cost": 1000, "unlocks": "storage_placeholder_3"},
	"talent_boat_2": {"name": "Boat Placeholder 2", "cost": 400, "unlocks": "boat_placeholder_2"},
	"talent_cat_house_2": {"name": "Cat House Placeholder 2", "cost": 600, "unlocks": "cat_house_placeholder_2"},
	"talent_robot_storage": {"name": "Robot Storage", "cost": 800, "unlocks": "robot_storage"},
	"talent_robot_cleaner": {"name": "Robot Cleaner", "cost": 600, "unlocks": "robot_cleaner"},
	"talent_robot_reparateur": {"name": "Robot Réparateur", "cost": 700, "unlocks": "robot_reparateur"},
	"talent_carry_capacity": {"name": "Quantité transportable +10", "cost": 200, "unlocks": "carry_capacity"},
	"talent_auto_restock": {"name": "Auto restock storage", "cost": 1000, "unlocks": "auto_restock"},
}

# Prix matière première pour les bateaux
const RAW_COFFEE_UNIT_PRICE := 4.0
