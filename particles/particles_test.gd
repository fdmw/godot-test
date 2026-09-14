extends Control

enum Preset {
	FOUNTAIN,
	BURST,
	SNOW,
	FIRE,
}

const PRESET_NAMES: Array[String] = ["喷泉", "爆发", "飘雪", "火花"]
const EMISSION_SHAPES: Array[int] = [
	ParticleProcessMaterial.EMISSION_SHAPE_POINT,
	ParticleProcessMaterial.EMISSION_SHAPE_SPHERE,
	ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE,
	ParticleProcessMaterial.EMISSION_SHAPE_BOX,
	ParticleProcessMaterial.EMISSION_SHAPE_RING,
]
const EMISSION_SHAPE_NAMES: Array[String] = ["点", "球体", "球面", "盒体", "环形"]

@onready var _particles: GPUParticles2D = %Particles
@onready var _material: ParticleProcessMaterial = _particles.process_material as ParticleProcessMaterial
@onready var _preview: Control = %Preview
@onready var _status: Label = %Status
@onready var _preset_buttons: Array[Button] = [%Fountain, %Burst, %Snow, %Fire]
@onready var _amount: SpinBox = %Amount
@onready var _lifetime: SpinBox = %Lifetime
@onready var _preprocess: SpinBox = %Preprocess
@onready var _speed_scale: SpinBox = %SpeedScale
@onready var _explosiveness: HSlider = %Explosiveness
@onready var _randomness: HSlider = %Randomness
@onready var _one_shot: CheckBox = %OneShot
@onready var _local_coords: CheckBox = %LocalCoords
@onready var _trail: CheckBox = %Trail
@onready var _trail_lifetime: SpinBox = %TrailLifetime
@onready var _draw_order: OptionButton = %DrawOrder
@onready var _shape: OptionButton = %Shape
@onready var _direction: HSlider = %Direction
@onready var _spread: HSlider = %Spread
@onready var _velocity: HSlider = %Velocity
@onready var _gravity: SpinBox = %Gravity
@onready var _scale_min: SpinBox = %ScaleMin
@onready var _scale_max: SpinBox = %ScaleMax
@onready var _color: ColorPickerButton = %Color
@onready var _hue: HSlider = %Hue
@onready var _damping: HSlider = %Damping

func _ready() -> void:
	for order_name: String in ["按索引绘制", "按生命周期绘制"]:
		_draw_order.add_item(order_name)
	for shape_name: String in EMISSION_SHAPE_NAMES:
		_shape.add_item(shape_name)
	for index: int in _preset_buttons.size():
		_preset_buttons[index].pressed.connect(_on_preset_pressed.bind(index))
	_amount.value_changed.connect(_on_amount_changed)
	_lifetime.value_changed.connect(_on_lifetime_changed)
	_preprocess.value_changed.connect(_on_preprocess_changed)
	_speed_scale.value_changed.connect(_on_speed_scale_changed)
	_explosiveness.value_changed.connect(_on_explosiveness_changed)
	_randomness.value_changed.connect(_on_randomness_changed)
	_one_shot.toggled.connect(_on_one_shot_changed)
	_local_coords.toggled.connect(_on_local_coords_changed)
	_trail.toggled.connect(_on_trail_changed)
	_trail_lifetime.value_changed.connect(_on_trail_lifetime_changed)
	_draw_order.item_selected.connect(_on_draw_order_changed)
	_shape.item_selected.connect(_on_shape_changed)
	_direction.value_changed.connect(_on_direction_changed)
	_spread.value_changed.connect(_on_spread_changed)
	_velocity.value_changed.connect(_on_velocity_changed)
	_gravity.value_changed.connect(_on_gravity_changed)
	_scale_min.value_changed.connect(_on_scale_min_changed)
	_scale_max.value_changed.connect(_on_scale_max_changed)
	_color.color_changed.connect(_on_color_changed)
	_hue.value_changed.connect(_on_hue_changed)
	_damping.value_changed.connect(_on_damping_changed)
	_preview.resized.connect(_center_particles)
	_apply_preset(Preset.FOUNTAIN)

func _center_particles() -> void:
	if is_instance_valid(_particles):
		_particles.position = _preview.size * 0.5

