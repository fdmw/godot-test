# Sprite2D、Texture2D 与图集纹理工作流

本文记录 2D 项目中从图片资源到屏幕显示的基本工作流，重点说明 `Sprite2D`、`Texture2D`、`AtlasTexture`、帧图、纹理导入和采样设置。它服务于本项目的功能验证和日常编辑器操作，不要求每个纹理属性都建立一个独立测试。

## 1. 本文范围与当前验证内容

当前项目已经在以下位置覆盖了部分相关能力：

- `tests/rendering/rendering_test.tscn` 使用 `Sprite2D` 显示 `res://icon.svg`，并验证 `region_enabled`、区域矩形、纹理过滤和运行时材质切换。
- `tests/scene_resource/spawned_item.tscn` 使用独立场景中的 `Sprite2D` 和纹理，作为 `PackedScene` 实例化后的显示对象。
- `tests/tilemap/tilemap_test.tscn` 使用场景内生成的 `GradientTexture2D` 作为 TileSet 图集源，验证纹理区域与网格单元的关系。

当前没有专门覆盖外部精灵表、`AnimatedSprite2D`、法线贴图、多种压缩格式对比或不同缩放倍率下的采样对比。它们属于后续动画、渲染或性能专题，不应把本文误解成完整的美术资源规范。

## 2. 先区分几个概念

| 概念 | 作用 | 典型使用位置 |
| --- | --- | --- |
| `Texture2D` | 2D 纹理的通用类型；导入后的图片通常以其具体资源类型提供 | `Sprite2D.texture`、`TextureRect.texture` |
| `Sprite2D` | 在 2D 世界中绘制一张纹理的 `Node2D` | 角色、道具、背景、特效贴图 |
| `AtlasTexture` | 从一张大纹理中描述一个矩形区域，并作为独立纹理资源使用 | 需要把图集中的某块纹理复用到多个节点时 |
| `TextureRect` | 用 `Control` 的布局方式显示纹理 | HUD、菜单、头像、预览图 |
| 帧图 | 将一张精灵表按行列划分为多个等尺寸帧 | `Sprite2D.hframes/vframes/frame` |

`Texture2D` 是纹理接口/基类，不等于源文件本身。PNG、JPEG、SVG 等源文件经过导入后，Godot 才会生成运行时使用的纹理资源。通常只修改源图片和 Import Dock 中的设置，不直接编辑 `.godot/imported/` 下的生成文件。

`Sprite2D` 属于 2D 世界节点，位置、旋转、缩放参与父子节点 Transform；`TextureRect` 属于 UI 控件，尺寸、锚点和布局由 `Control` 系统管理。两者都能显示纹理，但排查坐标和布局问题时不能混为一谈。

## 3. 最基本的 Sprite2D 操作流程

在编辑器中创建一个普通的世界精灵，可以按以下顺序操作：

1. 将 PNG、SVG 等源图片放入项目的资源目录。使用外部文件管理器复制后，回到 Godot 等待 FileSystem 重新扫描。
2. 在 FileSystem 中选中图片，查看 Import Dock。根据资源类型和目标平台调整导入选项，修改后点击 **Reimport**。
3. 在 Scene Dock 中选中一个 `Node2D`，添加子节点 `Sprite2D`；也可以将图片从 FileSystem 拖到 2D 视口，让 Godot 创建带纹理的 Sprite2D。
4. 在 Inspector 的 `Texture` 属性中拖入图片，或从资源选择器中选择已经导入的纹理。
5. 调整 `Transform` 中的位置、旋转和缩放，再根据锚点需要调整 `Centered`、`Offset` 或翻转属性。
6. 保存场景。节点层级、初始 Transform、纹理引用和静态属性应保存在 `.tscn` 中；脚本只处理运行时变化。

如果只是想验证纹理是否能显示，先使用最小场景：一个 `Node2D`、一个 `Sprite2D` 和一张纹理。不要一开始叠加 Camera2D、CanvasLayer、材质和复杂脚本，否则纹理不显示时难以判断是资源、坐标还是渲染状态的问题。

