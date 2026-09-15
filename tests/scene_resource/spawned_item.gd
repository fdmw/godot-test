extends Node2D

@onready var _sprite: Sprite2D = %Sprite

func configure(color: Color, scale_value: float) -> void:
	modulate = color
	_sprite.scale = Vector2(scale_value, scale_value)
