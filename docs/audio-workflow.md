# 2D 音频、Audio Bus 与监听器工作流

本文说明 Godot 中非空间音频、世界空间音频和总线混音的分工，覆盖当前 `audio/` 与 `audio_bus/` 测试。音频播放是表现系统，不应把播放节点当成领域状态的唯一事实来源。

## 1. 播放器和监听器怎么选

- `AudioStreamPlayer` 不随 2D 距离衰减，适合 BGM、UI 音效和全局提示。
- `AudioStreamPlayer2D` 有世界位置，会根据监听器距离、`max_distance`、`attenuation` 和 `panning_strength` 计算空间效果，适合脚步、爆炸和环境声。
- `AudioListener2D` 是听音点。没有活动 Listener 时，2D 音频默认以屏幕中心作为听音点；场景有多个监听器时应明确调用 `make_current()` 选择一个。

播放节点的 `stream` 是 `AudioStream` 资源，`volume_db` 表示相对音量，`pitch_scale` 调整播放速度/音高，`play()`、`stop()` 和 `stream_paused` 控制播放状态。隐藏 `AudioStreamPlayer2D` 不等于停止声音，需要停止、暂停或将音量降到不可听的范围。

## 2. 编辑器中的配置流程

1. 在场景中添加合适的播放器，给 `Stream` 指定导入的 WAV/OGG/MP3 或其他 AudioStream 资源。
2. 在播放器的 `Bus` 属性选择目标总线；BGM、SFX 和 UI 不要全部直接写死在 Master 上。
3. 空间音频放在实际世界位置，确认 `Max Distance`、`Attenuation` 和 `Panning Strength`；添加 AudioListener2D 并在运行时使其成为当前监听器。
4. 打开 Audio 面板，在 Master 下建立 `Music`、`SFX`、`UI` 等子总线。总线音量影响该总线及其子总线的最终输出。
5. 在总线上添加 AudioEffect，例如低通、压缩或混响；播放节点只负责把声音送入总线，统一效果放在总线层管理。

音量使用 dB 而不是线性乘法。`0 dB` 表示不衰减，负 dB 表示降低音量；静音和音量是两个独立控制维度。

## 3. 当前测试怎么观察

`tests/audio/` 运行时生成短 WAV，分别由 AudioStreamPlayer 和 AudioStreamPlayer2D 播放；改变音调、音量和监听器 X 位置，观察空间衰减与声像变化。`tests/audio_bus/` 运行时创建独立总线和低通效果，验证总线音量、静音、截止频率及退出场景时的恢复/移除。

总线属于 AudioServer 的进程级状态。测试临时创建的总线、效果器和对已有总线的修改必须在退出时清理；正式项目的总线布局则适合保存为项目音频配置，而不是每个场景重复创建。

## 4. 常见误区

- `AudioStreamPlayer` 没有世界距离衰减；需要位置感时不能只给它设置 Node2D 坐标。
- 播放器的 `volume_db` 与 Bus 的音量会叠加影响结果；排查“声音太小”时同时检查两处和是否静音。
- 听不到空间音频时检查播放器是否在监听器范围内、Bus 是否存在、音频是否正在播放以及是否有当前 Listener。
- 频繁实例化短音效时，应关注播放器复用和 `max_polyphony`，不要先用大量节点掩盖播放管理问题。

参考：[Audio streams](https://docs.godotengine.org/en/4.7/tutorials/audio/audio_streams.html)、[AudioStreamPlayer2D](https://docs.godotengine.org/en/4.7/classes/class_audiostreamplayer2d.html)、[AudioListener2D](https://docs.godotengine.org/en/4.7/classes/class_audiolistener2d.html)、[Audio buses](https://docs.godotengine.org/en/4.7/tutorials/audio/audio_buses.html)。
