# Control、Container 与 Theme 工作流

本文说明 Godot UI 中 `Control` 的坐标和布局、Container 的自动排列，以及 Theme/StyleBox 的样式覆盖。UI 应优先表达“相对父控件如何布局”，而不是堆积固定屏幕坐标。

## 1. Control 与 Node2D 的区别

`Control` 同样继承 `CanvasItem`，但它的尺寸和位置主要由 anchors、offsets、minimum size、size flags 与父 Container 决定。Node2D 的 `position`/`scale` 思维不能直接套用到 UI。

```text
Control 的矩形
├── Anchors：相对于父控件或 Viewport 的比例位置
├── Offsets：相对于 Anchor 的像素偏移
├── Minimum Size：控件愿意接受的最小尺寸
└── Container：可能重新计算子控件布局
```

编辑器中调整 UI 时，先选父控件，在 Layout 菜单选择合适的 Anchor Preset，再调整 offsets。需要铺满父控件时通常使用 Full Rect；需要固定边距时让 offsets 表达边距，而不是把控件放到某个分辨率下的绝对坐标。

## 2. Anchors 与 Offsets

四个 anchor 是 0～1 的比例参考点，四个 offset 是相对于这些参考点的像素偏移。父控件尺寸变化时，anchor 决定控件边缘跟随父控件的哪一侧，offset 决定具体边距和尺寸。

常见布局意图：

| 意图 | Anchor/Offset 思路 |
| --- | --- |
| 左上角固定 | 左上 anchors，设置正的 left/top offsets |
| 右下角固定 | 右下 anchors，使用合适的负 right/bottom offsets |
| 横向铺满且保留边距 | left/right anchors 分别在 0/1，设置左右 offsets |
| 居中固定尺寸 | 四个 anchors 设为 0.5，用正负 offsets 表达半尺寸 |
| HUD 铺满视口 | 根 Control 使用 Full Rect，子节点再按功能分区 |

当 offset 位于 anchor 的左侧或上方时，需要使用负值。调整 anchors 后要重新检查 offsets；只改变一个 anchor 往往会让控件尺寸瞬间变大或变小。

## 3. Container 的职责

Container 会根据子控件的 minimum size、size flags 和自身布局规则重新排列子节点。常见选择：

- `MarginContainer`：统一提供内边距；
- `VBoxContainer` / `HBoxContainer`：纵向或横向排列；
- `GridContainer`：固定列数的网格，如背包格；
- `CenterContainer`：让一个或多个子节点居中；
- `PanelContainer`：以 Panel/StyleBox 作为容器背景；
- `ScrollContainer`：显示可滚动的超出内容；
- `TabContainer`：组织多个页面；
- `AspectRatioContainer`：保持子内容宽高比。

复杂 UI 推荐按层级组合 Container：

```text
MarginContainer
└── VBoxContainer
    ├── HBoxContainer（标题和操作）
    ├── GridContainer（内容区）
    └── HBoxContainer（底部按钮）
```

不要在 Container 管理的子节点上反复手工设置 position/size；这些值可能在下一次布局时被覆盖。需要控制间距时使用 Container 的 theme constants、子节点的 minimum size 和 size flags。

## 4. Size Flags 与 Minimum Size

`custom_minimum_size` 表达控件在布局中不希望被压缩到的最小尺寸。Horizontal/Vertical Size Flags 决定控件在父 Container 剩余空间中的扩展、收缩和填充方式。

排查 Container 布局时按顺序检查：

1. 父节点是否真的是预期的 Container；
2. 子节点的 custom minimum size 是否过大；
3. size flags 是否让某个子节点独占剩余空间；
4. Container 的 separation、margin 等 theme constant；
5. 外层 Control 的 anchors、offsets 和窗口 Stretch。

## 5. Theme、Theme Override 与 StyleBox

Theme 是可复用的样式 Resource，按控件类型提供 Color、Constant、Font、Font Size、Icon 和 StyleBox 等 theme item。Theme 从父 Control 向子 Control 传播；子控件可以通过 Theme Override 局部覆盖。

推荐的样式层级：

```text
项目 Theme / 页面根 Control Theme
→ 子树继承统一风格
→ 特定控件 Theme Override 做少量例外
→ StyleBox 描述 normal/hover/pressed/focus 等状态外观
```

编辑器操作：

1. 创建或选中页面根 Control；
2. 在 Theme 属性中创建/加载 Theme 资源；
3. 在 Theme 面板按控件类型添加字体、颜色、常量、图标和 StyleBox；
4. 在 Button、LineEdit 等控件上检查各状态的 StyleBox；
5. 只有个别控件需要例外时，再使用 Theme Overrides；
6. 将可复用 Theme 保存为 `.tres`，不要在多个场景中复制一整套样式数值。

StyleBox 的 `normal`、`hover`、`pressed`、`disabled` 和 `focus` 是不同状态。focus StyleBox 通常设计为轮廓或半透明叠加，否则可能遮住正常背景。Theme Override 优先级高于继承 Theme，因此“改了 Theme 但控件不变”时要先清除控件自己的覆盖值。

## 6. 当前验证与常见问题

`tests/controls/` 集中验证 Label、TextEdit、Button、CheckBox、OptionButton、SpinBox、Slider、ColorPickerButton、ItemList、PopupMenu、Tree 和 Theme 切换；页面布局本身由场景中的 Control/Container 固定。

- UI 在窗口缩放后错位：检查 anchors/offsets 和 Project Stretch，不要继续增加绝对坐标。
- Container 改掉手工位置：这是预期行为，把布局意图放到 Container、minimum size 和 size flags。
- Theme 覆盖不生效：检查控件或祖先是否有更高优先级的 Theme Override。
- Button 状态样式异常：分别检查 normal、hover、pressed、disabled 和 focus StyleBox。
- 控件被压得太小：检查 custom minimum size、Container 的可用空间和 size flags。
- UI 输入不符合预期：继续检查 focus、mouse_filter 和 `gui_input`，详见 [InputMap、输入事件与鼠标坐标工作流](input-workflow.md)。

## 7. 官方参考

- [Control — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_control.html)
- [Size and anchors — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/ui/size_and_anchors.html)
- [Container — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_container.html)
- [Introduction to GUI skinning — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html)
- [Theme — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_theme.html)
