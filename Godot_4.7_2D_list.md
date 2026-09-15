# Godot 4.7 2D 实用能力清单

> 目标：不是背完 Godot API，也不是精通所有冷门细节，而是做到——**遇到常见 2D 游戏开发问题时，知道 Godot 已经提供了什么系统、节点或资源，能在编辑器中找到它、正确配置它、用 GDScript 控制它，并知道出问题时从哪里调试。**
>
> 版本基准：**Godot 4.7**
>
> 核心原则：**问题 → 系统 → 节点/资源 → 编辑器配置 → GDScript 控制 → Debug**

---

## 0. 使用方法

### 0.1 熟练度标准

每个模块不要求把所有属性和 API 背下来，而按以下 4 级验收：

- **L1：认识** —— 知道这个系统解决什么问题，知道对应节点/资源叫什么。
- **L2：会配置** —— 能在 Godot 编辑器里独立创建、连接、配置并运行。
- **L3：会控制** —— 能用 GDScript 动态读写、创建、查询和响应。
- **L4：会排错** —— 出现异常时知道看哪个 Debug 选项、Remote 节点、监视器或 API 状态。

本清单的目标：

- **P0 核心模块：至少 L3，重要模块达到 L4**
- **P1 常用模块：至少 L2～L3**
- **P2 扩展模块：至少 L1～L2，实际项目需要时再深入**

### 0.2 优先级

- **P0 — 必须熟练**：绝大多数 2D 项目都会频繁使用。
- **P1 — 应该掌握**：很常见，但不是每个项目都会使用。
- **P2 — 知道入口**：属于专项能力，先建立“Godot 有这个东西”的认知即可。

---

# 第一部分：Godot 的基本工作模型

## 1. Scene、Node 与 SceneTree【P0】

### 必须理解

- `Node`
- Scene 本质上是一棵节点树
- Scene 与 Node 的关系
- SceneTree
- 父节点 / 子节点
- 场景实例化
- 场景嵌套
- 当前场景与主场景
- 节点生命周期
  - `_enter_tree()`
  - `_ready()`
  - `_process()`
  - `_physics_process()`
  - `_exit_tree()`
- `queue_free()`
- `reparent()`
- `owner`
- PackedScene

### 编辑器能力

熟悉：

- Scene 面板
- FileSystem 面板
- Inspector
- Output
- Debugger
- Remote SceneTree
- Remote Inspector
- 运行当前场景
- 运行项目
- 保存分支为独立 Scene
- Editable Children
- 场景继承的基本概念

### 达标标准

看到一棵场景树时，能解释：

- 谁控制谁
- 谁跟着谁移动
- 谁应该成为独立 Scene
- 谁应该在运行时实例化

---

## 2. GDScript 实用基础【P0】

> 目标不是系统学习一门语言，而是足够熟练地控制 Godot。

### 必须掌握

- `extends`
- `class_name`
- 变量与常量
- 类型标注
- Array / Dictionary
- Vector2 / Vector2i
- enum
- 函数
- 默认参数
- 返回值
- `if / match / for / while`
- `@export`
- `@onready`
- `preload()`
- `load()`
- `get_node()`
- `$Node`
- `%UniqueNode`
- `is_instance_valid()`
- `await`
- Callable
- Lambda 基本使用
- `self`
- `super`

### 需要形成的习惯

- 能类型化时尽量类型化。
- Inspector 可配置数据优先考虑 `@export`。
- 不要大量依赖脆弱的 `"../../../../Node"` 路径。
- 节点路径、资源路径和普通字符串要分清。

### 达标标准

能够独立编写一个：

- 玩家移动脚本
- 敌人状态脚本
- 子弹生成脚本
- UI 按钮响应脚本

而不需要先查询 GDScript 基础语法。

---

## 3. 信号、Group 与节点通信【P0】

### 信号

- 内置信号
- 自定义 `signal`
- 编辑器连接
- 代码 `connect()`
- `emit()`
- Callable
- 一次性连接基本概念

### Group

- 编辑器加入 Group
- `add_to_group()`
- `is_in_group()`
- `get_nodes_in_group()`
- `call_group()`

### 通信方式选择

应该知道什么时候使用：

- 直接调用子节点
- 父节点协调
- Signal
- Group
- Autoload
- Resource 共享数据

### 达标标准

不会把所有系统都写成：

```gdscript
get_node("../../../../../Something")
```

---

# 第二部分：2D 空间、显示与渲染

## 4. Node2D 与 2D 坐标系统【P0】

### 核心节点

- `Node2D`
- `CanvasItem`

### 必须掌握

- `position`
- `global_position`
- `rotation`
- `rotation_degrees`
- `scale`
- local / global transform
- 父节点 Transform 对子节点的影响
- `to_local()`
- `to_global()`
- Vector2
- 方向向量
- 距离
- normalize
- angle
- lerp 基本概念

### 达标标准

能够快速判断：

- 为什么节点位置不对
- 为什么子节点跟着父节点旋转
- 为什么 global_position 正确但 position 不对
- 为什么鼠标坐标和对象坐标对不上

---

## 5. Sprite、Texture 与资源导入【P0】

### 节点与资源

- `Sprite2D`
- `Texture2D`
- `AtlasTexture`
- `TextureRect`

### Sprite2D 常用功能

- Texture
- Centered
- Offset
- Flip H / V
- Region
- Hframes / Vframes
- Frame

### 纹理导入与 2D 采样设置

Import 面板理解：

- Mipmaps
- Compression
- 像素画与高清素材的不同导入策略

