# Godot 2D 功能验证台

这是一个用于独立学习和验证 Godot 功能细节的实验项目，不承载正式游戏业务逻辑。

项目当前以 Godot 4.7.x 为基准，只验证 2D 和通用 Godot 功能，不新增 3D 节点、3D 场景、3D 资源或 3D 专项目录。

## 如何使用

1. 使用 Godot 4.7.x 导入本项目。
2. 运行项目主场景。
3. 在顶部选择要验证的功能。
4. 阅读测试场景中的说明并操作控件，观察场景中的结果和反馈。
5. 需要恢复初始状态时点击“重置测试”。

项目入口是 [test_hub.tscn](test_hub.tscn)，入口脚本 [test_hub.gd](test_hub.gd) 只负责选择、加载和重置测试，不介入测试场景内部逻辑。

## 文档与学习清单

文档按职责分层维护：

- [Godot_4.7_2D_list.md](Godot_4.7_2D_list.md)：记录学习范围、验证主题、当前覆盖情况和后续补充方向。
- [godot-implementation.md](godot-implementation.md)：记录本项目的 Godot 实现规范，包括场景职责、测试隔离、类型化 GDScript、生命周期和物理查询约束。
- [Scene、Node、SceneTree 与 PackedScene 工作流](docs/scene-node-workflow.md)：说明场景拆分、编辑器组织、运行时实例化、生命周期和释放边界。
- [GDScript、类型化代码、节点引用与资源加载](docs/gdscript-workflow.md)：说明脚本职责、类型标注、节点引用、资源加载选择和异步边界。
- [Signal、Group、父子节点通信与 Autoload](docs/signal-group-communication.md)：说明命令与事件的区别、节点通信方式、Group 边界和全局服务选择。
- [Godot 编辑器工作流](docs/editor-workflow.md)：说明 Scene、FileSystem、Inspector、Bottom Panel、场景实例和资源保存复用。
- [2D 坐标、Canvas、Camera2D 与 Viewport 工作流](docs/2d-coordinate-workflow.md)：说明局部/全局/Viewport 坐标、CanvasLayer、Camera2D、绘制顺序和 SubViewport。
- [Sprite2D、Texture2D 与图集纹理工作流](docs/sprite-texture-workflow.md)：说明 Sprite2D、Texture2D、AtlasTexture、规则帧图、纹理导入和 2D 采样设置。
- [TileSet 与 TileMapLayer 工作流](docs/tilemap-workflow.md)：说明 TileSet 创建、图集切分、TileMapLayer 绘制、Tile 数据和坐标 API。
- [2D 导航、AStar 与 Path2D 工作流](docs/navigation-path-workflow.md)：说明导航网格、NavigationAgent2D、NavigationServer2D、AStar 和 Path2D 的选型与操作。
- [2D 动画与 Tween 工作流](docs/animation-tween-workflow.md)：说明 AnimatedSprite2D、AnimationPlayer、AnimationTree 和 Tween 的职责与选择。
- [Polygon2D、Line2D 与自定义绘制工作流](docs/2d-drawing-workflow.md)：说明静态几何、Line2D、`_draw()`、`queue_redraw()` 和绘制顺序。
- [2D 粒子、灯光与 CanvasItem Shader 工作流](docs/particles-light-shader-workflow.md)：说明粒子、2D 灯光、遮挡、CanvasModulate 和 ShaderMaterial。
- [Physics Joint2D 工作流](docs/physics-joint-workflow.md)：说明 PinJoint2D、DampedSpringJoint2D、关节约束、刚体响应和物理时序。
- [InputMap、输入事件与鼠标坐标工作流](docs/input-workflow.md)：说明语义 Action、输入轮询、事件传播、UI 输入和 2D 鼠标坐标。
- [2D Physics Body、碰撞几何与 Area2D 工作流](docs/physics-body-area-workflow.md)：说明 Body 类型选择、CollisionShape2D、CollisionPolygon2D 和 Area2D。
- [Collision Layer、Mask 与 2D 空间查询工作流](docs/physics-query-workflow.md)：说明 Layer/Mask、RayCast2D、ShapeCast2D、直接空间查询和物理时序。
- [Control、Container 与 Theme 工作流](docs/ui-layout-theme-workflow.md)：说明 Control 坐标、Anchor/Offset、Container 布局、Theme 和 StyleBox。
- [Popup、Dialog 与 Control 拖放工作流](docs/ui-popup-drag-workflow.md)：说明 Popup、Dialog、FileDialog、拖放两端和 UI 结果传递。
- [Timer、暂停与 process_mode 工作流](docs/timer-pause-workflow.md)：说明 Timer、create_timer、SceneTree 暂停、process_mode 和逻辑时间边界。
- [Skeleton2D、Bone2D 与 2D IK 工作流](docs/skeleton-2d-workflow.md)：说明骨骼层级、Rest Pose、Polygon2D 绑定和 TwoBoneIK。
- [Resource、PackedScene 与数据驱动工作流](docs/resource-scene-data-workflow.md)：说明 `.tres`/`.res`、Resource 共享复制、资源加载和场景实例化。
- [2D 音频、Audio Bus 与监听器工作流](docs/audio-workflow.md)：说明普通/空间音频、AudioListener2D、Bus 音量和效果器。
- [文件、配置、存档与多语言资源工作流](docs/file-save-localization-workflow.md)：说明 `res://`、`user://`、FileAccess、JSON、ConfigFile 和 Translation。
- [Project Settings、InputMap 与窗口显示工作流](docs/project-settings-display-workflow.md)：说明项目配置、层命名、Action、Window、Viewport 和 Stretch。
- [Godot 调试与 2D 问题排查工作流](docs/debug-workflow.md)：说明 Output、Debugger、Remote SceneTree、Remote Inspector 和 2D 调试视图。
- [Godot 2D 性能测量与优化工作流](docs/performance-workflow.md)：说明 Profiler、Monitors、回调、物理、渲染和粒子成本。
- [项目目录、文件版本控制与导出工作流](docs/project-maintenance-export-workflow.md)：说明目录拆分、职责边界、Git 文件和 Export Preset。
- 顶层 `README.md`：说明项目用途、使用方式、目录组织和文档入口。
- 后续专题文档：按学习需要逐步补充，重点说明 Godot 编辑器操作、Inspector 属性、场景与资源关系以及容易混淆的技术点。

