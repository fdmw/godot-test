extends Control

@onready var _pausable_timer: Timer = %PausableTimer
@onready var _always_timer: Timer = %AlwaysTimer
@onready var _player: AnimationPlayer = %Player
@onready var _pause_button: Button = %PauseButton
@onready var _reset_button: Button = %ResetButton
@onready var _status: Label = %Status
@onready var _pausable_count: Label = %PausableCount
@onready var _always_count: Label = %AlwaysCount

var _pausable_ticks: int = 0
var _always_ticks: int = 0

func _ready() -> void:
	_pause_button.pressed.connect(_toggle_pause)
	_reset_button.pressed.connect(_reset_test)
	_pausable_timer.timeout.connect(_on_pausable_timeout)
	_always_timer.timeout.connect(_on_always_timeout)
	_reset_test()

func _exit_tree() -> void:
	get_tree().paused = false

func _toggle_pause() -> void:
	_set_paused(not get_tree().paused)

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	_pause_button.text = "继续运行" if value else "暂停场景"
	_status.text = "SceneTree.paused = %s" % value

func _reset_test() -> void:
	get_tree().paused = false
	_pausable_ticks = 0
	_always_ticks = 0
	_player.stop()
	_player.play(&"pulse")
	_pause_button.text = "暂停场景"
	_status.text = "场景正在运行"
	_update_counts()

func _on_pausable_timeout() -> void:
	_pausable_ticks += 1
	_update_counts()

func _on_always_timeout() -> void:
	_always_ticks += 1
	_update_counts()

func _update_counts() -> void:
	_pausable_count.text = "Pausable Timer：%d" % _pausable_ticks
	_always_count.text = "Always Timer：%d" % _always_ticks