CanvasItem / Project Settings 理解：

- Texture Filter
- Repeat
- 2D 默认纹理过滤设置

### 达标标准

拿到普通 PNG、角色帧图或图集后，能正确导入并显示，不依赖外部程序临时修正 Godot 配置问题。

---

## 6. 绘制顺序、Y Sort 与 CanvasLayer【P0】

### 必须掌握

- SceneTree 顺序
- `z_index`
- `z_as_relative`
- `y_sort_enabled`
- Y Sort Origin 基本概念
- `CanvasLayer`
- 世界层与 HUD 层

### 典型问题

- 玩家走到树后面时应该被树挡住
- 走到树前面时应该盖住树
- HUD 不应跟随 Camera
- 前景装饰始终盖住角色
- 地面、角色、前景的层级划分

### 达标标准

能独立设计：

```text
World
├── Ground
├── Actors
├── Decorations
└── Foreground

HUD (CanvasLayer)
```

并理解每层为什么这样放。

---

## 7. Camera2D【P0】

### 必须掌握

- `Camera2D`
- Position
- Zoom
- Position Smoothing
- Limits
- Drag
- 多 Camera 切换
- Camera 与 Canvas 的关系

### 常见实现

- 跟随玩家
- 平滑跟随
- 地图边界限制
- 镜头缩放
- 屏幕震动
- 临时聚焦目标

### 达标标准

能够完成一个基本俯视游戏 Camera，而不需要自己重新实现完整摄像机系统。

---

## 8. Parallax2D【P1】

### 核心内容

- `Parallax2D`
- `scroll_scale`
- `repeat_size`
- `repeat_times`
- `autoscroll`
- Camera 相对滚动

### 应用

- 天空
- 远景
- 云层
- 无限背景
- 多层景深错觉

### 注意

Godot 4.x 新项目优先认识 `Parallax2D`，不要只照旧教程机械使用老式 Parallax 结构。

---

## 9. Polygon、Line 与自定义 2D 绘制【P1】

### 节点

- `Polygon2D`
- `Line2D`

### API

- `_draw()`
- `draw_line()`
- `draw_circle()`
- `draw_rect()`
- `draw_polygon()`
- `queue_redraw()`

### 应用

- 攻击范围
- 路径预览
- 战术线
- Debug 图形
- 动态区域提示
- 简单程序化图形

---

## 10. Viewport / SubViewport【P2】

### 认识

- `Viewport`
- `SubViewport`
- `SubViewportContainer`
- `ViewportTexture`

### 知道它能解决

- 小地图
- 独立渲染区域
- 画中画
- 单独渲染到纹理
- 特殊 UI / 后处理结构
- 多视角

### 学习要求

不要求一开始深入 RenderingServer，但必须知道当“一个场景需要被单独渲染成纹理”时应想到 Viewport 系统。

---

# 第三部分：输入、移动与物理

## 11. Input 与 Input Map【P0】

### Project Settings

掌握：

- Input Map
- Action
- Deadzone
- Keyboard
- Mouse
- Gamepad

### 常用 API

- `Input.is_action_pressed()`
- `Input.is_action_just_pressed()`
- `Input.is_action_just_released()`
- `Input.get_axis()`
- `Input.get_vector()`
- `get_viewport().get_mouse_position()`
- `get_local_mouse_position()` / `get_global_mouse_position()`

### 事件

- `_input()`
- `_unhandled_input()`
- `InputEvent`
- Mouse Button
- Mouse Motion
- Key
- Joypad

### 必须理解

- 轮询输入 vs 输入事件
- UI 对输入事件的影响
- `_gui_input()`
- Mouse Filter 基本概念

---

## 12. 2D Physics Body 与 CollisionShape2D【P0】

### 核心节点

- `StaticBody2D`
- `CharacterBody2D`
- `RigidBody2D`
- `AnimatableBody2D`
- `CollisionShape2D`
- `CollisionPolygon2D`

### 必须理解

#### StaticBody2D

适合：

- 墙
- 固定障碍
- 静态地形

#### CharacterBody2D

适合：

- 玩家
- NPC
- 敌人
- 代码控制的移动对象

重点：

- `velocity`
- `move_and_slide()`
- `move_and_collide()`
- `is_on_floor()` 等平台类能力的基本认知

#### RigidBody2D

适合：

- 物理模拟对象
- 箱子
- 弹性/惯性物体
- 需要真实物理响应的对象

#### AnimatableBody2D

知道其适合由动画或代码移动、但需要向其他物理体提供正确运动信息的物体，例如移动平台。

### 达标标准

看到需求后能先选对 Body 类型，而不是所有对象都用 `CharacterBody2D`。

---

## 13. Collision Layer / Mask【P0】

这是 2D 物理必须真正理解的一项。

### 必须理解

- Layer：我属于什么类别
- Mask：我要检测什么类别

### 能设计

例如：

```text
1 Player
2 Enemy
3 World
4 PlayerAttack
5 EnemyAttack
6 Pickup
7 Interactable
```

### 必须掌握

- Project Settings 中给物理 Layer 命名
- Inspector 中配置 Layer / Mask
- 运行时修改
- Debug Visible Collision Shapes

### 达标标准

碰撞不工作时首先会检查 Layer / Mask，而不是盲改脚本。

---

## 14. Area2D 与触发区域【P0】

### 核心能力

- `Area2D`
- `CollisionShape2D`
- `body_entered`
- `body_exited`
- `area_entered`
- `area_exited`
- monitoring
- monitorable

