extends Control

@onready var _grid_path: Line2D = %GridPath
@onready var _graph_path: Line2D = %GraphPath
@onready var _status: Label = %Status
@onready var _rebuild_button: Button = %RebuildButton
@onready var _grid_config: Node2D = %GridConfig
@onready var _cell_size_marker: Marker2D = %CellSize
@onready var _grid_end_marker: Marker2D = %GridEnd
@onready var _start_marker: Polygon2D = %Start
@onready var _target_marker: Polygon2D = %Target
@onready var _obstacle_a: ColorRect = %ObstacleA
@onready var _obstacle_b: ColorRect = %ObstacleB
@onready var _obstacle_c: ColorRect = %ObstacleC
@onready var _obstacle_d: ColorRect = %ObstacleD

var _grid: AStarGrid2D
var _graph: AStar2D
var _grid_size: Vector2i
var _cell_size: Vector2
var _grid_origin: Vector2
var _start_cell: Vector2i
var _target_cell: Vector2i
var _blocked_cells: Array[Vector2i]

func _ready() -> void:
	_read_static_grid_data()
	_rebuild_button.pressed.connect(_rebuild_graphs)
	_rebuild_graphs()

func _read_static_grid_data() -> void:
	_grid_origin = _grid_config.position
	_cell_size = _cell_size_marker.position
	_grid_size = Vector2i(
		roundi(_grid_end_marker.position.x / _cell_size.x),
		roundi(_grid_end_marker.position.y / _cell_size.y),
	)
	_start_cell = _position_to_cell(_start_marker.position)
	_target_cell = _position_to_cell(_target_marker.position)
	_blocked_cells = [
		_position_to_cell(_obstacle_a.position),
		_position_to_cell(_obstacle_b.position),
		_position_to_cell(_obstacle_c.position),
		_position_to_cell(_obstacle_d.position),
	]

func _rebuild_graphs() -> void:
	_build_grid_graph()
	_build_point_graph()
	_update_paths()

func _build_grid_graph() -> void:
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, _grid_size)
	_grid.cell_size = _cell_size
	_grid.offset = _grid_origin + _cell_size * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	for cell: Vector2i in _blocked_cells:
		_grid.set_point_solid(cell, true)

func _build_point_graph() -> void:
	_graph = AStar2D.new()
	for y: int in range(_grid_size.y):
		for x: int in range(_grid_size.x):
			var cell := Vector2i(x, y)
			_graph.add_point(_cell_id(cell), _cell_position(cell))
	for y: int in range(_grid_size.y):
		for x: int in range(_grid_size.x):
			var cell := Vector2i(x, y)
			if cell in _blocked_cells:
				continue
			for neighbor: Vector2i in [cell + Vector2i.RIGHT, cell + Vector2i.DOWN]:
				if not _is_valid_cell(neighbor) or neighbor in _blocked_cells:
					continue
				_graph.connect_points(_cell_id(cell), _cell_id(neighbor))

func _update_paths() -> void:
	var grid_points: PackedVector2Array = _grid.get_point_path(_start_cell, _target_cell)
	_grid_path.points = grid_points
	var graph_points: PackedVector2Array = _graph.get_point_path(_cell_id(_start_cell), _cell_id(_target_cell))
	_graph_path.points = graph_points
	_status.text = "AStarGrid2D：%d 个节点\nAStar2D：%d 个节点\n障碍：%d 个" % [
		grid_points.size(),
		graph_points.size(),
		_blocked_cells.size(),
	]

func _cell_id(cell: Vector2i) -> int:
	return cell.y * _grid_size.x + cell.x

func _cell_position(cell: Vector2i) -> Vector2:
	return _grid_origin + _cell_size * (Vector2(cell) + Vector2.ONE * 0.5)

func _position_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		roundi((position.x - _grid_origin.x - _cell_size.x * 0.5) / _cell_size.x),
		roundi((position.y - _grid_origin.y - _cell_size.y * 0.5) / _cell_size.y),
	)

func _is_valid_cell(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, _grid_size).has_point(cell)
