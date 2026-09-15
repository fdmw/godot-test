# 2D 导航、AStar 与 Path2D 工作流

本文整理 2D 中几种容易被混用的“路径”能力：导航网格、导航代理、直接导航查询、AStar 图和 `Path2D`。重点是如何选择、在哪里配置、如何等待引擎同步，以及谁负责真正移动对象。

## 1. 先选择路径模型

| 需求 | 适合的能力 | 关键特征 |
| --- | --- | --- |
| 在可自由行走的连续区域内移动 | `NavigationRegion2D` + `NavigationAgent2D` | 导航多边形描述可行走区域，Agent 辅助路径和避障 |
| 直接获取一张导航地图上的路径或最近点 | `NavigationServer2D` | 以导航地图 RID 查询，不需要为每个查询创建 Agent |
| 固定格子上的寻路 | `AStarGrid2D` | 由区域和单元尺寸生成网格，可标记单元阻塞 |
| 自己定义离散点和连接关系 | `AStar2D` | 点、连接、权重和可通过性都由代码管理 |
| 沿设计好的曲线移动或做镜头/装饰轨迹 | `Path2D` + `PathFollow2D` | 路径是表现或轨迹，不是障碍感知的寻路系统 |

`NavigationAgent2D`、`AStar2D` 和 `AStarGrid2D` 都可以返回路径，但它们的数据来源不同。不要因为结果都是 `PackedVector2Array` 就把导航网格、网格寻路和曲线轨迹混成一套系统。

## 2. NavigationRegion2D 的编辑器流程

最小的导航网格可以这样建立：

1. 在世界场景中添加 `NavigationRegion2D`。
2. 在 Inspector 的 `Navigation Polygon` 属性中新建 `NavigationPolygon` 资源。
3. 选中 Region，在 2D 视口使用导航多边形绘制工具圈出可行走区域。
4. 根据项目需要设置导航层；不同层可以表示不同角色或不同通行规则。
5. 点击工具栏的 Bake/烘焙按钮生成导航网格。
6. 添加移动对象、碰撞形状和 `NavigationAgent2D`，运行时再设置目标位置。

导航多边形表示的是“角色中心可以站立和移动的区域”，不是墙体的外轮廓。边缘应为角色体积和运动误差预留余量，否则 Agent 可能得到贴着碰撞体边缘的路径并反复卡住。

地图中存在相邻 Region 时，NavigationServer2D 会按距离尝试连接它们。Region 的启用状态和 `navigation_layers` 会影响它是否参与查询；修改这些属性后要重新观察地图是否仍然连通。

## 3. NavigationAgent2D 的使用边界

Agent 通常作为移动对象的子节点，负责根据目标位置提供下一段路径位置；父节点仍然是移动的所有者：

```gdscript
@onready var _agent: NavigationAgent2D = %Agent

func set_target(target: Vector2) -> void:
	_agent.target_position = target

func _physics_process(_delta: float) -> void:
	if _agent.is_navigation_finished():
		return
	var next_position := _agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(next_position) * 120.0
	# 这里由父节点决定如何消费 desired_velocity 并更新自身位置。
```

设置 `target_position` 后，应在每个物理帧调用 `get_next_path_position()`，让 Agent 更新内部路径状态。不要在 UI 回调中直接连续调用导航查询并修改运动对象；UI 只提交目标请求，移动逻辑在明确的物理入口执行。

场景刚进入 SceneTree 时，导航地图可能还没有完成同步。首次设置目标或查询前等待至少一个物理帧，并在等待返回后确认当前节点和绑定仍然有效。项目中的 `navigation/` 测试用这种方式初始化 Agent。

### 避障不是路径规划

`avoidance_enabled` 使用局部避障计算安全速度。它不会重新烘焙导航网格，也不会让 `NavigationObstacle2D` 变成路径规划墙体。开启避障后，应连接 `velocity_computed`，再由移动所有者消费安全速度：

```gdscript
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_safe_velocity = safe_velocity
```

避障、路径和实际运动的职责应分开：

```text
导航目标 → Agent 路径 → 期望速度 → 避障安全速度 → 移动对象提交位置
```

`NavigationObstacle2D` 影响避障速度，不直接改变 Agent 的导航路径。真正不可通行的静态区域，应修改导航多边形或碰撞/导航数据，而不是只添加 Obstacle。

## 4. NavigationLink2D

`NavigationLink2D` 用于连接两个导航区域之间的跳跃、门、传送入口或其他非连续连接。编辑器中应检查：

- 起点和终点是否落在正确的导航区域附近；
- 是否启用 Link；
- `bidirectional` 是否符合通行方向；
- `navigation_layers` 是否与 Agent 的层相交；
- 路径经过 Link 后，移动脚本是否真的实现了跨越或传送动作。

Link 只告诉寻路系统“这里存在一条连接及其代价”，不负责把角色移动过去。当前项目的 `navigation/` 测试通过切换 Link 和 Agent 导航层观察路径是否变化。

## 5. NavigationServer2D 直接查询

