# TileSet 与 TileMapLayer 工作流

适用版本：Godot 4.7.x

本文是本项目的 TileSet / TileMapLayer 学习和操作说明，重点记录编辑器中的完整工作流程、关键属性以及运行时 API 的对应关系。它不要求每个属性都逐一罗列，而是帮助建立一条可以重复使用的工作路径。

对应清单：17～21。

## 一、先建立正确的模型

TileMap 相关功能可以拆成三层：

```text
TileSet
├── TileSetAtlasSource / TileSetScenesCollectionSource
├── Tile
└── TileData

TileMapLayer
└── Cell 数据：source_id、atlas_coords、alternative_tile
```

- `TileSet` 是可复用的瓦片资源，保存瓦片来源和每个瓦片的碰撞、导航、遮挡、自定义数据等定义。
- `TileSetAtlasSource` 把一张图集纹理按网格暴露成多个瓦片。
- `TileSetScenesCollectionSource` 把独立场景作为场景型瓦片使用。
- `TileData` 表示某个瓦片的附加数据。
- `TileMapLayer` 是实际绘制地图单元格的节点。一个 `TileMapLayer` 只有一个瓦片层；需要地面、墙体、前景等多个层时，创建多个 `TileMapLayer` 节点。
- 一个单元格不是直接保存“图片”，而是保存瓦片来源 ID、图集坐标和 alternative ID。运行时读取时要把这三个标识和 TileSet 对照起来。

Godot 4.7 中旧的 `TileMap` 节点已弃用，新项目应优先使用多个 `TileMapLayer`。

## 二、从图集创建可用 TileSet

### 1. 准备纹理

把 PNG 或其他纹理放进项目的 `FileSystem` 面板。像素画和高清素材的导入策略不同：

- 像素画通常需要关闭或谨慎使用会改变边缘的平滑、Mipmaps 和压缩设置。
- 高清素材更关注过滤、Mipmaps 和压缩质量。
- 修改 Import 选项后，需要点击 `Reimport`，否则场景仍可能使用旧的导入结果。

图集最好使用规则网格，并提前确认：

- 每个瓦片的像素尺寸；
- 图集是否有边缘留白；
- 瓦片之间是否有分隔线或间距；
- 是否包含完全透明的区域。

### 2. 创建 TileMapLayer 和 TileSet

1. 在目标地图 Scene 中添加 `Node2D` 或其他合适的地图根节点。
2. 添加子节点 `TileMapLayer`。
3. 选中 `TileMapLayer`，在 Inspector 的 `Tile Set` 属性中选择 `New TileSet`。
4. 展开 TileSet 资源，先设置 `Tile Size`。
5. 根据素材选择 Tile Shape。普通方形图集使用 `Square`；等距、半偏移或六边形素材还要检查 `Tile Layout` 和 `Tile Offset Axis`。

自动创建图集瓦片前必须先设置 Tile Size。Tile Size 决定地图网格，而 Atlas 的 Texture Region Size 通常应与它一致。

### 3. 添加 Atlas 来源并切分

1. 选中 TileMapLayer，打开底部的 `TileSet` 面板。
2. 将图集纹理拖入 TileSet 面板，创建 `Atlas` 来源。
3. 在 Atlas 属性中检查：
   - `Texture`：图集纹理；
   - `Texture Region Size`：每个网格区域的像素尺寸；
   - `Margins`：图集外边缘不参与切分的像素；
   - `Separation`：图块之间的间距；
   - `Use Texture Padding`：过滤开启时用于减少相邻纹理渗色，通常保持开启。
4. 使用自动创建瓦片功能，从非透明纹理区域生成瓦片。
5. 删除不应使用的瓦片，或手动创建遗漏的瓦片。

完全透明的区域通常不会被自动创建为瓦片。如果修改了边距、间距或区域尺寸导致瓦片丢失，可以重新执行按非透明区域创建瓦片。

### 4. 保存 TileSet

原型阶段可以让 TileSet 作为 TileMapLayer 的内置资源保存。多个地图需要复用时，应通过 TileSet 资源右侧菜单将它保存为外部 `.tres` 资源。

这样可以避免每个地图各自复制一份 TileSet，也可以集中修改碰撞、导航和自定义数据。需要注意：外部 TileSet 是共享资源，运行时不要把某个实例的可变状态写回共享 TileSet。

## 三、在 TileMapLayer 中绘制地图

### 1. 选择要编辑的图层

如果场景中有多个 TileMapLayer：

1. 在 Scene 面板中选中目标 TileMapLayer；
2. 打开底部 `TileMap` 面板；
3. 在面板右上方确认当前编辑的图层；
4. 必要时关闭或开启 `Highlight Selected TileMap Layer`，控制其他图层是否显示为灰色。

