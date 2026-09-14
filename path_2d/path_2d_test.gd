extends Control

@onready var _follower: PathFollow2D = %Follower
@onready var _progress: HSlider = %Progress
@onready var _play_button: Button = %PlayButton
@onready var _reset_button: Button = %ResetButton
@onready var _loop: CheckBox = %Loop
@onready var _status: Label = %Status

var _playing: bool = false

func _ready() -> void:
	_progress.value_changed.connect(_set_progress)
	_play_button.pressed.connect(_toggle_play)
	_reset_button.pressed.connect(_reset_path)
	_loop.toggled.connect(_set_loop)
	_set_loop(_loop.button_pressed)
	_set_progress(_progress.value)

func _process(delta: float) -> void:
	if not _playing:
		return
	var next_progress := _follower.progress_ratio + delta * 0.18
	if _loop.button_pressed:
		next_progress = fmod(next_progress, 1.0)
	elif next_progress >= 1.0:
		next_progress = 1.0
		_playing = false
		_play_button.text = "播放"
	_follower.progress_ratio = next_progress
	_progress.set_value_no_signal(next_progress * 100.0)
	_update_status()

func _toggle_play() -> void:
	_playing = not _playing
	_play_button.text = "暂停" if _playing else "播放"
	_update_status()

func _reset_path() -> void:
	_playing = false
	_play_button.text = "播放"
	_follower.progress_ratio = 0.0
	_progress.set_value_no_signal(0.0)
	_update_status()

func _set_progress(value: float) -> void:
	_follower.progress_ratio = clampf(value / 100.0, 0.0, 1.0)
	_update_status()

func _set_loop(enabled: bool) -> void:
	_follower.loop = enabled
	_update_status()

func _update_status() -> void:
	_status.text = "进度：%.0f%%\n位置：%s\n循环：%s" % [
		_progress.value,
		_follower.global_position,
		"开启" if _loop.button_pressed else "关闭",
	]
