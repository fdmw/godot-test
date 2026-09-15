extends Control

# 验证目标：验证 TranslationServer、ResourcePreloader、语言切换和动态文本翻译。
# 生命周期说明：进入场景时保存原语言，退出场景时恢复，避免影响测试台和其他场景。

@onready var _translations: ResourcePreloader = %Translations
@export var zh_translation: Translation
@export var en_translation: Translation
@onready var _locale_selector: OptionButton = %LocaleSelector
@onready var _name_input: LineEdit = %NameInput
@onready var _greeting: Label = %Greeting
@onready var _message: Label = %Message
@onready var _status: Label = %Status
@onready var _refresh_button: Button = %RefreshButton

var _zh_translation: Translation
var _en_translation: Translation
var _original_locale: String = ""

func _ready() -> void:
	_original_locale = TranslationServer.get_locale()
	_translations.add_resource("zh", zh_translation)
	_translations.add_resource("en", en_translation)
	_zh_translation = _translations.get_resource("zh") as Translation
	_en_translation = _translations.get_resource("en") as Translation
	TranslationServer.add_translation(_zh_translation)
	TranslationServer.add_translation(_en_translation)
	_locale_selector.add_item("中文")
	_locale_selector.add_item("English")
	_locale_selector.item_selected.connect(_set_locale)
	_name_input.text_changed.connect(_refresh_text)
	_refresh_button.pressed.connect(_refresh_text)
	_set_locale(0)

func _exit_tree() -> void:
	# TranslationServer 是进程级服务，退出时撤销本测试注册的翻译并恢复原语言。
	if _zh_translation != null:
		TranslationServer.remove_translation(_zh_translation)
	if _en_translation != null:
		TranslationServer.remove_translation(_en_translation)
	if not _original_locale.is_empty():
		TranslationServer.set_locale(_original_locale)

func _set_locale(index: int) -> void:
	TranslationServer.set_locale("zh_CN" if index == 0 else "en")
	_refresh_text()

func _refresh_text(_value: String = "") -> void:
	var display_name := _name_input.text.strip_edges()
	if display_name.is_empty():
		display_name = "开发者" if TranslationServer.get_locale() == "zh_CN" else "Developer"
	_greeting.text = TranslationServer.translate("demo_greeting") % [display_name]
	_message.text = TranslationServer.translate("demo_message")
	_status.text = "当前 locale：%s" % TranslationServer.get_locale()
