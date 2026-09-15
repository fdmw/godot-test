# Scene、Node、SceneTree 与 PackedScene 工作流

本文说明 Godot 中场景结构和运行时节点的关系，重点放在编辑器里的组织方式、运行时的实例化与释放、生命周期回调，以及排查场景没有按预期工作的顺序。

本文不是 Node API 目录，也不要求为每一种节点分别建立说明。理解这套工作模型后，Sprite2D、Control、PhysicsBody2D 等节点都可以沿用相同的场景和生命周期思路。

## 1. 四个核心概念

### Node：运行时对象

`Node` 是运行时存在于 SceneTree 中的对象基类。它提供名称、父子关系、生命周期、Signal、元数据和处理回调等能力；具体功能由派生类型提供：

- `Node2D` 增加 2D Transform 和 CanvasItem 能力。
- `Control` 使用 anchors、offsets 和 Container 完成 UI 布局。
- `Area2D`、`CharacterBody2D`、`RigidBody2D` 等节点接入物理系统。

一个节点是否应该存在，取决于它是否需要 SceneTree 生命周期、Transform、渲染、物理、输入等 Node 能力。纯数据或短生命周期的纯逻辑对象不必为了放进场景树而创建 Node。

### Scene：可保存的节点结构

Scene 是一棵可保存、可复用的节点树。编辑器中的 Scene 面板展示这棵树，保存后通常写入 `.tscn` 文件；场景文件还会记录脚本、资源引用、节点属性和部分实例关系。

Scene 不是运行时对象本身。打开或保存 `.tscn` 不等于已经把它加入当前运行中的 SceneTree。

### PackedScene：场景的可实例化资源

`.tscn` 在运行时通过 `PackedScene` 表示。加载 `PackedScene` 只得到一个资源，调用 `instantiate()` 才会创建一棵新的运行时节点树；创建出的根节点仍然不在 SceneTree 中，必须通过 `add_child()` 或其他明确的父节点关系加入树。

因此应区分三个时点：

```text
加载 .tscn → 得到 PackedScene 资源
instantiate() → 创建运行时 Node 树，但尚未进入 SceneTree
add_child() → 进入 SceneTree，开始生命周期和引擎服务
```

每次 `instantiate()` 都是独立的节点实例。实例之间可以共享只读内容资源，但不应通过修改共享 Resource 保存某个实例的可变状态。

### SceneTree：管理活动节点

SceneTree 保存当前运行中的节点层级，并负责将节点接入生命周期、处理帧回调、管理当前场景和提供运行时树的观察入口。

编辑器 Scene 面板看到的是保存的结构；运行项目后，Debugger 的 Remote SceneTree 看到的是当前实例化后的运行时结构。两者可能不同，例如运行时动态生成的节点只会出现在 Remote SceneTree 中。

## 2. 在编辑器中组织场景

一个可复用场景通常从一个明确的根节点开始：

1. 在 Scene 面板创建合适的根节点，先决定它需要哪种能力。
2. 添加子节点，设置静态层级、布局、碰撞几何、初始 Transform、默认属性和基础资源。
3. 为需要行为的节点附加脚本；脚本只处理运行时行为，不在 `_ready()` 里重复搭建静态界面。
4. 保存为独立 `.tscn`，使用有意义且稳定的文件名。
5. 在其他场景中实例化这个场景；实例节点保留场景边界，只有确实需要修改内部结构时才启用 Editable Children。

### 如何决定是否拆成独立 Scene

适合拆分的内容通常具有以下特征：

- 会在多个位置复用；
- 有自己的节点层级和生命周期；
- 需要单独运行或单独调试；
- 有独立的资源、碰撞几何或交互行为；
- 主场景继续增长后已经难以定位和维护。

不必为了拆分而拆分。只服务于一个父场景、结构非常简单且没有独立生命周期的节点，可以继续留在父场景中。

### 父子关系与 owner

父节点决定运行时的树关系和许多传播行为，例如 `Node2D` 子节点会受到父节点 Transform 影响。`owner` 是场景编辑和保存关系中的归属信息，不等同于 `get_parent()`，也不是运行时服务定位机制。

编辑器把分支保存为独立 Scene 时，会依据 owner 判断哪些节点属于要保存的场景。运行时代码建立父子关系时，应明确调用 `add_child()`，不要把设置 owner 当成“加入场景树”的替代操作。

## 3. 进入 SceneTree 后的生命周期