## 4. Sprite2D 的关键属性

| 属性 | 作用 | 使用时注意 |
| --- | --- | --- |
| `Texture` | 要绘制的 `Texture2D` | 为空时 Sprite2D 没有可绘制内容 |
| `Centered` | 是否以节点位置作为纹理中心 | 关闭后原点更接近纹理左上角，适合明确的像素对齐场景 |
| `Offset` | 只移动绘制内容相对于节点原点的位置 | 不改变节点的 `position`，也不会自动移动碰撞体或子节点 |
| `Flip H` / `Flip V` | 水平或垂直翻转绘制结果 | 只改变视觉方向，不改变节点 Transform 的旋转和缩放 |
| `Region Enabled` | 只绘制 `Region Rect` 指定的纹理区域 | 适合从图集选取矩形区域；开启后要检查区域大小和坐标 |
| `Region Rect` | 图集中要显示的矩形，单位是源纹理像素 | 它描述纹理区域，不是 Sprite2D 在世界中的矩形 |
| `Region Filter Clip Enabled` | 限制过滤采样不要越过区域边界 | 图集相邻区域出现颜色渗漏时很有用，但不能替代合理的图集留白 |
| `Hframes` / `Vframes` | 将完整纹理按列/行划分为等尺寸帧 | 适用于规则网格精灵表；纹理尺寸应能被帧数合理划分 |
| `Frame` / `Frame Coords` | 选择当前网格帧 | 只有设置了多行或多列帧时才有意义 |

`Region Enabled` 与 `Hframes/Vframes` 是两套不同的取图方式：前者使用一个明确的矩形，后者把整张纹理均匀切成网格。除非明确知道结果，否则不要同时依赖两套设置；排查“显示了错误图片”时先确认到底是哪套属性在生效。

`Centered` 和 `Offset` 影响绘制原点，但不改变节点的世界位置。角色需要以脚底参与 Y Sort 时，通常应通过节点结构、绘制偏移或独立的排序节点表达意图，而不是移动碰撞体来迁就 Sprite 的视觉中心。

## 5. 规则帧图与不规则图集

### 5.1 使用 Hframes/Vframes 选择规则帧

如果精灵表中的每一帧宽高相同，可以直接把整张纹理设置给 Sprite2D：

```text
Texture  = player_sheet.png
Hframes  = 4
Vframes  = 2
Frame    = 5
```

Godot 会按从左到右、从上到下的顺序计算帧索引。修改 `Frame` 只改变当前显示的单元，不会裁剪源文件，也不会改变节点位置。

脚本中切换帧时，保留整数边界并使用类型标注：

```gdscript
@onready var _sprite: Sprite2D = %Sprite

func show_frame(frame_index: int) -> void:
	_sprite.frame = frame_index
```

帧索引必须落在有效范围内：

```gdscript
func show_frame(frame_index: int) -> void:
	var frame_count := _sprite.hframes * _sprite.vframes
	_sprite.frame = clampi(frame_index, 0, frame_count - 1)
```

这里的 `Hframes/Vframes` 只适合规则网格。帧之间存在不规则空白、不同尺寸或复杂裁剪要求时，应改用明确区域的图集资源或后续的 `SpriteFrames` 工作流。

### 5.2 使用 Sprite2D Region

对一个规则但暂时只需要显示其中一块的图集，可以直接启用 `Region`：

```gdscript
func show_region(region: Rect2) -> void:
	_sprite.region_enabled = true
	_sprite.region_rect = region
	_sprite.region_filter_clip_enabled = true
```

`region_rect` 的坐标以整张源纹理的左上角为原点，单位是纹理像素。它不是以 Sprite2D 当前节点位置为原点，也不是以当前显示区域的左上角为原点。

### 5.3 使用 AtlasTexture

当图集中的某个区域需要作为一个可复用的纹理资源交给多个节点时，可以创建 `AtlasTexture`：

