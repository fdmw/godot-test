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
	var probe := get_node("Probe")
	if not probe.tree_entered.is_connected(_on_probe_tree_entered):
		probe.tree_entered.connect(_on_probe_tree_entered)

func _ready() -> void:
	_events.append("root._ready")
	_record_button.pressed.connect(_record_again)
	_free_button.pressed.connect(_free_probe)
	_probe.tree_exiting.connect(_on_probe_tree_exiting)
	_probe.tree_exited.connect(_on_probe_tree_exited)
	_update_view()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			_events.append("root.notification: ENTER_TREE")
			_update_view_if_ready()
		NOTIFICATION_READY:
			_events.append("root.notification: READY")
			_update_view_if_ready()
		NOTIFICATION_EXIT_TREE:
			_events.append("root.notification: EXIT_TREE")

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

func _on_probe_tree_entered() -> void:
	_events.append("probe.tree_entered")
	_update_view_if_ready()

func _on_probe_tree_exiting() -> void:
	_events.append("probe.tree_exiting")
	_update_view_if_ready()

func _on_probe_tree_exited() -> void:
	_events.append("probe.tree_exited")
	_update_view_if_ready()

func _update_view_if_ready() -> void:
	if is_node_ready():
		_update_view()

func _update_view() -> void:
	_status.text = "process 调用次数：%d" % _process_count
	_event_log.text = "事件顺序：\n" + "\n".join(_events)
