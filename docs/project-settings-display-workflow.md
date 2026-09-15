# Project Settings、InputMap 与窗口显示工作流

本文说明项目级配置的入口、运行时读取方式以及窗口、Viewport、Stretch 的关系。它覆盖清单中的 Project Settings、Layer Names、InputMap 和显示配置，当前运行时验证入口是 `tests/window_display/`，输入操作另见 [InputMap、输入事件与鼠标坐标工作流](input-workflow.md)。

## 1. Project Settings 的职责

在编辑器打开 `Project > Project Settings`，按分类查找 Application、Display、Input Map、Layer Names、Physics、Rendering、Audio 和 Debug。Inspector 中的项目设置最终保存在根目录 `project.godot`；适合提交的是项目共同事实，不适合把某个用户机器的临时偏好写进项目配置。

优先使用设置界面和搜索定位准确键名，再在代码中通过 `ProjectSettings.get_setting()` 读取。只有确实需要项目运行时配置时才调用 `set_setting()`，并明确它是否需要 `save()`；Project Settings 不是保存用户存档的替代品。

## 2. Layer Names 与 InputMap

在 Layer Names 中为 2D Physics、2D Render 或其他层位设置稳定语义名称。代码通过集中定义的具名常量或明确接口使用碰撞层，不在各个脚本散落难以理解的裸位值；Layer 名称变更应和碰撞 Mask 的使用方一起检查。

在 Input Map 中建立语义 Action，例如 `move_left`、`jump`、`open_menu`，再给 Action 添加键盘、鼠标或手柄绑定。游戏逻辑消费 Action 或转换后的类型化请求，不直接依赖某个物理按键。用户自定义绑定属于 `user://` 数据，不能误写回 `project.godot`。

## 3. Window、Viewport 和 Stretch

这三个概念解决不同层次的问题：

```text
Window Size       实际窗口/屏幕表面尺寸
Viewport Size     游戏内容坐标空间的尺寸
Stretch / Aspect  内容在不同窗口尺寸和比例下如何缩放或扩展
```

在 Display > Window 中先设置内容基准尺寸，再选择 Stretch Mode 和 Aspect。`canvas_items` 会按 CanvasItem 体系缩放 2D 内容；`expand` 等 Aspect 策略决定比例变化时显示更多内容还是保留边界。Control 布局应使用 anchors/Container 适应变化，不能只按一次窗口尺寸硬编码像素位置。

VSync、全屏模式和窗口尺寸是显示输出层设置，不等于 Viewport 的逻辑尺寸。运行时读取当前窗口用 `DisplayServer.window_get_size()`、`window_get_mode()`，读取当前场景内容区域可用 `get_viewport_rect()`；不要用 ProjectSettings 中的初始值代替运行时实际值。

## 4. 当前测试操作

在 `tests/window_display/` 选择 `900 x 600` 或 `1280 x 720`，选择窗口/全屏后点击应用，再点击刷新信息，对比 Window、Viewport、模式和 Stretch/Aspect。切换测试时场景会恢复进入前的窗口尺寸和模式，因此不会把验证操作永久留在其他测试中。

窗口改变后若 UI 变形，依次检查根 Control 的 anchors、Container 的 size flags、Viewport 尺寸和 Stretch/Aspect；不要先通过大量运行时 `position` 修补布局。

参考：[ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)、[DisplayServer](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html)、[Multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html)、[InputMap](https://docs.godotengine.org/en/4.7/classes/class_inputmap.html)。
