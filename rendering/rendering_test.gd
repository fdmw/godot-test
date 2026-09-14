extends Control

@onready var _sprite: Sprite2D = %Sprite
@onready var _canvas_modulate: CanvasModulate = %CanvasModulate
@onready var _light: PointLight2D = %Light
@onready var _status: Label = %Status
@onready var _light_toggle: CheckBox = %LightToggle
@onready var _dark_toggle: CheckBox = %DarkToggle
@onready var _shader_toggle: CheckBox = %ShaderToggle
@onready var _z_slider: HSlider = %ZSlider

func _ready() -> void:
	_light_toggle.toggled.connect(_set_light_enabled)
	_dark_toggle.toggled.connect(_set_canvas_modulate)
	_shader_toggle.toggled.connect(_set_shader_enabled)
	_z_slider.value_changed.connect(_set_z_index)

func _set_light_enabled(value: bool) -> void:
	_light.enabled = value
	_status.text = "PointLight2D：" + ("开启" if value else "关闭")

func _set_canvas_modulate(value: bool) -> void:
	_canvas_modulate.color = Color("#586b86") if value else Color.WHITE
	_status.text = "CanvasModulate：" + ("变暗" if value else "正常")

func _set_shader_enabled(value: bool) -> void:
	if value:
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment() { vec2 uv = UV; uv.x += sin(UV.y * 20.0 + TIME * 3.0) * 0.02; COLOR = texture(TEXTURE, uv) * COLOR; }"
		var material := ShaderMaterial.new()
		material.shader = shader
		_sprite.material = material
	else:
		_sprite.material = null
	_status.text = "ShaderMaterial：" + ("开启" if value else "关闭")

func _set_z_index(value: float) -> void:
	_sprite.z_index = roundi(value)
	_status.text = "Sprite2D z_index：%d" % _sprite.z_index
