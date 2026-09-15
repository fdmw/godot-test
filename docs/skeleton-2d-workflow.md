# Skeleton2D、Bone2D 与 2D IK 工作流

本文说明 Godot 原生 2D 骨骼的基本组成、编辑器操作和运行时修改边界。它只覆盖足以判断是否适合使用骨骼的内容，不替代完整的角色动画制作教程。

## 1. 适用范围与当前测试

骨骼适合多部件角色、布偶式 Cutout Animation 和需要运行时调整姿态的对象。如果角色主要使用序列帧，通常不必为了“完整使用 Godot”而引入 Skeleton2D。

当前验证入口是 `tests/skeleton_2d/`，场景固定了 `Skeleton2D → UpperBone → LowerBone` 层级，并用两个 Polygon2D 表示骨骼段。界面可以应用姿态、恢复姿态、启用 TwoBoneIK、反转弯曲方向以及移动 IK 目标。

## 2. 编辑器中的建立流程

1. 创建 `Skeleton2D` 作为骨骼根节点。
2. 在 Skeleton2D 下添加第一个 `Bone2D`，再将后续 Bone2D 按关节层级作为子节点添加。
3. 用节点的位置和旋转放置关节；骨骼的 `length` 主要用于末端骨骼的显示和部分工具计算。
4. 选中 Skeleton2D，在 2D 编辑器的骨骼工具中执行 `Overwrite Rest Pose`，保存初始姿态。
5. 让 Polygon2D 等可变形节点绑定到 Skeleton2D，并通过 Polygon2D 的 UV/骨骼权重编辑完成变形数据。

Rest Pose 是“默认姿态”，不是运行时当前姿态。重新布置骨骼或增加骨骼后，应重新确认 Rest Pose；需要回到默认姿态时使用 Bone2D 的 `apply_rest()` 或编辑器的恢复操作。

## 3. FK、骨骼变换与 IK

直接修改 Bone2D 的位置、旋转或缩放属于正向控制（FK）。父骨骼的变换会影响子骨骼及其子节点，因此角色姿态应优先修改合适层级的关节，而不是同时给每个子节点写一套独立坐标。

IK 则由目标反推骨骼姿态。Godot 4 的 IK 修改通常由以下对象组成：

```text
Skeleton2D
└── SkeletonModificationStack2D
    └── SkeletonModification2DTwoBoneIK
```

TwoBoneIK 只解决两段骨骼，适合手臂、腿等“两节链条”。需要正确指定第一段和第二段骨骼索引或 NodePath，并指定目标节点；`flip_bend_direction` 选择肘部/膝部向哪一侧弯曲，最小/最大距离可以限制目标的有效范围。

本项目测试在运行时创建修改栈，因为“创建和配置修改栈”本身就是验证目标。可确定的骨骼层级仍保存在 `.tscn` 中；正式项目若配置稳定，应优先在场景或专用资源中保存，而不是每次启动重新拼装。

> TwoBoneIK 相关类在 Godot 4.7 文档中标为 Experimental。使用前应确认目标版本的 API 和项目对兼容性的要求。

## 4. 常见误区

- Bone2D 是控制关节的 Node2D，不会自动让任意 Sprite2D 变形；可变形 Polygon2D 还需要绑定 Skeleton 和权重。
- `rest` 是相对父骨骼的基准 Transform；子骨骼的位置不应被误当成世界坐标。
- IK 目标必须位于修改器能解析的 NodePath 范围内，目标移动但链条不动时先检查路径、骨骼索引和修改栈是否启用。
- 骨骼姿态、碰撞几何和领域权威位置是不同事实。不要让表现用的 IK 或抖动直接覆盖物理规则所依赖的 Transform。

## 5. 当前项目对应关系

`tests/skeleton_2d/skeleton_2d_test.tscn` 验证静态骨骼层级、Polygon2D 子节点、初始 Rest Pose 和目标 Marker2D；`skeleton_2d_test.gd` 验证姿态修改、修改栈、TwoBoneIK、目标路径和退出前的场景隔离。

参考：[2D skeletons](https://docs.godotengine.org/en/4.7/tutorials/animation/2d_skeletons.html)、[Skeleton2D](https://docs.godotengine.org/en/4.7/classes/class_skeleton2d.html)、[Bone2D](https://docs.godotengine.org/en/4.7/classes/class_bone2d.html)、[SkeletonModification2DTwoBoneIK](https://docs.godotengine.org/en/4.7/classes/class_skeletonmodification2dtwoboneik.html)。
