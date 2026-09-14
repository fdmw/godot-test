extends Control

@onready var _accept_dialog: AcceptDialog = %AcceptDialog
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmationDialog
@onready var _file_dialog: FileDialog = %FileDialog
@onready var _popup_panel: PopupPanel = %PopupPanel
@onready var _status: Label = %Status
@onready var _accept_button: Button = %AcceptButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _file_button: Button = %FileButton
@onready var _popup_button: Button = %PopupButton

func _ready() -> void:
	_accept_button.pressed.connect(_show_accept_dialog)
	_confirm_button.pressed.connect(_show_confirmation_dialog)
	_file_button.pressed.connect(_show_file_dialog)
	_popup_button.pressed.connect(_show_popup_panel)
	_accept_dialog.confirmed.connect(_on_accept_confirmed)
	_confirm_dialog.confirmed.connect(_on_confirmation_confirmed)
	_confirm_dialog.canceled.connect(_on_confirmation_canceled)
	_file_dialog.file_selected.connect(_on_file_selected)
	_update_status("等待打开弹窗")

func _show_accept_dialog() -> void:
	_accept_dialog.popup_centered()
	_update_status("已打开 AcceptDialog")

func _show_confirmation_dialog() -> void:
	_confirm_dialog.popup_centered()
	_update_status("已打开 ConfirmationDialog")

func _show_file_dialog() -> void:
	_file_dialog.popup_centered()
	_update_status("已打开 FileDialog")

func _show_popup_panel() -> void:
	_popup_panel.popup_centered()
	_update_status("已打开 PopupPanel")

func _on_accept_confirmed() -> void:
	_update_status("AcceptDialog 已确认")

func _on_confirmation_confirmed() -> void:
	_update_status("ConfirmationDialog 已确认")

func _on_confirmation_canceled() -> void:
	_update_status("ConfirmationDialog 已取消")

func _on_file_selected(path: String) -> void:
	_update_status("FileDialog 选择：" + path)

func _update_status(message: String) -> void:
	_status.text = message
