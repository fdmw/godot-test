extends Control

# 验证目标：验证节点加入、移除、查询 Group，以及 Group 对成员的批量操作边界。
# 机制说明：Group 只用于分类和查询；测试不依赖 Group 进行服务定位或核心逻辑派发。

const VALIDATION_GROUP: StringName = &"validation_items"

@onready var _item_a: ColorRect = %ItemA
@onready var _item_b: ColorRect = %ItemB
@onready var _toggle_button: Button = %ToggleButton
@onready var _highlight_button: Button = %HighlightButton
@onready var _status: Label = %Status

func _ready() -> void:
	_toggle_button.pressed.connect(_toggle_item_b)
	_highlight_button.pressed.connect(_highlight_group)
	_update_status()

func _toggle_item_b() -> void:
	if _item_b.is_in_group(VALIDATION_GROUP):
		_item_b.remove_from_group(VALIDATION_GROUP)
	else:
		_item_b.add_to_group(VALIDATION_GROUP)
	_update_status()

func _highlight_group() -> void:
	for node: Node in get_tree().get_nodes_in_group(VALIDATION_GROUP):
		var item := node as ColorRect
		if item != null:
			item.color = Color("#70c8ff")
	_status.text = "已通过 Group 查询批量更新 %d 个节点" % _group_size()

func _update_status() -> void:
	_toggle_button.text = "移除 Item B" if _item_b.is_in_group(VALIDATION_GROUP) else "加入 Item B"
	_status.text = "validation_items 成员：%d\nItem A：%s\nItem B：%s" % [
		_group_size(),
		"是" if _item_a.is_in_group(VALIDATION_GROUP) else "否",
		"是" if _item_b.is_in_group(VALIDATION_GROUP) else "否",
	]

func _group_size() -> int:
	return get_tree().get_nodes_in_group(VALIDATION_GROUP).size()
