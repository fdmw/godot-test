extends Control

# 验证目标：验证 Tween 的缓动曲线、串行/并行播放、停止和重新创建。
# 机制说明：Tween 是一次性运行时对象，停止或重新播放前先结束旧 Tween，避免多个动画同时写同一属性。

enum Transition {
	LINEAR,
	SINE,
	QUAD,
	BOUNCE,
}

@onready var _sprite: Sprite2D = %Sprite
@onready var _status: Label = %Status
@onready var _parallel: CheckBox = %Parallel
@onready var _transition: OptionButton = %Transition
@onready var _play_button: Button = %PlayButton
@onready var _reset_button: Button = %ResetButton
@onready var _stop_button: Button = %StopButton
var _tween: Tween

func _ready() -> void:
	_transition.add_item("Linear")
	_transition.add_item("Sine")
	_transition.add_item("Quad")
	_transition.add_item("Bounce")
	_play_button.pressed.connect(_play_tween)
	_reset_button.pressed.connect(_reset_tween)
	_stop_button.pressed.connect(_stop_tween)
	_reset_tween()

func _play_tween() -> void:
	# Tween 是一次性对象，先终止旧实例，避免多个 Tween 同时写入同一 Sprite2D 属性。
	_stop_tween()
	_tween = create_tween()
	_tween.set_trans(_selected_transition())
	if _parallel.button_pressed:
		_tween.set_parallel(true)
	_tween.tween_property(_sprite, "position", Vector2(430, 145), 0.8)
	_tween.tween_property(_sprite, "rotation", TAU, 0.8)
	_tween.tween_property(_sprite, "scale", Vector2(0.72, 0.72), 0.8)
	if not _parallel.button_pressed:
		_tween.chain().tween_property(_sprite, "modulate", Color("#70c8ff"), 0.4)
	_tween.finished.connect(_on_tween_finished)
	_status.text = "Tween 播放中：" + _transition.get_item_text(_transition.selected)

func _selected_transition() -> Tween.TransitionType:
	match _transition.selected:
		Transition.SINE:
			return Tween.TRANS_SINE
		Transition.QUAD:
			return Tween.TRANS_QUAD
		Transition.BOUNCE:
			return Tween.TRANS_BOUNCE
		_:
			return Tween.TRANS_LINEAR

func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null

func _reset_tween() -> void:
	_stop_tween()
	_sprite.position = Vector2(150, 145)
	_sprite.rotation = 0.0
	_sprite.scale = Vector2(0.5, 0.5)
	_sprite.modulate = Color.WHITE
	_status.text = "Tween 已重置"

func _on_tween_finished() -> void:
	_status.text = "Tween 已完成"
