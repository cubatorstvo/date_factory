class_name ApartmentPlaceSetting
extends Node3D
## Home-date place setting: show CheapGlass pair after drink prep; hide on clear/cancel/finish.

const GLASS_A: String = "DateGlassA"
const GLASS_B: String = "DateGlassB"


func _ready() -> void:
	visible = true
	if is_instance_valid(EventBus):
		if not EventBus.table_prep_changed.is_connected(_on_table_prep_changed):
			EventBus.table_prep_changed.connect(_on_table_prep_changed)
		if not EventBus.date_cancelled.is_connected(_on_date_cancelled):
			EventBus.date_cancelled.connect(_on_date_cancelled)
		if not EventBus.date_finished.is_connected(_on_date_finished):
			EventBus.date_finished.connect(_on_date_finished)
	if is_instance_valid(Game) and Game.dating != null:
		if not Game.dating.date_ui_close.is_connected(_on_date_ui_close):
			Game.dating.date_ui_close.connect(_on_date_ui_close)
		_sync_from_state(Game.dating.schedule.table_state())
	else:
		_set_glasses_visible(false)


func _exit_tree() -> void:
	if is_instance_valid(EventBus):
		if EventBus.table_prep_changed.is_connected(_on_table_prep_changed):
			EventBus.table_prep_changed.disconnect(_on_table_prep_changed)
		if EventBus.date_cancelled.is_connected(_on_date_cancelled):
			EventBus.date_cancelled.disconnect(_on_date_cancelled)
		if EventBus.date_finished.is_connected(_on_date_finished):
			EventBus.date_finished.disconnect(_on_date_finished)
	if is_instance_valid(Game) and Game.dating != null and Game.dating.date_ui_close.is_connected(_on_date_ui_close):
		Game.dating.date_ui_close.disconnect(_on_date_ui_close)


func _on_table_prep_changed(state: Dictionary) -> void:
	_sync_from_state(state)


func _on_date_cancelled(_payload: Dictionary) -> void:
	_set_glasses_visible(false)


func _on_date_finished(_result: Dictionary) -> void:
	_set_glasses_visible(false)


func _on_date_ui_close() -> void:
	_set_glasses_visible(false)


func _sync_from_state(state: Dictionary) -> void:
	var drink_tier: int = int(state.get("drink_tier", 0))
	_set_glasses_visible(drink_tier > 0)


func _set_glasses_visible(show: bool) -> void:
	var names: PackedStringArray = PackedStringArray([GLASS_A, GLASS_B])
	for i in names.size():
		var node_path: String = names[i]
		var node: Node3D = get_node_or_null(node_path) as Node3D
		if is_instance_valid(node):
			node.visible = show
