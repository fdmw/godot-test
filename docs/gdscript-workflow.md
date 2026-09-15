# GDScript、类型化代码、节点引用与资源加载

本文说明在 Godot 4.7 项目中编写 GDScript 的常用工作流，重点回答：脚本挂在哪里、如何引用场景节点、什么时候使用 `preload()` 或 `load()`、如何让类型和生命周期边界清楚，以及脚本出现问题时如何定位。

本文不是 GDScript 语法大全。循环、条件、函数等语言基础只说明在 Godot 场景脚本中的使用方式；Signal、Group 和 Autoload 的通信取舍另见后续专题。

## 1. 脚本和场景的职责

脚本是一个 `Script` 资源，用来扩展它所附加到的对象。场景文件负责保存节点树和静态属性，脚本负责运行时行为。一个最小的场景脚本通常从下面的结构开始：

```gdscript
extends Control

@onready var _status: Label = %Status

func _ready() -> void:
	_status.text = "已准备"
```

这里有三个重要约定：

- `extends` 明确脚本可以附加到哪一类对象；
- `@onready` 在节点进入树并准备好后取得内部节点；
- `_ready()` 处理运行时初始化，不重新搭建场景中已经保存的静态布局。

本项目的 `.tscn` 固定保存节点层级、Control 布局、初始位置、静态文字、碰撞几何和基础资源引用；`.gd` 主要负责节点引用、Signal 连接、用户操作、状态修改和动态反馈。动态实例化本身是验证目标时，才在脚本中创建对象，并为其指定独立的生命周期容器。

## 2. 类型化 GDScript 的基本写法

Godot 支持对变量、常量、参数、返回值、数组和自定义类进行类型标注。类型信息可以让编辑器补全更准确，也能在运行前暴露一部分拼写、调用和返回值错误。

### 变量、常量和推导

```gdscript
const MAX_ITEMS: int = 8
const DEFAULT_SPEED := 120.0

var item_count: int = 0
var speed := 120.0
var direction: Vector2 = Vector2.ZERO
var tags: Array[String] = []
```

选择方式：

- 对公共字段、跨对象接口和会影响结果的状态，写出明确类型；
- 类型已经由右侧初值明确时，可以使用 `:=` 推导；
- 空数组、空字典和 `null` 往往无法表达完整类型，应显式标注；
- 数值运算区分 `int` 和 `float`，需要时使用 `absi()`、`absf()`、`clampi()`、`clampf()` 等类型明确的函数。

不要为了消除编辑器提示把所有变量改成 `Variant`。如果一个接口实际只接受 `Node2D`、`Vector2` 或自定义 Resource，就让签名表达这个契约。

### 函数参数和返回值

```gdscript
func move_to(target: Vector2, duration: float = 0.2) -> void:
	position = target

func distance_to(target: Vector2) -> float:
	return global_position.distance_to(target)
```

公共函数、跨节点调用的函数和测试对象对外提供的函数都应标注参数与返回值。默认参数用于表达可选配置，不应让一个函数同时承担几种互不相关的职责。

### Array、Dictionary、Vector2 与 enum

`Vector2` 表示连续的二维坐标、方向或位移，`Vector2i` 表示整数网格坐标。两者不能因为都包含两个分量就混用；TileMap 单元格、数组索引等离散值优先使用 `Vector2i`。

数组适合有顺序的同类集合：

```gdscript
var pending_positions: Array[Vector2] = []
pending_positions.append(Vector2.ZERO)
```

字典适合按键查找的开放结构，但核心数据仍应尽量使用明确的类或 Resource 表达。如果确实使用 `Dictionary`，应在进入核心逻辑时检查键和值的类型，不把任意 `Variant` 直接扩散到整个系统。

`enum` 适合有限且封闭的程序状态：

```gdscript
enum TestState { IDLE, RUNNING, FINISHED }
var state: TestState = TestState.IDLE
```

enum 的底层值是整数，类型标注不能自动保证任意整数一定属于枚举成员；外部输入仍然需要验证。开放式内容 ID 和 Tag 则使用稳定字符串或明确的数据类型。

### `class_name`、脚本类型与 `super`

需要在多个脚本和 Inspector 中使用的自定义类型可以注册为全局类：

