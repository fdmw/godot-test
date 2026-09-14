extends Control

# 验证目标：验证 DisplayServer 窗口尺寸、窗口模式和 Viewport 尺寸反馈。
# 机制说明：显示设置属于进程级窗口状态，测试只通过按钮修改并在界面中刷新当前值。

@onready var _size_option: OptionButton = %SizeOption
@onready var _mode_option: OptionButton = %ModeOption
@onready var _status: Label = %Status
@onready var _apply_button: Button = %ApplyButton
@onready var _refresh_button: Button = %RefreshButton
var _original_window_size := Vector2i.ZERO
var _original_window_mode := DisplayServer.WINDOW_MODE_WINDOWED

func _ready() -> void:
	_original_window_size = DisplayServer.window_get_size()
	_original_window_mode = DisplayServer.window_get_mode()
	_size_option.add_item("900 x 600")
	_size_option.add_item("1280 x 720")
	_mode_option.add_item("窗口")
	_mode_option.add_item("全屏")
	_apply_button.pressed.connect(_apply_display)
	_refresh_button.pressed.connect(_refresh_status)
	_refresh_status()

func _exit_tree() -> void:
	# DisplayServer 状态属于进程级窗口，切换测试时恢复进入本测试前的设置。
	if _original_window_size != Vector2i.ZERO:
		DisplayServer.window_set_mode(_original_window_mode)
		DisplayServer.window_set_size(_original_window_size)

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
	var stretch_mode := str(ProjectSettings.get_setting("display/window/stretch/mode", "未设置"))
	var stretch_aspect := str(ProjectSettings.get_setting("display/window/stretch/aspect", "未设置"))
	_status.text = "窗口：%s\nViewport：%s\n模式：%s\nStretch：%s / Aspect：%s" % [window_size, viewport_size, mode_text, stretch_mode, stretch_aspect]
