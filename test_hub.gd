extends Control

const TEST_TITLES: Array[String] = ["基础控件", "TileMap", "粒子特效", "物理", "动画", "摄像机", "音频", "导航", "Viewport", "输入", "2D 渲染", "场景资源", "Tween", "资源数据", "文件配置", "场景生命周期", "音频总线", "窗口显示", "可见性", "物理扩展"]
const TEST_SUMMARIES: Array[String] = [
	"验证常用输入、操作、选择、数值、布局和展示控件。",
	"验证 TileMapLayer 场景和本地素材引用。",
	"验证 GPUParticles2D 和 ParticleProcessMaterial 的常用特性。",
	"验证常用 2D 物理节点、碰撞体和空间查询。",
	"验证 AnimationPlayer、AnimatedSprite2D 和 Timer。",
	"验证 Camera2D、CanvasLayer、缩放、平滑和边界。",
	"验证普通音频、空间音频、监听器和播放参数。",
	"验证 NavigationRegion2D、NavigationAgent2D 和 NavigationObstacle2D。",
	"验证 SubViewport、SubViewportContainer、ViewportTexture 和输入传递。",
	"验证 InputMap、_input、_unhandled_input、_gui_input 和焦点。",
	"验证常用 2D 绘制节点、灯光、遮挡、画布调制和 ShaderMaterial。",
	"验证 PackedScene 实例化、节点配置、queue_free 和资源读取。",
	"验证 Tween 的缓动、串行、并行和终止。",
	"验证自定义 Resource、复制、资源引用和运行时只读边界。",
	"验证 FileAccess、JSON、ConfigFile 和 user:// 持久化。",
	"验证节点进入树、ready、process、退出树和释放顺序。",
	"验证 AudioBus、音量、静音和总线效果器。",
	"验证窗口尺寸、全屏模式、拉伸和 Viewport 尺寸。",
	"验证 CanvasItem 可见性和 VisibleOnScreenNotifier2D。",
	"验证 2D 物理关节、刚体连接和关节启停。",
]
const TEST_SCENES: Array[String] = [
	"res://controls/control_test.tscn",
	"res://tilemap/tilemap_test.tscn",
	"res://particles/particles_test.tscn",
	"res://physics/physics_test.tscn",
	"res://animation/animation_test.tscn",
	"res://camera/camera_test.tscn",
	"res://audio/audio_test.tscn",
	"res://navigation/navigation_test.tscn",
	"res://viewport/viewport_test.tscn",
	"res://input/input_test.tscn",
	"res://rendering/rendering_test.tscn",
	"res://scene_resource/scene_resource_test.tscn",
	"res://tween/tween_test.tscn",
	"res://resource_data/resource_data_test.tscn",
	"res://file_config/file_config_test.tscn",
	"res://scene_lifecycle/scene_lifecycle_test.tscn",
	"res://audio_bus/audio_bus_test.tscn",
	"res://window_display/window_display_test.tscn",
	"res://visibility/visibility_test.tscn",
	"res://physics_extra/physics_extra_test.tscn",
]

@onready var _selector: OptionButton = %Selector
@onready var _reset_button: Button = %ResetButton
@onready var _title: Label = %Title
@onready var _summary: Label = %Summary
@onready var _content: Control = %Content
var _current_test: Control

func _ready() -> void:
	for title: String in TEST_TITLES:
		_selector.add_item(title)
	_selector.item_selected.connect(_select_test)
	_reset_button.pressed.connect(_reset_test)
	_select_test(0)

func _select_test(index: int) -> void:
	if index < 0 or index >= TEST_SCENES.size():
		return
	_title.text = TEST_TITLES[index]
	_summary.text = TEST_SUMMARIES[index]
	_free_current_test()
	var packed_scene := load(TEST_SCENES[index]) as PackedScene
	if packed_scene == null:
		_summary.text = "场景加载失败：" + TEST_SCENES[index]
		return
	var instance := packed_scene.instantiate()
	_current_test = instance as Control
	if _current_test == null:
		instance.free()
		_summary.text = "测试场景根节点必须是 Control。"
		return
	_content.add_child(_current_test)

func _reset_test() -> void:
	_select_test(_selector.selected)

func _free_current_test() -> void:
	if not is_instance_valid(_current_test):
		_current_test = null
		return
	_current_test.queue_free()
	_current_test = null
