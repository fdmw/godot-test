# 2D 动画与 Tween 工作流

本文说明 `AnimatedSprite2D`、`SpriteFrames`、`AnimationPlayer`、`AnimationTree` 和 `Tween` 的职责边界，以及在编辑器和脚本中如何选择它们。它们都能产生“动起来”的效果，但动画数据、状态切换和属性补间并不是同一层问题。

## 1. 先选择动画工具

| 需求 | 推荐工具 | 说明 |
| --- | --- | --- |
| 用多张图片做角色帧动画 | `AnimatedSprite2D` + `SpriteFrames` | 直接管理帧、速度、循环和播放状态 |
| 同时修改多个节点属性 | `AnimationPlayer` | 时间轴、轨道和关键帧是静态动画数据 |
| 根据状态机切换多个动画 | `AnimationTree` | 使用 AnimationPlayer 的动画，通过状态机或混合节点控制 |
| 运行时对一个或少量属性做一次补间 | `Tween` | 一次性运行时对象，适合位置、颜色、缩放等表现变化 |

一个对象可以组合这些工具，但应明确谁写入哪个属性。不要让 AnimationPlayer、Tween 和脚本在同一时段同时写 Sprite 的位置或颜色，否则结果取决于更新顺序，排错困难。

## 2. AnimatedSprite2D 与 SpriteFrames

编辑器中建立帧动画的基本流程：

1. 添加 `AnimatedSprite2D`。
2. 在 Inspector 的 `Sprite Frames` 属性中新建 `SpriteFrames` 资源。
3. 打开 SpriteFrames 面板，创建动画名称，例如 `idle`、`run`、`hit`。
4. 将图片或精灵表帧拖入动画轨道；规则精灵表可使用按网格切分的导入方式。
5. 设置动画速度和 Loop，选择默认动画和是否自动播放。
6. 保存场景或将 SpriteFrames 资源保存到项目目录，供需要的场景复用。

运行时只改变播放状态和当前帧，不在 `_ready()` 中重新创建静态 SpriteFrames：

```gdscript
@onready var _sprite: AnimatedSprite2D = %AnimatedSprite

func play_run() -> void:
	_sprite.play(&"run")

func stop_animation() -> void:
	_sprite.stop()

func pause_animation() -> void:
	_sprite.pause()
```

`play()` 是“开始或继续播放”，`pause()` 保留当前帧，`stop()` 停止并回到动画的起始状态。需要响应播放完成时连接 `animation_finished`，不要用固定秒数猜测最后一帧时刻。

## 3. AnimationPlayer 的时间轴

`AnimationPlayer` 适合编辑器中可视化制作的时间轴动画。常见配置步骤是：

1. 添加 `AnimationPlayer`；
2. 在 Animation 面板创建 Animation Library 和动画片段；
3. 添加属性、方法、音频或回调轨道；
4. 在时间轴插入关键帧，检查轨道绑定的节点路径是否稳定；
5. 设置循环、长度、播放速度和需要的 Autoplay；
6. 保存场景，确认动画数据没有只存在于未保存的编辑器状态中。

脚本通过动画名控制播放：

```gdscript
@onready var _player: AnimationPlayer = %Player

func play_motion() -> void:
	_player.play(&"motion")

func pause_motion() -> void:
	_player.pause()

func stop_motion() -> void:
	_player.stop()
```

动画完成时使用 `animation_finished`；动画被循环播放时不会按普通一次性动画的方式结束。跨场景复用动画时，检查轨道路径和场景实例边界，避免轨道指向外部场景的深层路径。

## 4. AnimationTree 与状态机

`AnimationTree` 不是另一套图片帧资源，而是 AnimationPlayer 动画之上的运行时控制层。基础结构通常是：

```text
角色场景
├── AnimationPlayer  ← 保存 idle/run/hit 等动画
└── AnimationTree    ← 选择、混合和切换动画状态
```

编辑器或运行时创建 `AnimationNodeStateMachine` 后，需要：

