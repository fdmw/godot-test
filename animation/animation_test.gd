extends Control

@onready var _player: AnimationPlayer = %Player
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite
@onready var _timer: Timer = %Timer
@onready var _status: Label = %Status
@onready var _play_button: Button = %PlayButton
@onready var _pause_button: Button = %PauseButton
@onready var _stop_button: Button = %StopButton
@onready var _timer_toggle: CheckBox = %TimerToggle
@onready var _speed: SpinBox = %Speed

func _ready() -> void:
	_play_button.pressed.connect(_play)
	_pause_button.pressed.connect(_pause)
	_stop_button.pressed.connect(_stop)
	_timer_toggle.toggled.connect(_set_timer_enabled)
	_speed.value_changed.connect(_set_speed)
	_timer.timeout.connect(_on_timer_timeout)
	_player.animation_finished.connect(_on_animation_finished)
	_animated_sprite.play("pulse")
	_player.play("motion")

func _play() -> void:
	_player.play("motion")
	_animated_sprite.play("pulse")
	_status.text = "正在播放动画"

func _pause() -> void:
	_player.pause()
	_animated_sprite.pause()
	_status.text = "动画已暂停"

func _stop() -> void:
	_player.stop()
	_animated_sprite.stop()
	_status.text = "动画已停止"

func _set_timer_enabled(value: bool) -> void:
	_timer.paused = not value
	if value:
		_timer.start()
	else:
		_timer.stop()

func _set_speed(value: float) -> void:
	_player.speed_scale = value
	_animated_sprite.speed_scale = value
	_timer.wait_time = 1.0 / value

func _on_timer_timeout() -> void:
	_status.text = "Timer timeout：动画时间 %.2f" % _player.current_animation_position

func _on_animation_finished(animation_name: StringName) -> void:
	_status.text = "AnimationPlayer 完成：" + String(animation_name)
