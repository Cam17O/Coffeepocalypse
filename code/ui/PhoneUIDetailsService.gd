extends RefCounted

var _ui: CanvasLayer

func _init(ui: CanvasLayer):
	_ui = ui

func machine_details(machine) -> String:
	if machine == null or not is_instance_valid(machine):
		return "Machine manquante"
	var lines = []
	lines.append("[b]Machine[/b]")
	if machine.has_method("get_upgrade_level"):
		lines.append("Niveau: " + str(machine.get_upgrade_level()))
	lines.append("Stock: " + str(machine.current_coffee_stock) + " / " + str(machine.max_coffee_stock))
	var brew_time = machine.get_effective_brewing_time() if machine.has_method("get_effective_brewing_time") else machine.brewing_time
	lines.append("Temps infusion: " + str(snapped(brew_time, 0.1)) + "s")
	lines.append("Echec: " + str(int(machine.fail_chance * 100.0)) + "%")
	lines.append("Mauvais gout: " + str(int(machine.bad_taste_chance * 100.0)) + "%")
	lines.append("Prend argent si echec: " + str(int(machine.take_money_on_fail_chance * 100.0)) + "%")
	lines.append("Prix cafe: " + str(snapped(machine.coffee_price, 0.1)))
	lines.append("Satisfaction (+/-): " + str(snapped(machine.satisfaction_reward, 0.1)) + " / " + str(snapped(machine.satisfaction_penalty, 0.1)))
	if machine.has_method("get_worker_count"):
		lines.append("Workers: " + str(machine.get_worker_count()) + " / " + str(machine.max_workers))
	var success_rate = max(0.0, 1.0 - machine.fail_chance)
	var expected_per_brew = machine.coffee_price * success_rate
	var expected_per_min = (60.0 / max(0.1, brew_time)) * expected_per_brew
	lines.append("Occupe: " + str(machine.is_busy))
	lines.append("File attente: " + str(machine.waiting_count))
	lines.append("Succes: " + str(int(success_rate * 100.0)) + "%")
	lines.append("Gain moyen / infusion: " + str(snapped(expected_per_brew, 0.1)))
	lines.append("Gain moyen / min: " + str(snapped(expected_per_min, 0.1)))
	return "\n".join(lines)

func storage_details(storage) -> String:
	if storage == null or not is_instance_valid(storage):
		return "Stockage manquant"
	var lines = []
	lines.append("[b]Stockage[/b]")
	if storage.has_method("get_upgrade_level"):
		lines.append("Niveau: " + str(storage.get_upgrade_level()))
	lines.append("Stock: " + str(storage.coffee_inventory) + " / " + str(storage.max_inventory))
	lines.append("Arrivage: +" + str(storage.arrival_amount) + " / " + str(snapped(storage.arrival_interval, 0.1)) + "s")
	lines.append("Auto remplissage: " + ("ON" if storage.auto_fill_enabled else "OFF"))
	lines.append("Cout auto: " + str(snapped(storage.auto_fill_cost_per_unit, 0.1)) + " / unite")
	lines.append("Capacite sac: " + str(Global.max_coffee_capacity))
	lines.append("Sac actuel: " + str(Global.raw_coffee_carried))
	if storage.has_method("get_worker_count"):
		lines.append("Workers: " + str(storage.get_worker_count()) + " / " + str(storage.max_workers))
	var free_space = max(0, storage.max_inventory - storage.coffee_inventory)
	var fill_time = 0.0
	if storage.arrival_amount > 0:
		fill_time = (free_space / float(storage.arrival_amount)) * storage.arrival_interval
	lines.append("Place libre: " + str(free_space))
	lines.append("Temps pour remplir: " + str(snapped(fill_time, 0.1)) + "s")
	return "\n".join(lines)