### 常见应用

- 拾取物
- 伤害区
- 攻击判定
- 进入房间触发器
- 交互区
- 环境区域
- 检测敌人

### 达标标准

能清楚区分：

- “我要阻挡对象” → Physics Body
- “我要检测对象进入” → Area2D

---

## 15. RayCast2D、ShapeCast2D 与空间查询【P1】

### 节点

- `RayCast2D`
- `ShapeCast2D`

### 直接查询

认识：

- `PhysicsDirectSpaceState2D`
- ray query
- point query
- shape query

### 时序与一致性

- 直接空间查询统一在物理帧安全上下文中执行。
- `Area2D` 重叠结果按物理步更新，不作为刚改变空间状态后的即时事务验证依据。
- 查询必须明确 Mask、查询 Body / Area、排除对象和边界条件。

### 应用

- 视线检测
- 激光
- 前方墙体
- 地面检测
- 鼠标选取
- 范围扫描
- 冲刺前碰撞预测

### 选择原则

- 固定长期检测 → RayCast2D / ShapeCast2D
- 临时一次查询 → DirectSpaceState

---

## 16. 2D Physics Joint【P2】

### 认识节点

- `PinJoint2D`
- `DampedSpringJoint2D`
- `GrooveJoint2D`

### 知道用途

- 铰链
- 绳索式连接
- 弹簧
- 活塞/滑槽
- 物理机关

不要求普通 RPG 项目深入，但看到“两个 RigidBody 需要物理约束”时应该想到 Joint2D。

---

# 第四部分：TileSet、地图与关卡

## 17. TileSet【P0】

> Godot 4.7 中，TileSet 是 2D 地图工作流的核心资源之一。

### 必须掌握

- `TileSet`
- Tile Size
- TileSet Atlas Source
- Atlas 自动切片
- 手动创建 Tile
- Alternative Tiles
- Tile Origin
- Texture Region
- Transform

### Tile 数据

理解 Tile 可以附带：

- Physics
- Navigation
- Occlusion
- Custom Data
- Terrain 数据

### 达标标准

拿到一张规则 Tile Atlas，能够从零创建可用 TileSet。

---

## 18. TileMapLayer【P0】

> **Godot 4.7 中旧 `TileMap` 已 deprecated。新项目以多个 `TileMapLayer` 为主。**

### 必须掌握

- `TileMapLayer`
- 一个节点代表一个 Tile Layer
- 多 TileMapLayer 组合地图
- 编辑器 Paint
- Erase
- Line
- Rect
- Bucket
- Picker
- Patterns

### 常用 API

- `set_cell()`
- `erase_cell()`
- `get_cell_source_id()`
- `get_cell_atlas_coords()`
- `get_cell_tile_data()`
- `get_used_cells()`
- `get_used_rect()`
- `local_to_map()`
- `map_to_local()`

### 地图坐标体系

必须分清：

```text
世界坐标
↓
TileMapLayer 局部坐标
↓
Cell / Map 坐标
```

### 达标标准

可以：

- 编辑器绘制地图
- 脚本读取地图
- 脚本修改格子
- 世界位置转格子
- 格子位置转世界位置

---

## 19. Terrain 自动拼接【P0】

### 必须理解

- Terrain Set
- Terrain
- Terrain Peering / 邻接关系
- Terrain Painting
- 自动边缘连接

### 常见应用

- 草地 ↔ 土地
- 水 ↔ 岸边
- 熔岩 ↔ 岩地
- 墙体连接
- 道路连接

### 必须知道

Terrain 不是“AI 自动理解图片”。

它依赖 TileSet 中**预先定义的邻接组合**，只有素材提供足够的组合 Tile，编辑器才能正确选择。

### 相关 API

认识：

- `set_cells_terrain_connect()`
- `set_cells_terrain_path()`

---

## 20. TileSet 高级数据【P1】

### Custom Data Layer

用途：

- 是否可破坏
- 地形类型
- 移动消耗
- 脚步声音类型
- 是否危险
- 元素属性

### Physics Layer

在 TileSet 内直接定义 Tile 碰撞。

### Navigation Layer

理解 Tile 导航数据，但不要默认认为它总是复杂项目的最佳导航方案。

### Occlusion Layer

用于 2D Light Occluder 类遮挡数据。

### Scene Collection Source

知道 TileSet 不只能放普通图片 Tile，也可以放场景型 Tile。

---

## 21. 地图分层与场景化设计【P0】

### 推荐思路

地图不应塞成一个巨大节点。

常见分层：

```text
Map
├── Ground
├── GroundDetails
├── Walls
├── Props
├── Obstacles
├── Foreground
├── Navigation
└── Entities
```

### 必须会判断

哪些应该：

- 是 Tile
- 是 TileMapLayer
- 是普通 Sprite2D
- 是独立 Scene
- 是运行时对象

### 目标

地图系统负责“重复且规则的内容”，复杂交互对象尽量保持独立 Scene。

---

# 第五部分：导航、路径与 AI 移动基础

## 22. NavigationRegion2D / NavigationPolygon【P0】

### 核心节点/资源

- `NavigationRegion2D`
- `NavigationPolygon`

### 必须理解

- 可行走区域
- Navigation Mesh
- 烘焙
- Navigation Layer
- Region 连接
- Navigation Map 基本概念

### 调试

掌握 Navigation Debug 可视化。

### 注意

TileMapLayer 可以包含导航数据，但复杂地图需要知道何时改用集中烘焙的 `NavigationRegion2D`。
TileMapLayer 的格子更新可能批处理到帧末；需要立即刷新内部数据时应了解 `update_internals()` 的适用范围。

