extends Control

# 验证目标：验证 Camera2D 的当前相机、缩放、平滑跟随和边界限制。
# 场景数据：相机初始位置、限制范围和目标节点固定在 camera_test.tscn。

@onready var _camera: Camera2D = %Camera
@onready var _status: Label = %Status
@onready var _zoom_slider: HSlider = %ZoomSlider
@onready var _left_button: Button = %LeftButton
@onready var _center_button: Button = %CenterButton
@onready var _right_button: Button = %RightButton
@onready var _limits: CheckBox = %Limits
@onready var _smooth: CheckBox = %Smooth
var _limits_enabled := true

func _ready() -> void:
	_left_button.pressed.connect(_move_camera.bind(Vector2(-120, 0)))
	_center_button.pressed.connect(_reset_camera)
	_right_button.pressed.connect(_move_camera.bind(Vector2(120, 0)))
	_zoom_slider.value_changed.connect(_set_zoom)
	_limits.toggled.connect(_set_limits_enabled)
	_smooth.toggled.connect(_set_smoothing_enabled)
	_camera.make_current()
	_update_status()

func _move_camera(offset: Vector2) -> void:
	_camera.position += offset
	_update_status()

func _reset_camera() -> void:
	_camera.position = Vector2.ZERO
	_camera.zoom = Vector2.ONE
	_zoom_slider.value = 1.0
	_update_status()

func _set_zoom(value: float) -> void:
	_camera.zoom = Vector2(value, value)
	_update_status()

func _set_limits_enabled(value: bool) -> void:
	_limits_enabled = value
	_camera.limit_smoothed = value
	if value:
		_camera.limit_left = -500
		_camera.limit_top = -300
		_camera.limit_right = 500
		_camera.limit_bottom = 300
	else:
		_camera.limit_left = -10000000
		_camera.limit_top = -10000000
		_camera.limit_right = 10000000
		_camera.limit_bottom = 10000000
	_update_status()

func _set_smoothing_enabled(value: bool) -> void:
	_camera.position_smoothing_enabled = value
	_update_status()

func _update_status() -> void:
	if not is_instance_valid(_status):
		return
	_status.text = "位置：%s\n缩放：%.2f\n边界：%s" % [_camera.position, _camera.zoom.x, "开启" if _limits_enabled else "关闭"]
