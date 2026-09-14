extends Control

# 验证目标：验证 PinJoint2D、DampedSpringJoint2D 的连接、启停、弹簧和刚体响应。
# 机制说明：关节几何和连接关系固定在场景中；禁用碰撞相关属性使用 set_deferred() 遵守引擎时序。

@onready var _body_a: RigidBody2D = %BodyA
@onready var _body_b: RigidBody2D = %BodyB
@onready var _pin: PinJoint2D = %PinJoint
@onready var _spring: DampedSpringJoint2D = %SpringJoint
@onready var _pin_toggle: CheckBox = %PinToggle
@onready var _spring_toggle: CheckBox = %SpringToggle
@onready var _impulse_button: Button = %ImpulseButton
@onready var _reset_button: Button = %ResetButton
@onready var _status: Label = %Status

func _ready() -> void:
	_pin_toggle.toggled.connect(_set_pin_enabled)
	_spring_toggle.toggled.connect(_set_spring_enabled)
	_impulse_button.pressed.connect(_apply_impulse)
	_reset_button.pressed.connect(_reset_bodies)
	_update_status("等待物理关节操作")

func _set_pin_enabled(value: bool) -> void:
	_pin.set_deferred("disabled", not value)
	_update_status("PinJoint2D：" + ("启用" if value else "停用"))

func _set_spring_enabled(value: bool) -> void:
	_spring.set_deferred("disabled", not value)
	_update_status("DampedSpringJoint2D：" + ("启用" if value else "停用"))

func _apply_impulse() -> void:
	_body_a.apply_central_impulse(Vector2(-120, -180))
	_body_b.apply_central_impulse(Vector2(120, -180))
	_update_status("已施加冲量")

func _reset_bodies() -> void:
	_body_a.position = Vector2(250, 150)
	_body_b.position = Vector2(430, 150)
	_body_a.linear_velocity = Vector2.ZERO
	_body_b.linear_velocity = Vector2.ZERO
	_body_a.angular_velocity = 0.0
	_body_b.angular_velocity = 0.0
	_body_a.sleeping = false
	_body_b.sleeping = false
	_update_status("刚体已重置")

func _update_status(message: String) -> void:
	_status.text = "%s\nA：%s\nB：%s" % [message, _body_a.position, _body_b.position]
