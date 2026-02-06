extends CanvasLayer # On étend CanvasLayer pour être au dessus de tout

# Chemins mis à jour selon l'arborescence de l'Étape 1
@onready var main_control = $MainControl
@onready var phone_body = $MainControl/PhoneBody
@onready var item_list = $MainControl/PhoneBody/ContentBox/LeftColumn/ScrollContainer/ItemList
@onready var detail_panel = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel
@onready var detail_text = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/Labels
@onready var fill_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/FillButton
@onready var upgrade_button = $MainControl/PhoneBody/ContentBox/RightColumn/DetailPanel/VBoxDetails/UpgradeButton
@onready var info_label = $MainControl/PhoneBody/InfoLabel

# Boutons d'onglets
@onready var btn_machines = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnMachines
@onready var btn_cats = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnCats
@onready var btn_player = $MainControl/PhoneBody/ContentBox/LeftColumn/TabsContainer/BtnPlayer

var selected_object: Node = null
var typing_tween: Tween

func _ready():
	add_to_group("ui_layer")
	process_mode = Node.PROCESS_MODE_ALWAYS # Important pour fonctionner en pause
	
	# Initialisation visuelle
	main_control.visible = false
	info_label.modulate.a = 0
	detail_panel.modulate.a = 0
	
	# --- CONNEXIONS AUTOMATIQUES (Plus besoin de le faire à la souris) ---
	btn_machines.pressed.connect(func(): open_category("machines"))
	btn_cats.pressed.connect(func(): open_category("cats"))
	btn_player.pressed.connect(func(): open_category("player"))
	
	fill_button.pressed.connect(_on_fill_button_pressed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	item_list.item_selected.connect(_on_item_list_item_selected)
	
	# Position de départ (hors écran vers le bas)
	phone_body.position.y = get_viewport().get_visible_rect().size.y

func _input(event):
	if event.is_action_pressed("toggle_phone"): # Vérifie que cette action existe !
		toggle_phone()

func toggle_phone(category: String = "machines", target_node: Node = null):
	var viewport_h = get_viewport().get_visible_rect().size.y
	var target_y = (viewport_h - phone_body.size.y) / 2 # Centre verticalement
	
	if not main_control.visible:
		# OUVERTURE
		main_control.visible = true
		get_tree().paused = true
		
		# Reset position bas
		phone_body.position.y = viewport_h
		
		var t = create_tween()
		t.tween_property(phone_body, "position:y", target_y, 0.4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		
		open_category(category)
		if target_node:
			await get_tree().process_frame
			select_specific_object(target_node)
	else:
		# FERMETURE
		var t = create_tween()
		t.tween_property(phone_body, "position:y", viewport_h, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		await t.finished
		main_control.visible = false
		get_tree().paused = false

func open_category(cat: String):
	item_list.clear()
	detail_panel.hide() # Cache les détails quand on change d'onglet
	var nodes = get_tree().get_nodes_in_group(cat)
	for node in nodes:
		var idx = item_list.add_item(" " + node.name)
		item_list.set_item_metadata(idx, node)

func _on_item_list_item_selected(index):
	selected_object = item_list.get_item_metadata(index)
	_show_details(selected_object)

func _show_details(obj):
	if not is_instance_valid(obj): return
	
	var content = ""
	if obj.is_in_group("machines"):
		var cost = 50 * obj.local_level
		content = "[center][b][color=yellow]— MACHINE —[/color][/b][/center]\n"
		content += "\nNom: %s" % obj.name
		content += "\nNiveau: [color=cyan]%d[/color]" % obj.local_level
		content += "\nStock: [color=orange]%d/%d[/color]" % [obj.current_coffee_stock, obj.max_coffee_stock]
		content += "\n\n[wave amp=50 freq=2]Coût: %d$[/wave]" % cost
		fill_button.show()
		upgrade_button.show()
		upgrade_button.text = "AMELIORER"
		
	elif obj.is_in_group("player"):
		var cost = 40 * Global.fishing_level
		content = "[center][b][color=orange]— MOI —[/color][/b][/center]\n"
		content += "\nPêche: [color=cyan]Lvl %d[/color]" % Global.fishing_level
		content += "\nArgent: [color=green]%d$[/color]" % Global.money
		content += "\n\n[wave amp=50 freq=2]Coût: %d$[/wave]" % cost
		fill_button.hide()
		upgrade_button.show()
		upgrade_button.text = "ENTRAINEMENT"

	elif obj.is_in_group("cats"):
		content = "[center][b][color=pink]— CLIENT —[/color][/b][/center]\n"
		content += "\nNom: %s" % obj.name
		content += "\nSanté: %d" % obj.health
		fill_button.hide()
		upgrade_button.hide()

	_typewriter_effect(content)

func _typewriter_effect(new_text: String):
	if typing_tween: typing_tween.kill()
	
	detail_text.text = new_text
	detail_text.visible_ratio = 0.0
	detail_panel.show()
	detail_panel.modulate.a = 1.0
	
	typing_tween = create_tween()
	typing_tween.tween_property(detail_text, "visible_ratio", 1.0, 0.5)

# --- FONCTIONS D'ACTION ---

func _on_fill_button_pressed():
	if is_instance_valid(selected_object) and selected_object.is_in_group("machines"):
		if Global.raw_coffee_carried > 0:
			var space = selected_object.max_coffee_stock - selected_object.current_coffee_stock
			if space > 0:
				var transfer = min(space, Global.raw_coffee_carried)
				selected_object.current_coffee_stock += transfer
				Global.raw_coffee_carried -= transfer
				display_info("Rempli !")
				_show_details(selected_object)
			else:
				display_info("Déjà plein !")
		else:
			display_info("Pas de café !")

func _on_upgrade_button_pressed():
	if not is_instance_valid(selected_object): return
	
	if selected_object.is_in_group("machines"):
		var cost = 50 * selected_object.local_level
		if Global.money >= cost:
			Global.money -= cost
			selected_object.upgrade_this_machine()
			_show_details(selected_object)
			display_info("Upgrade OK !")
		else:
			display_info("Pas assez d'argent")
			
	elif selected_object.is_in_group("player"):
		var cost = 40 * Global.fishing_level
		if Global.money >= cost:
			Global.money -= cost
			Global.fishing_level += 1
			_show_details(selected_object)
			display_info("Niveau UP !")
		else:
			display_info("Pas assez d'argent")

func select_specific_object(target: Node):
	for i in range(item_list.get_item_count()):
		if item_list.get_item_metadata(i) == target:
			item_list.select(i)
			_show_details(target)
			break

func display_info(msg):
	info_label.text = msg
	info_label.modulate.a = 1.0
	var t = create_tween()
	t.tween_interval(1.5)
	t.tween_property(info_label, "modulate:a", 0.0, 0.5)
