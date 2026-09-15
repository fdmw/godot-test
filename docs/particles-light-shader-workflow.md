# 2D 粒子、灯光与 CanvasItem Shader 工作流

本文说明 `GPUParticles2D`、`ParticleProcessMaterial`、`PointLight2D`、`LightOccluder2D`、`CanvasModulate` 和 `CanvasItem` Shader 的配置入口及职责边界。它们都属于 2D 表现系统，不能把粒子或灯光效果当作物理、导航或领域状态。

## 1. GPUParticles2D 的基本流程

编辑器中建立一个可观察的粒子系统：

1. 添加 `GPUParticles2D`；
2. 设置 `amount`、`lifetime`、`one_shot`、`explosiveness`、`randomness` 和 `preprocess`；
3. 在 `Process Material` 中新建 `ParticleProcessMaterial`；
4. 在 Draw Pass 中提供粒子要绘制的基础纹理或网格；
5. 调整发射形状、方向、Spread、初速度、重力、阻尼、缩放和颜色；
6. 保存场景，把基础纹理和初始参数作为静态配置保存在 `.tscn` 或资源中；
7. 运行时只修改需要验证的参数，并使用 `restart()` 或 `emitting` 控制表现。

核心属性可以按两组理解：

| 位置 | 典型属性 | 影响 |
| --- | --- | --- |
| GPUParticles2D | `amount`、`lifetime`、`one_shot` | 粒子数量、寿命和是否只发射一次 |
| GPUParticles2D | `explosiveness`、`randomness`、`speed_scale` | 发射时机和播放节奏 |
| GPUParticles2D | `local_coords`、`draw_order` | 粒子是否随发射器移动、绘制排序方式 |
| ParticleProcessMaterial | `emission_shape`、`direction`、`spread` | 从哪里发射以及初始方向 |
| ParticleProcessMaterial | `initial_velocity_*`、`gravity`、`damping_*` | 运动速度、持续加速度和阻尼 |
| ParticleProcessMaterial | `scale_*`、`color`、`hue_variation_*` | 大小、颜色和随机外观 |

`amount` 越大不一定越好；应结合粒子寿命、纹理尺寸、目标平台和实际画面需求观察。`preprocess` 适合让场景出现时看起来已经运行了一段时间，不能替代真正的运行状态保存。

## 2. 发射形状与局部坐标

`ParticleProcessMaterial.emission_shape` 决定粒子从点、球体、球面、盒体、环形等区域发出。选择形状后还要检查对应的尺寸、方向和节点 Transform；发射形状的坐标相对于粒子发射器。

`local_coords` 决定粒子生成后是否继续跟随发射器：

- 开启时，适合烟雾、火焰等与对象绑定的效果；
- 关闭时，适合爆炸、尘土等生成后留在世界中的效果；
- 切换时要观察发射器移动、旋转和缩放对已有粒子的影响。

粒子方向、重力和速度是表现参数。它们不应被用来模拟必须精确结算的移动、碰撞或伤害规则。

## 3. One Shot、轨迹和重启

持续喷射使用 `one_shot = false`，爆发效果通常使用 `one_shot = true`，然后在触发时 `restart()`：

```gdscript
@onready var _particles: GPUParticles2D = %Particles

func emit_burst() -> void:
	_particles.one_shot = true
	_particles.restart()
```

`trail_enabled` 和 `trail_lifetime` 用于粒子轨迹表现，启用后还要确认粒子材质、绘制方式和渲染设置满足轨迹要求。开启轨迹会增加表现成本，不能仅凭 Inspector 中出现开关就认为画面一定有明显拖尾。

`draw_order` 可以按索引或生命周期影响粒子前后关系。需要稳定的层次时，同时检查发射器的 Canvas 层、z-index 和粒子绘制顺序。

## 4. 2D 灯光与遮挡

### PointLight2D

`PointLight2D` 通常需要一张光照纹理来定义光斑形状。基本配置包括：

1. 添加 `PointLight2D`；
2. 设置 `texture`，检查纹理中心和透明边缘；
3. 调整 `energy`、`color`、`texture_scale` 和范围；
4. 通过 `range_item_cull_mask` 等层设置决定影响哪些 CanvasItem；
5. 需要阴影时启用 shadow 并配置对应的遮挡节点；
6. 用 `CanvasModulate` 或环境底色观察灯光是否确实产生了明暗差异。

