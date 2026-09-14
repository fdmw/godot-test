extends Control

@onready var _status: Label = %Status
@onready var _event_log: Label = %EventLog
@onready var _probe: Node = %Probe
@onready var _record_button: Button = %RecordButton
@onready var _free_button: Button = %FreeButton
var _events: Array[String] = []
var _process_count := 0

func _enter_tree() -> void:
	_events.append("root._enter_tree")

func _ready() -> void:
	_events.append("root._ready")
	_record_button.pressed.connect(_record_again)
	_free_button.pressed.connect(_free_probe)
	_update_view()

func _process(_delta: float) -> void:
	_process_count += 1
	if _process_count % 10 == 0:
		_update_view()

func _exit_tree() -> void:
	_events.append("root._exit_tree")

func _record_again() -> void:
	_events.append("manual_signal")
	_process_count = 0
	_update_view()

func _free_probe() -> void:
	if is_instance_valid(_probe):
		_probe.queue_free()
		_events.append("probe.queue_free")
		_update_view()

func _update_view() -> void:
	_status.text = "process 调用次数：%d" % _process_count
	_event_log.text = "事件顺序：\n" + "\n".join(_events)