专题文档不要求每个节点或每个测试目录都单独建立。只有操作步骤多、配置复杂、概念容易混淆或具有跨测试意义的主题，才单独补充说明。例如 TileMapLayer、物理、导航、渲染、控件布局和输入坐标等。

简单节点的验证以场景内说明、脚本中的验证目标和清单中的覆盖记录为主。

## 当前验证入口

当前验证台包含以下测试目录：

| 主题 | 目录 |
| --- | --- |
| 控件与布局 | `tests/controls/` |
| TileMapLayer | `tests/tilemap/` |
| 粒子 | `tests/particles/` |
| 物理 | `tests/physics/`、`tests/physics_extra/` |
| 动画与补间 | `tests/animation/`、`tests/animation_tree/`、`tests/tween/` |
| 摄像机与视差 | `tests/camera/`、`tests/parallax/` |
| 音频 | `tests/audio/`、`tests/audio_bus/` |
| 导航与寻路 | `tests/navigation/`、`tests/navigation_query/`、`tests/astar/` |
| Viewport 与坐标 | `tests/viewport/`、`tests/canvas_transform/` |
| 输入与交互 | `tests/input/`、`tests/drag_drop/` |
| 2D 渲染 | `tests/rendering/`、`tests/visibility/` |
| 场景与资源 | `tests/scene_resource/`、`tests/resource_data/`、`tests/resource_loading/` |
| 文件与配置 | `tests/file_config/`、`tests/localization/` |
| 生命周期与暂停 | `tests/scene_lifecycle/`、`tests/pause_process/` |
| 窗口显示 | `tests/window_display/` |
| 弹窗 | `tests/dialog/` |
| 路径与骨骼 | `tests/path_2d/`、`tests/skeleton_2d/`、`tests/remote_transform_2d/` |
| 节点分组 | `tests/groups/` |

这张表用于定位测试入口；具体的学习条目和覆盖细节以 [Godot_4.7_2D_list.md](Godot_4.7_2D_list.md) 为准。

## 目录约定

每个测试目录独立维护自己的场景、脚本和专属资源。例如：

```text
tests/tilemap/
├── tilemap_test.tscn
├── tilemap_test.gd
└── 测试专属资源
```