```gdscript
class_name DemoItem
extends Node2D

@export var value: int = 0

func reset() -> void:
	value = 0
```

也可以只在一个脚本内通过预加载脚本建立类型：

```gdscript
const DemoItemScript = preload("res://tests/scene_resource/spawned_item.gd")
```

`class_name` 会把脚本类型登记到项目的全局类列表，适合稳定、可复用的公开类型；仅用于局部实现的脚本不必全部注册成全局类。

重写父类行为时，使用 `super()` 调用父类的同名实现，或使用 `super.some_method()` 调用父类的其他方法。只有确实需要保留父类行为时才调用，避免父类和子类重复修改同一份状态。

## 3. 节点引用的选择

节点引用的关键不是“哪种写法最短”，而是引用是否符合场景边界和生命周期。优先级如下：

```text
场景内部稳定节点的类型化引用
> 受控动态查找
> 外部拥有者显式注入的类型化依赖
```

可复用场景不能依赖外部 SceneTree 的深层路径。跨场景依赖应由拥有者传入，或通过明确的公共接口建立关系。

### `$Node`：短路径访问

```gdscript
var sprite := $Sprite2D as Sprite2D
```

`$Node2D` 是 `get_node("Node2D")` 的简写，适合路径短、节点名称稳定的场景内部访问。它仍然依赖名称和相对路径，节点重命名或层级调整后可能失效。

### `get_node()` 与 `get_node_or_null()`

```gdscript
var label := get_node("Layout/Status") as Label
var optional_panel := get_node_or_null("OptionalPanel") as Panel
```

`get_node()` 适合场景契约中必需的节点；缺失时应尽早暴露配置问题。可选节点才使用 `get_node_or_null()`，并对 `null` 设计明确的降级行为。不要用很长的 `../../../../` 路径把外部场景结构写进可复用组件。

### `%UniqueNode`：场景内部稳定引用

在编辑器中将节点设置为 Scene Unique Name 后，可以使用 `%UniqueNode`：

```gdscript
@onready var _status: Label = %Status
@onready var _spawn_root: Node2D = %SpawnRoot
```

这是本项目测试场景的主要引用方式。它把引用限制在所属场景的命名边界内，重排局部层级时比深层相对路径更稳。Scene Unique Name 不是跨场景全局查找，也不能替代外部依赖注入。

### `@onready` 与引用时机

依赖 SceneTree 或子节点 ready 状态的引用放在 `@onready` 成员中，或在 `_ready()` 中取得。不要在对象尚未进入树时访问依赖 SceneTree 的 API，也不要在 `_enter_tree()` 中假设所有兄弟节点已经 ready。

静态类型转换可以尽早发现场景结构错误：

```gdscript
@onready var _button: Button = %ActionButton
```

如果场景结构确实动态变化，则使用受控查找、`get_node_or_null()` 和明确的类型检查，不要为了绕过错误把引用声明成 `Variant`。

## 4. 资源路径和资源加载

Godot 中的场景、脚本、纹理和 `.tres` 都是项目资源。`res://` 表示项目资源路径，资源路径、节点路径和普通文本字符串是三种不同概念：

| 类型 | 示例 | 用途 |
| --- | --- | --- |
| 资源路径 | `res://tests/resource_loading/loadable_data.tres` | 加载场景、脚本或 Resource |
| 节点路径 | `Layout/Status` | 在某个 Node 下查找子节点 |
| 普通字符串 | `"demo"` | 显示文本、内容 ID 或字典键 |

### `preload()`：固定依赖

`preload()` 在脚本加载时预先取得资源，路径必须是脚本中可确定的常量。适合场景必需的脚本、PackedScene、纹理和静态数据：

```gdscript
const ITEM_SCENE: PackedScene = preload(
	"res://tests/scene_resource/spawned_item.tscn"
)
```

优点是依赖明确、调用简单；代价是资源属于脚本加载依赖，不能根据运行时路径选择。资源路径错误会在较早阶段暴露。

### `load()`：运行时决定的资源

`load()` 在执行到调用处时加载资源，适合路径来自配置、用户选择或测试需要观察加载失败的情况：

```gdscript
var packed_scene := load(scene_path) as PackedScene
if packed_scene == null:
	push_error("无法加载场景：%s" % scene_path)
	return
```

