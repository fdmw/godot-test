# Godot 调试与 2D 问题排查工作流

本文是编辑器调试的通用入口，覆盖 Output、Debugger、断点、Remote SceneTree、Remote Inspector 和 2D 调试可视化。当前项目没有把调试面板再做成一个测试目录，因为这些工具用于观察其他测试。

## 1. 先看什么信息

- `print()` 记录普通诊断；`push_warning()` 表示需要注意但不一定失败；`push_error()` 表示明确错误。
- Output 看文本、脚本解析和运行时日志；Debugger 的 Errors 列表更适合查看运行时错误、脚本位置和调用链。
- 断点暂停后查看当前行、局部变量、调用栈和调用者，不要只在代码中插入大量 print。需要确认节点结构时可临时使用 `print_tree()`。

调试输出应包含足够上下文，例如测试名、节点路径、关键 ID 和状态，不要把打印本身做成业务逻辑或字符串式分派机制。修复后移除噪声日志，必要的警告保留明确原因。

## 2. Remote SceneTree 与 Inspector

从编辑器运行项目后，Scene Dock 顶部会出现 Local/Remote。Remote 展示运行时实际的节点树，适合确认：

- `instantiate()` 后是否真的 `add_child()`；
- 节点名称、父子层级和动态生成节点是否正确；
- Control 的实际尺寸、CanvasItem 的可见性和 Transform；
- CollisionShape2D、NavigationRegion2D、Timer 或 Audio 节点是否存在并启用。

Remote Inspector 可以实时查看、临时修改运行时属性。临时修改只用于验证假设，不会自动回写场景或脚本；要保留结果必须回到本地场景/资源或代码中明确修改。编辑器值和运行时值不一致时，继续检查 `_ready()`、用户操作、动画、Tween、物理同步和暂停状态。

## 3. 2D 专用可视化

Debug 菜单中的 `Visible Collision Shapes` 可以显示运行时碰撞形状和 RayCast；导航相关调试选项可显示导航网格、路径或避障信息。它们用于确认引擎实际看到的几何和路径，不等于游戏中的正式渲染效果。

本项目可结合以下入口观察：`physics/` 看碰撞层、ShapeCast 和查询结果，`navigation/` 与 `navigation_query/` 看导航网格和查询时序，`tilemap/` 看地图层级和碰撞/导航数据，`window_display/` 看实际窗口与 Viewport 尺寸。

## 4. 固定排错顺序

```text
节点是否存在
→ 属性和资源是否正确
→ Layer / Mask 或 Bus / Navigation layer 是否正确
→ 坐标系、父节点 Transform 和 Viewport 是否正确
→ Signal / Action 是否触发
→ Runtime 状态是否按预期变化
→ 最后再怀疑引擎或版本问题
```

碰撞问题先开可视化并检查 Shape、Layer、Mask；导航问题先确认 Region 已烘焙、地图已同步且目标在可达范围；“看不见”先检查 Remote Transform、Visible、z-index、CanvasLayer 和 Control 布局；Signal 问题先确认连接对象和连接时机。

## 5. 当前项目的检查边界

每次新增或修改测试后，先运行 Godot 无头编辑器检查场景和脚本能否加载，再在编辑器中运行对应测试观察 Remote 状态。无头检查适合发现解析、资源引用和场景加载错误，不能替代窗口、输入、音频、导航或视觉调试。

参考：[Overview of debugging tools](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/overview_of_debugging_tools.html)、[Output panel](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/output_panel.html)、[Debug](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/index.html)。
