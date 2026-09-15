extends Control

# 验证目标：验证 FileAccess、JSON、ConfigFile 在 user:// 下的保存、读取和清理。
# 机制说明：文件路径使用 user://，避免测试写入项目资源目录，也便于重复执行验证。

const JSON_PATH := "user://validation_data.json"
const CONFIG_PATH := "user://validation_data.cfg"

@onready var _text: LineEdit = %Text
@onready var _amount: SpinBox = %Amount
@onready var _status: Label = %Status
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _clear_button: Button = %ClearButton

func _ready() -> void:
	_save_button.pressed.connect(_save_data)
	_load_button.pressed.connect(_load_data)
	_clear_button.pressed.connect(_clear_data)

func _save_data() -> void:
	var data := {"text": _text.text, "amount": int(_amount.value)}
	var json_file := FileAccess.open(JSON_PATH, FileAccess.WRITE)
	if json_file == null:
		_status.text = "JSON 打开失败：%s" % error_string(FileAccess.get_open_error())
		return
	json_file.store_string(JSON.stringify(data))
	json_file.close()
	var config := ConfigFile.new()
	config.set_value("validation", "text", _text.text)
	config.set_value("validation", "amount", int(_amount.value))
	var error := config.save(CONFIG_PATH)
	_status.text = "已保存 JSON 和 ConfigFile：%s" % error_string(error)

func _load_data() -> void:
	if not FileAccess.file_exists(JSON_PATH) or not FileAccess.file_exists(CONFIG_PATH):
		_status.text = "没有找到已保存数据"
		return
	var json_file := FileAccess.open(JSON_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(json_file.get_as_text())
	json_file.close()
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if not parsed is Dictionary or error != OK:
		_status.text = "读取失败：JSON=%s ConfigFile=%s" % ["无效" if not parsed is Dictionary else "有效", error_string(error)]
		return
	_text.text = str(parsed["text"])
	_amount.value = float(parsed["amount"])
	_status.text = "已读取：JSON 和 ConfigFile"

func _clear_data() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(JSON_PATH))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CONFIG_PATH))
	_status.text = "已删除本测试生成的 user:// 文件"
