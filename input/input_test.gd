extends Control

const LEFT_ACTION := "validation_move_left"
const RIGHT_ACTION := "validation_move_right"

@onready var _status: Label = %Status
@onready var _focus_status: Label = %FocusStatus
@onready var _mouse_panel: ColorRect = %MousePanel
@onready var _field: LineEdit = %Field
@onready var _first: Button = %FirstButton
@onready var _second: Button = %SecondButton
@onready var _checkbox: CheckBox = %Checkbox
var _created_actions: Array[StringName] = []

func _ready() -> void:
	_register_actions()
	_field.focus_entered.connect(_on_focus_entered.bind("LineEdit"))
	_field.focus_exited.connect(_on_focus_exited.bind("LineEdit"))
	_first.focus_entered.connect(_on_focus_entered.bind("按钮一"))
	_first.focus_exited.connect(_on_focus_exited.bind("按钮一"))
	_first.pressed.connect(_on_button_pressed.bind("按钮一"))
	_second.focus_entered.connect(_on_focus_entered.bind("按钮二"))
	_second.focus_exited.connect(_on_focus_exited.bind("按钮二"))
	_second.pressed.connect(_on_button_pressed.bind("按钮二"))
	_checkbox.focus_entered.connect(_on_focus_entered.bind("CheckBox"))
	_mouse_panel.gui_input.connect(_on_panel_gui_input)

func _exit_tree() -> void:
	for action: StringName in _created_actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)

func _register_actions() -> void:
	if not InputMap.has_action(LEFT_ACTION):
		InputMap.add_action(LEFT_ACTION)
		_created_actions.append(LEFT_ACTION)
		var left_event := InputEventKey.new()
		left_event.physical_keycode = KEY_A
		InputMap.action_add_event(LEFT_ACTION, left_event)
	if not InputMap.has_action(RIGHT_ACTION):
		InputMap.add_action(RIGHT_ACTION)
		_created_actions.append(RIGHT_ACTION)
		var right_event := InputEventKey.new()
		right_event.physical_keycode = KEY_D
		InputMap.action_add_event(RIGHT_ACTION, right_event)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_status.text = "_input 收到：" + OS.get_keycode_string(event.keycode)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(LEFT_ACTION):
		_status.text = "_unhandled_input：向左动作"
	elif event.is_action_pressed(RIGHT_ACTION):
		_status.text = "_unhandled_input：向右动作"

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_status.text = "_gui_input：面板点击 %s" % event.position

func _on_focus_entered(control_name: String) -> void:
	_focus_status.text = "焦点：" + control_name

func _on_focus_exited(control_name: String) -> void:
	_focus_status.text = "离开焦点：" + control_name

func _on_button_pressed(button_name: String) -> void:
	_status.text = "pressed：" + button_name
