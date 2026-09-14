extends Node2D

func _draw() -> void:
	for x: int in range(-1000, 1001, 100):
		draw_line(Vector2(x, -600), Vector2(x, 600), Color("#26384e"), 1.0)
	for y: int in range(-600, 601, 100):
		draw_line(Vector2(-1000, y), Vector2(1000, y), Color("#26384e"), 1.0)
	draw_rect(Rect2(-500, -300, 1000, 600), Color("#5b7fa6"), false, 4.0)
	draw_circle(Vector2(-280, -120), 36.0, Color("#e5b65c"))
	draw_circle(Vector2(260, 160), 52.0, Color("#62b0e8"))
	draw_string(ThemeDB.fallback_font, Vector2(-470, -250), "世界坐标内容", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8e6f5"))
