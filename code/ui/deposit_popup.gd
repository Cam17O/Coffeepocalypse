extends PopupPanel

signal deposited(amount: int)

var _machine: Node

@onready var btn_x1 = $VBox/Buttons/X1Button
@onready var btn_x10 = $VBox/Buttons/X10Button
@onready var btn_max = $VBox/Buttons/MaxButton
@onready var cancel_btn = $VBox/CancelButton

func _ready():
	btn_x1.pressed.connect(func(): _do_deposit(1))
	btn_x10.pressed.connect(func(): _do_deposit(10))
	btn_max.pressed.connect(func(): _do_deposit(-1))
	cancel_btn.pressed.connect(hide)

func open(machine: Node):
	_machine = machine
	popup_centered()

func _do_deposit(amount: int):
	if not _machine or not is_instance_valid(_machine):
		hide()
		return
	var space = _machine.max_coffee_stock - _machine.current_coffee_stock
	if space <= 0 or Global.raw_coffee_carried <= 0:
		deposited.emit(0)
		hide()
		return
	var to_deposit: int
	if amount < 0:
		to_deposit = min(space, Global.raw_coffee_carried)
	else:
		to_deposit = mini(mini(amount, space), Global.raw_coffee_carried)
	if to_deposit > 0:
		_machine.current_coffee_stock += to_deposit
		Global.raw_coffee_carried -= to_deposit
		deposited.emit(to_deposit)
	hide()
