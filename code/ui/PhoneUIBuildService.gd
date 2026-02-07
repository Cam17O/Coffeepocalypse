extends RefCounted

const BUILD_SNAP_TOLERANCE := 8.0

var _ui: CanvasLayer
var _pending_build_scene: PackedScene
var _pending_build_cost: float = 0.0
var _pending_build_name: String = ""
var _build_ghost: Node2D

func _init(ui: CanvasLayer):
	_ui = ui

func has_pending_build() -> bool:
	return _pending_build_scene != null

func start_build(scene_path: String, cost: float, label: String):
	if Global.money < cost:
		_ui.display_info("Pas assez d'argent")
		return
	_pending_build_scene = load(scene_path)
	_pending_build_cost = cost
	_pending_build_name = label
	_ui.visible = false
	_ui.get_tree().paused = false
	_create_build_ghost()
	print("[Build] Start:", label, "cost", cost)

func process():
	if _pending_build_scene:
		_update_build_ghost()

func handle_unhandled_input(event) -> bool:
	if not _pending_build_scene:
		return false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_pending_build()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_pending_build()
		return true
	return false

func _place_pending_build():
	if not _pending_build_scene:
		return
	if Global.money < _pending_build_cost:
		_ui.display_info("Pas assez d'argent")
		_cancel_pending_build()
		return
	var world_pos = _get_mouse_world_position()
	var instance = _pending_build_scene.instantiate()
	var parent = _ui.get_tree().current_scene
	var nav = parent.get_node_or_null("NavigationRegion2D")
	if nav:
		nav.add_child(instance)
	else:
		parent.add_child(instance)
	instance.global_position = world_pos
	Global.add_money(-_pending_build_cost)
	print("[Build] Placed:", _pending_build_name, "at", world_pos)
	_cancel_pending_build()

func _cancel_pending_build():
	_pending_build_scene = null
	_pending_build_cost = 0.0
	_pending_build_name = ""
	if _build_ghost and is_instance_valid(_build_ghost):
		_build_ghost.queue_free()
	_build_ghost = null

func _create_build_ghost():
	if not _pending_build_scene:
		return
	if _build_ghost and is_instance_valid(_build_ghost):
		_build_ghost.queue_free()
	_build_ghost = _pending_build_scene.instantiate()
	_build_ghost.modulate = Color(1, 1, 1, 0.5)
	_build_ghost.process_mode = Node.PROCESS_MODE_DISABLED
	var parent = _ui.get_tree().current_scene
	var nav = parent.get_node_or_null("NavigationRegion2D")
	if nav:
		nav.add_child(_build_ghost)
	else:
		parent.add_child(_build_ghost)
	_update_build_ghost()

func _update_build_ghost():
	if not _build_ghost or not is_instance_valid(_build_ghost):
		return
	var pos = _get_mouse_world_position()
	_build_ghost.global_position = pos
	var ok = _is_valid_build_position(pos)
	if ok:
		_build_ghost.modulate = Color(0.2, 1.0, 0.2, 0.5)
	else:
		_build_ghost.modulate = Color(1.0, 0.2, 0.2, 0.5)

func _get_mouse_world_position() -> Vector2:
	var viewport = _ui.get_viewport()
	var cam = viewport.get_camera_2d()
	if cam:
		return cam.get_global_mouse_position()
	var mouse_pos = viewport.get_mouse_position()
	return viewport.get_canvas_transform().affine_inverse() * mouse_pos

func _is_valid_build_position(world_pos: Vector2) -> bool:
	var parent = _ui.get_tree().current_scene
	if not parent:
		return true
	var world = parent.get_world_2d()
	if not world:
		return true
	var nav_map = world.navigation_map
	if nav_map == RID():
		return true
	var closest = NavigationServer2D.map_get_closest_point(nav_map, world_pos)
	return world_pos.distance_to(closest) <= BUILD_SNAP_TOLERANCE
