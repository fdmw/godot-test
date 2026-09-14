extends Control

# 验证目标：验证 Skeleton2D、Bone2D 层级、姿态变换和 TwoBoneIK 修改栈。
# 机制说明：骨骼层级固定在场景；IK 修改对象运行时创建，因为本测试直接验证修改栈配置接口。

@onready var _skeleton: Skeleton2D = %Skeleton
@onready var _upper_bone: Bone2D = %UpperBone
@onready var _lower_bone: Bone2D = %LowerBone
@onready var _ik_target: Marker2D = %IKTarget
@onready var _pose_button: Button = %PoseButton
@onready var _reset_button: Button = %ResetButton
@onready var _ik_toggle: CheckBox = %IKToggle
@onready var _flip_toggle: CheckBox = %FlipToggle
@onready var _move_target_button: Button = %MoveTargetButton
@onready var _status: Label = %Status

var _posed: bool = false
var _ik_stack: SkeletonModificationStack2D
var _two_bone_ik: SkeletonModification2DTwoBoneIK

func _enter_tree() -> void:
	var lower_bone := get_node("Layout/Preview/Skeleton/UpperBone/LowerBone") as Bone2D
	# 测试手动控制骨骼长度，关闭自动计算以避免编辑器/运行时重新推导覆盖演示值。
	lower_bone.set_autocalculate_length_and_angle(false)

func _ready() -> void:
	_pose_button.pressed.connect(_toggle_pose)
	_reset_button.pressed.connect(_reset_pose)
	_ik_toggle.toggled.connect(_set_ik_enabled)
	_flip_toggle.toggled.connect(_set_flip_direction)
	_move_target_button.pressed.connect(_move_ik_target)
	_build_ik()
	_reset_pose()

func _build_ik() -> void:
	# IK 修改栈是本测试要验证的运行时 API；UpperBone/LowerBone 对应骨骼索引 0/1。
	_two_bone_ik = SkeletonModification2DTwoBoneIK.new()
	_two_bone_ik.set_joint_one_bone_idx(0)
	_two_bone_ik.set_joint_two_bone_idx(1)
	# 目标路径相对于 Skeleton2D 所在节点解析，IKTarget 与 Skeleton 是同级节点。
	_two_bone_ik.set_target_node(NodePath("../IKTarget"))
	_ik_stack = SkeletonModificationStack2D.new()
	_ik_stack.add_modification(_two_bone_ik)
	_ik_stack.enabled = false
	_skeleton.set_modification_stack(_ik_stack)

func _set_ik_enabled(value: bool) -> void:
	_ik_stack.enabled = value
	_status.text = "TwoBoneIK：" + ("开启" if value else "关闭")

func _set_flip_direction(value: bool) -> void:
	_two_bone_ik.flip_bend_direction = value
	_status.text = "TwoBoneIK 弯曲方向：" + ("反向" if value else "默认")

func _move_ik_target() -> void:
	_ik_target.position += Vector2(28, 18)
	_status.text = "IK 目标位置：%s" % _ik_target.position

func _toggle_pose() -> void:
	_posed = not _posed
	if _posed:
		_upper_bone.rotation = deg_to_rad(-22.0)
		_lower_bone.rotation = deg_to_rad(58.0)
		_pose_button.text = "恢复姿态"
		_status.text = "已应用骨骼姿态"
	else:
		_reset_pose()

func _reset_pose() -> void:
	_posed = false
	_upper_bone.rotation = 0.0
	_lower_bone.rotation = 0.0
	_ik_target.position = Vector2(350, 140)
	_pose_button.text = "应用姿态"
	_status.text = "Skeleton2D：%d 个 Bone2D；TwoBoneIK 待启用" % _skeleton.get_bone_count()
