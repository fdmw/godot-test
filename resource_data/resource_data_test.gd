extends Control

class ValidationResource extends Resource:
	@export var title: String = ""
	@export var amount: int = 0
	@export var tags: Array[String] = []

@onready var _status: Label = %Status
@onready var _resource_view: Label = %ResourceView
@onready var _create_button: Button = %CreateButton
@onready var _duplicate_button: Button = %DuplicateButton
@onready var _mutate_button: Button = %MutateButton
@onready var _reset_button: Button = %ResetButton
var _resource: ValidationResource
var _copy: ValidationResource

func _ready() -> void:
	_create_button.pressed.connect(_create_resource)
	_duplicate_button.pressed.connect(_duplicate_resource)
	_mutate_button.pressed.connect(_mutate_copy)
	_reset_button.pressed.connect(_reset_resource)
	_reset_resource()

func _create_resource() -> void:
	_resource = ValidationResource.new()
	_resource.title = "静态定义数据"
	_resource.amount = 10
	_resource.tags = ["共享", "只读基准"]
	_copy = null
	_update_view("已创建 Resource")

func _duplicate_resource() -> void:
	if _resource == null:
		_update_view("请先创建 Resource")
		return
	_copy = _resource.duplicate(true) as ValidationResource
	_update_view("已复制 Resource，等待修改副本")

func _mutate_copy() -> void:
	if _copy == null:
		_update_view("请先复制 Resource")
		return
	_copy.amount += 5
	_copy.tags.append("副本修改")
	_update_view("已修改副本，原资源不应变化")

func _reset_resource() -> void:
	_resource = null
	_copy = null
	_update_view("等待操作")

func _update_view(message: String) -> void:
	_status.text = message
	_resource_view.text = "原资源：%s\n副本：%s" % [_describe(_resource), _describe(_copy)]

func _describe(resource: ValidationResource) -> String:
	if resource == null:
		return "无"
	return "%s / amount=%d / tags=%s" % [resource.title, resource.amount, resource.tags]