```gdscript
func use_atlas_region(source: Texture2D, region: Rect2) -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = source
	atlas_texture.region = region
	_sprite.texture = atlas_texture
```

更常见的编辑器操作是在 Inspector 的 `Texture` 属性中新建 `AtlasTexture`，然后设置：

1. `Atlas`：选择完整的源纹理；
2. `Region`：填写图集中矩形区域的像素坐标和尺寸；
3. 必要时设置 `Margin` 或 `Filter Clip Enabled`，处理边缘留白和过滤边界；
4. 将这个 AtlasTexture 资源保存到合适的项目目录，供多个场景引用。

`Sprite2D.region_enabled` 是节点上的显示选项；`AtlasTexture` 是一个纹理资源包装器。前者适合场景中临时或节点专属的裁剪，后者适合要命名、复用或作为其他纹理属性输入的区域。两种方式都不会修改源图片。

## 6. TextureRect 与世界 Sprite 的选择

使用 `TextureRect` 时，重点不是 `Sprite2D` 的中心和世界 Transform，而是控件的布局与 `Expand Mode`、`Stretch Mode`：

- 世界中的角色、道具、粒子贴图等使用 `Sprite2D`；
- HUD、菜单背景、头像和固定预览图等使用 `TextureRect`；
- 需要保持原始比例时选择保持比例的 Stretch Mode，并检查控件尺寸；
- 需要像素级裁剪时优先准备明确的 AtlasTexture 或区域，而不是单纯把控件压缩到目标尺寸。

当 UI 图片“位置正确但变形”时，先检查 Control 的尺寸和 Stretch Mode；当世界图片“位置不对”时，先检查父节点 Transform、Camera2D 和 Sprite2D 的 Centered/Offset。两类问题的排查入口不同。

## 7. 纹理导入：源文件与运行时资源

选中源图片后，在 Import Dock 中调整导入选项，再点击 Reimport。导入设置作用于源资源，可能影响所有引用该纹理的场景，因此修改前要确认它不是多个测试共同依赖的关键资源。

### Mipmaps

Mipmaps 是为不同缩小级别准备的纹理层级。它们会增加纹理内存和导入数据，是否启用应结合缩放方式、平台和渲染目标决定：

- 以像素画、原始尺寸或整数倍放大为主的 2D 贴图，通常先关闭并使用 Nearest 过滤；
- 需要频繁缩小、远距离显示或希望缩小采样更稳定时，再验证 mipmap 的收益；
- 开启 mipmap 后仍然需要选择匹配的带 mipmap 过滤方式，单独打开导入选项不会自动解决所有采样问题。

### 压缩与质量

压缩是在内存占用、包体大小和画质之间取舍：

- 像素画、文字、UI 和带硬边的图像对压缩伪影敏感，通常优先使用无损或更保真的设置；
- 大尺寸照片类背景和移动平台资源可能更关注显存、包体与加载速度，应在目标平台实测；
- 透明边缘、细线和小图标最容易暴露压缩或过滤问题，不要只用大图判断设置是否合适。

SVG 也会经过导入成为可供 2D 节点使用的纹理。需要改变 SVG 的导入尺寸或渲染结果时，在 Import Dock 调整其导入选项并重新导入；不要把生成的缓存文件当作项目源资源修改。

### 导入设置的排查顺序

1. 确认 FileSystem 中引用的是预期源文件，而不是同名的另一份资源；
2. 修改 Import Dock 后确认已经点击 Reimport；
3. 检查场景是否在 Sprite2D 或材质层又覆盖了纹理相关属性；
4. 关闭材质、缩放和复杂后处理，用原始尺寸 Sprite2D 做对照；
5. 将导入选项、CanvasItem 采样和 Camera2D 缩放分别测试，不要一次改动全部变量。

## 8. 2D 纹理采样与像素对齐