测试场景独立初始化状态，测试之间不通过 Autoload、全局变量、Group 或共享可变 Resource 传递运行时状态。切换测试时，验证台释放当前场景并重新实例化目标场景。

静态节点层级、布局、默认属性、碰撞几何、导航几何和基础资源引用放在 `.tscn` 中；`.gd` 主要负责节点引用、Signal 连接、用户操作、运行时状态变化和动态反馈。

## 测试目录组织

所有功能测试统一位于 `res://tests/` 下，根目录只保留验证台入口、项目规范、学习清单和项目级文档。

`tests/` 下的每个直接子目录都是一个相互独立的功能示例。测试场景、脚本和专属资源放在对应目录内；测试之间不通过目录结构共享运行时状态。`test_hub.gd` 通过 `res://tests/<主题>/` 下的稳定场景路径加载测试。

## 待补充文档

以下列表根据 [Godot_4.7_2D_list.md](Godot_4.7_2D_list.md) 的 50 个主题整理而成。列表项是专题文档，不是测试目录清单；一个专题可以覆盖多个节点和测试目录。

### 基础模型与编辑器

- Scene、Node、SceneTree、PackedScene 与节点生命周期已记录于 [Scene、Node、SceneTree 与 PackedScene 工作流](docs/scene-node-workflow.md)（清单 1、39）。
- GDScript、类型化代码、节点引用、资源加载与常用脚本工作流已记录于 [GDScript、类型化代码、节点引用与资源加载](docs/gdscript-workflow.md)（清单 2）。
- Signal、Group、父子节点通信、Autoload 与通信方式选择已记录于 [Signal、Group、父子节点通信与 Autoload](docs/signal-group-communication.md)（清单 3、41）。
- Godot 编辑器工作流已记录于 [Godot 编辑器工作流](docs/editor-workflow.md)（清单 1、44）。

### 2D 空间与显示

- Node2D 坐标、Transform、local/global 转换、CanvasLayer、Camera2D 与 Viewport 的关系已记录于 [2D 坐标、Canvas、Camera2D 与 Viewport 工作流](docs/2d-coordinate-workflow.md)（清单 4、6、7、10）。
- Sprite2D、Texture2D、AtlasTexture、帧图、纹理导入与 2D 采样设置已记录于 [Sprite2D、Texture2D 与图集纹理工作流](docs/sprite-texture-workflow.md)（清单 5）。

### 输入与物理

- InputMap、Action、输入轮询与事件、UI 输入传播以及鼠标坐标转换已记录于 [InputMap、输入事件与鼠标坐标工作流](docs/input-workflow.md)（清单 11，并结合清单 4、35）。
- 2D Physics Body、CollisionShape2D、CollisionPolygon2D、Area2D 与移动平台选择已记录于 [2D Physics Body、碰撞几何与 Area2D 工作流](docs/physics-body-area-workflow.md)（清单 12、14）。
- Collision Layer / Mask、ShapeCast2D、RayCast2D、DirectSpaceState 查询和物理时序已记录于 [Collision Layer、Mask 与 2D 空间查询工作流](docs/physics-query-workflow.md)（清单 13、15）。
- Physics Joint2D 的使用场景已记录于 [Physics Joint2D 工作流](docs/physics-joint-workflow.md)（清单 16）。

### TileSet、地图与导航

- TileSet、TileMapLayer、Atlas 切分、选取、绘制、擦除、图案和地图坐标已记录于 [TileSet 与 TileMapLayer 工作流](docs/tilemap-workflow.md)（清单 17、18）。
- Terrain 自动拼接、Tile Physics、Navigation、Occlusion、Custom Data 和 Scene Collection Source 已记录于 [TileSet 与 TileMapLayer 工作流](docs/tilemap-workflow.md)（清单 19、20）。
- 地图分层、Tile 与独立 Scene 的边界、Y Sort 与场景化关卡组织已记录于 [TileSet 与 TileMapLayer 工作流](docs/tilemap-workflow.md)（清单 21，并结合清单 6）。
- NavigationRegion2D、NavigationAgent2D、NavigationObstacle2D、NavigationLink2D、AStar 与 Path2D 的选型已记录于 [2D 导航、AStar 与 Path2D 工作流](docs/navigation-path-workflow.md)（清单 22～26）。

### 动画、绘制与表现