使用 `load()` 后必须检查结果和类型。路径不存在、资源格式不匹配或依赖资源缺失时，不能继续把结果当成预期类型使用。

### `ResourceLoader`：需要加载策略时

`ResourceLoader.load()` 是更明确的资源加载入口，可以指定类型提示和缓存模式，也提供依赖查询及线程加载接口。普通固定资源不必为了“更底层”而强行使用它；需要运行时加载、缓存控制或后台加载时再考虑。

```gdscript
var data := ResourceLoader.load(
	"res://tests/resource_loading/loadable_data.tres",
	"Resource",
	ResourceLoader.CACHE_MODE_REUSE
)
var resource_data := data as Resource
if resource_data == null:
	return
```

标准加载是同步操作，大资源可能阻塞当前线程。需要加载屏幕、进度和取消策略时，应单独设计 `load_threaded_request()`、状态查询和场景切换边界，不要把同步 `load()` 放进高频循环。

### `ResourcePreloader`：场景内预载资源

`ResourcePreloader` 是 Node，可以在场景中保存命名资源并通过名称取回。它适合一组属于同一个场景、需要随场景准备好的资源；它不是全局资源仓库，也不替代资源目录规划。

本项目的 [资源加载测试](../tests/resource_loading/resource_loading_test.tscn) 将同一份 `Resource` 分别交给场景导出属性、`ResourceLoader` 和 `ResourcePreloader`，用于观察引用、缓存和运行时引用释放的区别。

### 资源缓存和“释放”

释放一个 GDScript 成员引用，不等于立刻从引擎缓存中删除资源；其他引用或缓存仍可能使资源继续存在。运行时可以清理本场景不再使用的引用，但不要把引用清空误解为强制卸载。

内容 Resource 在本项目中视为共享、只读定义。要修改实例状态，使用独立运行时字段或明确复制后的 Resource，并确认嵌套数组、字典和 Resource 的共享关系；不要直接修改由多个场景实例引用的内容资源。

## 5. 常用脚本工作流

### 第一步：先确定脚本挂载对象

选择一个真实拥有行为的节点作为脚本宿主。UI 交互脚本可以挂在根 `Control`，动态对象可以挂在自己的 `Node2D`，纯逻辑数据不必强行挂在 Node 上。

### 第二步：把静态结构放进场景

在编辑器里完成子节点、布局、默认属性和资源引用。为脚本需要访问的内部节点设置稳定名称，并在必要时打开 Scene Unique Name。

### 第三步：声明类型化引用和状态

```gdscript
@onready var _status: Label = %Status
@onready var _load_button: Button = %LoadButton
var _loaded_data: Resource
var _load_count: int = 0
```

成员命名应反映所有权和生命周期。临时资源、动态实例和异步结果都要能看出谁负责清理或失效。

### 第四步：在 `_ready()` 连接和初始化

```gdscript
func _ready() -> void:
	_load_button.pressed.connect(_load_resource)
	_refresh_view()
```

Signal 连接使用函数引用或 Callable，不用字符串函数名。重复进入树或重新绑定时，要防止重复连接并在退出时解除外部观察关系。通信方式的完整选择规则留给 Signal/Group 专题。

### 第五步：把用户操作转换为明确函数

按钮回调只负责取得输入、调用当前场景拥有的操作并更新反馈；核心状态仍由明确的应用或领域入口修改。不要让 UI 回调通过字符串反射调用任意方法。

### 第六步：处理跨帧和失效引用

`await` 会暂停当前函数，恢复后节点、场景和绑定对象可能已经被释放或替换：

```gdscript
func wait_then_update() -> void:
	await get_tree().process_frame
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	_status.text = "仍然有效"
```

这段检查只能保证当前对象仍有效；如果还持有目标节点或绑定代次，也要分别检查目标和代次。异步任务应有明确取消或失效机制。

## 6. Callable、Lambda 和 `await` 的边界

### Callable

Callable 是函数引用，可用于 Signal 连接、延迟执行或把一个明确的回调传给辅助函数：

```gdscript
func run_once(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()

func _ready() -> void:
	run_once(_refresh_view)
```

