extends Control

# 验证目标：验证普通音频、空间音频、监听器、音量和音高参数。
# 机制说明：测试音频流在运行时生成，因为音调波形本身就是本测试要观察的内容。

const SAMPLE_RATE := 44100
const TONES: Array[float] = [220.0, 440.0, 660.0, 880.0]

@onready var _global_player: AudioStreamPlayer = %GlobalPlayer
@onready var _positional_player: AudioStreamPlayer2D = %PositionalPlayer
@onready var _listener: AudioListener2D = %Listener
@onready var _tone: OptionButton = %Tone
@onready var _volume_slider: HSlider = %VolumeSlider
@onready var _pitch_slider: HSlider = %PitchSlider
@onready var _listener_slider: HSlider = %ListenerSlider
@onready var _status: Label = %Status
@onready var _global_button: Button = %GlobalButton
@onready var _positional_button: Button = %PositionalButton
@onready var _stop_button: Button = %StopButton
var _streams: Array[AudioStreamWAV] = []

func _ready() -> void:
	for frequency: float in TONES:
		_streams.append(_make_tone(frequency, 0.8))
	for index: int in TONES.size():
		_tone.add_item("%d Hz" % TONES[index])
	_tone.item_selected.connect(_on_tone_selected)
	_global_button.pressed.connect(_play_global)
	_positional_button.pressed.connect(_play_positional)
	_stop_button.pressed.connect(_stop)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_pitch_slider.value_changed.connect(_on_pitch_changed)
	_listener_slider.value_changed.connect(_on_listener_position_changed)
	_global_player.stream = _streams[1]
	_positional_player.stream = _streams[1]
	_listener.make_current()

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_count := roundi(float(SAMPLE_RATE) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var progress := float(index) / float(sample_count)
		var envelope := minf(progress * 30.0, minf(1.0, (1.0 - progress) * 30.0))
		var sample := sin(TAU * frequency * float(index) / float(SAMPLE_RATE)) * envelope * 0.3
		data.encode_s16(index * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _on_tone_selected(index: int) -> void:
	_global_player.stream = _streams[index]
	_positional_player.stream = _streams[index]
	_status.text = "选择音调：%d Hz" % TONES[index]

func _play_global() -> void:
	_global_player.play()
	_status.text = "AudioStreamPlayer 播放中"

func _play_positional() -> void:
	_positional_player.play()
	_status.text = "AudioStreamPlayer2D 播放中"

func _stop() -> void:
	_global_player.stop()
	_positional_player.stop()
	_status.text = "音频已停止"

func _on_volume_changed(value: float) -> void:
	_global_player.volume_db = value
	_positional_player.volume_db = value

func _on_pitch_changed(value: float) -> void:
	_global_player.pitch_scale = value
	_positional_player.pitch_scale = value

func _on_listener_position_changed(value: float) -> void:
	_listener.position.x = 300.0 + value
	_status.text = "监听器位置 X：%.0f" % _listener.position.x
