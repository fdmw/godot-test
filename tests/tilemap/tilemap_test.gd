extends Control

# 验证目标：验证 TileMapLayer 的坐标转换、单元格写入、读取和清空。
# 机制说明：Marker2D 在场景中提供静态位置；TileSet 使用场景内生成的渐变纹理，不依赖已删除图片。

@onready var _layer: TileMapLayer = %TileMapLayer
@onready var _marker_a: Marker2D = %MarkerA
@onready var _marker_b: Marker2D = %MarkerB
@onready var _write_button: Button = %WriteButton
@onready var _read_button: Button = %ReadButton
@onready var _clear_button: Button = %ClearButton
@onready var _status: Label = %Status

func _ready() -> void:
	_write_button.pressed.connect(_write_cells)
	_read_button.pressed.connect(_read_cells)
	_clear_button.pressed.connect(_clear_cells)
	_write_cells()

func _write_cells() -> void:
	# Marker2D 与 TileMapLayer 处于同一个 SubViewport 坐标系，转换后才得到单元格坐标。
	var first_cell := _layer.local_to_map(_marker_a.position)
	var second_cell := _layer.local_to_map(_marker_b.position)
	_layer.clear()
	_layer.set_cell(first_cell, 0, Vector2i(0, 0), 0)
	_layer.set_cell(second_cell, 0, Vector2i(1, 0), 0)
	_status.text = "已写入：%s、%s" % [first_cell, second_cell]

func _read_cells() -> void:
	# 读取同时展示 source_id 和 atlas 坐标，便于区分 TileSet 来源与图集内瓦片位置。
	var first_cell := _layer.local_to_map(_marker_a.position)
	var second_cell := _layer.local_to_map(_marker_b.position)
	var first_source := _layer.get_cell_source_id(first_cell)
	var second_source := _layer.get_cell_source_id(second_cell)
	var first_atlas := _layer.get_cell_atlas_coords(first_cell)
	var second_atlas := _layer.get_cell_atlas_coords(second_cell)
	_status.text = "读取：%s=%s/%s，%s=%s/%s" % [first_cell, first_source, first_atlas, second_cell, second_source, second_atlas]

func _clear_cells() -> void:
	_layer.clear()
	_status.text = "已清空 TileMapLayer 单元格"