1. 将 `AnimationTree.tree_root` 设为状态机或其他 AnimationNode；
2. 设置 `anim_player` 路径，让 AnimationTree 找到 AnimationPlayer；
3. 设置 `active = true`；
4. 通过 `parameters/playback` 取得 `AnimationNodeStateMachinePlayback`；
5. 用 `start()` 或 `travel()` 切换状态。

```gdscript
var playback: AnimationNodeStateMachinePlayback

func go_to_run() -> void:
	playback.travel(&"run")
```

状态机适合“当前状态和转移条件”较多的角色表现。简单的播放/暂停/停止不必为了使用状态机而增加一层复杂性。状态机节点本身属于静态动画结构时应保存在场景或资源中；本项目的 `animation_tree/` 测试运行时创建它，是为了直接验证状态机运行时接口。

## 5. Tween 的一次性补间

Tween 适合运行时产生短暂的属性变化，例如按钮反馈、闪烁、移动到目标位置或颜色渐变。Tween 是一次性对象，通常通过节点的 `create_tween()` 创建：

```gdscript
var tween := create_tween()
tween.set_trans(Tween.TRANS_SINE)
tween.tween_property(_sprite, "position", target_position, 0.4)
```

多个补间可以串行或并行：

```gdscript
var tween := create_tween()
tween.set_parallel(true)
tween.tween_property(_sprite, "rotation", TAU, 0.8)
tween.tween_property(_sprite, "scale", Vector2.ONE, 0.8)
```

重新播放前先终止旧 Tween，避免两个 Tween 同时写同一属性：

```gdscript
if _tween != null and _tween.is_valid():
	_tween.kill()
_tween = create_tween()
```

需要顺序时使用 `chain()` 或连续的 `tween_*`；需要同时开始时使用 `set_parallel(true)`。完成通知连接 `finished`，场景销毁时不要继续持有已经失效的 Tween。

Tween 只负责补间，不负责业务状态。比如“角色已经受伤”应由明确的游戏逻辑提交，Tween 只表现受伤闪烁；不要通过 Tween 完成回调承担必须可靠结算的领域规则。

## 6. 时间、速度和暂停

- `AnimationPlayer.speed_scale` 和 `AnimatedSprite2D.speed_scale` 改变动画播放速度；
- Tween 的 duration 是补间时间，不等同于领域逻辑时间；
- `Timer` 的 timeout 适合现实时间或表现节奏；
- 节点暂停由 `process_mode` 和树的暂停状态共同影响；
- 需要全局暂停时，不要只停止某一个 Tween 或 AnimationPlayer 而留下其他表现继续播放。

本项目的 `animation/` 测试并列观察 AnimationPlayer、AnimatedSprite2D 和 Timer 的播放、暂停、停止与完成通知；`pause_process/` 文档将继续说明暂停树和 process_mode 的边界。

## 7. 常见问题

- AnimatedSprite2D 没有画面：检查 SpriteFrames 是否有当前动画和帧，动画名是否使用 `StringName`，节点是否可见。
- AnimationPlayer 播放但属性不变：检查 AnimationTree 是否 active、轨道路径是否正确，以及是否有其他对象覆盖同一属性。
- AnimationTree 状态切换无效：检查 AnimationPlayer 路径、状态名、转移连接和 playback 是否已经取得。
- Tween 重播后速度或结果异常：检查是否仍有旧 Tween 写同一属性，并在重置时 kill 旧实例。
- 动画完成回调没有触发：确认动画是否循环、是否真的播放到末尾，以及信号是否只连接了一次。
- 运行时创建动画结构后首帧异常：先完成资源和节点配置，再启用 AnimationTree；必要时在依赖 SceneTree 的时点初始化。

## 8. 当前验证目录与官方参考

- `tests/animation/`：AnimationPlayer、AnimatedSprite2D、Timer 的播放控制。
- `tests/animation_tree/`：AnimationTree 状态机的创建、激活和状态切换。
- `tests/tween/`：Tween 缓动、串行/并行、停止和重建。
- [AnimatedSprite2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html)
- [AnimationPlayer — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_animationplayer.html)
- [使用 AnimationTree — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html)
- [Tween — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_tween.html)
