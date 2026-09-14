extends Control

@onready var _size_option: OptionButton = %SizeOption
@onready var _mode_option: OptionButton = %ModeOption
@onready var _status: Label = %Status
@onready var _apply_button: Button = %ApplyButton
@onready var _refresh_button: Button = %RefreshButton

func _ready() -> void:
	_size_option.add_item("900 x 600")
	_size_option.add_item("1280 x 720")
	_mode_option.add_item("窗口")
	_mode_option.add_item("全屏")
	_apply_button.pressed.connect(_apply_display)
	_refresh_button.pressed.connect(_refresh_status)
	_refresh_status()

func _apply_display() -> void:
	var sizes: Array[Vector2i] = [Vector2i(900, 600), Vector2i(1280, 720)]
	DisplayServer.window_set_size(sizes[_size_option.selected])
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if _mode_option.selected == 1 else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	_refresh_status()

func _refresh_status() -> void:
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	var mode := DisplayServer.window_get_mode()
	var mode_text := "全屏" if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else "窗口"
	_status.text = "窗口：%s\nViewport：%s\n模式：%s" % [window_size, viewport_size, mode_text]
