# 2D 坐标、Canvas、Camera2D 与 Viewport 工作流

本文说明 Godot 2D 中最容易混淆的几类位置：节点局部坐标、Canvas 全局坐标、Viewport 坐标和窗口显示位置，并说明 `CanvasLayer`、`Camera2D`、Y Sort 与绘制顺序如何参与其中。

## 1. 先确认坐标空间

处理一个点之前，先确认它属于哪个空间：

```text
节点局部坐标
    ↓ 父节点 Transform
Canvas 全局坐标
    ↓ Camera2D / CanvasLayer / Canvas Transform
Viewport 坐标
    ↓ 窗口尺寸、Stretch 和显示区域
窗口/屏幕位置
```

名称中的“全局”不一定意味着操作系统屏幕像素。对普通 `CanvasItem` 来说，`global_position` 主要表示节点在所属 Canvas 中的全局位置；Camera 和 Viewport 的变换还决定它最终落在视口的哪里。

因此不要混用以下几类变量：

```gdscript
var node_local_point: Vector2
var canvas_point: Vector2
var viewport_point: Vector2
```

如果一个点来自鼠标事件、Viewport、Node2D 或 Control，先确认来源 API 的坐标空间，再选择转换函数。

## 2. Node2D 的局部与全局 Transform

`Node2D` 的 `position`、`rotation`、`rotation_degrees` 和 `scale` 默认都是相对于父节点的局部属性。父节点移动、旋转或缩放时，子节点的最终全局 Transform 会随之变化。

```text
World
└── Actor
    └── Weapon
```

`Weapon.position` 是相对于 `Actor` 的位置；`Actor.position` 是相对于 `World` 的位置。修改 `Actor.rotation` 会让武器一起旋转，这是父子 Transform 的正常结果。

`global_position`、`global_rotation` 和 `global_scale` 表示经过父节点 Transform 合成后的结果。需要把对象放到世界中的指定位置时可以设置 `global_position`；需要设置相对于当前父节点的偏移时使用 `position`。

```gdscript
@onready var _actor: Node2D = %Actor
@onready var _target: Node2D = %Target

func place_target_at_actor() -> void:
	_target.global_position = _actor.global_position

func move_target_relative_to_actor(offset: Vector2) -> void:
	_target.position = offset
```

如果两个节点的父节点不同，直接复制 `position` 往往得到错误位置；如果希望重设世界位置，使用 `global_position` 或 `global_transform`。

Transform 不只是位置，还包含旋转和缩放。多个父节点的变换会按层级组合，因此只比较 `position` 不能解释所有错位问题。需要转换点时使用 `to_global()` 和 `to_local()`，不要手工相加坐标：

```gdscript
var local_point := Vector2(20, 10)
var global_point := _actor.to_global(local_point)
var back_to_local := _actor.to_local(global_point)
```

### Vector2 与 Vector2i

`Vector2` 适合连续坐标、方向和位移，`Vector2i` 适合整数网格坐标和数组索引。TileMap 单元格等离散值不能因为“也是两个分量”就与世界像素坐标混用。

## 3. 常见坐标转换

### 局部点与 Canvas 全局点

对 `Node2D` 或合适的 `CanvasItem`，使用节点自身的转换方法：

```gdscript
var local_point := Vector2(32, 16)
var canvas_point := _world.to_global(local_point)
var same_local_point := _world.to_local(canvas_point)
```

`local_point` 是 `_world` 局部空间中的点，`canvas_point` 是同一 Canvas 下的全局点。

### Canvas 与 Viewport

`Viewport.get_canvas_transform()` 表示 Canvas 到 Viewport 的变换。对普通世界 Canvas，可以这样转换：

```gdscript
var viewport_point: Vector2 = get_viewport().get_canvas_transform() * canvas_point
```

反向转换使用逆变换：

```gdscript
var canvas_point: Vector2 = (
	get_viewport().get_canvas_transform().affine_inverse() * viewport_point
)
```

Camera2D 改变当前 Viewport 的 Canvas 变换后，同一个世界点对应的 Viewport 位置会变化，不要继续使用相机移动前缓存的转换结果。

### 鼠标点与世界点

对于普通世界 Canvas，最直接的方式是在合适的 `CanvasItem` 上使用：

```gdscript
var world_mouse: Vector2 = get_global_mouse_position()
```

如果从 Viewport 鼠标位置开始，则先把 Viewport 点转换回 Canvas 点，再交给目标节点的 `to_local()`：

```gdscript
var viewport_mouse := get_viewport().get_mouse_position()
var canvas_mouse := get_viewport().get_canvas_transform().affine_inverse() * viewport_mouse
var local_mouse := _world.to_local(canvas_mouse)
```

CanvasLayer、SubViewport、Control 输入和嵌套 Viewport 会引入不同坐标基准。遇到点击偏移时，不要先加减固定屏幕偏移，先确认输入事件来自哪个 Viewport 和 Canvas。

