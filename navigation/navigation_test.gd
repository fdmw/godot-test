extends Control

# 验证目标：验证 NavigationRegion2D、NavigationAgent2D、NavigationLink2D、层过滤和障碍。
# 机制说明：目标点和导航几何固定在场景中；运行时只修改 Agent 目标、Link 开关和导航层。

@onready var _agent: NavigationAgent2D = %Agent
@onready var _target: Marker2D = %Target
@onready var _target_one_marker: Marker2D = %TargetOneMarker
@onready var _target_two_marker: Marker2D = %TargetTwoMarker
@onready var _target_three_marker: Marker2D = %TargetThreeMarker
@onready var _actor: Polygon2D = %Actor
@onready var _status: Label = %Status
@onready var _target_one: Button = %TargetOne
@onready var _target_two: Button = %TargetTwo
@onready var _target_three: Button = %TargetThree
@onready var _reset_button: Button = %ResetButton
@onready var _link: NavigationLink2D = %Link
@onready var _link_toggle: CheckBox = %LinkToggle
@onready var _layer_toggle: CheckBox = %LayerToggle
@onready var _avoidance_toggle: CheckBox = %AvoidanceToggle
var _actor_start_position: Vector2
var _safe_velocity := Vector2.ZERO

func _ready() -> void:
	_actor_start_position = _actor.position
	_target_one.pressed.connect(_set_target.bind(_target_one_marker.position))
	_target_two.pressed.connect(_set_target.bind(_target_two_marker.position))
	_target_three.pressed.connect(_set_target.bind(_target_three_marker.position))
	_reset_button.pressed.connect(_reset_agent)
	_link_toggle.toggled.connect(_set_link_enabled)
	_layer_toggle.toggled.connect(_set_agent_layer)
	_avoidance_toggle.toggled.connect(_set_avoidance_enabled)
	_agent.velocity_computed.connect(_on_velocity_computed)
	await get_tree().physics_frame
	_set_target(_target.position)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_agent) or not is_instance_valid(_actor):
		return
	if _agent.is_navigation_finished():
		_actor.position = _agent.position
		_update_status("已到达目标")
		return
	var next_position := _agent.get_next_path_position()
	var desired_velocity: Vector2 = _actor.global_position.direction_to(next_position) * 110.0
	_agent.velocity = desired_velocity
	# 开启避障时使用 NavigationAgent2D 通过 velocity_computed 给出的安全速度。
	# 回调与物理帧存在先后关系，因此保留上一帧结果作为当前帧的连续运动输入。
	var motion_velocity := _safe_velocity if _agent.avoidance_enabled else desired_velocity
	_actor.position += motion_velocity * delta
	_agent.target_position = _target.position
	_update_status("移动中")

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_safe_velocity = safe_velocity

func _set_target(position: Vector2) -> void:
	_target.position = position
	_agent.target_position = position
	_update_status("目标已设置")

func _reset_agent() -> void:
	_actor.position = _actor_start_position
	_agent.target_position = _target.position

func _set_link_enabled(value: bool) -> void:
	_link.enabled = value
	_status.text = "NavigationLink2D：" + ("开启" if value else "关闭")

func _set_agent_layer(secondary_layer: bool) -> void:
	_agent.navigation_layers = 2 if secondary_layer else 1
	_agent.target_position = _target.position
	_status.text = "代理 NavigationLayers：%d" % _agent.navigation_layers

func _set_avoidance_enabled(value: bool) -> void:
	_agent.avoidance_enabled = value
	_safe_velocity = Vector2.ZERO
	_status.text = "NavigationAgent2D 避障：" + ("开启" if value else "关闭")

func _update_status(state: String) -> void:
	_status.text = "%s\n代理：%s\n目标：%s" % [state, _actor.position, _target.position]