不同 TileMapLayer 可以在同一个位置放置瓦片，从而分别表达地面、装饰、墙体和前景。

### 2. 选择瓦片

在 TileMap 面板中：

- 单击选择一个瓦片；
- 拖动选择多个瓦片；
- 按住 `Shift` 将选择追加到当前选择；
- 选择 alternative tile 时，从基础瓦片旁边的替代项中选择；
- 使用场景集合来源时，可以像普通瓦片一样选择场景型瓦片。

多选不要求区域连续，空白位置会保留在绘制图案中，适合复制树、平台等由多个瓦片组成的结构。

### 3. 常用绘制工具

| 工具 | 用途 | 关键操作 |
| --- | --- | --- |
| Selection | 选择已经绘制的区域 | 可复制、删除或作为新图案 |
| Paint | 自由绘制 | 左键绘制，右键擦除 |
| Line | 绘制直线 | 适合道路、墙线和边界 |
| Rectangle | 绘制矩形 | 适合地面、房间和规则区域 |
| Bucket Fill | 填充区域 | 注意 `Contiguous` 是否只处理相邻区域 |
| Picker | 从已绘制地图取样 | 可临时取得已有瓦片或图案 |
| Eraser | 擦除瓦片 | 可以与 Paint、Line、Rectangle、Bucket Fill 组合 |
| Patterns | 保存和复用多瓦片图案 | 适合重复房间结构或装饰组合 |

常用快捷操作：

- Paint 模式下按住 `Shift` 后拖动，可临时画线；
- Paint 模式下按住 `Ctrl + Shift` 后拖动，可临时画矩形；
- Paint 模式下按住 `Ctrl` 点击，可临时取样；
- 右键通常表示擦除；
- Selection 后可以使用复制、粘贴和删除完成地图局部复用。

### 4. TileMapLayer 的层级组织

推荐根据职责创建多个兄弟节点，而不是让一个 TileMapLayer 承担所有内容：

```text
Map
├── Ground
├── GroundDetails
├── Walls
├── Props
├── Obstacles
├── Foreground
├── Navigation
└── Entities
```

判断原则：

- 规则、重复、适合网格绘制的内容使用 Tile；
- 需要单独脚本、独立碰撞或独立生命周期的对象使用独立 Scene；
- 需要与角色产生复杂交互的对象，不要为了方便塞成场景型 Tile；
- 前景和 Y Sort 相关内容单独分层，便于调试绘制顺序。

## 四、给 Tile 添加附加数据

TileSet 资源中的数据层决定 Tile 能表达哪些行为。应先在 TileSet 中添加对应的数据层，再选中具体瓦片进行编辑。

### Physics Layer

用于在瓦片上绘制碰撞几何：

1. 在 TileSet Inspector 的 `Physics Layers` 中添加物理层；
2. 在 Atlas 中选中瓦片；
3. 打开 Physics Layer 编辑区域；
4. 使用矩形或多边形工具绘制碰撞形状；
5. 运行时打开 `Visible Collision Shapes`，确认地图碰撞是否符合预期。

不要只看图片判断碰撞，碰撞几何才是物理系统使用的事实来源。

### Navigation Layer

用于为瓦片提供导航多边形：

1. 在 TileSet 中添加 Navigation Layer；
2. 为可行走瓦片配置导航多边形；
3. 打开 Navigation Debug 检查生成结果；
4. 根据地图复杂度决定继续使用 TileMapLayer 导航，还是将地图烘焙为 `NavigationRegion2D`。

TileMapLayer 的内置导航适合建立认知和处理中小型规则地图；复杂地图通常需要评估集中烘焙导航网格的方案。导航网格不能像视觉层或物理形状一样随意上下堆叠，否则可能产生合并和寻路逻辑问题。

### Occlusion Layer

用于给 2D 光照添加遮挡多边形。添加 Occlusion Layer 后，在 Tile 的 Rendering 区域编辑遮挡几何，再配合 `PointLight2D`、`DirectionalLight2D` 和 `CanvasModulate` 验证效果。

### Custom Data Layer

Custom Data 适合保存每种 Tile 的静态内容定义，例如：

- `walk_cost`：移动消耗；
- `footstep_type`：脚步声音类型；
- `damage`：接触伤害；
- `destructible`：是否可破坏；
- `element`：元素类型。

配置流程：

1. 在 TileSet 中添加 Custom Data Layer；
2. 为它设置稳定名称和数据类型；
3. 选中瓦片，在 TileData 区域填写值；
4. 运行时通过 `get_cell_tile_data()` 取得 TileData，再读取对应自定义数据。

