extends Control

# 验证目标：直接验证 NavigationServer2D 的地图路径查询和最近导航点查询。
# 机制说明：导航地图需要经过物理帧同步后才可查询，因此首次查询前等待 map iteration 建立。

@onready var _region: NavigationRegion2D = %Region
@onready var _origin: Marker2D = %Origin
@onready var _target_a: Marker2D = %TargetA
@onready var _target_b: Marker2D = %TargetB
@onready var _target_c: Marker2D = %TargetC
@onready var _path: Line2D = %Path
@onready var _status: Label = %Status
@onready var _target_a_button: Button = %TargetAButton
@onready var _target_b_button: Button = %TargetBButton
@onready var _target_c_button: Button = %TargetCButton

func _ready() -> void:
	_target_a_button.pressed.connect(_query_path.bind(_target_a.global_position))
	_target_b_button.pressed.connect(_query_path.bind(_target_b.global_position))
	_target_c_button.pressed.connect(_query_path.bind(_target_c.global_position))
	var navigation_map := _region.get_navigation_map()
	# NavigationRegion2D 加入场景树后，导航服务器仍需同步一次地图，不能立即假定查询结果可用。
	while NavigationServer2D.map_get_iteration_id(navigation_map) == 0:
		await get_tree().physics_frame
	_query_path(_target_a.global_position)

func _query_path(destination: Vector2) -> void:
	var navigation_map := _region.get_navigation_map()
	# 路径和最近点都直接查询同一张导航地图，避免用表现节点的位置替代导航空间结果。
	var points: PackedVector2Array = NavigationServer2D.map_get_path(
		navigation_map,
		_origin.global_position,
		destination,
		true,
		1,
	)
	_path.points = points
	var closest_point := NavigationServer2D.map_get_closest_point(navigation_map, destination)
	_status.text = "路径节点：%d\n目标：%s\n最近导航点：%s" % [points.size(), destination, closest_point]
