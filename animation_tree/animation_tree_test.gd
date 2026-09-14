extends Control

# 验证目标：验证 AnimationTree 状态机的状态注册、播放控制和状态切换。
# 机制说明：状态机节点在运行时创建，目的是直接展示 AnimationTree 的运行时状态机接口。

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
	# AnimationTree 的 tree_root 是运行时状态机资源；场景只提供 AnimationPlayer 和动画资源。
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
	# playback 参数由 AnimationTree 创建，取得后通过 travel/start 控制状态而非直接改动画节点。
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