func _apply_preset(preset: int) -> void:
	switch_preset(preset)
	_particles.restart()

func switch_preset(preset: int) -> void:
	match preset:
		Preset.FOUNTAIN:
			_particles.amount = 120
			_particles.lifetime = 2.0
			_particles.one_shot = false
			_particles.explosiveness = 0.0
			_material.direction = Vector3(0, -1, 0)
			_material.spread = 28.0
			_material.initial_velocity_min = 100.0
			_material.initial_velocity_max = 160.0
			_material.gravity = Vector3(0, 220, 0)
			_material.color = Color("#70c8ff")
		Preset.BURST:
			_particles.amount = 140
			_particles.lifetime = 0.9
			_particles.one_shot = true
			_particles.explosiveness = 1.0
			_material.direction = Vector3(0, -1, 0)
			_material.spread = 180.0
			_material.initial_velocity_min = 120.0
			_material.initial_velocity_max = 280.0
			_material.gravity = Vector3(0, 40, 0)
			_material.color = Color("#ffd166")
		Preset.SNOW:
			_particles.amount = 180
			_particles.lifetime = 5.0
			_particles.one_shot = false
			_particles.explosiveness = 0.0
			_material.direction = Vector3(0, 1, 0)
			_material.spread = 12.0
			_material.initial_velocity_min = 20.0
			_material.initial_velocity_max = 45.0
			_material.gravity = Vector3(0, 12, 0)
			_material.color = Color("#d9f3ff")
		Preset.FIRE:
			_particles.amount = 100
			_particles.lifetime = 1.2
			_particles.one_shot = false
			_particles.explosiveness = 0.0
			_material.direction = Vector3(0, -1, 0)
			_material.spread = 24.0
			_material.initial_velocity_min = 35.0
			_material.initial_velocity_max = 90.0
			_material.gravity = Vector3(0, -50, 0)
			_material.color = Color("#ff7043")
	_particles.emitting = true
	_status.text = "已应用预设：" + PRESET_NAMES[preset]

func _on_preset_pressed(index: int) -> void:
	_apply_preset(index)

func _on_amount_changed(value: float) -> void:
	_particles.amount = roundi(value)

func _on_lifetime_changed(value: float) -> void:
	_particles.lifetime = value

func _on_preprocess_changed(value: float) -> void:
	_particles.preprocess = value

func _on_speed_scale_changed(value: float) -> void:
	_particles.speed_scale = value

func _on_explosiveness_changed(value: float) -> void:
	_particles.explosiveness = value

func _on_randomness_changed(value: float) -> void:
	_particles.randomness = value

func _on_one_shot_changed(value: bool) -> void:
	_particles.one_shot = value
	_particles.restart()

func _on_local_coords_changed(value: bool) -> void:
	_particles.local_coords = value

func _on_trail_changed(value: bool) -> void:
	_particles.trail_enabled = value

func _on_trail_lifetime_changed(value: float) -> void:
	_particles.trail_lifetime = value

func _on_draw_order_changed(index: int) -> void:
	_particles.draw_order = GPUParticles2D.DRAW_ORDER_LIFETIME if index == 1 else GPUParticles2D.DRAW_ORDER_INDEX

func _on_shape_changed(index: int) -> void:
	_material.emission_shape = EMISSION_SHAPES[index]

func _on_direction_changed(value: float) -> void:
	var angle := deg_to_rad(value)
	_material.direction = Vector3(cos(angle), sin(angle), 0.0)

func _on_spread_changed(value: float) -> void:
	_material.spread = value

func _on_velocity_changed(value: float) -> void:
	_material.initial_velocity_min = value * 0.7
	_material.initial_velocity_max = value

func _on_gravity_changed(value: float) -> void:
	_material.gravity = Vector3(0, value, 0)

func _on_scale_min_changed(value: float) -> void:
	_material.scale_min = value

func _on_scale_max_changed(value: float) -> void:
	_material.scale_max = value

func _on_color_changed(color: Color) -> void:
	_material.color = color

func _on_hue_changed(value: float) -> void:
	_material.hue_variation_min = value
	_material.hue_variation_max = value

func _on_damping_changed(value: float) -> void:
	_material.damping_min = value
	_material.damping_max = value
