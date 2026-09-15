extends Control

# 验证目标：验证 2D 绘制节点、CanvasModulate、PointLight2D、遮挡、纹理区域、滤镜和 ShaderMaterial。
# 机制说明：自定义绘制节点的数据固定在场景；脚本只切换绘制状态并通过 queue_redraw() 请求重绘。

const DrawCanvas = preload("res://tests/rendering/draw_canvas.gd")

@onready var _sprite: Sprite2D = %Sprite
@onready var _canvas_modulate: CanvasModulate = %CanvasModulate
@onready var _light: PointLight2D = %Light
@onready var _status: Label = %Status
@onready var _light_toggle: CheckBox = %LightToggle
@onready var _dark_toggle: CheckBox = %DarkToggle
@onready var _shader_toggle: CheckBox = %ShaderToggle
@onready var _region_toggle: CheckBox = %RegionToggle
@onready var _filter_selector: OptionButton = %FilterSelector
@onready var _z_relative: CheckBox = %ZRelative
@onready var _z_slider: HSlider = %ZSlider
@onready var _draw_canvas: DrawCanvas = %DrawCanvas
@onready var _custom_draw_toggle: CheckBox = %CustomDrawToggle
@onready var _redraw_button: Button = %RedrawButton

func _ready() -> void:
	_light_toggle.toggled.connect(_set_light_enabled)
	_dark_toggle.toggled.connect(_set_canvas_modulate)
	_shader_toggle.toggled.connect(_set_shader_enabled)
	_region_toggle.toggled.connect(_set_region_enabled)
	_filter_selector.item_selected.connect(_set_texture_filter)
	_z_relative.toggled.connect(_set_z_relative)
	_z_slider.value_changed.connect(_set_z_index)
	_custom_draw_toggle.toggled.connect(_set_custom_draw_enabled)
	_redraw_button.pressed.connect(_redraw_custom_canvas)
	_filter_selector.add_item("Nearest")
	_filter_selector.add_item("Linear")
	_filter_selector.select(0)

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

func _set_region_enabled(value: bool) -> void:
	_sprite.region_enabled = value
	_status.text = "Sprite2D region_enabled：" + ("开启" if value else "关闭")

func _set_texture_filter(index: int) -> void:
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if index == 0 else CanvasItem.TEXTURE_FILTER_LINEAR
	_status.text = "纹理过滤：" + _filter_selector.get_item_text(index)

func _set_z_relative(value: bool) -> void:
	_sprite.z_as_relative = value
	_status.text = "Sprite2D z_as_relative：" + ("开启" if value else "关闭")

func _set_z_index(value: float) -> void:
	_sprite.z_index = roundi(value)
	_status.text = "Sprite2D z_index：%d" % _sprite.z_index

func _set_custom_draw_enabled(value: bool) -> void:
	_draw_canvas.set_draw_enabled(value)
	_status.text = "自定义绘制：" + ("开启" if value else "关闭")

func _redraw_custom_canvas() -> void:
	_draw_canvas.queue_redraw()
	_status.text = "已调用 queue_redraw()"
