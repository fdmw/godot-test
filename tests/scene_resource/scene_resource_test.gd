extends Control

# 验证目标：验证 PackedScene 加载、实例化、运行时节点生命周期和批量清理。
# 机制说明：运行时实例化是本测试目标，因此实例放入专用 SpawnRoot，并由清理按钮统一 queue_free。

var _packed_scene: PackedScene
@onready var _spawn_root: Node2D = %SpawnRoot
@onready var _status: Label = %Status
@onready var _spawn_button: Button = %SpawnButton
@onready var _clear_button: Button = %ClearButton
var _spawn_count := 0

func _ready() -> void:
	_packed_scene = load("res://tests/scene_resource/spawned_item.tscn") as PackedScene
	_spawn_button.pressed.connect(_spawn_item)
	_clear_button.pressed.connect(_clear_items)

func _spawn_item() -> void:
	if _packed_scene == null:
		_status.text = "PackedScene 加载失败"
		return
	var item := _packed_scene.instantiate() as Node2D
	if item == null:
		_status.text = "实例根节点不是 Node2D"
		return
	# 这里的运行时创建本身就是 PackedScene 验证目标；统一挂入 SpawnRoot 便于清理。
	_spawn_count += 1
	item.position = Vector2(380 + (_spawn_count % 4) * 130, 180 + (_spawn_count % 3) * 110)
	_spawn_root.add_child(item)
	if item.has_method("configure"):
		var color := Color.from_hsv(fmod(float(_spawn_count) * 0.17, 1.0), 0.55, 1.0)
		item.configure(color, 0.2 + float(_spawn_count % 3) * 0.05)
	_status.text = "已实例化第 %d 个场景节点" % _spawn_count

func _clear_items() -> void:
	for child: Node in _spawn_root.get_children():
		child.queue_free()
	_spawn_count = 0
	_status.text = "已请求 queue_free，实例计数已重置"
