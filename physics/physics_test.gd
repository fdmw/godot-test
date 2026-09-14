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
@onready var _cast_toggle: CheckBox = %CastToggle
@onready var _force_cast_button: Button = %ForceCastButton
@onready var _contact_toggle: CheckBox = %ContactToggle
@onready var _respawn_point: Marker2D = %RespawnPoint
var _area_enabled := true
var _cast_enabled := true
var _contact_monitor_enabled := true
var _character_start_position: Vector2
var _rigid_body_start_position: Vector2

func _ready() -> void:
	_character_start_position = _character.position
	_rigid_body_start_position = _rigid_body.position
	_reset_button.pressed.connect(_reset_objects)
	_impulse_button.pressed.connect(_apply_impulse)
	_area_toggle.toggled.connect(_set_area_enabled)
	_cast_toggle.toggled.connect(_set_cast_enabled)
	_force_cast_button.pressed.connect(_force_update_casts)
	_contact_toggle.toggled.connect(_set_contact_monitor)
	_area.body_entered.connect(_on_area_body_entered)
	_area.body_exited.connect(_on_area_body_exited)
	_rigid_body.body_entered.connect(_on_rigid_body_entered)
	_rigid_body.body_exited.connect(_on_rigid_body_exited)
	_update_status()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_character):
		return
	if _character.is_on_floor():
		_character.velocity.x = 70.0
	else:
		_character.velocity.y += 700.0 * delta
	if _character.position.x > 650.0:
		_character.position = _respawn_point.position
		_character.velocity = Vector2(70, 0)
	_character.move_and_slide()
	_update_status()

func _reset_objects() -> void:
	_character.position = _character_start_position
	_character.velocity = Vector2(70, 0)
	_rigid_body.position = _rigid_body_start_position
	_rigid_body.linear_velocity = Vector2.ZERO
	_rigid_body.angular_velocity = 0.0
	_rigid_body.sleeping = false

func _apply_impulse() -> void:
	_rigid_body.apply_central_impulse(Vector2(160, -220))

func _set_area_enabled(value: bool) -> void:
	_area_enabled = value
	_area.monitoring = value
	_status.text = "Area2D 监测：" + ("开启" if value else "关闭")

func _set_cast_enabled(value: bool) -> void:
	_cast_enabled = value
	_ray_cast.enabled = value
	_shape_cast.enabled = value
	_update_status()

func _force_update_casts() -> void:
	if not _cast_enabled:
		_status.text = "投射已关闭，无法立即刷新"
		return
	_ray_cast.force_raycast_update()
	_shape_cast.force_shapecast_update()
	_update_status()

func _set_contact_monitor(value: bool) -> void:
	_contact_monitor_enabled = value
	_rigid_body.contact_monitor = value
	_status.text = "RigidBody2D 接触监测：" + ("开启" if value else "关闭")

func _on_rigid_body_entered(body: Node) -> void:
	if _contact_monitor_enabled:
		_status.text = "RigidBody2D 接触到：" + body.name

func _on_rigid_body_exited(body: Node) -> void:
	if _contact_monitor_enabled:
		_status.text = "RigidBody2D 离开：" + body.name

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
	_status.text = "CharacterBody2D 地面：%s\nRayCast2D：%s\nShapeCast2D：%s\n投射 Mask：%d\n接触监测：%s" % ["是" if _character.is_on_floor() else "否", ray_state, shape_state, _ray_cast.collision_mask, "开" if _contact_monitor_enabled else "关"]
