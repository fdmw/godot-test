# Resource、PackedScene 与数据驱动工作流

本文说明 Resource、场景资源和运行时对象之间的职责边界，重点覆盖 `.tres`、共享引用、复制、加载和实例化。Resource 用于描述数据，Node/Scene 用于结构和行为；两者组合后才形成可运行对象。

## 1. 当前测试范围

- `tests/resource_data/`：创建自定义 Resource，比较原对象与 `duplicate(true)` 副本，观察嵌套数组是否意外共享。
- `tests/resource_loading/`：比较场景固定引用、`preload`、`ResourceLoader.load()`、`ResourcePreloader` 和运行时引用释放。
- `tests/scene_resource/`：验证 `PackedScene` 加载、`instantiate()`、加入专用容器、运行时配置和 `queue_free()`。

## 2. 如何选择对象类型

```text
静态内容定义 / 配置数据       → Resource（.tres / .res）
可复用的节点树和运行时行为     → PackedScene（.tscn / .scn）
需要树生命周期、Transform、物理或渲染 → Node
某个实例的当前血量、冷却、位置 → 独立运行时状态
```

例如 `WeaponData` 可以是包含伤害和冷却的自定义 Resource，武器的碰撞、动画和输入行为则属于 Weapon Scene。不要把一个共享 Resource 的 `current_ammo` 当成某一把武器实例的运行时状态。

## 3. 创建和保存自定义 Resource

常用流程是创建继承 `Resource` 的独立脚本，在字段上使用 `@export`，然后在 FileSystem 中创建 `.tres` 并在 Inspector 中编辑：

```gdscript
extends Resource
class_name WeaponData

@export var damage: int = 1
@export var cooldown: float = 0.2
@export var tags: Array[String] = []
```

`.tres` 是可读的文本资源，适合版本控制和人工审查；`.res` 是二进制资源，适合不希望以文本保存或更关注文件体积/读写的场景。资源也可以作为内置资源保存在 `.tscn` 中。Inspector 的 `Make Unique`、`Local to Scene` 等选项会改变引用关系，应在保存后检查实际资源路径和场景内容。

用于持久化的自定义 Resource 应使用可被引擎稳定加载的顶层 Resource 脚本。不要把需要序列化的资源类型只定义成脚本内部的临时类；这类类型在保存和重新加载时容易失去自定义字段。

## 4. 共享与复制

同一个资源路径通常只加载一份 Resource，多个节点可以持有同一引用。这对只读内容定义是优势，但修改共享对象会影响所有使用者。运行时应把内容 Resource 视为只读。

需要独立副本时，应明确复制契约：

- 浅复制只复制外层 Resource，嵌套 Resource、Array 或 Dictionary 可能仍共享。
- `duplicate(true)` 请求深复制，但仍应针对目标版本和字段类型验证嵌套关系，不要把它当作无条件的通用深拷贝。
- `resource_local_to_scene` 适合每个场景实例确实需要独立资源的情况，不应替代普通运行时状态模型。

当前 `resource_data` 测试用深复制后修改 `tags` 和 `amount`，预期原 Resource 不变；这正是判断共享边界的最小实验。

## 5. 加载资源和生成场景

- `preload("res://...")` 使用固定常量路径，在脚本加载时准备资源，适合场景契约明确的固定依赖。
- `load()` 或 `ResourceLoader.load()` 在运行时按路径加载，适合路径由配置决定、允许失败或需要显式缓存模式的情况；同步加载可能阻塞当前线程。
- `ResourcePreloader` 可把场景内预先登记的资源集中保存和读取；它不是全局资源服务。
- 场景文件加载后得到的是 `PackedScene`，调用 `instantiate()` 才创建 Node 树，再由明确的父节点 `add_child()` 加入 SceneTree。

能够预先确定的实例配置应在加入树前完成：

```gdscript
var instance := packed_scene.instantiate() as Node2D
if instance == null:
	return
instance.position = spawn_position
spawn_root.add_child(instance)
```

每次 `instantiate()` 得到独立节点实例，但实例使用的 Texture、Animation 和内容 Resource 仍可能共享。动态实例应挂在职责明确的容器下，清理时统一 `queue_free()`。

## 6. 当前项目的操作顺序

先在 `resource_data` 点击创建、复制、修改副本，观察原值；再在 `resource_loading` 分别点击 ResourceLoader 加载和释放；最后在 `scene_resource` 实例化对象并观察 SpawnRoot 的节点数量。Resource 的引用释放由引用关系和生命周期决定，不能把“清空一个变量”理解成强制卸载全局缓存。

参考：[Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html)、[Resource](https://docs.godotengine.org/en/4.7/classes/class_resource.html)、[PackedScene](https://docs.godotengine.org/en/4.7/classes/class_packedscene.html)、[Background loading](https://docs.godotengine.org/en/4.7/tutorials/io/background_loading.html)。
