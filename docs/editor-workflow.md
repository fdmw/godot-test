# Godot 编辑器工作流

本文说明在 Godot 4.7 中完成一次常见 2D 场景编辑、资源配置、保存和验证所需要的编辑器操作。重点不是记住每个按钮的位置，而是知道每个面板编辑的对象、修改最终保存到哪里，以及实例场景和运行时场景为什么可能不同。

## 1. 编辑器区域和职责

| 区域 | 主要对象 | 常用用途 |
| --- | --- | --- |
| Scene Dock | 当前打开场景的节点树 | 添加、删除、重命名、复制、重排节点；查看实例边界 |
| FileSystem Dock | 项目内 `res://` 资源 | 查找和打开 `.tscn`、`.gd`、纹理、音频、`.tres` 等文件 |
| 中央工作区 | 当前场景或脚本 | 2D 视口编辑、脚本编辑、运行结果观察 |
| Inspector | 当前选中的 Node、Resource 或文件 | 修改属性、查看资源引用、搜索属性、恢复默认值 |
| Node Dock | 当前节点的 Signal、Group 等关系 | 连接 Signal、查看节点分组和相关配置 |
| Bottom Panel | Output、Debugger、Animation、TileMap、Audio 等工具 | 看日志和错误、调试运行时、编辑动画/地图/音频 |
| 顶部运行控制 | 当前场景和项目 | F6 运行当前场景、F5 运行项目、F8 停止 |

选择对象后，先确认 Inspector 顶部显示的到底是 Node、Resource 还是导入文件。很多“属性改了但没有生效”的问题，实际是编辑了错误对象或没有保存正确的资源。

## 2. 打开项目和确认版本

1. 使用 Godot 4.7.x 导入项目目录。
2. 等待 FileSystem 完成资源扫描和导入；首次打开纹理、音频等资源可能需要更长时间。
3. 检查顶部或项目管理器显示的引擎版本，项目设置中的 feature 标记也应与项目约定一致。
4. 如果出现资源解析错误，先看 Output 和 FileSystem 中的错误标记，再开始编辑场景。

本项目只验证 2D 和通用 Godot 功能。不要因为编辑器顶部存在 3D 工作区，就向项目加入 3D 节点、3D 场景或 3D 资源。

## 3. 一次完整的场景编辑流程

### 3.1 创建根节点

在 Scene Dock 中新建场景，根据场景职责选择根节点：

- 需要 2D Transform 的世界对象通常使用 `Node2D` 或其派生节点；
- UI 页面通常使用 `Control`，再由 Container 或 anchors 管理布局；
- 需要物理身份的对象选择合适的 `PhysicsBody2D` 或 `Area2D`；
- 只负责组织子节点、没有 Transform 或专项能力时可以使用 `Node`。

根节点的选择会影响 Inspector 中的属性、子节点行为和场景对外接口。不要先随意创建一个根节点，再用脚本弥补根节点类型不合适造成的问题。

### 3.2 添加和配置子节点

1. 在 Scene Dock 选中目标父节点。
2. 点击 Add Child Node，搜索并创建节点。
3. 在 Scene Dock 中给节点起稳定、可读的名称。
4. 在 Inspector 设置静态属性，例如 Transform、尺寸、布局、碰撞几何、纹理和默认文本。
5. 将需要由脚本访问的内部节点设置为 Scene Unique Name，之后可以使用 `%NodeName` 引用。
6. 使用 Ctrl+S 保存场景，并留意场景标签上的未保存标记。

能在编辑器中确定的结构和默认值应保存于 `.tscn` 或其引用的静态 Resource；不要在脚本 `_ready()` 中重复创建静态 UI、碰撞形状或固定测试对象。

### 3.3 复制、重命名和重排

Scene Dock 中常见操作包括：

- 右键节点进行 Rename、Duplicate、Delete 和 Reparent；
- 拖动节点到另一个父节点下改变层级；
- 使用多选同时移动或修改同类节点；
- 使用节点搜索过滤大型场景树；
- 必要时使用 Quick Open 在项目文件和脚本之间快速跳转。

重排节点不仅改变显示位置，也可能改变父节点 Transform、Control 布局、处理顺序和局部路径。完成 Reparent 后要同时检查 Inspector 中的 Transform、owner、脚本引用以及运行结果。

### 3.4 2D 视口工具

在 2D 工作区中，常用工具包括移动、旋转、缩放、框选和对齐。编辑 Node2D 时区分 Local 和 Global Transform：

- Local Transform 是相对于父节点的值；
- Global Transform 是映射到世界/画布后的值；
- 改变父节点 Transform 后，子节点的全局位置可能变化，但局部位置可能不变；
- Control 的位置和尺寸还会受到 anchors、offsets 和 Container 的约束。

需要规则排列时打开 Grid 和 Snap，设置合适的网格间距；需要保留某个节点位置不被误拖时使用 Lock。Snap 是编辑器辅助，不是运行时碰撞、导航或网格逻辑的替代品。

## 4. FileSystem Dock 和资源管理

