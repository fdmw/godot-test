# Collision Layer、Mask 与 2D 空间查询工作流

本文说明碰撞层/掩码，以及 `RayCast2D`、`ShapeCast2D` 和 `PhysicsDirectSpaceState2D` 的选择。它重点解决“检测谁、何时检测、返回什么、如何保证结果与物理状态一致”这几个问题。

## 1. Layer 与 Mask

Layer 表示对象所属的类别，Mask 表示对象主动检测的类别。例如：

```text
1 Player
2 Enemy
3 World
4 PlayerAttack
5 EnemyAttack
6 Pickup
```

如果玩家在 Layer 1，世界在 Layer 3，玩家需要被世界阻挡，则玩家的 Mask 应包含 3；世界的 Mask 是否包含 1，取决于世界是否也需要主动检测玩家。排查碰撞时必须同时查看双方 Layer 和 Mask，不能只改一个数字直到“碰巧有效”。

在 Project Settings > Layer Names > 2D Physics 中统一命名层。业务代码通过集中定义的具名常量或接口操作掩码，避免散落 `1 << 4` 之类无法读懂的魔法位值。

## 2. RayCast2D：固定方向的首个命中

`RayCast2D` 从节点原点向 `target_position` 发出射线，报告沿线最近的命中对象。典型配置入口：

1. 将 RayCast2D 添加到需要检测的 Node2D 或 Body 下；
2. 设置相对节点的 `target_position`；
3. 设置 `collision_mask`；
4. 按需要启用 `collide_with_bodies`、`collide_with_areas` 和 `exclude_parent`；
5. 运行时读取 `is_colliding()`、`get_collider()`、`get_collision_point()` 和 `get_collision_normal()`。

```gdscript
@onready var _ray: RayCast2D = %RayCast

func read_ground() -> bool:
	return _ray.is_colliding()

func read_hit_point() -> Vector2:
	if not _ray.is_colliding():
		return global_position
	return _ray.get_collision_point()
```

RayCast2D 每个物理帧更新并保留结果。如果同一物理帧内修改了射线或父节点状态后必须立即刷新，可以调用 `force_raycast_update()`；这不是绕过物理时序、随时读取任意状态的通用办法。

## 3. ShapeCast2D：用形状扫过空间

`ShapeCast2D` 用一个 `Shape2D` 沿目标方向扫描，比单条射线更适合角色前方宽度检测、冲刺预测和范围探测。关键属性包括：

- `shape`：需要扫描的 CircleShape2D、RectangleShape2D 等；
- `target_position`：相对节点的扫描终点；
- `collision_mask`：要检测的层；
- `collide_with_bodies` / `collide_with_areas`：查询对象类别；
- `max_results`：最多保存的命中结果数量；
- `margin`：形状检测的边界余量；
- `enabled`：是否持续更新。

```gdscript
@onready var _cast: ShapeCast2D = %ShapeCast

func can_dash() -> bool:
	return not _cast.is_colliding()
```

如果需要完整候选集，必须确认 `max_results` 足够，不能默认只读取第一个结果。修改 Cast 的 Transform 或形状后，需要按测试目的决定等待下一物理帧，或调用 `force_shapecast_update()` 做明确的立即刷新。

RayCast2D 检查一条细线，ShapeCast2D 检查带体积的扫掠区域。角色移动前的“能否通过”通常需要 ShapeCast 或实际 Body 移动结果，不能只用一条中心射线推断整个角色不会碰撞。

## 4. PhysicsDirectSpaceState2D：一次性直接查询

临时查询不必创建长期 Node，可以从当前世界取得直接空间状态：

```gdscript
var space_state := get_world_2d().direct_space_state
var query := PhysicsRayQueryParameters2D.create(origin, destination)
query.collision_mask = world_mask
query.collide_with_bodies = true
query.collide_with_areas = false
query.exclude = [self]
var result: Dictionary = space_state.intersect_ray(query)
```

