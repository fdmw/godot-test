# 功能验证台开发约定

## 开始工作前

- 先阅读根目录的 `godot-implementation.md`，它是本项目 Godot 实现规范。
- 本项目使用 Godot 4.7.x。
- 功能验证台用于独立验证 Godot 功能细节，不承载正式游戏业务逻辑。
- 本项目只验证 2D 和通用 Godot 功能，不新增任何 3D 节点、3D 场景、3D 资源或 3D 测试目录。

## 目录约定

```text
res://
├── test_hub.tscn
├── test_hub.gd
├── controls/
├── tilemap/
├── particles/
├── physics/
├── animation/
├── camera/
├── audio/
├── navigation/
├── viewport/
├── input/
├── rendering/
├── scene_resource/
├── tween/
├── resource_data/
├── file_config/
├── scene_lifecycle/
├── audio_bus/
├── window_display/
├── visibility/
├── physics_extra/
├── path_2d/
├── astar/
├── parallax/
└── dialog/
```

- 根目录的 `test_hub` 只负责选择、加载、重置测试。
- 每个测试使用一个根目录子目录；该测试的场景、脚本和专属资源必须放在同一目录。
- `tilemap/` 包含 TileMap 测试及其全部图片资源，不再使用单独的 `layer/` 目录。
- `particles/` 包含粒子测试场景和脚本；粒子测试使用目录内场景定义的基础纹理，不增加跨目录资源依赖。
- `physics/`、`animation/`、`camera/`、`audio/` 分别验证对应核心节点；每个测试目录保持独立。
- `navigation/`、`viewport/`、`input/`、`rendering/`、`scene_resource/` 同样各自维护独立场景和脚本。
- `controls/` 可以集中验证相关 UI 控件和布局容器，不为每个控件单独建立测试目录。
- `tween/`、`resource_data/`、`file_config/`、`scene_lifecycle/`、`audio_bus/`、`window_display/`、`visibility/`、`physics_extra/` 分别维护对应的通用或 2D 功能验证。
- `path_2d/`、`astar/`、`parallax/`、`dialog/` 分别验证 2D 路径、寻路、视差和常用弹窗节点。
- 不保留临时入口场景或与验证台无关的重复入口。

## 测试隔离

- 每个测试场景独立初始化自己的状态。
- 测试之间不得通过 Autoload、全局变量、Group 或共享可变 Resource 传递运行时状态。
- 切换或重置测试时，验证台释放当前测试并重新实例化目标场景。
- 新测试必须拥有自己的 `.tscn` 和 `.gd`，不能把多个功能继续堆进已有测试脚本。

## 界面约定

- 主界面保持紧凑：顶部工具栏选择测试，剩余区域展示测试内容。
- 测试项不使用编号；使用稳定、可读的功能名称。
- 基础控件测试集中验证常见控件使用方式，避免为每个基础控件拆分一个测试目录。
- 测试说明和操作控件由对应测试场景自己管理，验证台不介入测试内部逻辑。

## 实现约定

- 遵守 `godot-implementation.md` 中关于类型化 GDScript、节点生命周期、Signal 和禁止字符串式代码分派的要求。
- 静态场景数据与运行时行为职责分离：节点层级、Control 布局、anchors、offsets、尺寸、初始位置、静态文本、默认属性、碰撞几何、导航几何以及基础资源引用必须固定在对应 `.tscn` 中；`.gd` 不得在 `_ready()` 中搭建静态界面或创建静态测试对象。
- `.gd` 只负责获取场景节点引用、连接 Signal、处理用户操作、修改运行时状态、更新动态反馈，以及创建确实属于被验证功能的临时对象。需要动态修改的属性应以 `.tscn` 的初始值为基准。
- 动态实例化、运行时生成内容等本身就是验证目标时可以保留运行时创建，但必须放在独立的运行时节点容器下，并在脚本中明确其生命周期；不得以此替代静态场景布局。
- 不为验证台增加 Autoload、Service Locator 或不必要的共享基类。
- 不使用 `_process()` 或 `_physics_process()` 推进测试状态；只有确实需要连续表现时才启用帧回调。
- 运行时创建的节点，在加入 SceneTree 前完成可确定的配置；场景切换使用 `queue_free()` 清理当前测试。
- 新增测试后，用 Godot 无头模式检查场景和脚本是否能加载。