---

## 23. NavigationAgent2D【P0】

### 用途

为移动角色提供：

- 路径查询
- 下一个路径点
- 到达判断
- Agent 参数
- 避障辅助
- `avoidance_enabled`
- `velocity_computed(safe_velocity)`
- `avoidance_layers` / `avoidance_mask`

### 必须理解

`NavigationAgent2D`：

- **不会自动移动父节点**
- 它负责导航相关计算
- 实际移动仍由你的 CharacterBody2D 等对象执行
- 设置 `target_position` 后，通常需要在每个物理帧调用 `get_next_path_position()` 更新路径逻辑。

### 版本注意

Godot 4.7 官方文档将 `NavigationAgent2D`、`NavigationRegion2D`、`NavigationPolygon` 和 `NavigationObstacle2D` 标为 Experimental；项目应固定引擎版本并用验证场景覆盖关键行为。

### 常见结构

```text
Enemy (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
└── NavigationAgent2D
```

### 达标标准

能实现：

> 敌人绕过地图障碍追逐玩家。

---

## 24. NavigationObstacle2D / NavigationLink2D【P1】

### NavigationObstacle2D

必须知道：

- 默认主要用于影响 Agent avoidance。
- 启用 `affect_navigation_mesh` 后，可以在导航网格烘焙时丢弃其形状内的源几何；`carve_navigation_mesh` 可控制烘焙时的裁剪方式。
- **不会实时自动重建已经烘焙的寻路网格**；动态移动对象通常应使用 avoidance 或显式重新烘焙。
- “避让”与“不可通行路径”不是同一回事

### NavigationLink2D

应用：

- 跳跃点
- 楼梯逻辑连接
- 门
- 传送连接
- 特殊跨区路径

### 达标标准

理解：

```text
Pathfinding ≠ Avoidance
```

---

## 25. AStar2D / AStarGrid2D【P1】

### AStar2D

适合：

- 自定义图结构
- 离散节点
- 有权重路径

### AStarGrid2D

适合：

- 方格地图
- 战棋
- 网格 RPG
- Roguelike
- Cell-based 移动

### 必须理解

Navigation Mesh 和 AStarGrid2D 是两种不同的问题建模方式。

#### 连续自由移动

优先想到：

```text
NavigationRegion2D
NavigationAgent2D
```

#### 明确格子移动

优先想到：

```text
AStarGrid2D
```

---

## 26. Path2D / PathFollow2D【P1】

> **Path2D 不是动态寻路。**

### 核心节点

- `Path2D`
- `PathFollow2D`
- `Curve2D`

### 应用

- 固定巡逻路线
- 过场运动
- 飞行轨迹
- 道路
- 传送带
- 固定 Boss 路径

### 关键属性

- progress
- progress_ratio
- loop
- rotates
- rotation（来自 Node2D 的变换）

### 必须形成的判断

```text
“沿我画好的路线走”
→ Path2D

“自己计算如何绕过障碍”
→ Navigation / AStar
```

---

# 第六部分：动画、特效与表现

## 27. AnimatedSprite2D 与 SpriteFrames【P0】

### 掌握

- `AnimatedSprite2D`
- `SpriteFrames`
- animation
- frame
- speed_scale
- autoplay
- loop
- `play()`
- `stop()`
- animation_finished

### 适合

- 序列帧角色
- 简单火焰
- 宝箱
- 特效帧动画

---

## 28. AnimationPlayer【P0】

### 必须掌握

- Animation Library
- Property Track
- Method Track
- Audio Track
- Bezier Track 基本认识
- RESET Animation
- autoplay
- loop
- Call Method

### 应用

AnimationPlayer 不只是“角色动画”。

它可以统一控制：

- position
- rotation
- scale
- modulate
- shader 参数
- UI
- 声音
- 节点属性
- 方法调用

### 达标标准

能独立做：

- 门打开
- 宝箱动画
- UI 弹出
- 攻击动作 + Hitbox 开关
- 场景机关

---

## 29. AnimationTree【P1】

### 认识并会基础配置

- `AnimationTree`
- StateMachine
- Transition
- BlendSpace1D
- BlendSpace2D

### 适合

- Idle / Walk / Run / Attack / Hurt / Death
- 方向动画
- 复杂角色动画状态切换

### 学习边界

不需要一开始研究所有 Blend Node。

目标是理解：

```text
AnimatedSprite2D
→ 简单帧动画

AnimationPlayer
→ 时间线上控制多个属性

AnimationTree
→ 管理复杂动画状态与混合
```

---

## 30. Tween【P0】

### 必须掌握

- `create_tween()`
- `tween_property()`
- `tween_method()`
- `tween_callback()`
- parallel
- chain
- transition
- ease
- kill

### 应用

- UI 弹入
- 飘字
- 淡入淡出
- 缩放反馈
- 伤害闪动
- 简单移动
- 数值过渡

### 原则

短暂的程序化过渡优先考虑 Tween，而不是为所有效果建立 AnimationPlayer。

---

## 31. Particles2D【P1】

### 节点

- `GPUParticles2D`
- `CPUParticles2D`
- `ParticleProcessMaterial`

### 常用属性

- Amount
- Lifetime
- One Shot
- Explosiveness
- Randomness
- Direction
- Spread
- Initial Velocity
- Gravity
- Scale
- Color
- Emission Shape
- Local Coords
- Visibility Rect

### 应用

