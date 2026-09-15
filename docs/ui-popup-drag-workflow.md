# Popup、Dialog 与 Control 拖放工作流

本文说明常用弹窗节点和 Control 拖放接口，重点回答“弹窗如何显示和取得结果”“拖动源与放置目标如何协作”“UI 场景如何保持独立”。

## 1. Popup、Dialog 与 Window 的区别

| 类型 | 适合场景 | 典型结果 |
| --- | --- | --- |
| `PopupMenu` | 上下文菜单、选项菜单 | `id_pressed`、`index_pressed` |
| `PopupPanel` | 自定义的小型浮层 | 自己处理内部控件信号 |
| `AcceptDialog` | 只有确认动作的提示 | `confirmed` |
| `ConfirmationDialog` | 确认/取消操作 | `confirmed`、`canceled` |
| `FileDialog` | 文件或目录选择 | `file_selected`、`files_selected`、`dir_selected` |
| `Window` | 独立窗口或需要独立 Viewport 的内容 | 窗口关闭、焦点和 Viewport 行为 |

`Window` 继承 Viewport，不是 Control。需要固定在当前页面中的菜单、提示和对话框，通常使用 Popup/AcceptDialog/ConfirmationDialog；需要独立窗口行为时再使用 Window，并重新确认输入和坐标基准。

## 2. Dialog 的编辑器和脚本流程

弹窗节点可以直接放在页面场景中，由页面控制显示：

1. 添加 AcceptDialog、ConfirmationDialog、FileDialog 或 PopupPanel；
2. 在场景中配置标题、尺寸、初始文本、过滤器和内部控件；
3. 保存场景，保持弹窗节点与页面一起管理生命周期；
4. 页面脚本连接确认、取消、选择和关闭信号；
5. 点击按钮时调用 `popup_centered()`、`popup()` 等显示方法；
6. 结果通过 Signal 返回页面，再由页面提交后续请求。

```gdscript
@onready var _confirm: ConfirmationDialog = %ConfirmDialog

func _ready() -> void:
	_confirm.confirmed.connect(_on_confirmed)
	_confirm.canceled.connect(_on_canceled)

func ask_delete() -> void:
	_confirm.popup_centered()

func _on_confirmed() -> void:
	# 这里只提交“确认删除”请求，实际合法性由拥有数据的对象判断。
	delete_requested.emit()

func _on_canceled() -> void:
	_confirm.hide()
```

弹窗的显示是 UI 行为，业务提交仍应经过明确接口。不要让 Dialog 直接遍历场景树寻找要修改的对象，也不要把弹窗做成全局状态容器。

## 3. PopupMenu 与 FileDialog

`PopupMenu` 的菜单项可以在编辑器中固定，也可以在运行时由脚本根据当前菜单内容添加。每个菜单项使用稳定 ID，接收 `id_pressed` 后通过明确的 `match` 或接口处理：

```gdscript
func _on_menu_id_pressed(id: int) -> void:
	match id:
		1:
			request_copy()
		2:
			request_delete()
		_:
			return
```

`FileDialog` 只负责选择路径，不负责读取、写入或验证文件内容。收到 `file_selected(path)` 后，交给明确的数据层接口检查路径和权限；不要把用户选择的路径直接当成可信存档数据。

## 4. Control 拖放的两端

Godot Control 拖放通常由四个步骤组成：

```text
拖动源 _get_drag_data()
→ 设置 drag preview
→ 目标 _can_drop_data()
→ 目标 _drop_data()
→ 目标 Signal 通知页面
```

拖动源示例：

```gdscript
func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = item_text
	set_drag_preview(preview)
	drag_started.emit(item_text)
	return {"item_text": item_text}
```

放置目标示例：

```gdscript
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item_text")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_dropped.emit(String(data["item_text"]))
```

`_can_drop_data()` 只做可放置判断，不要在其中修改状态；它可能被调用多次。`_drop_data()` 才是放置发生后的入口，但仍应先验证数据类型和目标状态。拖动预览只负责显示，不应成为真实物品对象。

## 5. 拖放与输入传播

拖放是 Control 输入体系的一部分，目标区域的 `mouse_filter`、可见性、禁用状态和父节点裁剪都会影响命中。排查时检查：

1. 源控件是否真的返回了非空拖放数据；
2. `set_drag_preview()` 的预览节点是否只用于表现；
3. 目标控件的 `_can_drop_data()` 是否返回 true；
4. 目标及祖先的 Mouse Filter 是否拦截或忽略鼠标；
5. 放置后的 Signal 是否连接到当前页面，而不是已经释放的场景。

可放置性和业务合法性可以分两层：UI 层先判断数据形状，领域/数据拥有者再判断容量、类型、权限和目标状态。不要因为 `_can_drop_data()` 返回 true 就直接认定业务操作一定成功。

## 6. 当前验证与常见问题

`tests/dialog/` 验证 AcceptDialog、ConfirmationDialog、FileDialog 和 PopupPanel 的显示及结果信号；`tests/drag_drop/` 验证拖动预览、`_can_drop_data()`、`_drop_data()` 和两端 Signal。

- 弹窗不显示：检查节点是否在 SceneTree、是否被其他 Popup 覆盖、尺寸和位置是否有效。
- ConfirmationDialog 无结果：检查 `confirmed`/`canceled` 是否连接一次，按钮是否被禁用或被其他控件拦截。
- FileDialog 选到路径却无法保存：路径选择和文件读写是两步，继续检查权限、目录和数据层验证。
- 拖动没有开始：检查源控件的拖动判定和 `_get_drag_data()` 返回值。
- 目标始终不能放置：检查 `_can_drop_data()` 的数据类型、目标 Mouse Filter 和控件层级。
- 放置后状态重复变化：避免在 `_can_drop_data()` 中修改状态，检查 Signal 是否重复连接。

## 7. 官方参考

- [Popup — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_popup.html)
- [AcceptDialog — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_acceptdialog.html)
- [ConfirmationDialog — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_confirmationdialog.html)
- [FileDialog — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_filedialog.html)
- [Control — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_control.html)
- [Window — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_window.html)
