extends Control

# 验证目标：验证 Node2D、CanvasLayer、CanvasGroup 之间的坐标转换和分组显示。
# 机制说明：世界坐标、全局坐标和 Canvas 坐标分别显示，便于观察转换基准的差异。

@onready var _world: Node2D = %World
@onready var _world_marker: Marker2D = %WorldMarker
@onready var _canvas_layer: CanvasLayer = %OverlayLayer
@onready var _canvas_group: CanvasGroup = %CanvasGroup
@onready var _status: Label = %Status
@onready var _world_position: Label = %WorldPosition
@onready var _global_position: Label = %GlobalPosition
@onready var _canvas_position: Label = %CanvasPosition
@onready var _move_button: Button = %MoveButton
@onready var _convert_button: Button = %ConvertButton
@onready var _toggle_group_button: Button = %ToggleGroupButton
@onready var _reset_button: Button = %ResetButton

func _ready() -> void:
	_move_button.pressed.connect(_move_marker)
	_convert_button.pressed.connect(_convert_coordinates)
	_toggle_group_button.pressed.connect(_toggle_group)
	_reset_button.pressed.connect(_reset_test)
	_reset_test()

func _move_marker() -> void:
	_world_marker.position += Vector2(32, 20)
	_convert_coordinates()

func _convert_coordinates() -> void:
	var global_point := _world.to_global(_world_marker.position)
	var local_point := _world.to_local(global_point)
	var canvas_point := get_viewport().get_canvas_transform() * global_point
	_world_position.text = "局部坐标：%s" % local_point
	_global_position.text = "全局坐标：%s" % global_point
	_canvas_position.text = "Canvas 坐标：%s" % canvas_point
	_status.text = "已完成 to_global()、to_local() 和 CanvasTransform 转换"

func _toggle_group() -> void:
	_canvas_group.visible = not _canvas_group.visible
	_toggle_group_button.text = "显示 CanvasGroup" if not _canvas_group.visible else "隐藏 CanvasGroup"
	_status.text = "CanvasGroup：%s" % ["显示" if _canvas_group.visible else "隐藏"]

func _reset_test() -> void:
	_world_marker.position = Vector2(190, 120)
	_canvas_group.visible = true
	_toggle_group_button.text = "隐藏 CanvasGroup"
	_status.text = "等待操作"
	_convert_coordinates()