## 4. CanvasLayer：把 UI 和世界分层

`CanvasLayer` 提供独立的 2D 画布层。常见用途是将 HUD、暂停菜单、固定提示或调试信息放到世界内容之上，使它们不随普通 Camera2D 的世界视角移动。

```text
Root
├── World
│   ├── Ground
│   └── Actors
└── HUD (CanvasLayer)
    └── Panel / Label / Button
```

`CanvasLayer.layer` 决定 CanvasLayer 之间的绘制层级；同一层内部仍要考虑子节点的 `z_index`、Y Sort 和 SceneTree 顺序。世界节点的 `z_index` 不能用来跨越一个不合适的 CanvasLayer 结构。

普通世界 Canvas 会受到当前 Camera2D 的视图变换影响。CanvasLayer 的子节点属于独立 Canvas，默认以视口为参照，因此 Camera 移动或缩放世界时，HUD 仍然固定在屏幕位置。

如果确实需要让 CanvasLayer 跟随 Viewport 变化，应明确配置跟随视口的选项，并重新确认子节点坐标含义。不要一边把 HUD 放在 CanvasLayer，一边又手工把 Camera 位置加到 HUD 上。

检查 CanvasLayer 时：

1. 确认节点是否真的位于目标 CanvasLayer 下；
2. 检查 `layer` 是否与其他层发生遮挡关系；
3. 检查 HUD Control 的 anchors、offsets 和窗口 Stretch；
4. 输入异常时确认输入接收节点和显示节点属于预期 Viewport；
5. 不要用 CanvasLayer 解决本应由 Node2D 父子 Transform 解决的世界层级问题。

## 5. Camera2D：改变观察世界的方式

Camera2D 通常挂在世界节点或玩家场景下。启用后，它改变当前 Viewport 对世界 Canvas 的观察变换，而不是把世界中的每个 Node2D 真正搬到另一个位置。

| 属性 | 作用 | 常见误解 |
| --- | --- | --- |
| Position | 相机在父节点坐标中的位置 | 改相机不是改世界对象位置 |
| Zoom | 视图放大/缩小，`(1, 1)` 为默认 | 值越大通常看到的世界范围越小 |
| Position Smoothing | 相机向目标位置平滑追踪 | 会引入表现延迟，不改变目标位置 |
| Limits | 限制相机可观察的边界 | 不是自动生成的碰撞墙 |
| Drag | 让目标不必始终处于画面中心 | 需要结合拖动边距理解结果 |
| Enabled / Current | 选择当前 Viewport 使用的相机 | 多个相机不代表同时生效 |

Camera 的 `position` 是相对于父节点的局部位置。如果 Camera 是玩家的子节点，玩家移动会连带相机移动；如果相机需要跟随多个目标，应由一个明确的相机拥有者更新它。

Camera2D 已经提供常见的跟随、平滑和边界能力。不要在 `_process()` 中重复实现一套相机平滑并同时启用内置平滑，否则会产生双重延迟。

切换镜头时明确决定谁拥有当前镜头：

```gdscript
func focus_camera(camera: Camera2D) -> void:
	if is_instance_valid(camera):
		camera.make_current()
```

切换后重新检查 Canvas 到 Viewport 的转换、HUD 是否仍固定、输入坐标是否仍使用正确 Viewport。

## 6. 绘制顺序、z-index 与 Y Sort

### `z_index` 和 `z_as_relative`

同一 Canvas 中，`z_index` 用于表达绘制前后关系。通常较大的 z 值绘制在较小值之上；`z_as_relative` 决定节点的 z 值是否叠加父节点 z 值。

```text
Ground      z = 0
Actors      z = 10
Foreground  z = 20
```

先用节点层级和 CanvasLayer 规划大的渲染分区，再用 z-index 调整同一区域中的局部关系。不要散落大量魔法 z 值，让不同父节点的相对 z 叠加后无法推断最终结果。

开启父节点的 `y_sort_enabled` 后，适合根据子节点的 Y 位置决定前后关系，例如俯视游戏中的角色和树。它解决的是同一 Y Sort 体系中的绘制排序，不是物理碰撞、导航或节点 Transform。

Y Sort Origin 决定用于比较的参考点。角色的脚底、树的底部或其他接触地面的点通常比 Sprite 中心更适合作为排序依据；必要时通过节点结构和 Y Sort Origin 把视觉中心与排序点分开。

排查前后遮挡时：

1. 确认两个对象属于同一个 Canvas 和预期 CanvasLayer；
2. 检查父节点的 `y_sort_enabled`、节点 `z_index` 和 `z_as_relative`；
3. 检查 Sprite 的中心、Offset 和实际排序点；
4. 确认前景装饰是否应当独立放在更高的渲染层；
5. 使用 Remote SceneTree 和运行时 Inspector 查看实际属性。