- 火焰
- 烟
- 火花
- 雪
- 魔法粒子
- 爆炸碎屑
- 环境尘埃

### 原则

默认先了解 GPUParticles2D；只有明确需求时才考虑 CPU 粒子。

---

## 32. 2D Light、Shadow 与 CanvasModulate【P1】

### 节点

- `PointLight2D`
- `DirectionalLight2D`
- `LightOccluder2D`
- `CanvasModulate`

### 理解

- Light Texture
- Energy
- Light2D 的层 / Z 范围筛选
- PointLight2D 的纹理形状与 texture_scale
- Shadow
- Occluder Polygon
- 全局环境暗度

### 应用

- 火把
- 夜间地图
- 洞穴
- 闪光
- 技能光照

---

## 33. CanvasItem Shader【P1】

### 最低要求

认识：

- Shader
- ShaderMaterial
- `shader_type canvas_item`
- vertex
- fragment
- UV
- COLOR
- TEXTURE
- uniform
- TIME

### 能修改常见 Shader

- 受击闪白
- 溶解
- 描边
- 换色
- 水波扭曲
- UV 滚动
- 发光辅助效果

### 学习目标

不是成为图形学专家，而是：

> 看得懂普通 2D Shader，并能调整和接入项目。

---

## 34. Skeleton2D / Bone2D【P2】

### 认识

- `Skeleton2D`
- `Bone2D`
- Polygon2D 骨骼变形
- Rest Pose
- 2D IK / Modification 基本概念

### 适合

- Cutout Animation
- 多部件角色
- 骨骼变形角色

如果项目主要使用序列帧，可以停留在“知道 Godot 原生支持”这一层。

---

# 第七部分：UI、音频、数据与游戏系统

## 35. Control 与 UI 坐标体系【P0】

### 核心节点

- `Control`

### 必须理解

- Position / Size
- Anchors
- Offsets
- Grow Direction
- Layout
- Minimum Size
- Size Flags / Container Sizing

### 特别注意

`Node2D` 和 `Control` 都继承自 `CanvasItem`，但布局逻辑完全不同。

不要拿 Node2D 的布局思路硬套 Control。

---

## 36. Container 布局系统【P0】

### 常用节点

- `MarginContainer`
- `VBoxContainer`
- `HBoxContainer`
- `GridContainer`
- `CenterContainer`
- `PanelContainer`
- `ScrollContainer`
- `TabContainer`
- `AspectRatioContainer`
- `FlowContainer`

### 必须形成的习惯

复杂 UI：

> 优先用 Container 布局，不要手工摆一堆坐标。

### 达标标准

能做一个窗口缩放后依然正常的：

- 主菜单
- 设置页
- 背包格
- HUD

---

## 37. 常用 Control 节点与 Theme【P0】

### 常用节点

- Label
- RichTextLabel
- Button
- TextureButton
- TextureRect
- Panel
- ProgressBar
- LineEdit
- CheckBox
- OptionButton
- Slider
- ScrollContainer
- Popup 基本认识
- Window 基本认识（Window 继承 Viewport，不是 Control）

### Theme

理解：

- Theme
- Theme Override
- Font
- Font Size
- StyleBox
- Color
- Constant
- Theme Type Variation

### 输入相关

- Focus
- Mouse Filter
- Tooltip

---

## 38. Timer 与时间控制【P1】

### 节点/API

- `Timer`
- `timeout`
- `one_shot`
- `autostart`
- `SceneTree.create_timer()`

### 应用

- 表现或现实时间延迟
- UI 倒计时
- 自动刷新
- 明确属于引擎时间的周期任务

### 项目规则边界

- 攻击 CD、Buff 时间、AI 思考周期等领域规则默认使用领域定义的逻辑时间，不用 `Timer` 或 `SceneTree.create_timer()` 代替。
- `Timer` 按物理帧或渲染帧更新，并受 `Engine.time_scale` 等因素影响；不能把它当作精确的领域调度器。

### 同时理解

- `delta`
- physics delta
- Engine time scale
- Pause 基本概念

---

## 39. PackedScene 与对象生成【P0】

### 必须掌握

- `PackedScene`
- `preload()`
- `load()`
- `instantiate()`
- `add_child()`
- `queue_free()`
- `Marker2D`

### 常见对象

- Bullet
- Enemy
- Pickup
- Effect
- DamageNumber
- Room
- Projectile

### 原则

一个可独立复用的游戏对象，优先做成 Scene，而不是把所有内容写在主场景里。

---

## 40. Resource 与数据驱动【P0】

### 必须理解

- `Resource`
- `.tres`
- `.res`
- 自定义 Resource
- `@export`
- Inspector 编辑 Resource
- Resource 引用共享
- `duplicate()`
- local to scene 基本概念

### 适合存储

- WeaponData
- SkillData
- EnemyData
- ItemData
- CharacterStats
- LevelConfig

### 目标

把：

```text
“这个节点怎么运行”
```

和：

```text
“这个角色的数据是什么”
```

逐渐分开。

---

## 41. Autoload 与全局服务【P1】

### 学会

- Project Settings → Autoload
- Singleton 基本模式
- 场景切换
- 少量、确有跨场景全局生命周期的服务

### 常见用途

- GameManager
- SaveManager
- AudioManager
- SceneManager
- 全局配置

### 注意

Autoload 不是 Service Locator，也不应承载本应属于局部场景、流程或会话的可变业务状态。

不要把 Autoload 变成“什么都往里面塞”的垃圾桶。

---

## 42. Audio【P1】

