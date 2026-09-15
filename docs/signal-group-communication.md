# Signal、Group、父子节点通信与 Autoload

本文说明 Godot 中几种常见的节点通信方式，重点回答“谁发起行为、谁拥有状态、谁只需要知道事情已经发生”。通信方式选得合适，场景可以保持局部、可复用，也更容易在切换和释放时清理关系。

本文不把所有通信都归结为全局事件。项目的基本原则是：明确的命令使用直接函数调用，已经发生的状态变化使用 Signal，分类和批量处理使用 Group，只有确实具有跨场景全局生命周期的服务才考虑 Autoload。

## 1. 先区分命令和事件

通信前先问两个问题：

1. 这次调用是要求对方现在执行一个行为，还是通知对方某件事已经发生？
2. 接收者是一个明确对象，还是一组按标签分类的对象？

可以用下面的简化模型选择：

```text
明确对象 + 请求执行行为       → 直接函数调用
一个对象 + 状态变化通知       → Signal
多个对象 + 分类/批量操作       → Group
跨场景 + 全局生命周期服务      → Autoload（谨慎）
静态定义数据 + 多个实例读取    → Resource（运行时只读）
```

Signal 和 Group 都不是为了隐藏所有依赖而存在。调用关系越明确，越应该通过类型化引用和直接函数调用表达；只有确实需要解耦或批量处理时才引入间接关系。

## 2. Signal：通知已经发生的事件

Signal 是对象发出的事件通知。发送者只声明事件和参数，不需要知道所有监听者；监听者连接到 Signal 后，在事件发生时执行自己的回调。这适合“按钮已按下”“生命值已变化”“对象已进入区域”等事实。

### 内置信号

节点和资源已经提供了大量内置信号，优先使用它们而不是自己轮询状态：

```gdscript
extends Control

@onready var _button: Button = %ActionButton
@onready var _status: Label = %Status

func _ready() -> void:
	_button.pressed.connect(_on_action_pressed)

func _on_action_pressed() -> void:
	_status.text = "按钮已触发"
```

这里的按钮是事件发送者，当前场景是监听者。连接通常在 `_ready()` 中完成，因为此时场景内部节点已经进入树并准备好。

### 自定义 Signal

自定义 Signal 的名字应描述已经发生的事实，参数要表达监听者需要的最小信息：

```gdscript
extends Node2D

signal item_collected(item_id: String, amount: int)

func collect(item_id: String, amount: int) -> void:
	item_collected.emit(item_id, amount)
```

Signal 负责通知，不负责代替 `collect()` 这样的行为入口。调用方应直接调用 `collect()`；对象完成状态提交后，再发出 `item_collected`，让 UI、音效或统计模块更新。

### 代码连接和编辑器连接

编辑器连接适合场景结构固定、连接关系属于该 `.tscn` 的情况。选中发送节点，在 Signals 面板选择信号和接收节点，连接关系会保存到场景。

代码连接适合动态实例化的节点、按运行时条件建立的关系，或希望所有连接都在脚本中可见的场景：

```gdscript
func _ready() -> void:
	_source.item_dropped.connect(_on_item_dropped)

func _on_item_dropped(item_text: String) -> void:
	_status.text = "收到：" + item_text
```

本项目优先使用 Godot 4 的一等 Signal 和 Callable 写法，例如 `pressed.connect(_on_pressed)`，不使用字符串 Signal 名和字符串函数名建立普通业务连接。这样节点名、Signal 名和回调签名更容易被编辑器检查。

### 参数绑定

循环创建多个相似控件时，可以用 `Callable.bind()` 补充固定参数：

```gdscript
for index: int in range(_buttons.size()):
	_buttons[index].pressed.connect(_on_button_pressed.bind(index))

func _on_button_pressed(index: int) -> void:
	_status.text = "按钮索引：%d" % index
```

Signal 发出的参数会先传给回调，`bind()` 添加的参数随后传入。绑定的 Callable 仍然是明确的函数引用，不应通过拼接字符串决定要调用的方法。

### 防止重复连接和解除连接

同一个 Signal 不能无意中重复连接到同一个 Callable。节点可能重新进入树、重新绑定目标或重复执行初始化时，先检查连接状态：