自定义数据属于 Tile 定义，因此同一种 Tile 的所有单元格默认共享同一份值。需要不同数据的变体时，创建 Alternative Tile，而不是修改某个地图实例的共享 TileSet 数据。

### Scene Collection Source

场景集合可以让一个 Tile 代表一组节点，例如交互物、环境音或粒子效果。但每个场景型 Tile 都会单独实例化场景，性能开销高于 Atlas Tile。

普通图片和静态装饰优先使用 Atlas；只有确实需要独立节点行为时才使用 Scene Collection Source。

## 五、Terrain 自动拼接

Terrain 不是根据图片内容自动推断地形，而是根据 TileSet 中预先配置的邻接关系，从已有的 Tile 组合中选择合适的瓦片。

基本流程：

1. 在 TileSet 中创建 Terrain Set；
2. 在 Terrain Set 中创建具体 Terrain，例如草地、土地或水面；
3. 为每个相关 Tile 配置 Terrain 类型；
4. 配置 Terrain Peering / 邻接关系，让 Godot 知道瓦片边缘与相邻方向的连接方式；
5. 在 TileMap 编辑器中使用 Terrain Paint；
6. 检查草地、边缘、内角、外角和过渡组合是否都有对应 Tile。

如果某种边缘没有正确出现，优先检查 TileSet 是否缺少对应邻接组合，而不是先怀疑绘制工具。

脚本中可以使用：

```gdscript
tile_map_layer.set_cells_terrain_connect(cells, terrain_set_id, terrain_id)
tile_map_layer.set_cells_terrain_path(path, terrain_set_id, terrain_id)
```

这些 API 仍然依赖 TileSet 中正确配置的 Terrain 数据，不能替代素材和邻接规则的准备。

## 六、运行时读写 TileMapLayer

### 坐标转换

TileMapLayer 的坐标流程是：

```text
世界坐标
→ TileMapLayer.to_local()
→ TileMapLayer.local_to_map()
→ Vector2i cell 坐标
```

反向转换是：

```text
Vector2i cell 坐标
→ TileMapLayer.map_to_local()
→ TileMapLayer.to_global()
→ 世界坐标
```

示例：

```gdscript
var cell: Vector2i = tile_map_layer.local_to_map(
	 tile_map_layer.to_local(world_position)
)
var cell_center: Vector2 = tile_map_layer.to_global(
	 tile_map_layer.map_to_local(cell)
)
```

`local_to_map()` 的参数必须是 TileMapLayer 的局部坐标。如果输入的是全局坐标，先调用 `to_local()`。`map_to_local()` 返回的是单元格中心附近的局部坐标，再根据需要转换到全局坐标。

### 写入、删除和读取

```gdscript
tile_map_layer.set_cell(cell, source_id, atlas_coords, alternative_tile)
tile_map_layer.erase_cell(cell)
tile_map_layer.clear()

var source_id: int = tile_map_layer.get_cell_source_id(cell)
var atlas_coords: Vector2i = tile_map_layer.get_cell_atlas_coords(cell)
var tile_data: TileData = tile_map_layer.get_cell_tile_data(cell)
```

当前项目的 [tilemap_test.gd](../tests/tilemap/tilemap_test.gd) 使用场景内两个 Marker2D 作为静态位置，验证了：

- `local_to_map()` 将局部位置转换为单元格；
- `set_cell()` 写入两个 Atlas Tile；
- `get_cell_source_id()` 和 `get_cell_atlas_coords()` 读取 Tile 标识；
- `clear()` 清空地图。

由于 Marker2D 和 TileMapLayer 位于同一个 SubViewport 坐标系，测试中可以直接使用 Marker2D 的局部 `position`。一般场景不要假设节点坐标系相同，应明确进行 `to_local()` / `to_global()` 转换。

### 常用查询

```gdscript
var used_cells: Array[Vector2i] = tile_map_layer.get_used_cells()
var used_rect: Rect2i = tile_map_layer.get_used_rect()
var filtered_cells: Array[Vector2i] = tile_map_layer.get_used_cells_by_id(
	source_id,
	atlas_coords,
	alternative_tile
)
```

空单元格通常表现为 `source_id == -1`，Atlas 坐标为 `Vector2i(-1, -1)`。`get_cell_tile_data()` 在单元格不存在或来源不是 Atlas 时可能返回 `null`，读取前要做判断。

### 批处理与内部更新

TileMapLayer 的更新通常会批处理到帧末。大量修改时不要在 `changed` 信号中立即执行复杂处理；需要强制提前刷新内部数据时才考虑 `update_internals()`，不要把它当作每次写入后的默认调用。

## 七、需要重点检查的属性

