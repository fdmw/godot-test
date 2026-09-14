extends Control

const DragSourceScript = preload("res://drag_drop/drag_source.gd")
const DropTargetScript = preload("res://drag_drop/drop_target.gd")

@onready var _source: DragSourceScript = %Source
@onready var _target: DropTargetScript = %Target
@onready var _status: Label = %Status
@onready var _reset_button: Button = %ResetButton

func _ready() -> void:
	_source.drag_started.connect(_on_drag_started)
	_target.item_dropped.connect(_on_item_dropped)
	_reset_button.pressed.connect(_reset_test)
	_reset_test()

func _on_drag_started(item_text: String) -> void:
	_status.text = "正在拖动：%s\n请将项目拖到右侧区域。" % item_text

func _on_item_dropped(item_text: String) -> void:
	_status.text = "已放置：%s\n_can_drop_data() 和 _drop_data() 已触发。" % item_text

func _reset_test() -> void:
	_status.text = "等待拖放\n鼠标过滤：%s" % ["停止" if _target.mouse_filter == Control.MOUSE_FILTER_IGNORE else "接收"]