```gdscript
if not _source.item_dropped.is_connected(_on_item_dropped):
	_source.item_dropped.connect(_on_item_dropped)
```

关系结束时解除连接：

```gdscript
if _source.item_dropped.is_connected(_on_item_dropped):
	_source.item_dropped.disconnect(_on_item_dropped)
```

如果连接目标对象被释放，Godot 会移除该连接；但外部观察关系、异步任务和自定义集合仍可能需要由拥有者主动清理。只在确实只需要一次通知时使用一次性连接，例如 `signal.connect(callback, CONNECT_ONE_SHOT)`。

### Signal 的时序边界

Godot 默认同步调用连接的回调。发送者执行 `emit()` 时，监听回调可能立即运行，因此：

- 先完成权威状态的完整提交，再发出对外状态通知；
- 不要在事务尚未完成时发 Signal，让回调重入当前事务；
- 回调产生的新行为请求交给统一入口按明确顺序处理；
- 不要依赖监听者的注册顺序产生核心逻辑结果。

如果通知包含多个字段，应保证它们来自同一份已提交状态，而不是一部分更新前、一部分更新后的临时值。

## 3. 父子节点通信

父子关系本身已经是一种明确的所有权和通信边界。父节点通常负责协调，子节点负责自己的局部行为。

### 父节点调用子节点

当父节点明确拥有子节点，并且子节点接口是场景契约的一部分时，父节点可以保存类型化引用并直接调用：

```gdscript
@onready var _health_bar: ProgressBar = %HealthBar

func set_health(value: float) -> void:
	_health_bar.value = value
```

这表达了一个明确命令：父节点要求自己的健康条显示某个值。不要为了调用一个明确的子节点方法而广播 Signal 或使用 Group。

### 子节点通知父节点

子节点需要让父节点知道状态变化时，优先定义 Signal，由父节点连接：

```gdscript
# 子节点
signal finished(result: int)

func complete(result: int) -> void:
	finished.emit(result)
```

```gdscript
# 父节点
func _ready() -> void:
	_worker.finished.connect(_on_worker_finished)

func _on_worker_finished(result: int) -> void:
	_apply_result(result)
```

这样子节点不必依赖父节点的具体脚本类型，也不必通过 `get_parent().get_parent()` 查找业务对象。

### 兄弟节点通信

兄弟节点之间不要互相持有很多深层路径。通常由共同父节点协调：

```text
子节点 A 发出状态 Signal
        ↓
共同父节点决定规则并调用
        ↓
子节点 B 执行明确命令
```

如果两个节点实际上组成了一个独立功能，应将它们封装进一个场景，由场景根节点提供更清晰的接口，而不是让外部同时了解所有内部节点。

### 外部依赖注入

可复用场景需要外部对象时，由拥有者显式传入并保存类型化引用：

```gdscript
var _inventory: Inventory

func setup(inventory: Inventory) -> void:
	_inventory = inventory
```

这比在场景内部遍历 SceneTree、按 Group 找服务或依赖固定绝对路径更容易测试和替换。必要依赖应在统一初始化入口检查，不要等到某个按钮点击后才因 `null` 失败。

## 4. Group：分类和批量处理

Group 类似标签。一个节点可以属于多个 Group，Group 本身不改变节点父子关系，也不提供业务所有权。

### 编辑器加入 Group

选中节点，在 Node 面板的 Groups 标签中加入 Group 名称。适合场景文件中固定的分类，例如场景内所有可交互对象都属于 `interactables`。

Group 名称建议使用 `snake_case`，并集中定义为 `StringName` 常量，避免项目中出现多个拼写：

```gdscript
const VALIDATION_GROUP: StringName = &"validation_items"
```

### 运行时管理成员

脚本可以在运行时加入、移除和检查 Group：

```gdscript
add_to_group(VALIDATION_GROUP)

if is_in_group(VALIDATION_GROUP):
	remove_from_group(VALIDATION_GROUP)
```

动态对象被释放或离开树后，不应继续作为有效业务成员使用。节点生命周期通常会管理 Group 成员，但业务集合和缓存仍要由拥有者同步清理。