灯光影响的是 CanvasItem 的显示，不会改变节点颜色属性、碰撞结果或导航结果。灯光不可见时，先检查纹理、能量、CanvasItem 的 light mask、灯光的 item cull mask 和当前渲染器。

### LightOccluder2D

`LightOccluder2D` 使用 `OccluderPolygon2D` 描述遮挡轮廓。遮挡轮廓是灯光阴影事实，不会自动成为物理碰撞体；如果同一形状还需要碰撞，应单独配置 CollisionShape2D 或 CollisionPolygon2D。

遮挡排错顺序：确认 PointLight2D 阴影已启用、遮挡多边形不是空的、灯光和遮挡层掩码匹配、节点处于同一个可见 Canvas，并检查灯光纹理范围是否覆盖遮挡物。

### CanvasModulate

`CanvasModulate` 对所在 Canvas 的整体颜色进行调制，常用于环境变暗、昼夜变化或统一色调。它会影响 Canvas 内的显示结果，但不等于一个点光源，也不应代替 UI 与世界分层设计。HUD 放在独立 CanvasLayer 时，应单独确认它是否需要受到环境调制。

## 5. CanvasItem Shader

2D 节点使用 `ShaderMaterial` 时，Shader 的入口应声明：

```glsl
shader_type canvas_item;

void fragment() {
	COLOR = texture(TEXTURE, UV) * COLOR;
}
```

常用内置量包括 `UV`、`TEXTURE`、`COLOR` 和 `TIME`。ShaderMaterial 只负责改变绘制过程；它不会替换节点 Transform、碰撞几何或脚本中的权威状态。

编辑器流程：

1. 选中 Sprite2D、Polygon2D 或其他 CanvasItem；
2. 在 Material 中新建 ShaderMaterial；
3. 新建 Shader，并确认 `shader_type canvas_item`；
4. 从最小的颜色或纹理采样开始，再逐步增加扭曲、闪烁和混合；
5. 在材质 Inspector 调整 uniform，避免把可调参数硬编码在多个 Shader 中；
6. 保存材质资源，或者明确它是只属于当前场景的本地资源。

如果 Shader 对 Sprite2D 的 Region 进行自定义采样，要注意 Sprite2D 的 UV 和 Region 语义；需要区域信息时使用引擎提供的 Region 相关内置量，而不是默认把整张图的 UV 当成当前可见区域。

## 6. 性能和职责边界

- 粒子数量、寿命、纹理尺寸、轨迹和材质复杂度共同决定成本；
- 粒子和 Shader 是表现层，不通过它们推进领域逻辑时间；
- 灯光数量、阴影和受影响的 CanvasItem 数量会影响渲染成本；
- 固定的粒子发射器、灯光节点和遮挡几何放在场景中；
- 运行时预设切换只修改被验证的属性，并保持资源和节点生命周期清晰；
- 不要为了改变一个粒子参数复制共享内容 Resource，除非确实需要实例独立资源。

## 7. 当前验证目录与常见问题

项目的 `tests/particles/` 验证预设、数量、寿命、发射形状、方向、Spread、速度、重力、阻尼、局部坐标、轨迹和绘制顺序。`tests/rendering/` 验证 PointLight2D、CanvasModulate、LightOccluder2D、Sprite2D 区域、CanvasItem 过滤和 ShaderMaterial。

常见问题：

- 粒子不显示：检查 `emitting`、`amount`、`lifetime`、Draw Pass 纹理、透明度和节点可见性。
- 粒子刚出现就消失：检查 `one_shot`、寿命、重启时机和是否在场景切换时被释放。
- 粒子跟随错误：切换 `local_coords`，并确认发射器父节点 Transform。
- 灯光没有效果：检查纹理、能量、灯光/物体掩码、CanvasModulate 和阴影配置。
- 阴影不出现：确认遮挡多边形有效且 PointLight2D 阴影已启用；遮挡体不是碰撞体的替代品。
- Shader 显示全黑或透明：从 `COLOR = texture(TEXTURE, UV) * COLOR` 的最小版本开始，逐步检查 UV、纹理和 uniform。

## 8. 官方参考

- [2D 粒子系统 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/2d/particle_systems_2d.html)
- [GPUParticles2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_gpuparticles2d.html)
- [ParticleProcessMaterial — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_particleprocessmaterial.html)
- [PointLight2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_pointlight2d.html)
- [LightOccluder2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_lightoccluder2d.html)
- [CanvasItem Shader — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html)