### TileSet 属性

- `Tile Size`：地图网格尺寸；自动创建 Atlas 前先设置。
- `Tile Shape`、`Tile Layout`、`Tile Offset Axis`：等距、半偏移和六边形地图的网格定义。
- `Physics Layers`：Tile 碰撞数据层。
- `Navigation Layers`：Tile 导航数据层。
- `Occlusion Layers`：Tile 光照遮挡数据层。
- `Custom Data Layers`：Tile 静态自定义数据。
- `Terrain Sets`：Terrain 类型和邻接规则。

### Atlas Source 属性

- `Texture`：图集纹理。
- `Texture Region Size`：图集网格区域尺寸。
- `Margins`：外边缘留白。
- `Separation`：瓦片间距。
- `Use Texture Padding`：减少纹理过滤造成的边缘渗色。
- Tile 的 `Texture Region`、`Texture Origin`、Transform 和 Alternative Tile：决定具体瓦片的显示和变体行为。

### TileMapLayer 属性

- `Tile Set`：该层使用的 TileSet。
- `Enabled`：关闭时会同时影响绘制、碰撞、导航和场景型 Tile。
- `Collision Enabled`：是否启用该层的 Tile 碰撞。
- `Navigation Enabled`：是否启用该层的 Tile 导航区域。
- `Occlusion Enabled`：是否启用该层的光照遮挡。
- `Y Sort Origin`：配合 Y Sort 调整 Tile 的排序基准。
- `X Draw Order Reversed`：Y Sort 时调整 X 方向的绘制顺序。
- `Rendering Quadrant Size`：绘制批次的分组大小。
- `Physics Quadrant Size`：碰撞形状的分组大小。
- `Use Kinematic Bodies`：移动 TileMapLayer 作为移动平台等物理对象时再评估使用。

## 八、常见问题排查

### TileMap 面板没有出现

确认已选中 `TileMapLayer` 节点。TileSet 面板用于编辑 TileSet 资源，TileMap 面板用于选择和绘制地图，两者职责不同。

### 图集能看到但无法绘制

依次检查：

1. TileSet 的 Tile Size 是否正确；
2. Atlas 的 Texture Region Size、Margins、Separation 是否正确；
3. 是否真的创建了 Tile，而不只是添加了纹理来源；
4. 当前编辑的是否是目标 TileMapLayer；
5. TileMapLayer 是否 Enabled。

### Tile 看起来偏移或切错

优先检查 Tile Size、Texture Region Size、Margins、Separation 和 Tile Origin。不要先通过修改节点 position 掩盖图集网格配置错误。

### 代码读取不到 Tile

检查传入的是否是 `Vector2i` 单元格坐标，而不是世界坐标或像素坐标；再检查 `source_id` 和 Atlas 坐标是否使用了当前 TileSet 中实际存在的值。

### 碰撞或导航没有效果

确认 TileSet 中已经创建对应的数据层，并且具体 Tile 绘制了有效几何；运行时分别打开碰撞和导航 Debug。还要检查 TileMapLayer 的开关以及物理层/导航层配置。

### 运行时修改后立即查询结果不符合预期

TileMapLayer 的部分内部更新会批处理到帧末。需要立即使用内部结果时，了解 `update_internals()` 的适用范围；更重要的是不要把尚未同步的内部状态当作任意时点都已完成更新。

## 九、本项目当前覆盖范围

当前 [tests/tilemap/tilemap_test.tscn](../tests/tilemap/tilemap_test.tscn) 有意使用场景内生成的 `GradientTexture2D`、`TileSetAtlasSource` 和 `TileSet`，不依赖外部图片。它用于验证基础 API 和坐标转换，不是完整的编辑器 TileMap 示例。

当前已覆盖：

- TileMapLayer 节点和场景内 TileSet；
- 两格 Atlas Tile 的基础定义；
- 单元格写入、读取、清空；
- 局部位置到单元格坐标的转换。

当前尚未在验证场景中覆盖：

- 从外部图集创建 TileSet 的完整编辑器流程；
- Paint、Line、Rectangle、Bucket、Picker、Patterns 等编辑器工具；
- Alternative Tile；
- Terrain 自动拼接；
- Tile Physics、Navigation、Occlusion 和 Custom Data；
- Scene Collection Source；
- 多 TileMapLayer 的地图分层和 Y Sort；
- TileMapLayer 的批处理和 `update_internals()` 行为。

## 官方参考

- [Using TileSets — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilesets.html)
- [Using TileMaps — Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html)
- [TileSet — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_tileset.html)
- [TileMapLayer — Godot 4.7](https://docs.godotengine.org/en/4.7/classes/class_tilemaplayer.html)