### 查询成员并类型化处理

```gdscript
for node: Node in get_tree().get_nodes_in_group(VALIDATION_GROUP):
	var item := node as ColorRect
	if item == null:
		continue
	item.color = Color("70c8ff")
```

`get_nodes_in_group()` 返回当前 SceneTree 中属于该 Group 的节点集合。返回顺序不应被当作稳定的业务顺序；如果处理结果受顺序影响，应先转换为明确类型，再按稳定业务 ID 或优先级排序。

### `call_group()` 的使用边界

`SceneTree.call_group()` 可以对所有成员调用同名方法，也可以使用 `notify_group()` 发送通知。它适合简单的、与顺序无关的批量操作，例如让多个表现节点刷新一次。

但 `call_group()` 接收方法名字符串，核心业务不应依赖它实现字符串式分派、服务定位或确定性结算。需要参数类型、返回结果、错误处理或稳定顺序时，使用 `get_nodes_in_group()` 后进行类型化迭代和直接函数调用：

```gdscript
for node: Node in get_tree().get_nodes_in_group(VALIDATION_GROUP):
	var item := node as ValidationItem
	if item != null:
		item.refresh_view()
```

### Group 不是服务定位器

下面的做法会把 Group 变成隐式依赖，不推荐：

```gdscript
# 不要用 Group 找唯一的核心服务。
var manager := get_tree().get_first_node_in_group("game_manager")
```

Group 可以回答“哪些节点被分类为 X”，不能可靠表达“哪个对象拥有这个服务”“调用失败怎么办”或“多个候选如何选”。核心依赖由拥有者创建或显式注入；Group 只承担分类、查询和合理的批量操作。

本项目的 [节点分组测试](../tests/groups/groups_test.tscn) 使用两个 `ColorRect` 验证固定分组、动态加入/移除、成员查询和批量高亮，没有把 Group 当成服务定位或业务分派机制。

## 5. Autoload：少量全局生命周期服务

Autoload 在 Project Settings → Globals → Autoload 中配置。自动加载脚本时，Godot 会创建一个 Node 并把它放到根 Viewport 下；它会在场景切换时继续存在，因此适合跨场景仍然需要的服务。

Autoload 的“全局可访问”是方便，不等于真正的语言级 Singleton，也不等于应该把所有状态放进去。项目需要明确服务的所有权、可变状态和关闭方式。

### 适合考虑 Autoload 的情况

只有同时满足“确实跨场景”“生命周期由整个应用拥有”“没有更局部的拥有者”时才考虑，例如：

- 存档读写服务；
- 场景切换和过渡服务；
- 跨场景持续播放的音频服务；
- 少量只读全局配置或平台适配服务。

即使使用 Autoload，也应提供类型化接口，不让调用方任意修改内部状态。Autoload 可以拥有服务，不应成为任意对象的注册表或 Service Locator。

### 不适合使用 Autoload 的情况

以下内容应优先由当前场景、流程或会话拥有：

- 当前关卡的敌人列表和交互状态；
- 一个测试场景的按钮、动态实例和临时 Resource；
- 只被一个场景使用的 UI、Timer 或 AudioStreamPlayer；
- 为了少写一段节点路径而提升到全局的局部依赖。

不要使用 Autoload 让测试之间共享运行时状态。测试切换时应释放当前测试并重新实例化目标场景。

### 本项目的选择

当前 `project.godot` 没有配置 Autoload。验证台由 `test_hub` 持有当前测试实例，测试场景持有自己的控件、资源和动态对象；这与本项目“测试相互隔离、根入口只负责切换”的目标一致。

## 6. Resource 共享数据与通信的区别

Resource 可以作为多个场景读取的静态定义数据，例如角色配置、物品定义或本地化资源。它不是自动的事件总线，也不应被当作多个实例共同写入的全局状态。

推荐分工：

```text
Resource       → 共享的只读内容定义
运行时对象      → 某个实例的可变状态
直接函数调用    → 对明确对象发起命令
Signal          → 通知状态变化
Group           → 查询和批量分类
Autoload        → 少量全局服务
```