以下是适合日常开发的生命周期视图：

```text
instantiate / new
    │       （对象已创建，但尚未在树中）
    ▼
add_child
    ▼
_enter_tree / NOTIFICATION_ENTER_TREE
    ▼
子节点完成进入树并准备就绪
    ▼
_ready / NOTIFICATION_READY
    ▼
_process 或 _physics_process（仅在启用且需要时）
    │
    └── queue_free
            ▼
        退出阶段：_exit_tree / tree_exiting / NOTIFICATION_EXIT_TREE
            ▼
        tree_exited
```

这里的图用于理解阶段，不应把所有 Notification、Signal 和脚本回调之间的每一个细粒度相对顺序当作业务协议。需要依赖某个时序时，应使用对应的 Signal 或明确的初始化入口，并在验证场景中观察实际结果。

### `_enter_tree()`

节点进入 SceneTree 时调用。此时节点已经有父节点并处于树中，但同一分支中的其他节点不一定都已经执行 `_ready()`。

适合：

- 建立与树生命周期相同的观察关系；
- 记录进入树事件；
- 做不依赖子节点 ready 状态的早期初始化。

不适合：

- 假设所有兄弟节点都已完成初始化；
- 把静态 UI 或静态测试对象在这里重新创建。

### `_ready()`

节点所在分支已经进入树，并且子节点已完成自己的 ready 阶段后，节点执行 `_ready()`。这是最常用的场景初始化入口，适合取得稳定的内部节点引用、连接 Signal 和开始必要的运行时行为。

`@onready` 引用也应在节点进入树、依赖节点已准备好后使用。若一个节点可能被移出再重新加入树，不要把“曾经 ready 过”误认为“当前绑定始终有效”；重新进入的初始化策略应明确设计，必要时使用 `request_ready()` 或单独的绑定函数。

### `_process(delta)` 与 `_physics_process(delta)`

这两个回调都属于持续帧回调：前者随渲染帧执行，后者按物理帧执行。它们适合连续表现、输入采样、插值和引擎交互，不应被用来每帧自动推进本项目的离散领域状态。

如果节点不需要持续更新，不要保留一个长期运行、只在回调开头 `return` 的空循环。应在需要时用 `set_process()` 或 `set_physics_process()` 明确启停，并让启停与节点生命周期一致。

### `_exit_tree()` 与 tree 信号

节点离开 SceneTree 时执行退出阶段。`tree_exiting` 适合观察或处理即将离开的时点，`tree_exited` 表示已经完成退出。`_exit_tree()` 适合解除外部连接、停止观察和清理与树绑定的运行时关系。

退出时应检查跨帧回调、异步任务和外部引用，避免它们在场景已经切换后继续访问旧节点。`await` 返回后也不能假设发起者、目标 Node 或 SceneTree 仍然有效。

## 4. PackedScene 的加载与实例化

### 资源路径选择

固定且属于场景契约的资源可以使用 `preload()`；需要运行时决定路径、允许加载失败或用于验证资源加载行为时使用 `load()` / `ResourceLoader`。路径应保持明确，不依赖当前场景的相对路径猜测。

```gdscript
const ITEM_SCENE: PackedScene = preload("res://tests/scene_resource/spawned_item.tscn")

func spawn_item(parent: Node, position: Vector2) -> Node2D:
	var item := ITEM_SCENE.instantiate() as Node2D
	if item == null:
		return null
	item.position = position
	parent.add_child(item)
	return item
```

示例表达的顺序很重要：能够在入树前确定的配置先完成，再 `add_child()`。这样可以避免节点在初始化回调中先以不完整状态运行。若某个配置必须依赖 SceneTree 或物理世界，则放到进入树后的明确初始化阶段。

项目中 `scene_resource` 测试使用 `load()` 验证可失败的资源加载；实例化后先设置位置，再把节点加入 `SpawnRoot`，随后调用测试对象的 `configure()` 验证运行时配置。正式项目可以把固定场景改为 `preload()`，但仍需保留加载失败和根节点类型检查等边界意识。

### 实例的父节点和生命周期

动态实例应放入职责明确的运行时容器，例如对象生成容器、特效容器或当前关卡容器。父节点负责持有实例的树关系；释放父节点时，其子节点也会随之释放。

不要把动态对象随意挂在验证台根节点或其他不相关的节点下，否则场景切换和批量清理时容易留下隐含依赖。

## 5. 释放、重置与场景切换

