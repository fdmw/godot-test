extends Control

# 验证目标：对比 preload、ResourceLoader、ResourcePreloader 的加载、缓存和释放行为。
# 机制说明：静态 preload 资源来自场景导出属性，运行时加载资源单独保存并可显式释放引用。

@export var preload_data: Resource

@onready var _preloader: ResourcePreloader = %Preloader
@onready var _status: Label = %Status
@onready var _preload_value: Label = %PreloadValue
@onready var _load_value: Label = %LoadValue
@onready var _preloader_value: Label = %PreloaderValue
@onready var _load_button: Button = %LoadButton
@onready var _release_button: Button = %ReleaseButton

var _loaded_data: Resource

func _ready() -> void:
	_preloader.add_resource("demo", preload_data)
	_load_button.pressed.connect(_load_resource)
	_release_button.pressed.connect(_release_loaded_resource)
	_refresh_values()

func _load_resource() -> void:
	_loaded_data = ResourceLoader.load(preload_data.resource_path, "Resource", ResourceLoader.CACHE_MODE_REUSE)
	_refresh_values()
	_status.text = "ResourceLoader.load() 已完成"

func _release_loaded_resource() -> void:
	_loaded_data = null
	_refresh_values()
	_status.text = "已释放 ResourceLoader 返回的运行时引用"

func _refresh_values() -> void:
	_preload_value.text = _format_data("preload 引用", preload_data)
	_load_value.text = _format_data("ResourceLoader", _loaded_data)
	var preloaded: Resource = _preloader.get_resource("demo")
	_preloader_value.text = _format_data("ResourcePreloader", preloaded)

func _format_data(source: String, data: Resource) -> String:
	if data == null:
		return "%s：未加载" % source
	return "%s：%s / value=%d" % [source, str(data.get("title")), int(data.get("value"))]