### 节点

- `AudioStreamPlayer`
- `AudioStreamPlayer2D`
- `AudioListener2D`

### 系统

- Audio Bus
- Master
- Music
- SFX
- UI
- Bus Volume
- Effects

### 2D 音频

理解：

- 世界位置
- 距离衰减
- `AudioListener2D.make_current()`
- 没有活动 Listener 时默认以屏幕中心作为听音点

### 达标标准

能建立：

```text
Master
├── Music
├── SFX
└── UI
```

这样的基础 Bus 结构。

---

## 43. 文件、配置与存档【P1】

### API / 概念

- `FileAccess`
- `DirAccess`
- JSON
- `ConfigFile`
- `user://`
- `ResourceSaver` / `ResourceLoader`
- Resource 保存基本认识

### 能解决

- 设置保存
- 键位设置
- 游戏进度
- 简单存档
- 用户生成数据

### 必须理解

`res://` 与 `user://` 的用途区别。

---

# 第八部分：编辑器效率、调试、性能与项目维护

## 44. Godot 编辑器熟练操作【P0】

### 必须熟练

- Inspector 搜索
- 节点搜索
- Scene Dock
- FileSystem
- Quick Open
- Node Reparent
- Duplicate
- Rename
- Multi-select
- Local / Global Transform
- Snap
- Grid
- Lock
- Group
- Editable Children
- Make Local
- Resource 保存与复用

### Bottom Panel

熟悉：

- Output
- Debugger
- Animation
- TileMap
- Audio 等项目实际出现的工具区

### 目标

编辑器操作不应该成为开发速度瓶颈。

---

## 45. Debug 工具【P0】

### 必须掌握

- `print()`
- `push_warning()`
- `push_error()`
- Breakpoint
- Call Stack
- Errors
- Profiler
- Monitors
- Remote SceneTree
- Remote Inspector

### 2D 专用 Debug

熟悉：

- Visible Collision Shapes
- Navigation Debug
- Paths / avoidance 相关可视化
- Remote 节点实时属性

### 排错顺序

遇到问题时尽量按：

```text
节点是否存在
→ 属性是否正确
→ Layer/Mask 是否正确
→ 坐标系是否正确
→ Signal 是否触发
→ Runtime 状态是否正确
→ 再怀疑引擎
```

---

## 46. 性能基础【P1】

### 必须理解

- `_process()` 与 `_physics_process()`
- 不必要的每帧查询
- 节点数量
- draw calls 基本概念
- 粒子成本
- 物理查询成本
- 碰撞 Shape 数量
- 大量 Signal / instantiate 的影响
- TileMapLayer 的批量绘制优势
- 对象池的适用场景

### 工具

- Profiler
- Monitors
- Rendering Statistics

### 原则

先测量，再优化。

---

## 47. Project Settings 与窗口/显示【P0】

### 熟悉分类

- Display / Window
- Rendering
- Input Map
- Physics
- Layer Names
- Audio
- Application
- Debug

### 显示

理解：

- Window Size
- Viewport Size
- Stretch / Content Scale
- Aspect
- Fullscreen
- VSync 基本概念

### 目标

不同窗口比例下，游戏画面和 UI 不应随意崩坏。

---

## 48. 项目目录与场景拆分【P0】

### 推荐按功能组织，而不是把所有资源堆在一个目录

例如：

```text
res://
├── actors/
│   ├── player/
│   └── enemies/
├── combat/
│   ├── skills/
│   └── projectiles/
├── maps/
│   ├── tilesets/
│   └── rooms/
├── ui/
├── effects/
├── audio/
├── data/
├── systems/
└── autoload/
```

### 必须理解

- 一个 Scene 不应该无限膨胀。
- 可独立复用、独立逻辑、独立维护的内容应拆 Scene。
- Resource 用于数据。
- Node / Scene 用于运行时行为和结构。

---

## 49. Git 与项目文件基本认识【P1】

### 知道

- 哪些是项目源文件
- `.godot/` 属于生成缓存类内容
- 二进制资源与文本资源的区别
- `.tscn`
- `.tres`
- `.gd`
- import 数据基本概念

### 目标

知道哪些内容应该提交版本控制，哪些内容可由 Godot 重新生成。

---

## 50. Export【P1】

### 掌握

- Export Templates
- Export Preset
- Debug / Release
- Windows 基础导出
- Web 基础导出
- 项目需要时再学习 Android / iOS

### 达标标准

项目不只“能在编辑器里跑”，还能够生成实际可运行版本。

---

# 第九部分：问题 → Godot 工具速查表

这是整份清单最重要的一部分。

真正的“用得得心应手”不是背节点，而是看到问题就能想到 Godot 中对应的工具。

