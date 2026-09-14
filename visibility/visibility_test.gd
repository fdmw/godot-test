extends Control

@onready var _sprite: Sprite2D = %Sprite
@onready var _notifier: VisibleOnScreenNotifier2D = %Notifier
@onready var _status: Label = %Status
@onready var _show_button: Button = %ShowButton
@onready var _hide_button: Button = %HideButton
@onready var _move_button: Button = %MoveButton
@onready var _reset_button: Button = %ResetButton

func _ready() -> void:
	_show_button.pressed.connect(_show_sprite)
	_hide_button.pressed.connect(_hide_sprite)
	_move_button.pressed.connect(_move_offscreen)
	_reset_button.pressed.connect(_reset_sprite)
	_notifier.screen_entered.connect(_on_screen_entered)
	_notifier.screen_exited.connect(_on_screen_exited)
	_update_status("等待可见性操作")

func _show_sprite() -> void:
	_sprite.visible = true
	_update_status("Sprite2D visible=true")

func _hide_sprite() -> void:
	_sprite.visible = false
	_update_status("Sprite2D visible=false")

func _move_offscreen() -> void:
	_sprite.position = Vector2(1200, 800)
	_update_status("Sprite2D 已移出可见区域")

func _reset_sprite() -> void:
	_sprite.position = Vector2(260, 170)
	_sprite.visible = true
	_update_status("已恢复初始位置")

func _on_screen_entered() -> void:
	_update_status("VisibleOnScreenNotifier2D：进入屏幕")

func _on_screen_exited() -> void:
	_update_status("VisibleOnScreenNotifier2D：离开屏幕")

func _update_status(message: String) -> void:
	_status.text = "%s\n位置：%s\nvisible：%s" % [message, _sprite.position, _sprite.visible]