func cat_details(cat) -> String:
	if cat == null or not is_instance_valid(cat):
		return "Chat manquant"
	var is_special = cat.get("is_special")
	var health = cat.get("health")
	var energy = cat.get("energy")
	var max_energy = cat.get("max_energy")
	var lines = []
	lines.append("[b]Chat[/b]")
	lines.append("Special: " + str(is_special))
	lines.append("Vie: " + str(health))
	lines.append("Energie: " + str(int(energy)) + " / " + str(int(max_energy)))
	var state_label = str(cat.current_state)
	if cat.current_state == 0:
		state_label = "Balade"
	elif cat.current_state == 1:
		state_label = "Cherche cafe"
	elif cat.current_state == 2:
		state_label = "Attente"
	elif cat.current_state == 3:
		state_label = "Boit"
	elif cat.current_state == 4:
		state_label = "Va travailler"
	elif cat.current_state == 5:
		state_label = "Travaille"
	lines.append("Etat: " + state_label)
	var target_name = "-"
	if cat.has_method("get_target_machine"):
		var target_machine = cat.get_target_machine()
		if target_machine and is_instance_valid(target_machine):
			target_name = target_machine.name
	lines.append("Machine cible: " + target_name)
	if cat.has_method("get_waiting_time"):
		lines.append("Attente: " + str(snapped(cat.get_waiting_time(), 0.1)) + "s")
	if cat.has_method("get_current_machine_score"):
		lines.append("Score actuel: " + str(snapped(cat.get_current_machine_score(), 1.0)))
	if cat.has_method("get_best_machine"):
		var best_machine = cat.get_best_machine()
		var best_name = "-" if not best_machine or not is_instance_valid(best_machine) else best_machine.name
		lines.append("Meilleure machine: " + best_name)
		if cat.has_method("get_best_machine_score"):
			lines.append("Meilleur score: " + str(snapped(cat.get_best_machine_score(), 1.0)))
	return "\n".join(lines)

func storage_product_list_text(storage_products: Array) -> Array:
	var result = []
	for product in storage_products:
		var name = product["name"]
		var unit = product["unit_cost"]
		result.append(name + " (" + str(snapped(unit, 0.1)) + "$)")
	return result

func cat_home_details(home) -> String:
	if home == null or not is_instance_valid(home):
		return "Cats house manquante"
	var lines = []
	lines.append("[b]Cats house[/b]")
	lines.append("Niveau: " + str(home.upgrade_level))
	lines.append("Chats max: " + str(home.max_cats_alive))
	lines.append("Spawn: " + str(snapped(home.spawn_interval, 0.1)) + "s")
	lines.append("Chance: " + str(int(home.min_spawn_chance * 100.0)) + "% - " + str(int(home.max_spawn_chance * 100.0)) + "%")
	if home.has_method("get_worker_count"):
		lines.append("Workers: " + str(home.get_worker_count()) + " / " + str(home.max_workers))
	var current = _ui.get_tree().get_nodes_in_group("cats").size()
	var capacity_rate = 0.0
	if home.max_cats_alive > 0:
		capacity_rate = float(current) / float(home.max_cats_alive)
	lines.append("Chats actuels: " + str(current))
	lines.append("Occupation: " + str(int(capacity_rate * 100.0)) + "%")
	return "\n".join(lines)

func stats_details() -> String:
	var lines = []
	lines.append("[b]Stats[/b]")
	lines.append("Argent: " + str(snapped(Global.money, 0.1)))
	lines.append("Satisfaction: " + str(int(Global.global_satisfaction)))
	lines.append("Cafe brut sac: " + str(Global.raw_coffee_carried) + " / " + str(Global.max_coffee_capacity))
	lines.append("Stock zone: " + str(_ui._total_storage_stock()))
	lines.append("Chats: " + str(_ui.get_tree().get_nodes_in_group("cats").size()))
	return "\n".join(lines)

func player_details() -> String:
	var lines = []
	lines.append("[b]Joueur[/b]")
	lines.append("Argent: " + str(snapped(Global.money, 0.1)))
	lines.append("Cafe brut sac: " + str(Global.raw_coffee_carried) + " / " + str(Global.max_coffee_capacity))
	return "\n".join(lines)