| 开发需求 | 首先想到 |
|---|---|
| 玩家/NPC 代码控制移动 | `CharacterBody2D` |
| 固定墙体/障碍 | `StaticBody2D` |
| 真实物理箱子 | `RigidBody2D` |
| 移动平台 | `AnimatableBody2D` |
| 碰撞形状 | `CollisionShape2D` / `CollisionPolygon2D` |
| 进入区域触发事件 | `Area2D` |
| 攻击 Hitbox / Hurtbox | `Area2D` + Layer/Mask |
| 前方射线检测 | `RayCast2D` |
| 扫描一个形状范围 | `ShapeCast2D` |
| 临时物理查询 | `PhysicsDirectSpaceState2D` |
| 普通图片显示 | `Sprite2D` |
| 帧动画 | `AnimatedSprite2D` |
| 多属性时间线动画 | `AnimationPlayer` |
| 复杂角色动画状态 | `AnimationTree` |
| 简单过渡 | Tween |
| UI | `Control` |
| 自动 UI 布局 | `Container` |
| HUD 不跟相机移动 | `CanvasLayer` |
| 摄像机 | `Camera2D` |
| 视差背景 | `Parallax2D` |
| 地图 | `TileMapLayer` + `TileSet` |
| 地形自动连接 | TileSet Terrain |
| Tile 附加游戏数据 | TileSet Custom Data |
| 自由空间动态寻路 | `NavigationRegion2D` + `NavigationAgent2D` |
| 网格寻路 | `AStarGrid2D` |
| 自定义图结构寻路 | `AStar2D` |
| 固定轨迹运动 | `Path2D` + `PathFollow2D` |
| AI 避障 | `NavigationAgent2D` avoidance + `NavigationObstacle2D` |
| 特殊导航连接 | `NavigationLink2D` |
| 2D 位置光 | `PointLight2D` |
| 2D 全场平行光 | `DirectionalLight2D` |
| 光线遮挡 | `LightOccluder2D` |
| 环境整体变暗 | `CanvasModulate` |
| 粒子 | `GPUParticles2D` |
| 2D Shader | `ShaderMaterial` + CanvasItem Shader |
| 画线/圆/区域提示 | `Line2D` / `_draw()` |
| 小地图/画中画 | `SubViewport` |
| 物理铰链/弹簧 | `Joint2D` 系列 |
| 对象生成 | `PackedScene.instantiate()` |
| 出生点 | `Marker2D` |
| 现实时间延时/表现计时 | `Timer` / SceneTreeTimer |
| 模块间通知 | Signal |
| 批量分类对象 | Group |
| 游戏配置数据 | 自定义 `Resource` |
| 跨场景且具有全局生命周期的服务（按需） | Autoload |
| 游戏存档 | `FileAccess` / `ConfigFile` |
| 世界音效 | `AudioStreamPlayer2D` |
| BGM/UI 音效 | `AudioStreamPlayer` |
| 场景过大难维护 | 拆分独立 Scene |
| 看运行时节点状态 | Remote SceneTree / Inspector |
| 碰撞看不见不好查 | Visible Collision Shapes |
| 导航不对 | Navigation Debug |
| 游戏突然变慢 | Profiler / Monitors |

---

# 第十部分：推荐学习顺序

## 阶段 A：先建立 Godot 基础模型

1. Scene / Node / SceneTree
2. GDScript
3. Signal / Group
4. Node2D 坐标
5. Sprite2D
6. Input

完成后应能制作：

> 一个可以移动、响应输入的 Sprite 角色。

---

## 阶段 B：物理闭环

7. CharacterBody2D
8. StaticBody2D
9. CollisionShape2D
10. Layer / Mask
11. Area2D
12. RayCast2D

完成后应能制作：

> 玩家在房间中移动、撞墙、攻击敌人、进入区域触发事件。

---

## 阶段 C：地图闭环

13. TileSet
14. TileMapLayer
15. Terrain
16. Tile Physics
17. Tile Custom Data
18. 地图分层
19. Y Sort

完成后应能制作：

> 一张可编辑、可碰撞、有自动地形连接的正式游戏地图。

---

## 阶段 D：角色与世界运动

20. Camera2D
21. NavigationRegion2D
22. NavigationAgent2D
23. AStarGrid2D
24. Path2D

完成后应能制作：

> 玩家探索地图，敌人可以追击，特定对象可以沿预设路径运动。

---

## 阶段 E：动画与表现

25. AnimatedSprite2D
26. AnimationPlayer
27. Tween
28. Particles
29. Light
30. Shader

完成后应能制作：

> 一个具有基础战斗反馈、光照、粒子和动画表现的房间。

---

## 阶段 F：UI 与游戏系统

31. Control
32. Container
33. Theme
34. Timer（现实时间/表现用途）
35. Resource
36. PackedScene
37. Autoload（按需）
38. Audio
39. Save

完成后应能制作：

> HUD、菜单、技能/角色数据、音频、对象生成和存档系统。

---

## 阶段 G：工程能力

40. Remote Debug
41. Profiler
42. Project Settings
43. 项目拆分
44. Git
45. Export

完成后应达到：

> 项目扩大后仍然能够定位问题、维护场景和输出实际版本。

---

## 阶段 H：按项目需求补专项

- Parallax2D
- SubViewport
- Skeleton2D
- Physics Joint
- 更深入的 Shader
- NavigationServer2D
- PhysicsServer2D / RenderingServer 等低级 Server API

这些不应该阻塞前面的核心学习。

---

# 第十一部分：不需要在当前阶段刻意精通的内容

为了避免学习路线无限膨胀，以下内容不列入“Godot 2D 常规熟练”的硬要求：

- 所有节点的全部属性
- 所有 `Server` 底层 API
- RenderingServer 深度使用
- PhysicsServer2D 深度使用
- 自定义 RenderingDevice
- 高级 Shader 数学
- 自定义引擎模块
- GDExtension
- EditorPlugin 深度开发
- 自定义资源导入插件
- 高级网络同步
- XR
- 3D 系统

原则是：

> **先知道高层 Godot 工具什么时候能直接解决问题。只有高层系统无法满足需求时，再进入底层 API。**

---

# 第十二部分：最终验收标准

如果下面这些问题你基本都能立刻回答“应该用什么”，说明已经接近本清单定义的 **Godot 4.7 2D 熟练使用**。

