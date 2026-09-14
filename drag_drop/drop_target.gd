extends ColorRect

signal item_dropped(item_text: String)

var _is_hovering: bool = false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("text")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_dropped.emit(str(data["text"]))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		_is_hovering = true
		color = Color("#315b78")
	elif what == NOTIFICATION_DRAG_END:
		_is_hovering = false
		color = Color("#182f42")
