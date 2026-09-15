# Timer、暂停与 process_mode 工作流

本文说明 `Timer`、`SceneTree.create_timer()`、SceneTree 暂停和节点 `process_mode` 的关系。Timer 适合现实时间和表现调度；项目中的攻击 CD、Buff 持续时间、AI 逻辑周期等领域规则默认由领域逻辑时间管理。

## 1. Timer 的编辑器流程

需要可观察、可配置的计时器时：

1. 在目标场景中添加 `Timer`；
2. 设置 `wait_time`、`one_shot`、`autostart` 和 `process_callback`；
3. 连接 `timeout` Signal；
4. 由脚本调用 `start()`、`stop()`、`pause()` 或修改 `paused`；
5. 在场景切换或测试重置时明确停止或重置计时器。

```gdscript
@onready var _timer: Timer = %Timer

func _ready() -> void:
	_timer.timeout.connect(_on_timeout)

func start_hint() -> void:
	_timer.start()

func _on_timeout() -> void:
	show_hint()
```

`one_shot` 为 true 时触发一次后停止；false 时按间隔重复触发。`autostart` 适合场景进入后就开始的表现计时，但如果需要受控的初始化或重置，显式调用 `start()` 更容易追踪。

## 2. Timer 与现实时间

Timer 的计时受节点处理模式和引擎时间缩放影响，并非精确的领域调度器：

- `process_callback` 可选择按物理帧或空闲帧更新；
- `Engine.time_scale` 会影响常规 Timer 的经过速度；
- 暂停状态可能使 Timer 停止处理；
- 帧率、处理时机和场景切换会影响回调何时到达。

`SceneTree.create_timer()` 适合一次性的短暂延迟，不需要额外保留 Timer 节点：

```gdscript
func show_message_temporarily() -> void:
	show_message()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():
		return
	hide_message()
```

使用 `await` 后必须重新确认 Node、场景和绑定关系仍然有效。跨帧延迟不能用来掩盖依赖初始化顺序，也不能替代必须按逻辑刻度结算的领域规则。

## 3. SceneTree 暂停与 process_mode

`get_tree().paused = true` 会暂停默认处理模式的节点。节点的 `process_mode` 决定它在暂停树中的行为，常见语义是：

| 模式 | 暂停时行为 | 用途 |
| --- | --- | --- |
| Inherit | 继承父节点/场景树语义 | 普通游戏对象 |
| Pausable | 场景暂停时停止 | 世界、角色、普通 Timer |
| When Paused | 仅暂停时处理 | 暂停菜单、恢复按钮 |
| Always | 无论是否暂停都处理 | 必要的全局提示或监控 |
| Disabled | 不处理 | 明确停用的节点 |

暂停菜单通常需要位于一个在暂停时仍处理的分支中；只把按钮设为可处理，却让父节点或弹窗所在分支被禁用，仍可能无法接收输入。修改 `process_mode` 后要同时观察 UI 输入、Timer、AnimationPlayer 和 Tween 是否符合预期。

## 4. 暂停与输入/表现

暂停不是简单地把所有节点的 `visible` 设为 false：

- UI 是否可操作由 Control 所在分支的 process_mode 和输入传播决定；
- AnimationPlayer、AnimatedSprite2D、Tween 和 Timer 是否继续运行由各自处理模式及暂停设置决定；
- 物理世界暂停时，不应继续提交普通游戏对象的移动和物理事务；
- Always 节点若修改世界状态，会破坏暂停的预期边界，应限制职责。

暂停按钮本身由可在暂停时处理的 UI 分支拥有，并在切换时显式更新按钮文本、提示和必要的表现。不要在每个回调内部写“如果暂停就 return”来代替正确的 process_mode。

## 5. Timer 与领域逻辑时间的边界

项目约定如下：

```text
现实时间 / 表现延迟 / UI 倒计时 → Timer 或 create_timer()
攻击 CD / Buff 持续时间 / AI 逻辑周期 → 领域定义的逻辑时间
```

领域逻辑时间应由明确所有者推进，并按固定顺序处理请求和结算。Timer 可以通知“表现该更新了”，但不能成为权威规则状态，也不能通过 `await create_timer()` 把原子事务拆成跨帧流程。

## 6. 当前验证与常见问题

`tests/pause_process/` 使用两个 Timer 和 AnimationPlayer 对比可暂停与始终处理的节点；切换测试场景时在 `_exit_tree()` 恢复 `SceneTree.paused`，避免暂停状态泄漏。

- Timer 不触发：检查 `wait_time`、`autostart`/`start()`、节点是否在树中、处理模式和是否已 paused。
- 暂停菜单不能点击：检查 UI 分支 process_mode、Control 焦点、Mouse Filter 和输入是否被其他节点消费。
- 暂停后仍有世界动画：检查 AnimationPlayer、Tween、粒子和父节点的 process_mode。
- `await create_timer()` 返回后节点报错：确认场景没有被切换，目标 Node 仍有效，并复核当前任务代次。
- 计时规则不稳定：不要继续增加 Timer 精度，改用领域逻辑时间并明确推进顺序。
- 切换测试后项目仍暂停：在测试退出、重置和主入口切换处恢复全局暂停状态。

## 7. 官方参考

- [Timer — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_timer.html)
- [Node process mode — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [SceneTree — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)
- [Pausing games and process mode — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/pausing_games.html)