### 物理

- 玩家怎么移动？
- 墙用什么？
- 敌人的攻击区域怎么做？
- 子弹怎么检测命中？
- 怎么区分玩家子弹和敌人子弹？
- 怎么检查前面有没有墙？

### 地图

- 地图用什么节点？
- Tile 图片在哪里切？
- 碰撞怎么写进 Tile？
- 草地和土地怎么自动拼接？
- 怎么从鼠标世界位置得到 Cell？
- 怎么在代码里替换某个 Tile？

### 导航

- 敌人绕墙追玩家怎么做？
- 战棋格子怎么计算路线？
- 固定巡逻轨迹怎么做？
- NavigationObstacle2D 和不可通行区域有什么区别？

### 动画

- 帧动画用什么？
- 开门动画用什么？
- UI 放大缩小用什么？
- 复杂角色动画状态怎么管理？

### UI

- HUD 为什么不应该跟 Camera 一起移动？
- UI 为什么优先 Container 而不是手摆坐标？
- Mouse Filter 为什么会导致点击穿透或被拦截？

### 数据

- 武器参数放脚本常量还是 Resource？
- 敌人 Scene 和 EnemyData 应该是什么关系？
- 跨场景 AudioManager 放哪里？

### 调试

- 碰撞不工作先看什么？
- Navigation 不工作怎么看？
- 运行时节点值和编辑器值不一致怎么看？
- 帧率下降怎么定位？

如果这些问题大多不需要“先搜 Godot 有没有这个功能”，而只是偶尔需要查询具体 API 参数，那么目标已经达到。

---

# 第十三部分：核心能力地图

最终可以把整个 Godot 2D 心智模型压缩成：

```text
Godot
│
├── 结构
│   ├── Node
│   ├── Scene
│   ├── SceneTree
│   ├── Signal
│   └── Resource
│
├── 2D 世界
│   ├── Node2D
│   ├── Sprite2D
│   ├── Camera2D
│   ├── CanvasLayer
│   └── Parallax2D
│
├── 物理
│   ├── CharacterBody2D
│   ├── StaticBody2D
│   ├── RigidBody2D
│   ├── Area2D
│   ├── CollisionShape2D
│   ├── RayCast2D
│   └── ShapeCast2D
│
├── 地图
│   ├── TileSet
│   ├── TileMapLayer
│   ├── Terrain
│   ├── Physics
│   ├── Navigation
│   └── Custom Data
│
├── 导航
│   ├── NavigationRegion2D
│   ├── NavigationAgent2D
│   ├── NavigationObstacle2D
│   ├── NavigationLink2D
│   ├── AStar2D
│   ├── AStarGrid2D
│   └── Path2D
│
├── 动画表现
│   ├── AnimatedSprite2D
│   ├── AnimationPlayer
│   ├── AnimationTree
│   ├── Tween
│   ├── Particles
│   ├── Light
│   └── Shader
│
├── UI
│   ├── Control
│   ├── Container
│   ├── Theme
│   └── CanvasLayer
│
└── 工程系统
    ├── PackedScene
    ├── Timer
    ├── Autoload
    ├── Audio
    ├── Save
    ├── Debug
    ├── Profiler
    └── Export
```

真正要形成的是这张“能力地图”，而不是记住几百个零散 API。

---

# 第十四部分：本项目建议重点

对于偏 **2D 俯视、房间制、Tile 地图、战斗、元素主题地图** 的项目，建议优先把下面这些模块练到 L3～L4：

1. Scene / Node / SceneTree
2. GDScript
3. Signal
4. Node2D / 坐标系统
5. Sprite2D
6. CharacterBody2D
7. Area2D
8. Collision Layer / Mask
9. RayCast2D / ShapeCast2D
10. TileSet
11. TileMapLayer
12. Terrain
13. Tile Custom Data
14. Y Sort / Z Index
15. NavigationRegion2D
16. NavigationAgent2D
17. AStarGrid2D
18. AnimatedSprite2D
19. AnimationPlayer
20. Tween
21. Camera2D
22. Particles
23. CanvasItem Shader
24. Control / Container
25. Resource
26. PackedScene
27. Timer（现实时间/表现用途）
28. Autoload（仅确有全局生命周期时）
29. Audio
30. Remote Debug / Profiler

这 30 项形成项目的真正核心工具箱。

---

# 官方文档参考

以下均以 Godot 官方文档为主：

- Godot 4.7 Documentation  
  https://docs.godotengine.org/en/4.7/

- Node2D  
  https://docs.godotengine.org/en/4.7/classes/class_node2d.html

- TileMap（4.7 已标记 Deprecated）  
  https://docs.godotengine.org/en/4.7/classes/class_tilemap.html

- TileMapLayer  
  https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html

- NavigationAgent2D  
  https://docs.godotengine.org/en/4.7/classes/class_navigationagent2d.html

- AStarGrid2D  
  https://docs.godotengine.org/en/4.7/classes/class_astargrid2d.html

- Parallax2D  
  https://docs.godotengine.org/en/4.7/classes/class_parallax2d.html

- SubViewport  
  https://docs.godotengine.org/en/4.7/classes/class_subviewport.html

- 2D Tutorials  
  https://docs.godotengine.org/en/4.7/tutorials/2d/

- Navigation  
  https://docs.godotengine.org/en/4.7/tutorials/navigation/

- UI  
  https://docs.godotengine.org/en/4.7/tutorials/ui/

---

**版本：v1.0 — Godot 4.7 2D 实用能力清单**
