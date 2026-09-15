extends Node2D

# 验证对象：将 _draw() 的基础图元和 queue_redraw() 的重绘请求集中在一个独立 Node2D 中。
# 导出字段是场景静态绘制数据，脚本只维护“是否绘制”的运行时状态。

@export var line_points: PackedVector2Array
@export var polygon_points: PackedVector2Array
@export var circle_center: Vector2 = Vector2.ZERO
@export var circle_radius: float = 20.0
@export var draw_color: Color = Color.WHITE
@export var line_width: float = 3.0

var _draw_enabled: bool = true

func _draw() -> void:
	if not _draw_enabled:
		return
	# _draw() 只在 CanvasItem 重绘时执行；外部修改状态后必须显式调用 queue_redraw()。
	draw_polyline(line_points, draw_color, line_width, true)
	draw_colored_polygon(polygon_points, Color(draw_color, 0.35))
	draw_circle(circle_center, circle_radius, draw_color)
	draw_arc(circle_center, circle_radius + 14.0, 0.0, TAU * 0.75, 32, Color(draw_color, 0.7), 2.0, true)

func set_draw_enabled(value: bool) -> void:
	_draw_enabled = value
	queue_redraw()
