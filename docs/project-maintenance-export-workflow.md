# 项目目录、文件版本控制与导出工作流

本文说明项目增长后的目录、Scene/Node/Resource 边界、Git 文件和导出基础。当前仓库是功能验证台，组织目标是让每个实验独立、容易定位和容易清理，不直接套用正式游戏的全部生产目录。

## 1. 当前项目的目录原则

根目录只保留验证台入口、项目规范、学习清单和项目级文档；所有功能示例放在 `tests/<topic>/`，每个目录自带场景、脚本和专属资源：

```text
tests/<topic>/
├── <topic>_test.tscn
├── <topic>_test.gd
└── 该测试专属的资源
```

`test_hub` 只负责选择、加载、重置测试，不介入测试内部逻辑。测试之间不通过 Autoload、全局变量、Group 或共享可变 Resource 传递运行时状态；这比把所有示例堆在一个大场景中更容易确认单项行为。

## 2. Scene、Node 与 Resource 的职责

- Node 需要 SceneTree 生命周期、Transform、物理、渲染、输入或 Signal 等引擎能力。
- Scene/PackedScene 保存可复用的节点结构、静态布局、初始属性、碰撞/导航几何和行为脚本引用。
- Resource 保存可共享的静态定义数据、纹理、动画、音频、Theme 或自定义配置。
- 纯逻辑状态、请求和短生命周期值对象优先使用轻量对象，不为了存数据额外创建 Node。

一个场景过大、分支有独立生命周期或需要多处复用时拆成独立 Scene；一个节点只是结构简单且没有独立行为时不必过度拆分。静态场景事实写入 `.tscn`，脚本负责节点引用、Signal、用户操作和运行时变化。

## 3. Git 中提交什么

通常应提交：

- `project.godot`、`*.tscn`、`*.gd`、`*.tres`、`*.svg` 以及项目需要的图片、音频等源资源；
- `README.md`、`docs/`、学习清单和必要的导出配置；
- `export_presets.cfg`（存在时），以便团队复现导出目标。

通常不提交：

- `.godot/` 导入缓存、编辑器布局和本机生成数据；
- 导出凭据、密钥和密码；
- 可由 Godot 根据源资源重新生成的 import 缓存。

`.tscn`/`.tres` 是适合审查和合并的文本资源；大型二进制资源应保留来源、命名和导入配置，必要时使用适合二进制文件的版本控制策略。文件名和 `res://` 路径保持小写、稳定且大小写一致，避免在区分大小写的导出 PCK 中出现编辑器环境下未暴露的问题。

## 4. 导出前的最小流程

1. 在 `Project > Export` 创建目标平台 Export Preset。
2. 在 `Editor > Manage Export Templates` 确认目标模板已安装。
3. 检查主场景、资源依赖和非 Resource 文件过滤器；JSON、CSV 等文件若运行时要读取，确认它们会被包含。
4. 分别运行 Debug 和 Release 导出，检查启动、窗口显示、输入、音频、存档路径和资源加载。
5. 在干净目录或目标平台上验证一次，不把本机 `.godot` 缓存是否存在当成导出成功依据。

导出包中的 `res://` 通常是只读资源；用户设置和存档仍写 `user://`。导出凭据不要提交到 Git，导出预设和凭据的职责不同。

参考：[Project organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html)、[Version control systems](https://docs.godotengine.org/en/4.7/tutorials/best_practices/version_control_systems.html)、[Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html)。