Callable 适合表达“调用这个已经确定的函数”，不应变成用字符串拼接方法名的业务分派系统。跨对象核心契约优先使用明确类型和直接方法调用。

### Lambda

Lambda 适合很短、只使用当前位置上下文的临时计算或回调：

```gdscript
var double_value := func(value: int) -> int:
	return value * 2

var result: int = double_value.call(4)
```

如果函数需要名称、独立测试、复杂分支或多个调用点，应提取为有名字的类型化函数，不要让闭包隐藏重要状态。

### `await`

`await` 等待 Signal 或可等待的对象完成；它不是把函数放到后台线程，也不自动解决对象销毁和场景切换问题。等待前后要明确：

- 谁拥有这项异步工作；
- 场景退出时如何取消或使其失效；
- 恢复后需要重新确认哪些 Node、Resource 和外部绑定；
- 是否允许结果跨越场景切换继续生效。

## 7. 常见问题排查

### 编辑器提示找不到属性或方法

1. 检查 `extends` 是否是实际宿主类型。
2. 给变量、参数和返回值补充准确类型。
3. 检查 `as` 转换是否可能得到 `null`。
4. 确认调用的是当前 Godot 4.7 API，而不是旧版教程中的名称。
5. 不要用 `Variant` 或字符串调用把真正的类型错误隐藏起来。

### 节点引用为 `null` 或路径报错

1. 确认节点确实存在于当前场景实例，而不是只存在于另一个编辑器标签页。
2. 检查节点名称、Scene Unique Name 和相对路径。
3. 确认引用发生在 `_ready()` 或之后，而不是对象尚未入树时。
4. 如果节点是动态创建的，先配置、加入正确父节点，再在明确时点保存引用。
5. 跨场景组件不要依赖外部深层路径，改为显式注入依赖。

### `load()` 成功但使用时仍出错

1. 检查结果是否为 `null`。
2. 检查资源实际类型是否符合预期，必要时使用 `as PackedScene` 或 `as Resource`。
3. 检查资源的依赖文件和导入状态。
4. 场景资源要进一步检查 `instantiate()` 结果及根节点类型。
5. 如果是大资源，确认同步加载没有放在高频循环或输入回调的重复路径中。

### 运行后修改资源影响其他实例

检查该 Resource 是否由多个场景实例共享。内容定义保持只读；实例当前值放在节点或独立运行时对象中；必须复制时，明确使用的复制深度和嵌套容器关系。

## 8. 当前项目的验证覆盖

### 各测试脚本中的类型化场景引用

项目测试普遍使用 `@onready`、Scene Unique Name 和具体节点类型，例如 `Label`、`Button`、`Node2D`、`ResourcePreloader`。这些写法验证了场景内部引用和脚本职责分离的日常用法。

### `tests/resource_loading/`

验证：

- 场景导出属性中的固定 Resource 引用；
- `preload`、`ResourceLoader.load()` 和 `ResourcePreloader` 的入口差异；
- `CACHE_MODE_REUSE` 下的资源读取；
- 清空运行时成员引用与共享缓存的区别。

### `tests/resource_data/`

验证自定义 Resource、类型化字段、`duplicate(true)`、嵌套数组以及运行时只读边界。修改操作针对副本，原始定义保持不变。

### `tests/scene_resource/` 与 `test_hub`

验证 `PackedScene` 加载、实例化、类型转换、节点配置、动态父节点和 `queue_free()` 清理。相关场景结构和生命周期说明见 [Scene、Node、SceneTree 与 PackedScene 工作流](scene-node-workflow.md)。

## 9. 当前未覆盖的扩展

本专题覆盖日常场景脚本和资源读取，但以下内容仍可按需要增加验证：

- 自定义 `class_name` 在 Inspector 中的完整导出与脚本重载边界；
- `ResourceLoader.load_threaded_request()` 的进度、取消和失败处理；
- GDScript 警告等级、项目级检查和导出构建中的脚本错误门禁；
- 更复杂的泛型容器、接口约定和跨脚本数据模型。

## 官方参考

- [GDScript 基础 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_basics.html)
- [GDScript 静态类型 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html)
- [ResourceLoader — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html)
- [ResourcePreloader — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_resourcepreloader.html)
- [Script — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_script.html)
