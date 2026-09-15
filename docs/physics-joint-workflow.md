# Physics Joint2D 工作流

本文说明 2D 物理关节的基本用途和配置方式，重点以 `PinJoint2D`、`DampedSpringJoint2D` 为例。关节连接的是物理 Body，不是普通 Node2D 的父子 Transform。

## 1. 关节解决什么问题

Physics Joint2D 为两个 `PhysicsBody2D` 增加约束，让物理引擎计算它们之间的相对运动：

| 节点 | 主要效果 | 典型用途 |
| --- | --- | --- |
| `PinJoint2D` | 两个 Body 围绕一个锚点连接 | 摆臂、链节、转轴 |
| `DampedSpringJoint2D` | 两个 Body 之间具有弹簧长度、刚度和阻尼 | 弹簧、拉绳、柔性连接 |
| `GrooveJoint2D` | 一个 Body 沿槽方向运动 | 导轨、滑块 |
| `DampedSpringJoint2D` 与其他关节组合 | 形成更复杂约束 | 需要实测稳定性的机械结构 |

关节约束只影响物理模拟，不会自动绘制连接线、生成父子层级或替代碰撞形状。两个 Body 仍需要各自有效的 `CollisionShape2D`，并按需要设置碰撞层和掩码。

## 2. 编辑器配置流程

1. 在场景中创建两个 `RigidBody2D`，分别添加碰撞形状和视觉节点。
2. 在两个 Body 的中间添加 `PinJoint2D` 或 `DampedSpringJoint2D`。
3. 设置 Joint 的 `Node A` 和 `Node B`，指向两个物理 Body。
4. 调整 Joint 的位置，使锚点位于预期的连接点。
5. 对弹簧关节设置 `length`、`rest_length`、`stiffness` 和 `damping`。
6. 运行时施加冲量，观察约束、碰撞和阻尼响应。

`Node A`、`Node B` 是物理连接关系；它们不是关节节点的普通子节点路径。移动 Joint 的位置会改变约束锚点，但不会改变 Body 的初始位置。

## 3. 参数如何影响结果

对 `DampedSpringJoint2D`：

- `length` 表示约束的长度范围；
- `rest_length` 表示弹簧希望恢复的长度；
- `stiffness` 越大，恢复到目标长度的趋势越强；
- `damping` 越大，振荡衰减越快；
- 刚度过高、质量差异过大或碰撞形状重叠，可能造成不稳定，需要降低参数并逐步验证。

PinJoint2D 更适合表达旋转铰接关系。它不表示固定距离的刚性焊接；需要限制旋转或组合多个约束时，应根据物理目标选择其他 Joint2D，而不是在脚本中每帧强行修正位置。

## 4. 运行时启停与物理时序

关节的启停属于物理对象状态变化。修改 `disabled` 时遵守引擎时序，必要时使用 `set_deferred()`：

```gdscript
@onready var _pin: PinJoint2D = %PinJoint

func set_pin_enabled(enabled: bool) -> void:
	_pin.set_deferred("disabled", not enabled)
```

不要在同一物理步骤中先直接拆关节、再依赖旧约束结果回滚领域状态。测试中的重置操作应同时重置两个 Body 的位置、线速度、角速度和 sleeping 状态，否则上一次冲量会影响下一次观察。

施加冲量使用 Body 的物理 API：

```gdscript
func apply_test_impulse(body: RigidBody2D) -> void:
	body.apply_central_impulse(Vector2(120.0, -180.0))
```

不要用 Tween、AnimationPlayer 或每帧设置 Transform 来替代关节约束；这会让多个系统同时写入物理 Body，结果无法代表真实关节响应。

## 5. 碰撞与关节的边界

关节描述 Body 之间的运动约束，碰撞形状描述空间占用。启用关节并不保证两个 Body 不会互相碰撞；按测试目标配置 `disable_collision` 或双方碰撞层，确认你观察的是约束效果还是碰撞效果。

```text
CollisionShape2D → Body 占用空间
Joint2D → Body 相对运动约束
RigidBody2D → 物理引擎推进速度和位置
```

## 6. 当前验证与常见问题

`tests/physics_extra/` 固定了两个 RigidBody2D、PinJoint2D 和 DampedSpringJoint2D，通过复选框切换关节、施加冲量和重置刚体。

- 关节不起作用：检查 Node A/Node B、Joint 位置、Body 是否为 PhysicsBody2D，以及是否已经 disabled。
- 物体迅速发散：检查碰撞形状初始重叠、刚度/阻尼、质量和多个系统是否同时写 Transform。
- 启停时报物理时序错误：使用 `set_deferred("disabled", ...)`。
- 重置后运动不同：同时清理线速度、角速度、sleeping 和上一次的约束状态。
- 看不到“连接线”：Joint2D 默认是物理约束，不负责视觉绘制；需要单独添加 Line2D 或调试表现。

## 7. 官方参考

- [PinJoint2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_pinjoint2d.html)
- [DampedSpringJoint2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_dampedspringjoint2d.html)
- [Physics introduction — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/physics/physics_introduction.html)
