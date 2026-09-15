# InputMap、输入事件与鼠标坐标工作流

本文说明 Godot 2D 输入的配置和传播顺序，重点区分语义 Action、轮询、原始 `InputEvent`、GUI 输入和鼠标坐标。输入层只负责产生请求，不直接修改领域状态。

## 1. 先配置语义 Action

在 Project > Project Settings > Input Map 中创建具有稳定语义的 Action，例如 `move_left`、`move_right`、`confirm`、`cancel`。每个 Action 可以绑定键盘、鼠标、手柄或多个设备输入。

代码消费 Action，而不是绑定物理按键：

```gdscript
func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func wants_confirm() -> bool:
	return Input.is_action_just_pressed("confirm")
```

这样更换按键或增加手柄绑定时不需要修改游戏逻辑。Deadzone 应在 Input Map 或输入设置中统一管理，移动向量和确认操作不应各自复制一套设备判断。

### 运行时修改 InputMap

`InputMap` 可以在运行时添加 Action 或绑定事件，但这些修改不会自动写回项目配置。验证或重绑定功能应保存自己的配置，并在退出测试时清理临时 Action。当前 `tests/input/` 使用 `validation_move_left` 和 `validation_move_right` 验证这一点。

## 2. 轮询和事件的选择

| 方式 | 适合场景 | 特点 |
| --- | --- | --- |
| `Input.is_action_pressed()` | 持续移动、持续瞄准 | 在更新入口读取当前状态 |
| `is_action_just_pressed()` | 跳跃、确认、一次性触发 | 只在按下边沿为真 |
| `is_action_just_released()` | 松开蓄力、结束拖拽 | 只在释放边沿为真 |
| `_input(event)` | 全局或必须最早处理的原始事件 | 可在 GUI 之前消费事件 |
| `_unhandled_input(event)` | 游戏操作和未被 UI 消费的事件 | 通常更适合全屏游戏输入 |
| `Control._gui_input(event)` | 特定控件的鼠标/触摸交互 | 输入目标由控件和 Mouse Filter 决定 |

持续移动一般在明确的物理或应用入口读取 Action；按钮、快捷键、文本输入和触摸细节则使用事件。不要为一个按键同时维护轮询状态、原始 keycode 分支和 Action 分支。

## 3. 输入事件传播顺序

普通 Viewport 中，事件大致按以下阶段传播：

```text
Viewport
→ Node._input()
→ Control._gui_input() / gui_input
→ Node._shortcut_input()
→ Node._unhandled_key_input()
→ Node._unhandled_input()
→ 2D 对象拾取
```

事件在前面阶段被标记为 handled 后，后续阶段不会继续收到它。`_input()` 适合必须优先观察或拦截的底层输入；游戏玩法通常放在 `_unhandled_input()`，让按钮、LineEdit 等 UI 有机会先消费事件。

不要把 `_input()` 当成“所有玩法的全局入口”。如果它调用 `get_viewport().set_input_as_handled()`，可能阻止 UI 或其他场景节点收到事件；如果 UI 按钮已经消费了确认键，玩法层也不应再次执行同一动作。

## 4. UI 输入、焦点和 Mouse Filter

`Control.mouse_filter` 决定控件是否接收鼠标事件以及事件是否继续传播：

- `STOP`：控件接收并通常阻止事件继续向下传播；
- `PASS`：控件可以接收，未处理时允许继续传播；
- `IGNORE`：控件不参与鼠标命中，适合纯装饰层。

键盘和手柄输入还受焦点影响。检查 UI 输入时确认：

1. 当前控件是否拥有焦点；
2. 控件是否 disabled 或不可见；
3. 父控件的 Mouse Filter 和裁剪是否拦截了鼠标；
4. 是否在 `_gui_input()` 中调用了 `accept_event()`；
5. Viewport 或 SubViewport 是否是事件实际进入的目标。

按钮的 `pressed`、LineEdit 的焦点信号等高层信号，通常比在场景根节点解析原始键盘事件更合适。当前 `tests/input/` 通过按钮、CheckBox、LineEdit、焦点和面板 `gui_input` 观察这些差异。

## 5. 鼠标与 2D 坐标

`get_viewport().get_mouse_position()` 返回 Viewport 坐标；`get_global_mouse_position()` 返回当前 Canvas 中的全局坐标。需要转换到某个 Node2D 局部空间时使用 `to_local()`：

```gdscript
var viewport_point := get_viewport().get_mouse_position()
var canvas_point := get_viewport().get_canvas_transform().affine_inverse() * viewport_point
var local_point := _world.to_local(canvas_point)
```

对于普通世界节点，优先使用：

```gdscript
var world_mouse: Vector2 = _world.get_global_mouse_position()
var local_mouse: Vector2 = _target.to_local(world_mouse)
```

不要把窗口像素、Viewport 坐标、Canvas 全局坐标和节点局部坐标直接相加。Camera2D、CanvasLayer、窗口 Stretch、SubViewport 和嵌套 Control 都可能改变转换基准。点击偏移时先确定事件来源的 Viewport，再选择对应的转换函数。

## 6. 输入到游戏状态的边界

推荐流程是：

```text
物理按键 / 鼠标 / 手柄
→ InputMap Action 或 UI 信号
→ 类型化输入请求
→ 应用/领域入口
→ 合法性判断与状态提交
→ Signal / 表现 / UI 更新
```

输入节点可以做设备兼容和轻量预检，但不应直接修改真实游戏状态。比如按钮只提交“选择目标”请求，是否允许选择由拥有状态的对象判断。

## 7. 当前验证与常见问题

`tests/input/` 覆盖运行时注册 Action、`_input()`、`_unhandled_input()`、`_gui_input()`、按钮、焦点、触摸和拖动。`tests/canvas_transform/` 补充验证 Node2D 的局部/全局/Canvas 坐标转换。

- Action 没反应：检查 Action 名、绑定事件、Deadzone 和当前输入是否被 UI 消费。
- UI 和玩法同时响应：检查传播阶段、`accept_event()` 和是否同时实现了 `_input()` 与 `_unhandled_input()`。
- 鼠标位置偏移：确认 Viewport、Camera2D、CanvasLayer、Stretch 和局部坐标转换。
- LineEdit 无法输入：检查焦点、disabled 状态和是否有更早的 `_input()` 消费键盘事件。
- 运行测试后 Action 残留：清理运行时创建的 Action，不要修改项目原有绑定。

## 8. 官方参考

- [Using InputEvent — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/inputs/inputevent.html)
- [InputMap — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_inputmap.html)
- [Input — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_input.html)
- [Control — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_control.html)