### `queue_free()` 是默认释放方式

对于已经在 SceneTree 中的 Node，通常调用 `queue_free()` 请求安全销毁。它不是同步的 `free()`：调用返回后，对象进入待销毁状态，后续代码不得把它当作仍可交互对象使用；实际退出会在引擎安全时点完成。

```gdscript
func clear_spawned_items(root: Node) -> void:
	for child: Node in root.get_children():
		child.queue_free()
```

调用后，如果还需要保存引用，应在下一次使用前检查 `is_instance_valid()`，并按需要检查 `is_queued_for_deletion()` 和 `is_inside_tree()`。节点待销毁后应从新的交互集合、输入处理和异步任务中排除。

`free()` 会立即销毁对象，只有在对象尚未加入树或当前流程已经确认同步销毁安全时才考虑使用。它不是为了绕过不清楚的生命周期问题而使用的快捷方式。

### 验证台的重置流程

本项目的 `test_hub.gd` 采用以下流程切换测试：

```text
释放当前测试 → 加载目标 PackedScene → instantiate → 检查根节点类型 → add_child
```

每个测试场景独立初始化自己的状态，不通过 Autoload、全局变量、Group 或共享可变 Resource 把运行时状态带到下一个测试。测试内部创建的动态节点也应放在自己的容器下，便于测试按钮或场景退出时清理。

## 6. 常见排查顺序

### 场景“加载失败”

1. 检查 `res://` 路径、文件名大小写和文件是否已保存。
2. 检查 Output / Debugger 中的解析错误和资源依赖错误。
3. 将加载结果转为 `PackedScene` 或预期类型并判断 `null`。
4. 确认场景根节点类型符合调用方的接口要求。
5. 检查场景引用的脚本、子场景和资源是否也能加载。

### 节点已创建但看不见或不工作

1. 确认 `instantiate()` 的结果已经 `add_child()` 到预期父节点。
2. 在 Remote SceneTree 中确认节点实际存在、名称和层级正确。
3. 检查 Transform、Visible、z-index、CanvasLayer、Control 布局或物理启用状态。
4. 确认依赖节点引用在 `_ready()` 后有效，Signal 是否只连接了一次。
5. 若使用动态配置，确认配置发生在节点使用之前，并没有被后续初始化覆盖。

### 重置后旧对象仍有影响

1. 确认旧测试根节点确实调用了 `queue_free()`。
2. 检查是否有外部 Signal、Timer、异步回调或 Callable 仍持有旧节点。
3. 检查待销毁节点是否仍被加入新的查询、交互或业务集合。
4. 在 Remote SceneTree、Debugger 和必要的物理/导航调试视图中确认旧代理是否已退出。

## 7. 当前项目的验证覆盖

### `tests/scene_resource/`

验证：

- `PackedScene` 运行时加载和 `instantiate()`；
- 实例化节点加入专用 `SpawnRoot`；
- 加入 SceneTree 前设置确定的初始位置；
- 实例加入后的运行时配置；
- 使用 `queue_free()` 批量清理动态实例；
- 场景实例中的 `Sprite2D` 和共享纹理引用。

### `tests/scene_lifecycle/`

验证：

- `_notification()` 中的进入、ready、退出通知；
- `_enter_tree()`、`_ready()`、`_process()`、`_exit_tree()`；
- `tree_entered`、`tree_exiting`、`tree_exited`；
- `queue_free()` 请求与实际退出阶段的差别；
- 通过事件日志观察本次运行的回调记录。

### `test_hub`

验证台入口额外展示了一个实际的场景切换用例：选择测试时释放当前实例，加载目标 `PackedScene`，检查其根节点为 `Control`，再加入内容容器。它只负责测试选择和生命周期边界，不介入测试内部逻辑。

## 8. 当前未覆盖的扩展

本专题已覆盖日常场景拆分、实例化和生命周期的基本工作流，但以下内容仍可在项目需要时增加独立验证：

- 场景继承、实例覆盖和 Editable Children 的复杂边界；
- `SceneTree.current_scene`、显式场景切换与过渡期间的输入处理；
- `reparent()` 对 Transform、owner 和场景组织的影响；
- `request_ready()` 的重新初始化边界；
- 大型资源的异步加载、取消和进度反馈。

## 9. 参考入口

- [Nodes and Scenes — Godot 4.7](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/nodes_and_scenes.html)
- [Scene tree — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/scene_tree.html)
- [Node — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [PackedScene — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html)
