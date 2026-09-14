extends Button

signal drag_started(item_text: String)

@export var item_text: String = ""

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = item_text
	preview.add_theme_color_override("font_color", Color("#70c8ff"))
	preview.add_theme_font_size_override("font_size", 18)
	set_drag_preview(preview)
	drag_started.emit(item_text)
	return {"text": item_text}