FileSystem Dock 展示项目目录中的资源，并以 `res://` 作为项目资源根路径。当前项目的功能示例统一位于 `tests/`，每个测试目录保存自己的场景、脚本和专属资源。

### 常见操作

- 双击 `.tscn` 打开场景；
- 双击 `.gd` 在 Script 工作区打开脚本；
- 选中纹理、音频或 Resource，在 Inspector/Import 中查看配置；
- 右键资源进行复制、重命名、移动、删除和重新导入；
- 从 FileSystem 将 `.tscn` 拖入当前场景，创建场景实例；
- 从 FileSystem 将纹理拖入 2D 视口或合适的资源属性。

项目内移动资源时优先通过 FileSystem Dock 完成，避免编辑器没有及时感知外部文件移动而留下失效引用。移动后检查场景、脚本和资源中的 `res://` 路径。

### 导入文件和编辑资源的区别

源文件如 PNG、音频和字体通常先经过 Import 流程，Import Dock 中的设置控制 Godot 如何生成运行时可用的导入资源。导入设置改变后点击 Reimport，并重新检查运行结果。

`.tres`、`.res` 和 `.tscn` 是 Godot 项目资源，可以直接由 Inspector 或对应编辑器修改。不要把导入资源的 Import 设置和场景中某个节点的属性混为一谈：前者影响资源导入，后者通常保存在场景或引用的 Resource 中。

## 5. Inspector 的使用方法

Inspector 显示当前选中对象的可编辑属性。使用它时按下面顺序操作：

1. 先在 Scene Dock 或 FileSystem Dock 选择目标对象。
2. 用 Inspector 顶部搜索框过滤属性。
3. 展开相关分类，例如 Transform、Visibility、Process、CanvasItem 或脚本导出字段。
4. 修改属性后观察 2D 视口或底部状态。
5. Ctrl+S 保存当前场景；如果编辑的是外部 Resource，还要保存该 Resource。
6. 重新打开场景或资源，确认修改确实被序列化。

Inspector 中常见的三种保存对象：

| 选中的对象 | 修改通常保存到 | 典型例子 |
| --- | --- | --- |
| 场景中的 Node | 当前 `.tscn` | 节点位置、静态文本、碰撞形状引用 |
| 外部 Resource | 对应 `.tres`/`.res` 文件 | 角色数据、Theme、Curve、材质或共享配置 |
| 场景内 SubResource | 当前 `.tscn` | 场景专属 Gradient、Shape2D、TileSet |

### 资源引用、Make Unique 和 Local to Scene

多个节点可以引用同一个外部 Resource。编辑其中一个节点的共享 Resource，可能影响所有引用者。需要某个节点拥有独立副本时，在 Inspector 的资源菜单中使用 Make Unique，或按该资源类型支持的 Local to Scene 语义配置；操作后重新确认 Inspector 显示的是副本而不是原资源。

本项目的内容 Resource 在运行时视为只读定义。不要只因为 Inspector 里能修改，就把共享 Resource 当成某个实例的运行时状态。

### 脚本导出属性

脚本中的 `@export` 字段会出现在 Inspector：

```gdscript
@export var validation_theme: Theme
@export var speed: float = 120.0
```

它们适合配置场景差异和静态依赖。修改导出属性后保存场景；默认值来自脚本，场景中保存的覆盖值可能继续保留。若脚本修改了默认值却看不到变化，检查 Inspector 是否存在旧的场景覆盖。

## 6. 场景实例、Editable Children 和 Make Local

### 实例化场景

在 FileSystem Dock 将一个 `.tscn` 拖入另一个场景，或使用 Scene Dock 的 Instantiate Child Scene。实例在父场景中以一个节点显示，内部节点默认属于被实例化的源场景。

优先在源场景中修改公共结构和默认行为，再让所有实例继承更新。这样可以保持复用关系和统一修复路径。

### Editable Children

对场景实例使用 Editable Children 后，可以在当前父场景中展开并编辑实例内部的部分节点属性，也可以在允许的边界内添加局部子节点。修改保存为父场景中的覆盖项，不等于修改源场景。

适合使用的情况：

- 某个实例确实需要少量局部属性覆盖；
- 需要在父场景中观察和调整实例内部布局；
- 覆盖关系本身是关卡配置的一部分。

使用时要确认 Inspector 修改的是当前实例覆盖，而不是误打开源场景。Editable Children 会增加场景关系复杂度，不能替代清晰的导出属性或独立场景设计。

### Make Local

Make Local 会把该场景实例转换为当前场景中的本地结构，断开原有的外部场景实例关系。之后源场景的结构更新不会自动按原实例关系传递到这个本地副本。

因此：

- 想继续继承源场景，只需要局部覆盖时，优先使用 Editable Children；
- 确实不再需要源场景复用关系时，才 Make Local；
- 操作前确认版本控制中能追踪 `.tscn` 的变化，避免误断开场景依赖。

## 7. Signal、Group 和 Node Dock

Node Dock 可查看当前节点的 Signal 和 Group。Signal 连接应根据场景关系选择编辑器连接或代码连接；动态创建的节点通常在脚本中连接，固定的场景关系可以保存在 `.tscn`。

