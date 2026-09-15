# Godot 2D 性能测量与优化工作流

本文建立性能排查的基本方法，不给出脱离数据的固定节点数量或帧数门槛。性能优化应先测量，再针对瓶颈验证改动，不能把“少写几行代码”直接等同于更快。

## 1. 先建立可比较的基线

在目标平台、目标窗口尺寸和代表性场景下记录：帧率、帧时间、渲染对象/绘制调用、节点数量、物理帧时间、内存和粒子数量。使用 Debugger 的 Profiler、Monitors 和 Rendering Statistics 观察变化，分别比较空场景、正常负载和峰值负载。

一次只改变一个因素，并记录场景状态、运行方式和结果。编辑器运行、无头运行和导出版本的性能不能直接混为一个结论。

## 2. 主要成本来源

- `_process()` 和 `_physics_process()` 中的工作会随帧重复；不需要持续更新的 Node 应关闭对应回调。物理查询放在正确的物理上下文，不要每个渲染帧重复查询同一事实。
- 节点数量本身不是唯一指标，但大量生命周期、Transform、Signal 和回调会增加管理成本；可独立复用的对象应拆 Scene，同时避免为无意义的细节制造 Node。
- Sprite/TileMapLayer 的批量绘制通常比大量逐对象绘制更适合地图；材质、纹理、CanvasLayer 和 z 顺序变化可能破坏批处理，应由 Rendering Statistics 验证。
- GPUParticles2D 的数量、粒子寿命、纹理、处理材质和过度绘制都会影响成本；先调低数量和寿命确认瓶颈，再决定是否改方案。
- 物理 Body、CollisionShape2D 数量、复杂多边形、ShapeCast/RayCast 和直接空间查询都可能增加物理成本；查询范围、Mask 和结果容量应尽量精确。
- 高频 `instantiate()`、销毁、连接 Signal 和资源加载可能造成尖峰。对象池只适合创建/销毁确实成为热点且对象生命周期简单的场景，不能提前作为默认架构。

## 3. 回调和逻辑边界

连续表现、插值、输入采样和必要的引擎交互可以使用帧回调；本项目的离散验证状态不由帧循环自动推进。若临时需要连续表现，应通过 `set_process()`/`set_physics_process()` 明确启停，而不是长期保留空回调。

物理查询和 Transform 同步还要遵守 [Godot 实现规范](../godot-implementation.md)：同一事务使用候选 Transform 完成验证，确认后一次提交，不能先改权威状态再依赖未同步的物理空间回滚。

## 4. 实际优化顺序

```text
复现并测量
→ 定位 CPU / GPU / 物理 / 内存 / 加载瓶颈
→ 缩小到具体场景和操作
→ 做一个局部改动
→ 在同一基线下复测
→ 确认可读性、正确性和峰值表现仍然成立
```

例如帧率下降，先看 Profiler 和 Monitors 是脚本、物理、渲染还是粒子耗时；不要只因为场景中有很多节点就直接合并层级。优化后仍需在 Remote SceneTree 和功能测试中确认节点释放、碰撞结果、路径和视觉反馈没有改变。

## 5. 当前项目的观察样本

可用 `tests/particles/` 比较粒子数量和寿命，`tests/tilemap/` 观察批量地图与分层，`tests/physics/` 和 `tests/physics_extra/` 观察查询/碰撞成本，`tests/scene_resource/` 观察批量实例化和释放。它们是学习样本，不是正式项目的性能基准。

参考：[The profiler](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html)、[Monitors](https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/overview_of_debugging_tools.html)、[Optimization using servers](https://docs.godotengine.org/en/4.7/tutorials/performance/using_servers.html)。