常用参数资源包括：

- `PhysicsRayQueryParameters2D`：起点、终点、掩码、碰撞类别和排除对象；
- `PhysicsPointQueryParameters2D`：查询一个点附近的碰撞对象；
- `PhysicsShapeQueryParameters2D`：以一个 Shape2D 和 Transform 查询空间；
- `PhysicsDirectSpaceState2D.intersect_ray()`、`intersect_point()`、`intersect_shape()`：执行查询并返回结果。

Shape 查询示例：

```gdscript
var query := PhysicsShapeQueryParameters2D.new()
query.shape = _probe_shape
query.transform = candidate_transform
query.collision_mask = world_mask
query.collide_with_bodies = true
query.collide_with_areas = false
query.exclude = [self]
var hits: Array[Dictionary] = space_state.intersect_shape(query, 32)
```

查询必须明确 Mask、Body/Area 类型、排除对象、返回容量和边界条件。需要所有候选对象时，容量达到上限应扩容重查，不能把截断的结果当成完整事实。

## 5. 物理时序与事务一致性

RayCast2D、ShapeCast2D 和 Area2D 的持续结果按物理步更新。直接空间查询也应在物理安全上下文执行；不要在任意 UI 回调中修改 Body Transform 后，立即假定物理服务器已经同步。

本项目采用以下边界：

```text
输入请求
→ 领域/应用生成候选状态
→ 在物理安全入口查询并验证
→ 一次性提交权威状态
→ 更新 Node/代理与表现
```

如果查询对象的物理代理仍是旧位置，查询结果可能与候选状态不同。业务规则应使用同一份碰撞几何和候选 Transform 补充验证，并排除旧代理；不要先提交状态，查询失败后再回滚。

`Area2D.get_overlapping_bodies()` 等 API 读取的是已更新的重叠结果，不是刚移动对象后的即时事务查询。需要一次性检测时，直接构造对应 query；需要持续固定方向检测时，使用 RayCast2D 或 ShapeCast2D。

## 6. 如何选择

| 情况 | 选择 | 原因 |
| --- | --- | --- |
| 角色脚下、视线、激光 | RayCast2D | 持续、方向明确、通常只关心最近命中 |
| 前方宽度、冲刺、空间占用预检 | ShapeCast2D | 以形状而不是一条线检测 |
| 鼠标点选、一次范围查询 | DirectSpaceState | 不需要长期节点，查询参数可按次配置 |
| 需要持续管理目标进入/离开 | Area2D | 使用重叠和进入/离开信号 |
| 需要真正移动并产生碰撞响应 | CharacterBody2D/RigidBody2D | 查询不是移动行为的替代品 |

## 7. 当前验证与常见问题

`tests/physics/` 验证 RayCast2D、ShapeCast2D、Mask、启停和 `force_*_update()`；物理 Body 与 Area2D 的基础说明见 `docs/physics-body-area-workflow.md`。

- RayCast 命中错误对象：检查 `collision_mask`、`collide_with_bodies/areas` 和 parent exception。
- ShapeCast 漏掉对象：检查形状、方向、`max_results` 和是否把结果容量当成无限。
- 直接查询为空：确认查询在物理安全时机执行、Mask 正确、起终点/Transform 使用了正确坐标空间。
- 命中自己：把当前 Body 或其 RID 加入 `exclude`，或检查 RayCast2D 的 `exclude_parent`。
- 刚移动后结果旧：等待物理同步，或在明确的查询节点上使用 force update；不要用旧 Area 重叠列表做即时验证。

## 8. 官方参考

- [RayCast2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_raycast2d.html)
- [ShapeCast2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_shapecast2d.html)
- [PhysicsDirectSpaceState2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate2d.html)
- [PhysicsRayQueryParameters2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_physicsrayqueryparameters2d.html)
- [PhysicsShapeQueryParameters2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_physicsshapequeryparameters2d.html)
