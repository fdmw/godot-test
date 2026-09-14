extends Control

@onready var _character: CharacterBody2D = %Character
@onready var _rigid_body: RigidBody2D = %RigidBody
@onready var _area: Area2D = %Area
@onready var _ray_cast: RayCast2D = %RayCast
@onready var _shape_cast: ShapeCast2D = %ShapeCast
@onready var _status: Label = %Status
@onready var _reset_button: Button = %ResetButton
@onready var _impulse_button: Button = %ImpulseButton
@onready var _area_toggle: CheckBox = %AreaToggle
var _area_enabled := true

func _ready() -> void:
	_reset_button.pressed.connect(_reset_objects)
	_impulse_button.pressed.connect(_apply_impulse)
	_area_toggle.toggled.connect(_set_area_enabled)
	_area.body_entered.connect(_on_area_body_entered)
	_area.body_exited.connect(_on_area_body_exited)
	_update_status()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_character):
		return
	if _character.is_on_floor():
		_character.velocity.x = 70.0
	else:
		_character.velocity.y += 700.0 * delta
	if _character.position.x > 650.0:
		_character.position = Vector2(80, 80)
		_character.velocity = Vector2(70, 0)
	_character.move_and_slide()
	_update_status()

func _reset_objects() -> void:
	_character.position = Vector2(100, 80)
	_character.velocity = Vector2(70, 0)
	_rigid_body.position = Vector2(300, 80)
	_rigid_body.linear_velocity = Vector2.ZERO
	_rigid_body.angular_velocity = 0.0
	_rigid_body.sleeping = false

func _apply_impulse() -> void:
	_rigid_body.apply_central_impulse(Vector2(160, -220))

func _set_area_enabled(value: bool) -> void:
	_area_enabled = value
	_area.monitoring = value
	_status.text = "Area2D 监测：" + ("开启" if value else "关闭")

func _on_area_body_entered(body: Node2D) -> void:
	if _area_enabled:
		_status.text = "Area2D 检测到：" + body.name

func _on_area_body_exited(body: Node2D) -> void:
	if _area_enabled:
		_status.text = "Area2D 离开：" + body.name

func _update_status() -> void:
	if not is_instance_valid(_character):
		return
	var ray_state := "命中" if _ray_cast.is_colliding() else "未命中"
	var shape_state := "命中" if _shape_cast.is_colliding() else "未命中"
	_status.text = "CharacterBody2D 地面：%s\nRayCast2D：%s\nShapeCast2D：%s" % ["是" if _character.is_on_floor() else "否", ray_state, shape_state]