当只需要查询一张导航地图，而不需要维护一个移动 Agent 时，可以从 Region 取得导航地图并直接查询：

```gdscript
var navigation_map := _region.get_navigation_map()
var points: PackedVector2Array = NavigationServer2D.map_get_path(
	navigation_map,
	origin,
	destination,
	true,
	1,
)
var closest_point: Vector2 = NavigationServer2D.map_get_closest_point(
	navigation_map,
	destination,
)
```

导航服务器在物理帧同步 Region 数据。第一次查询为空并不一定表示导航多边形错误，应先检查 `map_get_iteration_id()`，在地图同步后再查询。项目的 `navigation_query/` 测试验证了路径查询和最近导航点查询。

直接查询适合一次性的预览、批量路径计算或需要集中管理查询的系统；如果对象需要逐物理帧获得下一路径位置并处理局部避障，`NavigationAgent2D` 更合适。

## 6. AStarGrid2D 与 AStar2D

### AStarGrid2D

网格寻路的典型初始化顺序是：设置 `region`、`cell_size`、`offset` 和对角线规则，调用 `update()` 创建网格，再标记阻塞单元：

```gdscript
var grid := AStarGrid2D.new()
grid.region = Rect2i(Vector2i.ZERO, Vector2i(20, 12))
grid.cell_size = Vector2(32.0, 32.0)
grid.offset = Vector2(16.0, 16.0)
grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
grid.update()
grid.set_point_solid(Vector2i(4, 3), true)
var path := grid.get_point_path(start_cell, target_cell)
```

`Vector2i` 是网格坐标，`Vector2` 是世界位置。必须明确单元中心和世界原点的转换，不能把一个网格坐标直接当成像素位置。修改网格区域、单元尺寸或代价配置后，按 API 要求重建或更新网格。

### AStar2D

`AStar2D` 适合固定点图：先添加带 ID 的点，再按规则连接点，最后查询两点之间的路径。连接关系是图的事实来源；仅添加点而不连接，不能产生可通行路径。

```gdscript
var graph := AStar2D.new()
graph.add_point(1, Vector2(32.0, 32.0))
graph.add_point(2, Vector2(96.0, 32.0))
graph.connect_points(1, 2)
var path := graph.get_point_path(1, 2)
```

固定格子项目优先考虑 `AStarGrid2D`；节点数少、连接关系有明确语义或需要不规则图结构时使用 `AStar2D`。项目的 `astar/` 测试刻意并列构建两者，便于比较，而不是要求正式项目同时维护两套路径事实。

## 7. Path2D 与 PathFollow2D

`Path2D` 保存 `Curve2D`，`PathFollow2D` 作为它的子节点，根据 `progress` 或 `progress_ratio` 沿曲线定位。它适合传送带、巡逻轨迹、相机轨迹和装饰动画，不会自动考虑障碍、碰撞或导航层。

编辑器操作重点是：

1. 添加 `Path2D`，在 Inspector 创建 `Curve2D`；
2. 在 2D 视口增加和调整曲线点、控制柄；
3. 添加 `PathFollow2D` 作为 Path2D 子节点；
4. 将需要沿路径移动的视觉节点作为 PathFollow2D 子节点；
5. 用 `progress_ratio` 在 0～1 范围控制相对进度，检查 `loop` 和旋转跟随设置。

```gdscript
@onready var _follower: PathFollow2D = %Follower

func set_progress(value: float) -> void:
	_follower.progress_ratio = clampf(value, 0.0, 1.0)
```

连续自动播放才需要帧回调；停止后应停用播放状态，不让 `_process()` 继续推进进度。项目的 `path_2d/` 测试同时验证手动进度、循环和播放停止。

## 8. 常见问题

- 路径为空：检查 Region 是否烘焙、地图是否同步、起终点是否在导航区域内，以及层掩码是否匹配。
- Agent 到不了边缘：导航网格描述的是角色中心区域，需要给碰撞体留边距。
- Obstacle 没有改变路径：这是预期行为；Obstacle 影响局部避障，不修改导航网格。
- AStar 路径穿过障碍：确认阻塞单元或图连接是在查询前设置的，并检查世界坐标与网格坐标换算。
- Path2D 穿过墙：Path2D 只是曲线轨迹；需要障碍感知时改用导航或在业务层增加验证。
- 首次运行查询失败：等待导航服务器完成物理帧同步，不要用固定的延时秒数猜测同步完成。

## 9. 当前验证目录与官方参考

- `tests/navigation/`：Region、Agent、Link、导航层和避障。
- `tests/navigation_query/`：NavigationServer2D 路径与最近点查询。
- `tests/astar/`：AStar2D 与 AStarGrid2D 对比。
- `tests/path_2d/`：Path2D、Curve2D 和 PathFollow2D。
- [2D 导航概览 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_introduction_2d.html)
- [NavigationAgent2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_navigationagent2d.html)
- [AStarGrid2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_astargrid2d.html)
- [Path2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_path2d.html)