Group Dock 用于给节点增加分类标签。它适合查询当前场景中的一类对象或进行合理的批量操作，不应被当作唯一服务定位器。通信方式的详细边界见 [Signal、Group、父子节点通信与 Autoload](signal-group-communication.md)。

## 8. Bottom Panel 的实际用法

### Output

查看脚本打印、解析错误、资源加载错误和运行时警告。遇到场景不显示、Signal 不触发或资源为空时，先清空无关旧日志，再重现问题并定位第一条相关错误。

### Debugger

查看断点、错误堆栈、远程运行状态和性能信息。运行项目后，切换到 Remote SceneTree 可以观察实际运行节点，而不是只看保存的编辑器场景。

### Animation

选中 `AnimationPlayer` 或相关动画节点后使用 Animation 面板编辑轨道、关键帧、播放和循环。动画中的属性变化会保存到场景或动画 Resource；修改前确认动画资源是场景内独有还是外部共享。

### TileMap

选中 `TileMapLayer` 后使用 TileMap 面板选择 TileSet、图集和绘制工具。TileSet 创建、图集切分、画笔、擦除、地图坐标和 Tile 数据的完整流程见 [TileSet 与 TileMapLayer 工作流](tilemap-workflow.md)。

### Audio

Audio 面板用于查看和调整编辑器中可见的音频总线。运行时音频节点、Audio Bus 资源和播放参数仍应回到对应场景或 Project Settings 检查，不能只凭编辑器面板状态判断游戏最终效果。

## 9. 本项目的编辑与验证流程

新增或修改一个功能示例时，按下面流程执行：

1. 在 `tests/<主题>/` 中准备该测试自己的 `.tscn`、`.gd` 和专属资源。
2. 打开 `.tscn`，先在 Scene Dock 完成静态节点树、布局、默认属性和资源引用。
3. 在 Inspector 检查导出字段、引用资源和节点唯一名称。
4. 在脚本中使用类型化节点引用，连接 Signal，并只实现运行时操作与动态反馈。
5. 保存场景、脚本和资源，重新打开确认没有依赖编辑器未保存状态。
6. 使用 F6 运行当前测试场景，使用 F5 运行整个验证台。
7. 在验证台顶部选择测试，操作测试控件，需要时点击重置。
8. 检查 Output、Debugger 和 Remote SceneTree，确认场景切换后旧实例已释放。

当前入口 [test_hub.tscn](../test_hub.tscn) 只负责选择、加载、重置测试；所有测试统一位于 `tests/`。不要为了方便编辑某个测试，把它的资源移回根目录或引入全局运行时状态。

## 10. 常见编辑器问题

### 属性修改后重开场景消失

确认修改的是正确的 Node 或 Resource，并已保存对应文件。运行时脚本修改不会自动回写 `.tscn`；编辑器中的临时预览也不代表已经序列化。

### 场景实例内部改了但没有保存

检查是否启用了 Editable Children，以及修改是否属于当前父场景允许保存的覆盖。若希望所有实例都改变，应打开源场景修改并保存源场景。

### 节点在编辑器可见，运行时不存在

确认节点被保存到当前 `.tscn`，而不是只由编辑器临时创建；检查 owner、实例边界和是否执行了 Make Local。再通过 Remote SceneTree 查看实际运行树。

### Inspector 找不到属性

检查选中的对象类型、脚本是否成功加载、属性是否为 `@export`，以及 Inspector 搜索框是否保留了过滤条件。导入文件的设置在 Import Dock，不一定出现在 Node Inspector。

### FileSystem 中有文件但场景引用失效

检查文件是否被外部移动、重命名或大小写变化。通过 FileSystem Dock 移动资源，重新导入后搜索项目中的旧 `res://` 路径。

### Bottom Panel 占用过多空间

完成查看后折叠或切换面板；需要调试时再打开。面板布局属于编辑器个人状态，不应把 `.godot` 下的个人编辑器布局当成项目功能配置提交。

## 11. 当前项目的覆盖与后续补充

当前项目已经在各测试中实际使用了：

- Scene Dock 中维护的静态 `.tscn` 节点树；
- Inspector 导出属性、节点默认属性和 SubResource；
- FileSystem 中的测试目录、脚本、纹理和 `.tres`；
- TileMap、Animation、Audio、Output 和 Debugger 等项目实际出现的工具区；
- Scene Unique Name、Signal、Group 和运行时 Remote SceneTree。

尚未专门做成编辑器操作测试的内容包括复杂场景继承、批量编辑、编辑器插件、导入器自定义和大型场景的版本控制冲突。这些属于后续专项内容，不影响当前功能验证台的日常使用。

## 官方参考

- [First look at Godot's interface — Godot 4.7](https://docs.godotengine.org/en/4.7/getting_started/introduction/first_look_at_the_editor.html)
- [Nodes and Scenes — Godot 4.7](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/nodes_and_scenes.html)
- [Inspector Dock — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/editor/inspector_dock.html)
- [Nodes and scene instances — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/scripting/nodes_and_scene_instances.html)
- [Using signals — Godot 4.7](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html)
