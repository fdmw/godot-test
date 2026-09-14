extends Control

@onready var _tree: AnimationTree = %AnimationTree
@onready var _status: Label = %Status
@onready var _idle_button: Button = %IdleButton
@onready var _move_button: Button = %MoveButton
@onready var _reset_button: Button = %ResetButton

var _playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	_build_state_machine()
	_idle_button.pressed.connect(_travel_to_idle)
	_move_button.pressed.connect(_travel_to_move)
	_reset_button.pressed.connect(_reset_tree)
	_reset_tree()

func _build_state_machine() -> void:
	var state_machine := AnimationNodeStateMachine.new()
	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = &"idle"
	state_machine.add_node(&"idle", idle_node, Vector2(100, 80))
	var move_node := AnimationNodeAnimation.new()
	move_node.animation = &"move"
	state_machine.add_node(&"move", move_node, Vector2(300, 80))
	var to_move := AnimationNodeStateMachineTransition.new()
	to_move.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	var to_idle := AnimationNodeStateMachineTransition.new()
	to_idle.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	state_machine.add_transition(&"idle", &"move", to_move)
	state_machine.add_transition(&"move", &"idle", to_idle)
	_tree.tree_root = state_machine
	_tree.active = true
	_playback = _tree.get("parameters/playback") as AnimationNodeStateMachinePlayback

func _travel_to_idle() -> void:
	_playback.travel(&"idle")
	_status.text = "状态机已切换到 idle"

func _travel_to_move() -> void:
	_playback.travel(&"move")
	_status.text = "状态机已切换到 move"

func _reset_tree() -> void:
	_playback.start(&"idle")
	_status.text = "当前状态：idle"
