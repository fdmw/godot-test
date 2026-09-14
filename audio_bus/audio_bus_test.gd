extends Control

const SAMPLE_RATE := 44100
const BUS_NAME := "ValidationBus"

@onready var _player: AudioStreamPlayer = %Player
@onready var _volume: HSlider = %Volume
@onready var _cutoff: HSlider = %Cutoff
@onready var _mute: CheckBox = %Mute
@onready var _status: Label = %Status
@onready var _play_button: Button = %PlayButton
@onready var _stop_button: Button = %StopButton
@onready var _reset_button: Button = %ResetButton
var _bus_index := -1
var _created_bus := false

func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(BUS_NAME)
	if _bus_index < 0:
		AudioServer.add_bus()
		_bus_index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_bus_index, BUS_NAME)
		_created_bus = true
	var filter := AudioEffectLowPassFilter.new()
	filter.cutoff_hz = _cutoff.value
	AudioServer.add_bus_effect(_bus_index, filter)
	_player.bus = BUS_NAME
	_player.stream = _make_tone(440.0, 1.0)
	_play_button.pressed.connect(_play)
	_stop_button.pressed.connect(_stop)
	_reset_button.pressed.connect(_reset)
	_volume.value_changed.connect(_set_volume)
	_cutoff.value_changed.connect(_set_cutoff)
	_mute.toggled.connect(_set_mute)
	_reset()

func _exit_tree() -> void:
	if _created_bus and _bus_index >= 0 and _bus_index < AudioServer.bus_count:
		AudioServer.remove_bus(_bus_index)

func _play() -> void:
	_player.play()
	_status.text = "AudioBus 播放中：%s" % BUS_NAME

func _stop() -> void:
	_player.stop()
	_status.text = "已停止"

func _reset() -> void:
	_volume.value = -6.0
	_cutoff.value = 18000.0
	_mute.button_pressed = false
	_set_volume(_volume.value)
	_set_cutoff(_cutoff.value)
	_set_mute(false)
	_status.text = "总线已重置：%s" % BUS_NAME

func _set_volume(value: float) -> void:
	if _bus_index >= 0:
		AudioServer.set_bus_volume_db(_bus_index, value)

func _set_cutoff(value: float) -> void:
	if _bus_index < 0 or AudioServer.get_bus_effect_count(_bus_index) == 0:
		return
	var filter := AudioServer.get_bus_effect(_bus_index, 0) as AudioEffectLowPassFilter
	if filter != null:
		filter.cutoff_hz = value

func _set_mute(value: bool) -> void:
	if _bus_index >= 0:
		AudioServer.set_bus_mute(_bus_index, value)
	_status.text = "总线静音：" + ("开启" if value else "关闭")

func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_count := roundi(float(SAMPLE_RATE) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index: int in sample_count:
		var envelope := minf(float(index) / float(sample_count) * 30.0, 1.0)
		var sample := sin(TAU * frequency * float(index) / float(SAMPLE_RATE)) * envelope * 0.25
		data.encode_s16(index * 2, clampi(roundi(sample * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
