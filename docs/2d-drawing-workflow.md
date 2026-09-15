# Polygon2D、Line2D 与自定义 2D 绘制工作流

本文说明 `Polygon2D`、`Line2D`、`CanvasItem._draw()` 和 `queue_redraw()` 的使用入口，以及静态几何、运行时绘制和绘制顺序的边界。它们适合表达视觉几何，不应替代需要参与物理查询的碰撞几何。

## 1. 三种绘制方式

| 方式 | 数据入口 | 适合场景 |
| --- | --- | --- |
| `Polygon2D` | Inspector 中的 `polygon`、颜色、UV 和材质 | 静态多边形、填充区域、简单视觉形状 |
| `Line2D` | `points`、宽度、颜色、纹理和端点样式 | 路径线、轨迹、调试线、折线效果 |
| `CanvasItem._draw()` | 脚本调用 `draw_*` API | 需要集中绘制多种动态或自定义图元的 CanvasItem |

如果只是固定的几何数据，优先放在场景中。如果绘制数据会在运行时变化，脚本更新状态后调用 `queue_redraw()`，由 `_draw()` 在合适的重绘时机读取状态。不要每帧无条件调用绘制函数或重复创建节点。

## 2. Polygon2D

编辑器流程：

1. 添加 `Polygon2D`；
2. 在 2D 视口用多边形工具添加和移动顶点；
3. 在 Inspector 设置颜色、纹理、材质和绘制顺序；
4. 如果使用纹理，检查 UV 是否覆盖正确范围；
5. 保存场景，确认多边形顶点数据写入 `.tscn`。

`Polygon2D` 的顶点是局部坐标。纹理 UV 是采样坐标，不等于世界位置；顶点和 UV 不匹配时，可能出现形状正确但纹理拉伸或偏移。

Polygon2D 的视觉轮廓不自动成为 `CollisionPolygon2D`。如果它还需要参与碰撞、阻挡或空间查询，应单独配置物理节点和碰撞几何，并遵守项目中“碰撞几何是唯一空间占用事实”的约定，不维护第二套手写碰撞半径。

## 3. Line2D

`Line2D` 使用一组按顺序连接的 `Vector2` 点。常见属性包括：

- `points`：折线的局部坐标点；
- `width`：线宽；
- `default_color`：默认颜色；
- `joint_mode`：折点连接方式；
- `begin_cap_mode` / `end_cap_mode`：首尾端点样式；
- `closed`：是否连接首尾；
- `antialiased`：是否使用抗锯齿；
- `texture`、`texture_mode` 和 `width_curve`：需要纹理或宽度变化时使用。

运行时更新折线时，只替换点数组：

```gdscript
@onready var _line: Line2D = %Line

func show_path(points: PackedVector2Array) -> void:
	_line.points = points
```

Line2D 是绘制节点，不是路径跟随系统，也不是碰撞线。需要让对象沿曲线移动使用 `Path2D`；需要阻挡或检测使用对应物理节点。

## 4. `_draw()` 与 CanvasItem 绘图 API

自定义绘制节点通常继承 `Node2D` 或其他 `CanvasItem`：

```gdscript
extends Node2D

@export var draw_color: Color = Color.WHITE
@export var radius: float = 24.0
var _draw_enabled: bool = true

func _draw() -> void:
	if not _draw_enabled:
		return
	draw_circle(Vector2.ZERO, radius, draw_color)
	draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 32, draw_color, 2.0)

func set_draw_enabled(value: bool) -> void:
	_draw_enabled = value
	queue_redraw()
```

`_draw()` 不是普通函数调用入口。Godot 在 CanvasItem 需要重绘时调用它；修改颜色、点集、半径或开关后，应调用 `queue_redraw()` 请求下一次重绘。连续变化的表现才需要帧回调，停止时应关闭对应的更新逻辑。

常用 API 包括 `draw_line()`、`draw_polyline()`、`draw_colored_polygon()`、`draw_circle()`、`draw_arc()`、`draw_rect()`、`draw_string()` 和 `draw_texture()`。绘制顺序通常就是这些调用在 `_draw()` 中的先后顺序；后画的图元可能覆盖先画的图元。

自定义绘制坐标属于节点局部空间。节点 Transform、父节点、Camera2D、CanvasLayer 和 Viewport 仍会影响最终显示。遇到偏移时，先确认点集是局部坐标还是世界坐标，不要在 `_draw()` 内凭经验叠加相机位置。

## 5. 绘制顺序与调试绘制

同一 Canvas 中，先按场景层级、CanvasLayer 和 Y Sort 规划大范围层次，再用 `z_index` 处理局部覆盖关系。调试线和碰撞轮廓可以使用独立的绘制节点或专门的调试层，避免把调试颜色和正式视觉材质混在一起。

排查遮挡时检查：

1. 节点是否属于预期的 Canvas 和 CanvasLayer；
2. 父节点是否启用 Y Sort，比较点是否符合角色脚底等实际排序点；
3. `z_index` 和 `z_as_relative` 是否因父层叠加而产生意外结果；
4. `visible`、`modulate`、材质和裁剪是否隐藏了绘制结果；
5. 自定义绘制是否在状态变化后调用了 `queue_redraw()`。

## 6. 与物理和导航的边界

视觉几何、导航几何和物理几何是不同事实来源：

```text
Polygon2D / Line2D / _draw()  → 视觉表现
CollisionShape2D / CollisionPolygon2D → 物理空间占用
NavigationPolygon → 可行走区域
```

视觉节点移动、抖动或变形时，不应顺带修改碰撞几何和导航几何。需要验证碰撞时直接查看物理节点和查询结果；需要验证导航时查看导航 Region 的烘焙数据。

## 7. 当前验证与常见问题

项目的 `tests/rendering/` 集中覆盖这些能力：

- 场景中的 `Line2D` 和 `Polygon2D` 验证静态点集与绘制属性；
- `draw_canvas.gd` 验证 `draw_polyline()`、`draw_colored_polygon()`、`draw_circle()`、`draw_arc()`；
- 运行时切换自定义绘制开关并调用 `queue_redraw()`；
- 同时观察 Sprite2D、灯光、CanvasModulate、ShaderMaterial 和 z-index 对最终显示的影响。

常见问题：

- 改了导出点但画面不变：确认脚本修改后调用了 `queue_redraw()`。
- 线或多边形跑到错误位置：确认点集局部坐标和父节点 Transform。
- 线被裁掉：检查视口、父节点裁剪、CanvasLayer 和可见范围。
- 多边形可见但角色穿过去：视觉 Polygon2D 不会自动产生碰撞，补充 CollisionShape2D 或 CollisionPolygon2D。
- 绘制顺序异常：先检查 CanvasLayer/Y Sort，再检查 z-index 相对关系。

## 8. 官方参考

- [Polygon2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_polygon2d.html)
- [Line2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_line2d.html)
- [CanvasItem — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html)
- [2D 自定义绘制 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/2d/custom_drawing_in_2d.html)
