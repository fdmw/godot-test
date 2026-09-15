extends Control

# 验证目标：验证 RemoteTransform2D 对目标节点的位置、旋转和缩放同步，以及同步开关。
# 机制说明：Source 是唯一被操作的节点，Target 的变化用于观察 RemoteTransform2D 的代理效果。

@onready var _source: Node2D = %Source
@onready var _target: Node2D = %Target
@onready var _remote: RemoteTransform2D = %RemoteTransform
@onready var _move_button: Button = %MoveButton
@onready var _pose_button: Button = %PoseButton
@onready var _sync_button: Button = %SyncButton
@onready var _reset_button: Button = %ResetButton
@onready var _status: Label = %Status

func _ready() -> void:
	_move_button.pressed.connect(_move_source)
	_pose_button.pressed.connect(_apply_source_pose)
	_sync_button.pressed.connect(_toggle_sync)
	_reset_button.pressed.connect(_reset_test)
	_reset_test()

func _move_source() -> void:
	_source.position += Vector2(35, 20)
	_update_status("已移动 Source，观察 Target 是否同步")

func _apply_source_pose() -> void:
	_source.rotation += deg_to_rad(18.0)
	_source.scale += Vector2(0.08, 0.08)
	_update_status("已修改 Source 的旋转和缩放")

func _toggle_sync() -> void:
	_remote.update_position = not _remote.update_position
	_remote.update_rotation = _remote.update_position
	_remote.update_scale = _remote.update_position
	_sync_button.text = "关闭同步" if _remote.update_position else "开启同步"
	_update_status("RemoteTransform2D 同步：%s" % ["开启" if _remote.update_position else "关闭"])

func _reset_test() -> void:
	_source.position = Vector2(150, 155)
	_source.rotation = 0.0
	_source.scale = Vector2.ONE
	_remote.update_position = true
	_remote.update_rotation = true
	_remote.update_scale = true
	_sync_button.text = "关闭同步"
	_update_status("等待操作")

func _update_status(message: String) -> void:
	_status.text = "%s\nSource：%s\nTarget：%s" % [message, _source.global_position, _target.global_position]