- AnimatedSprite2D、AnimationPlayer、AnimationTree 与 Tween 的使用场景和选择已记录于 [2D 动画与 Tween 工作流](docs/animation-tween-workflow.md)（清单 27～30）。
- Polygon2D、Line2D、`_draw()`、`queue_redraw()`、绘制顺序和调试绘制已记录于 [Polygon2D、Line2D 与自定义绘制工作流](docs/2d-drawing-workflow.md)（清单 9）。
- GPUParticles2D、2D Light、Shadow、CanvasModulate 和 CanvasItem Shader 的配置入口已记录于 [2D 粒子、灯光与 CanvasItem Shader 工作流](docs/particles-light-shader-workflow.md)（清单 31～33）。
- Skeleton2D、Bone2D 与 2D IK 已记录于 [Skeleton2D、Bone2D 与 2D IK 工作流](docs/skeleton-2d-workflow.md)（清单 34）。

### UI、时间、音频与数据

- Control、Anchor、Offset、Container、Theme、StyleBox、焦点和 Mouse Filter 已记录于 [Control、Container 与 Theme 工作流](docs/ui-layout-theme-workflow.md)（清单 35～37）。
- Popup、Dialog、拖放交互和 UI 场景组织已记录于 [Popup、Dialog 与 Control 拖放工作流](docs/ui-popup-drag-workflow.md)（结合 `dialog/`、`drag_drop/` 测试）。
- Timer、暂停、process_mode、生命周期信号，以及现实时间和领域逻辑时间的边界已记录于 [Timer、暂停与 process_mode 工作流](docs/timer-pause-workflow.md)（清单 38，并结合 `scene_lifecycle/`、`pause_process/`）。
- Resource、`.tres`、数据驱动、Resource 共享/复制、PackedScene 实例化和资源加载已记录于 [Resource、PackedScene 与数据驱动工作流](docs/resource-scene-data-workflow.md)（清单 39、40，并结合 `resource_data/`、`resource_loading/`、`scene_resource/`）。
- AudioStreamPlayer2D、AudioListener2D、Audio Bus、音量和效果器已记录于 [2D 音频、Audio Bus 与监听器工作流](docs/audio-workflow.md)（清单 42，并结合 `audio/`、`audio_bus/`）。
- FileAccess、JSON、ConfigFile、`res://` / `user://`、存档和多语言资源已记录于 [文件、配置、存档与多语言资源工作流](docs/file-save-localization-workflow.md)（清单 43，并结合 `file_config/`、`localization/`）。

### 工程、调试与发布

- Project Settings、Layer Names、InputMap、窗口尺寸、Viewport、Stretch、Fullscreen 和显示配置已记录于 [Project Settings、InputMap 与窗口显示工作流](docs/project-settings-display-workflow.md)（清单 47，并结合 `window_display/`）。
- Debugger、Remote SceneTree、Remote Inspector、物理/导航调试和问题排查顺序已记录于 [Godot 调试与 2D 问题排查工作流](docs/debug-workflow.md)（清单 45）。
- 性能基础、Process 回调、节点数量、物理查询、粒子、Profiler 和 Monitors 已记录于 [Godot 2D 性能测量与优化工作流](docs/performance-workflow.md)（清单 46）。
- 项目目录、场景拆分、Resource/Node/Scene 的职责边界、Git 文件和导出基础已记录于 [项目目录、文件版本控制与导出工作流](docs/project-maintenance-export-workflow.md)（清单 48～50）。

维护约定：

- 文档完成后，从本节删除对应待办项，避免已完成事项长期残留。
- 完成的专题文档在“文档与学习清单”或相关清单条目中增加正式链接。
- 如果一个主题拆分成多份文档，待办项应在全部必要内容完成后再删除，或改写为仍未完成的具体子项。

以下内容暂不单独建立文档，完成时并入上面的相关专题：

- `groups/`、`remote_transform_2d/`、`visibility/` 等操作简单的节点测试。
- `particles/`、`path_2d/`、`physics_extra/`、`audio_bus/` 等已有明确归属的专项测试。
- `dialog/`、`drag_drop/`、`localization/`、`window_display/` 等测试目录，它们的操作步骤分别并入 UI、数据/资源和工程配置专题。

每份专题文档应优先回答“在哪里配置、如何操作、属性有什么作用、运行时如何读取或修改、容易出现什么误解”，而不是简单重复节点 API 列表。