## 7. Viewport、SubViewport 与显示结果

运行项目时，SceneTree 的根 Viewport 负责承载主场景并输出到窗口。Camera2D 的观察变换、CanvasLayer、输入位置和窗口 Stretch 最终都会通过 Viewport 影响显示结果。

`SubViewport` 是独立的渲染区域，可以有自己的节点、Canvas、Camera 和更新模式。常见用途包括小地图、画中画、独立预览和渲染到纹理：

```text
SubViewportContainer
└── SubViewport
    └── 独立场景内容

TextureRect.texture = sub_viewport.get_texture()
```

`SubViewportContainer` 负责把 SubViewport 内容显示为控件区域；`get_texture()` 取得的是渲染结果，不是普通的世界坐标容器。

检查 SubViewport 时确认：

- SubViewport 是否有正确尺寸；
- SubViewportContainer 是否启用 stretch；
- `render_target_update_mode` 是否允许当前帧更新；
- `handle_input_locally` 和内容节点的 `mouse_filter` 是否符合预期；
- 输入事件的位置是 SubViewport 局部位置还是外层窗口位置。

项目的 [Viewport 测试](../tests/viewport/viewport_test.tscn) 使用 SubViewportContainer 显示独立内容，并把 `gui_input` 连接到 SubViewport 内部的 Control，验证独立渲染和输入边界。

## 8. CanvasGroup 不等于 CanvasLayer

`CanvasGroup` 用于将一组 CanvasItem 作为一个组进行合成、可见性或整体绘制处理；它不是独立的屏幕 HUD 层，也不会替代 Camera2D 的坐标转换。

需要“这一组内容整体隐藏/合成”时考虑 CanvasGroup；需要“内容不受世界 Camera 影响”时考虑 CanvasLayer；需要“对象跟随父节点移动”时使用 Node2D 父子 Transform。

## 9. 本项目的验证入口

### `tests/canvas_transform/`

通过移动世界标记，显示其局部坐标、全局坐标和 Canvas 到 Viewport 的转换结果，另外切换 CanvasGroup 的可见性。它用于观察转换公式和分组显示，不模拟完整的摄像机系统。

### `tests/camera/`

验证当前 Camera2D、位置、Zoom、Position Smoothing、Limits 和 CanvasLayer HUD。可以分别打开边界和平滑，观察镜头表现属性的差异。

### `tests/viewport/`

验证 SubViewport、SubViewportContainer、渲染纹理、更新模式和独立输入传递。它说明“显示一个 SubViewport”与“把节点加入主世界 Canvas”是两种不同的结构。

### `test_hub`

验证台本身是一个 Control 场景。顶部选择器和内容面板负责 UI 布局；每个测试在自己的场景中管理坐标、Camera、Viewport 和动态状态，不把这些状态泄漏到其他测试。

## 10. 常见错位排查

### 世界对象和鼠标点击不重合

确认鼠标点是 Viewport 坐标还是 Canvas 坐标；检查当前 Camera、CanvasLayer、SubViewport 和窗口 Stretch。优先使用 `get_global_mouse_position()` 或明确的逆 Canvas Transform，不要硬编码窗口左上角偏移。

### 复制 `position` 后对象位置错误

检查两个节点的父节点是否相同。父节点不同就不要直接复制局部 `position`；使用 `global_position`，或把目标点通过 `to_local()` 转换到目标父节点空间。

### Camera 移动后 HUD 也移动

确认 HUD 是否真正是目标 CanvasLayer 的子节点，是否误放在世界 Node2D 下；检查 CanvasLayer 的层级和跟随视口选项。

### Zoom 改变后点击偏移

Zoom 改变了 Canvas 到 Viewport 的变换。重新从当前 Viewport/Canvas 状态计算鼠标世界点，不要继续使用 Zoom 改变前缓存的屏幕到世界比例。

### Y Sort 没有明显效果

检查对象是否位于同一 Y Sort 层级、父节点是否启用 `y_sort_enabled`、排序参考点是否合理，以及是否被更高的 z-index 或 CanvasLayer 覆盖。

## 11. 当前未覆盖的扩展

本专题覆盖日常 2D 坐标和显示结构，但以下内容仍可按需要补充专项验证：

- Camera2D 的拖动边距、限制平滑和多相机过渡；
- CanvasLayer 跟随 Viewport、多个 SubViewport 和嵌套输入；
- 窗口 Stretch 模式、不同 DPI 和多分辨率下的精确坐标映射；
- CanvasItem 绘制排序的更多边界以及自定义排序策略。

## 官方参考

- [CanvasItem — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html)
- [Node2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_node2d.html)
- [CanvasLayer — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_canvaslayer.html)
- [Camera2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_camera2d.html)
- [Viewport — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_viewport.html)
- [SubViewportContainer — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_subviewportcontainer.html)
