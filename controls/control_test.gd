extends Control

@export var validation_theme: Theme

@onready var _status: Label = %Status
@onready var _progress: ProgressBar = %Progress
@onready var _line_edit: LineEdit = %LineEdit
@onready var _text_edit: TextEdit = %TextEdit
@onready var _button: Button = %ActionButton
@onready var _check_box: CheckBox = %CheckBox
@onready var _option_button: OptionButton = %OptionButton
@onready var _spin_box: SpinBox = %SpinBox
@onready var _slider: HSlider = %Slider
@onready var _color_button: ColorPickerButton = %ColorButton
@onready var _item_list: ItemList = %ItemList
@onready var _popup_button: Button = %PopupButton
@onready var _popup_menu: PopupMenu = %PopupMenu
@onready var _tree: Tree = %Tree
@onready var _theme_toggle: CheckBox = %ThemeToggle

func _ready() -> void:
	_line_edit.text_changed.connect(_on_line_edit_changed)
	_text_edit.text_changed.connect(_on_text_edit_changed)
	_button.pressed.connect(_on_button_pressed)
	_check_box.toggled.connect(_on_check_box_toggled)
	_option_button.item_selected.connect(_on_option_selected)
	_spin_box.value_changed.connect(_on_value_changed)
	_slider.value_changed.connect(_on_value_changed)
	_color_button.color_changed.connect(_on_color_changed)
	_item_list.item_selected.connect(_on_item_selected)
	_popup_button.pressed.connect(_open_popup)
	_popup_menu.id_pressed.connect(_on_popup_item_pressed)
	_theme_toggle.toggled.connect(_set_validation_theme)

	_option_button.add_item("OptionButton：选项 A")
	_option_button.add_item("OptionButton：选项 B")
	_option_button.add_item("OptionButton：选项 C")
	_item_list.add_item("ItemList：项目一")
	_item_list.add_item("ItemList：项目二")
	_item_list.add_item("ItemList：项目三")
	_popup_menu.add_item("菜单项一", 1)
	_popup_menu.add_item("菜单项二", 2)
	_popup_menu.add_separator()
	_popup_menu.add_item("菜单项三", 3)

	var tree_root := _tree.create_item()
	tree_root.set_text(0, "Tree 根节点")
	var tree_child := _tree.create_item(tree_root)
	tree_child.set_text(0, "子节点")
	tree_child.set_text(1, "可展开")

func _on_line_edit_changed(value: String) -> void:
	_status.text = "LineEdit 文本长度：%d" % value.length()

func _on_text_edit_changed() -> void:
	_status.text = "TextEdit 内容已变化"

func _on_button_pressed() -> void:
	_status.text = "Button 已点击"

func _on_check_box_toggled(value: bool) -> void:
	_status.text = "CheckBox：" + ("选中" if value else "未选中")

func _on_option_selected(index: int) -> void:
	_status.text = "OptionButton 选择了第 %d 项" % (index + 1)

func _on_value_changed(value: float) -> void:
	_progress.value = value
	_status.text = "当前数值：%d" % value

func _on_color_changed(color: Color) -> void:
	_status.text = "ColorPickerButton：%s" % color.to_html(false)

func _on_item_selected(index: int) -> void:
	_status.text = "ItemList 选择了第 %d 项" % (index + 1)

func _open_popup() -> void:
	_popup_menu.popup()

func _on_popup_item_pressed(id: int) -> void:
	_status.text = "PopupMenu 选择了菜单项：%d" % id

func _set_validation_theme(value: bool) -> void:
	theme = validation_theme if value else null
	_status.text = "Theme：" + ("启用覆盖样式" if value else "恢复默认样式")
