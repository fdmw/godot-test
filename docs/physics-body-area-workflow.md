# 2D Physics Body、碰撞几何与 Area2D 工作流

本文说明 `StaticBody2D`、`CharacterBody2D`、`RigidBody2D`、`AnimatableBody2D`、`CollisionShape2D`、`CollisionPolygon2D` 和 `Area2D` 的选择与配置。核心判断是：对象需要被阻挡、被物理模拟，还是只需要检测进入/离开。

## 1. 先选择 Body 类型

| 类型 | 谁负责移动 | 适合场景 | 关键入口 |
| --- | --- | --- | --- |
| `StaticBody2D` | 不移动，或极少改变 | 墙、地面、固定障碍 | 场景 Transform 和碰撞几何 |
| `CharacterBody2D` | 脚本或应用逻辑 | 玩家、NPC、代码控制的敌人 | `velocity`、`move_and_slide()`、`move_and_collide()` |
| `RigidBody2D` | 物理引擎 | 箱子、弹性物体、惯性物体 | 力、冲量、质量、阻尼和接触 |
| `AnimatableBody2D` | 动画或代码 | 移动平台、需要向其他物体提供运动信息的障碍 | 动画/Transform 驱动的物理运动 |
| `Area2D` | 不负责阻挡 | 拾取区、伤害区、触发器、检测范围 | `body_entered`、`area_entered` 等信号 |

不要把所有移动对象都做成 CharacterBody2D。需要真实惯性和碰撞响应时选 RigidBody2D；固定世界几何使用 StaticBody2D；移动平台等由动画驱动但仍要参与物理交互的对象考虑 AnimatableBody2D。

## 2. CollisionShape2D 与 CollisionPolygon2D

物理 Body 或 Area 通常需要一个或多个碰撞子节点：

```text
CharacterBody2D
├── CollisionShape2D  ← 引用 CircleShape2D / RectangleShape2D 等 Shape2D
└── Sprite2D          ← 只负责视觉
```

编辑器操作：

1. 添加 Body 或 Area2D；
2. 添加 `CollisionShape2D` 或 `CollisionPolygon2D` 子节点；
3. 为 CollisionShape2D 创建合适的 `Shape2D`；
4. 在 2D 视口调整几何，确保它覆盖实际占用区域；
5. 在 Body/Area Inspector 设置 Collision Layer、Mask 和启用状态；
6. 运行时用 Debug > Visible Collision Shapes 检查实际形状。

规则简单、可复用的形状优先使用 CircleShape2D、RectangleShape2D 等 Shape2D；轮廓复杂或必须贴合多边形时使用 CollisionPolygon2D。碰撞几何是物理空间占用的事实来源，Sprite 的外观边界和脚本中的手写半径不能替代它。

同一 Body 可以有多个碰撞子节点，但要明确每个形状的用途和层掩码。不要为了修复一次查询结果，额外维护一份与 CollisionShape2D 不一致的逻辑包围盒。

## 3. CharacterBody2D 的移动

CharacterBody2D 适合由代码控制的运动。常见闭环是：读取输入或导航请求，计算速度，在物理帧调用移动 API，再根据碰撞结果更新表现：

```gdscript
@onready var _character: CharacterBody2D = %Character

func move_character(direction: Vector2, delta: float) -> void:
	_character.velocity = direction * 160.0
	_character.move_and_slide()
	# 之后读取 is_on_floor()、get_slide_collision_count() 等结果。
```

重力、速度和移动必须在物理更新上下文中处理。`move_and_slide()` 会使用 `velocity` 进行滑动式移动；`move_and_collide()` 更适合需要直接取得碰撞信息并自行决定后续响应的情况。不要同时让父节点脚本、Tween 和物理移动 API 写入同一个 CharacterBody2D 的位置。

平台类判断可使用 `is_on_floor()`、`is_on_wall()`、`is_on_ceiling()`，但必须结合 `up_direction`、地面角度和实际碰撞几何理解结果。角色的视觉抖动应由 Sprite 子节点表现，不要为视觉效果修改参与碰撞的 Body Transform。

## 4. RigidBody2D 与 AnimatableBody2D

RigidBody2D 的位置和速度由物理引擎管理。应使用力或冲量表达外力：

```gdscript
func launch_body(body: RigidBody2D) -> void:
	body.apply_central_impulse(Vector2(160.0, -220.0))
```

不要在每个物理帧直接设置 RigidBody2D 的位置来模拟真实物理；这会绕过引擎的速度和接触响应。重置验证对象时可以明确清零速度、角速度并设置初始位置，但要把它视为测试控制操作。

AnimatableBody2D 适合由动画或脚本移动的物理平台。它不是 StaticBody2D 的简单替代品，移动时应让物理引擎获得正确的运动信息，使被推动或站在平台上的其他 Body 得到合理响应。

## 5. Area2D：检测而不阻挡

Area2D 通过碰撞几何和层掩码感知其他 PhysicsBody2D 或 Area2D。它本身通常不是阻挡体，检测逻辑依赖：

- `monitoring`：是否主动监测进入和离开；
- `monitorable`：是否允许其他 Area 监测到它；
- Collision Layer：Area 所属类别；
- Collision Mask：Area 要检测的类别；
- `body_entered` / `body_exited`：Body 进入/离开；
- `area_entered` / `area_exited`：Area 进入/离开。

典型连接方式：

```gdscript
func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("进入：", body.name)
```

重叠信号和 `get_overlapping_bodies()` 等结果按物理步更新。刚修改了空间状态后，不要把旧的重叠结果当成同一事务的即时事实；需要即时验证时使用符合物理时序的直接空间查询，并明确排除对象和碰撞层。

## 6. 碰撞层与掩码的配合

可以在 Project Settings > Layer Names > 2D Physics 中为物理层命名，例如：

```text
1 Player
2 Enemy
3 World
4 PlayerAttack
5 EnemyAttack
6 Pickup
```

Layer 表示“我属于什么类别”，Mask 表示“我检测什么类别”。碰撞或 Area 事件至少需要一方的 Layer 与另一方的 Mask 有交集；排查时不要只看其中一个节点。

层位应通过集中定义的具名常量或明确接口使用，避免在业务代码中散落难以识别的整数位值。临时切换层掩码可以作为验证操作，但不要让不同场景各自重新解释同一个层编号。

## 7. 当前验证与常见问题

`tests/physics/` 集中验证 CharacterBody2D、RigidBody2D、Area2D、碰撞几何、接触信号以及移动/冲量；RayCast2D 和 ShapeCast2D 也在该测试中验证。

- Body 穿过墙：检查 Body 是否有有效碰撞形状、双方 Layer/Mask 是否匹配，以及移动是否绕过了物理 API。
- Area 没有信号：检查 `monitoring`、`monitorable`、碰撞形状和双方层掩码；确认另一对象确实进入了 Area。
- RigidBody 位置被覆盖：检查是否有脚本、Tween 或动画直接写 Transform。
- 角色地面判断错误：检查 `up_direction`、地面角度、碰撞几何和移动调用时机。
- 形状与图片不一致：调整 CollisionShape2D，而不是仅缩放 Sprite 或修改视觉偏移。
- 修改碰撞属性时报时序错误：按照引擎要求使用 `set_deferred()`，并在领域层维护自己的状态事实。

## 8. 官方参考

- [Physics introduction — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/physics/physics_introduction.html)
- [CharacterBody2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
- [RigidBody2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_rigidbody2d.html)
- [AnimatableBody2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_animatablebody2d.html)
- [Area2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_area2d.html)
- [CollisionShape2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_collisionshape2d.html)
