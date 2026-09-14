extends Control

@onready var _background: Parallax2D = %Background
@onready var _foreground: Parallax2D = %Foreground
@onready var _speed: HSlider = %Speed
@onready var _direction: OptionButton = %Direction
@onready var _play_button: Button = %PlayButton
@onready var _reset_button: Button = %ResetButton
@onready var _status: Label = %Status

var _playing: bool = false
var _offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_direction.add_item("水平")
	_direction.add_item("垂直")
	_speed.value_changed.connect(_update_status)
	_direction.item_selected.connect(_on_direction_selected)
	_play_button.pressed.connect(_toggle_play)
	_reset_button.pressed.connect(_reset_scroll)
	_update_status()

func _process(delta: float) -> void:
	if not _playing:
		return
	var axis := Vector2.RIGHT if _direction.selected == 0 else Vector2.DOWN
	_offset += axis * _speed.value * delta
	_background.scroll_offset = _offset * 0.35
	_foreground.scroll_offset = _offset
	_update_status()

func _toggle_play() -> void:
	_playing = not _playing
	_play_button.text = "暂停" if _playing else "播放"
	_update_status()

func _reset_scroll() -> void:
	_playing = false
	_play_button.text = "播放"
	_offset = Vector2.ZERO
	_background.scroll_offset = Vector2.ZERO
	_foreground.scroll_offset = Vector2.ZERO
	_update_status()

func _on_direction_selected(_index: int) -> void:
	_update_status()

func _update_status(_value: float = 0.0) -> void:
	_status.text = "滚动偏移：%s\n背景比例：%s\n前景比例：%s" % [
		_offset,
		_background.scroll_scale,
		_foreground.scroll_scale,
	]
