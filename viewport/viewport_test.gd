extends Control

# 验证目标：验证 SubViewport、SubViewportContainer、ViewportTexture、刷新模式和输入传递。
# 机制说明：TextureRect 显示 SubViewport 的纹理；输入监听挂在 SubViewport 内容节点而不是主界面根节点。

@onready var _viewport: SubViewport = %Viewport
@onready var _viewport_label: Label = %ViewportLabel
@onready var _status: Label = %Status
@onready var _update: CheckBox = %Update
@onready var _texture_rect: TextureRect = %TextureRect
@onready var _viewport_content: Control = %ViewportContent

func _ready() -> void:
	_texture_rect.texture = _viewport.get_texture()
	_viewport_content.gui_input.connect(_on_viewport_input)
	_update.toggled.connect(_set_viewport_update)

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_status.text = "SubViewport 收到鼠标输入：" + str(event.position)
		_viewport_label.text = "最近点击：" + str(event.position)

func _set_viewport_update(value: bool) -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