如果需要发送事件，不要通过修改共享 Resource 的字段再让其他对象轮询；使用 Signal 或明确的应用接口。确实需要实例独立 Resource 时，显式复制并确认嵌套容器的共享关系。

## 7. 通信方式选择示例

| 需求 | 推荐方式 | 原因 |
| --- | --- | --- |
| 父节点让自己的按钮刷新文字 | 类型化引用 + 直接调用 | 目标明确，命令关系清楚 |
| 子节点完成任务通知父节点 | 子节点 Signal | 子节点不依赖父节点具体实现 |
| Area2D 通知收集系统发生碰撞 | 内置信号 | 碰撞已经发生，接收者可独立响应 |
| 找出当前场景所有可交互对象 | Group 查询 | 这是分类和查询需求 |
| 让一批表现节点刷新 | Group 查询后类型化调用 | 适合批量操作，不引入唯一服务依赖 |
| 保存服务跨场景存在 | Autoload 或显式应用拥有者 | 生命周期确实跨场景 |
| 两个实例共享物品定义 | 只读 Resource | 这是内容数据，不是运行时通信 |
| 唯一的战斗系统处理攻击请求 | 显式类型化接口 | 结果和所有权需要确定，不能靠广播猜测 |

如果一条通信链难以说明“谁拥有状态、谁发起请求、谁只接收通知”，先重新划分场景和接口，再增加通信机制。

## 8. 通信问题排查

### Signal 没有触发

1. 确认发送者和接收者都是当前运行中的实例，而不是编辑器里的另一个场景标签页。
2. 检查连接是否执行，连接时节点是否已经有效。
3. 检查 Signal 名称和回调参数签名。
4. 检查发送路径是否真的调用了 `.emit()`，以及是否有提前返回。
5. 在 Debugger 中断点观察连接和发送位置；必要时检查 `is_connected()`。

### Signal 触发多次

检查 `_ready()`、重新入树逻辑、动态绑定和编辑器持久连接是否重复建立。代码连接前用 `is_connected()`，同时确认场景文件没有保存一份不再需要的重复连接。

### Group 查询不到节点

1. 检查 Group 名称拼写，优先使用集中定义的 `StringName`。
2. 确认节点已经进入当前 SceneTree，动态加入是否真的执行。
3. 确认查询的是当前场景树，而不是已经排队释放的旧节点。
4. 检查是否在错误的场景切换阶段查询，或在节点加入 Group 前就执行了查询。
5. 不要依赖查询结果顺序作为业务规则。

### Autoload 造成状态串场

检查是否把当前场景状态、测试临时数据或节点引用写进了全局对象。将状态移回实际拥有者，通过参数、返回值或 Signal 传递必要信息；场景退出时解除 Autoload 对短生命周期对象的引用。

## 9. 当前项目的验证覆盖

项目中各测试普遍使用内置信号和类型化 Callable 连接按钮、输入、物理、动画、导航和生命周期事件；这验证了“行为直接调用、事件使用 Signal”的基础模式。

当前专题重点对应：

- `tests/groups/`：Group 的编辑器固定成员、动态加入/移除、查询和批量处理；
- `tests/drag_drop/`：自定义 `drag_started`、`item_dropped` Signal 及带参数的事件通知；
- `tests/scene_lifecycle/`：`tree_entered`、`tree_exiting` 和 `tree_exited` 生命周期 Signal；
- `test_hub.gd`：入口通过直接函数调用选择、释放和加载当前测试，不依赖全局通信；
- `project.godot`：当前没有 Autoload 配置，测试之间保持运行时隔离。

## 10. 当前未覆盖的扩展

本专题覆盖常用本地通信边界，但以下内容仍可按项目需要补充验证：

- Signal 连接标志、一次性连接和引用计数连接的详细组合；
- 跨场景应用接口与 Autoload 服务的启动、关闭和场景切换竞态；
- 更复杂的事件聚合、请求队列和异步 Signal；
- 大规模 Group 查询的性能和稳定排序策略。

## 官方参考

- [Using signals — Godot 4.7](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html)
- [Signal — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_signal.html)
- [Groups — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/groups.html)
- [Singletons (Autoload) — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/singletons_autoload.html)