Godot 4 中，纹理过滤和重复模式主要通过使用纹理的 `CanvasItem` 设置控制。对 Sprite2D，可在 Inspector 的 `CanvasItem` 相关纹理选项中设置 `Texture Filter` 和 `Texture Repeat`；也可以按项目需要设置默认值，再对个别节点覆盖。

常用选择如下：

| 目标 | 过滤建议 | 还要检查 |
| --- | --- | --- |
| 像素画、硬边 UI | `Nearest` | 整数倍缩放、Camera2D 缩放和像素对齐 |
| 平滑插画、照片类 2D 图 | `Linear` | 缩放后的清晰度和透明边缘 |
| 图集区域边缘 | 与目标画风匹配 | 区域裁剪、留白、`Region Filter Clip Enabled` |
| 需要重复平铺 | 合适的 Repeat 模式 | 纹理边缘是否无缝、节点尺寸和 UV 范围 |

`Nearest`/`Linear` 解决的是采样时如何在纹理像素之间取值；导入压缩解决的是纹理数据如何存储，两者不是同一个开关。像素画仍然模糊时，除了检查 Sprite2D 的过滤，还要检查父节点缩放、Camera2D Zoom、窗口 Stretch 和项目的 2D 像素对齐设置。

图集使用 Linear 过滤时，如果相邻区域没有留白，采样可能把另一块图集内容混入边缘。可以启用区域过滤裁剪，并在制作图集时保留适当 padding；如果项目是像素画，Nearest 通常更容易得到可预测的边缘。

## 9. 与当前验证台的对应关系

`tests/rendering/rendering_test.tscn` 的 Sprite 节点固定引用 `res://icon.svg`，并设置了区域矩形。运行该测试时：

- 切换“启用 Sprite2D 区域”可以观察整张纹理和区域显示之间的变化；
- 选择 Nearest 或 Linear 可以观察 CanvasItem 纹理过滤的差异；
- ShaderMaterial 开关会改变 Sprite 的采样过程，但它不是普通 Sprite2D Region 的替代品；
- 这份测试还包含 `Line2D`、`Polygon2D`、灯光和自定义绘制，其他节点的专门说明见后续渲染文档。

测试场景中的静态纹理引用放在 `.tscn`。如果后续增加帧切换或区域切换示例，应只让脚本修改 `frame`、`region_enabled`、`region_rect` 等运行时状态，不在 `_ready()` 中重新搭建 Sprite 或静态界面。

## 10. 常见问题

### 看到整张精灵表

检查是否设置了 `Hframes/Vframes` 或启用了 `Region`，并确认脚本没有在运行时覆盖 Inspector 中的值。规则帧图使用网格划分，不规则图集使用区域矩形或 AtlasTexture。

### 显示了图集中的错误区域

确认 `Region` 使用的是整张源纹理的像素坐标，检查导入后的实际尺寸、图集 padding、缩放和是否误用了 `Frame`。SVG 的导入尺寸变化也会使原先按像素填写的区域失效。

### 图集边缘出现其他颜色

先确认过滤模式，再检查图集 padding、`Region Filter Clip Enabled` 或 AtlasTexture 的过滤裁剪设置。不要只通过放大 `Offset` 或移动 Sprite 来处理采样污染。

### 像素画模糊或抖动

检查 Sprite2D 和父 CanvasItem 的过滤设置，确认没有意外使用 Linear；再检查 Camera2D Zoom、父节点非整数缩放、窗口 Stretch 以及像素对齐。只改源图片导入压缩通常不能解决采样模糊。

### Sprite2D 不显示

按顺序检查 `Texture` 是否为空、节点和父节点是否可见、Modulate/透明度是否为零、Region 是否裁剪到了空区域、节点是否位于当前 Camera2D 可见范围，以及是否被 CanvasLayer 或 z-index 遮挡。

## 11. 官方参考

- [Sprite2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_sprite2d.html)
- [Texture2D — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_texture2d.html)
- [AtlasTexture — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html)
- [TextureRect — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_texturerect.html)
- [导入图片 — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html)
- [CanvasItem — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html)
