class_name RivalEncounterUI
extends CanvasLayer
## Rival pre-competition + result presentation (MODULE 22 §§51–52, §99).
## Presentation only — calls existing RivalEncounters APIs; no formula changes.


signal choose_closed()
signal result_closed()
signal competition_started(competition_type: GameTypes.CompetitionType)

enum Mode {
	NONE,
	CHOOSE,
	RESULT,
}

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const TITLE_FONT_SIZE: int = 26
const HEADER_FONT_SIZE: int = 20
const BODY_FONT_SIZE: int = 17
const MUTED := Color(0.72, 0.74, 0.76, 1.0)
const WARNING := Color(0.78, 0.48, 0.38, 1.0)
const ACCENT := Color(0.95, 0.92, 0.55, 1.0)

var _mode: Mode = Mode.NONE
var _player: Node = null
var _exhibition: bool = false
var _restore_gameplay_on_close: bool = true
var _root: Control = null
var _panel: PanelContainer = null
var _title: Label = null
var _subtitle: Label = null
var _stakes_label: Label = null
var _list: VBoxContainer = null
var _close_btn: Button = null
var _rival_id: StringName = &""
var _pending_choice: bool = false
var _on_confirm: Callable = Callable()
var _invoke_confirm_on_close: bool = false


static func create() -> RivalEncounterUI:
	var ui: RivalEncounterUI = new() as RivalEncounterUI
	ui.name = "RivalEncounterUI"
	ui.layer = 48
	return ui


## Show allowed competitions for the active RivalEncounters session (choose phase).
func open_choose(player: Node, exhibition: bool = false) -> void:
	_ensure_tree()
	var encounters: Node = _service("/root/RivalEncounters")
	if encounters == null:
		push_error("[RivalEncounterUI] RivalEncounters missing")
		return
	var session: RivalEncounterSession = encounters.call("get_active_session") as RivalEncounterSession
	if session == null or session.phase != GameTypes.RivalEncounterPhase.CHOOSING:
		push_error("[RivalEncounterUI] no CHOOSING session")
		return
	_player = player
	_exhibition = exhibition
	_rival_id = session.rival_id
	_restore_gameplay_on_close = true
	_pending_choice = false
	_on_confirm = Callable()
	_invoke_confirm_on_close = false
	_mode = Mode.CHOOSE
	_build_choose(session)
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


## Result after RivalEncounters finish. exhibition=true → no Authority consequence line (§99).
func open_result(
	player: Node,
	result: RivalEncounterResult,
	exhibition: bool = false,
) -> void:
	if result == null:
		push_error("[RivalEncounterUI] null result")
		return
	_ensure_tree()
	_player = player
	_exhibition = exhibition
	_rival_id = result.rival_id
	_restore_gameplay_on_close = true
	_pending_choice = false
	_on_confirm = Callable()
	_invoke_confirm_on_close = false
	_mode = Mode.RESULT
	_build_result_from_encounter(result)
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


## MODULE 21 exhibition seam: same win/loss visual, no Authority line.
func open_exhibition_result(player: Node, competition_result: RivalCompetitionResult) -> void:
	if competition_result == null:
		push_error("[RivalEncounterUI] null exhibition result")
		return
	_ensure_tree()
	_player = player
	_exhibition = true
	_rival_id = &""
	_restore_gameplay_on_close = true
	_pending_choice = false
	_on_confirm = Callable()
	_invoke_confirm_on_close = false
	_mode = Mode.RESULT
	_build_result_simple(
		competition_result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
		0,
		false,
	)
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


## Pre-competition stakes for exhibition (no choose list required).
func open_exhibition_stakes(
	player: Node,
	rival_definition: RivalDefinition,
	on_confirm: Callable = Callable(),
) -> void:
	_player = player
	_exhibition = true
	_rival_id = rival_definition.id if rival_definition != null else &""
	_restore_gameplay_on_close = true
	_pending_choice = false
	_ensure_tree()
	_on_confirm = on_confirm
	_invoke_confirm_on_close = false
	_mode = Mode.CHOOSE
	_clear_list()
	var rival_name: String = "Соперник"
	if rival_definition != null and rival_definition.display_name.strip_edges() != "":
		rival_name = rival_definition.display_name
	_title.text = "ВЫСТАВКА"
	_subtitle.text = rival_name
	_stakes_label.text = "Авторитет не меняется"
	_stakes_label.add_theme_color_override("font_color", ACCENT)
	_close_btn.text = "Продолжить" if on_confirm.is_valid() else "Закрыть"
	visible = true
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")


## Close without restoring gameplay (transition into minigame / next modal).
func dismiss_for_transition() -> void:
	_restore_gameplay_on_close = false
	_invoke_confirm_on_close = false
	close()


func close() -> void:
	var p: Node = _player
	var restore: bool = _restore_gameplay_on_close
	var was_mode: Mode = _mode
	var confirm: Callable = _on_confirm
	var invoke_confirm: bool = _invoke_confirm_on_close
	_mode = Mode.NONE
	_player = null
	_pending_choice = false
	_on_confirm = Callable()
	_invoke_confirm_on_close = false
	visible = false
	if is_instance_valid(self):
		queue_free()
	if invoke_confirm and confirm.is_valid():
		confirm.call(p)
	elif restore and p != null and p.has_method("enter_gameplay"):
		p.call("enter_gameplay")
	if was_mode == Mode.RESULT:
		result_closed.emit()
	else:
		choose_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _mode == Mode.NONE:
		return
	# Never abort mid-minigame — this UI is hidden while runner owns the screen.
	if event.is_action_pressed("ui_cancel"):
		if _mode == Mode.CHOOSE and not _exhibition:
			_cancel_choose()
		else:
			close()
		get_viewport().set_input_as_handled()


func _service(absolute_path: String) -> Node:
	if is_inside_tree():
		return get_node_or_null(absolute_path)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(absolute_path.trim_prefix("/root/"))


func _ensure_tree() -> void:
	if get_parent() == null:
		var tree: SceneTree = Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.root.add_child(self)
	_build_shell()


func _build_shell() -> void:
	for child in get_children():
		child.queue_free()
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var theme_res: Resource = null
	if ResourceLoader.exists(THEME_PATH):
		theme_res = load(THEME_PATH)
	if theme_res is Theme:
		_root.theme = theme_res as Theme
	else:
		_root.theme = DateFactoryThemeBuilder.build()

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.04, 0.05, 0.72)
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(520, 420)
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	_subtitle.add_theme_color_override("font_color", MUTED)
	vbox.add_child(_subtitle)

	_stakes_label = Label.new()
	_stakes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stakes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stakes_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(_stakes_label)

	_list = VBoxContainer.new()
	_list.name = "List"
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_list)

	_close_btn = Button.new()
	_close_btn.custom_minimum_size = Vector2(0, 36)
	_close_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	_close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_btn)


func _clear_list() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()


func _build_choose(session: RivalEncounterSession) -> void:
	_clear_list()
	var def: RivalDefinition = session.rival_definition
	var rival_name: String = "Соперник"
	if def != null and def.display_name.strip_edges() != "":
		rival_name = def.display_name
	_title.text = "ВЫЗОВ"
	_subtitle.text = rival_name
	_stakes_label.text = _stakes_text(def)
	if _exhibition:
		_stakes_label.add_theme_color_override("font_color", ACCENT)
	else:
		_stakes_label.add_theme_color_override("font_color", MUTED)
	_close_btn.text = "Отмена"

	var encounters: Node = _service("/root/RivalEncounters")
	var available: Array = []
	if encounters != null:
		available = encounters.call("get_available_competitions", session.rival_id) as Array
	var allowed: Array = []
	if def != null:
		for ctype in def.allowed_competitions:
			allowed.append(ctype)
	if allowed.is_empty():
		allowed = available.duplicate()

	for ctype_v in allowed:
		var ctype: GameTypes.CompetitionType = ctype_v as GameTypes.CompetitionType
		var unlocked: bool = available.has(ctype)
		_list.add_child(_make_competition_row(ctype, def, rival_name, unlocked))


func _make_competition_row(
	ctype: GameTypes.CompetitionType,
	def: RivalDefinition,
	rival_name: String,
	unlocked: bool,
) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = _competition_short_name(ctype)
	name_lbl.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	box.add_child(name_lbl)

	var detail := Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	if unlocked:
		detail.text = _compare_line(ctype, def, rival_name)
		detail.add_theme_color_override("font_color", MUTED)
	else:
		detail.text = _lock_reason(ctype)
		detail.add_theme_color_override("font_color", WARNING)
	box.add_child(detail)

	if unlocked:
		var btn := Button.new()
		btn.text = "Выбрать"
		btn.custom_minimum_size = Vector2(0, 34)
		btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		var chosen: GameTypes.CompetitionType = ctype
		btn.pressed.connect(func() -> void:
			_on_choose(chosen)
		)
		box.add_child(btn)
	else:
		var locked_btn := Button.new()
		locked_btn.text = "Недоступно"
		locked_btn.disabled = true
		locked_btn.custom_minimum_size = Vector2(0, 34)
		locked_btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
		box.add_child(locked_btn)
	return box


func _on_choose(ctype: GameTypes.CompetitionType) -> void:
	if _pending_choice or _mode != Mode.CHOOSE:
		return
	var encounters: Node = _service("/root/RivalEncounters")
	if encounters == null:
		return
	_pending_choice = true
	var out: Dictionary = encounters.call("choose_competition", ctype) as Dictionary
	if not bool(out.get("ok", false)):
		_pending_choice = false
		var reason: StringName = out.get("reason", &"") as StringName
		_stakes_label.text = "Не удалось начать: %s" % String(reason)
		_stakes_label.add_theme_color_override("font_color", WARNING)
		return
	# Runner owns control; do not restore gameplay here.
	_restore_gameplay_on_close = false
	competition_started.emit(ctype)
	close()


func _cancel_choose() -> void:
	var encounters: Node = _service("/root/RivalEncounters")
	if encounters != null and bool(encounters.call("has_active_encounter")):
		var session: RivalEncounterSession = encounters.call("get_active_session") as RivalEncounterSession
		if session != null and session.phase == GameTypes.RivalEncounterPhase.CHOOSING:
			encounters.call("force_clear_session")
	_restore_gameplay_on_close = true
	close()


func _on_close_pressed() -> void:
	if _mode == Mode.CHOOSE and not _exhibition and not _on_confirm.is_valid():
		_cancel_choose()
		return
	if _on_confirm.is_valid():
		_invoke_confirm_on_close = true
		_restore_gameplay_on_close = false
	close()


func _build_result_from_encounter(result: RivalEncounterResult) -> void:
	var won: bool = result.outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN
	_build_result_simple(won, result.authority_delta, result.heroic_defeat_triggered)


func _build_result_simple(won: bool, authority_delta: int, heroic: bool) -> void:
	_clear_list()
	_title.text = "ПОБЕДА" if won else "ПОРАЖЕНИЕ"
	_title.add_theme_color_override("font_color", ACCENT if won else WARNING)
	_subtitle.text = ""
	_close_btn.text = "Продолжить"
	if _exhibition:
		_stakes_label.text = ""
		return
	if won:
		_stakes_label.text = "Авторитет %s" % UiNumberFormat.format_signed(authority_delta)
	elif heroic:
		_stakes_label.text = "Героическое поражение — Авторитет не изменился"
	else:
		_stakes_label.text = "Авторитет %s" % UiNumberFormat.format_signed(authority_delta)
	_stakes_label.add_theme_color_override("font_color", MUTED)


func _stakes_text(def: RivalDefinition) -> String:
	if _exhibition:
		return "Авторитет не меняется"
	var reward: int = 0
	if def != null:
		reward = def.authority_reward
	var win_line: String = "Победа: Авторитет %s" % UiNumberFormat.format_signed(reward)
	var loss_line: String = "Поражение: Авторитет -1"
	var gs: Node = _service("/root/GameState")
	if gs != null and bool(gs.call("has_perk", PerkIds.MUSCLE_HEROIC_DEFEAT)):
		loss_line = "Поражение: обычно -1"
	return "%s\n%s" % [win_line, loss_line]


func _competition_short_name(ctype: GameTypes.CompetitionType) -> String:
	match ctype:
		GameTypes.CompetitionType.SLAP:
			return "ПОЩЁЧИНА"
		GameTypes.CompetitionType.DANCE:
			return "ТАНЕЦ"
		GameTypes.CompetitionType.SIGMA:
			return "СИГМА"
		GameTypes.CompetitionType.MONEY:
			return "ДЕНЬГИ"
	return "СОСТЯЗАНИЕ"


func _characteristic_for(ctype: GameTypes.CompetitionType) -> GameTypes.PlayerCharacteristic:
	var db: Node = _service("/root/ContentDB")
	if db != null and db.has_method("get_competition"):
		var cdef: CompetitionDefinition = db.call("get_competition", ctype) as CompetitionDefinition
		if cdef != null:
			return cdef.characteristic
	match ctype:
		GameTypes.CompetitionType.SLAP:
			return GameTypes.PlayerCharacteristic.MUSCLE
		GameTypes.CompetitionType.DANCE:
			return GameTypes.PlayerCharacteristic.APPEARANCE
		GameTypes.CompetitionType.MONEY:
			return GameTypes.PlayerCharacteristic.CAPITAL
		GameTypes.CompetitionType.SIGMA:
			return GameTypes.PlayerCharacteristic.AURA
	return GameTypes.PlayerCharacteristic.MUSCLE


func _characteristic_label(ch: GameTypes.PlayerCharacteristic) -> String:
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return "Мышца"
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return "Внешность"
		GameTypes.PlayerCharacteristic.CAPITAL:
			return "Капитал"
		GameTypes.PlayerCharacteristic.AURA:
			return "Аура"
	return "Характеристика"


func _rival_level(def: RivalDefinition, ch: GameTypes.PlayerCharacteristic) -> int:
	if def == null:
		return 0
	match ch:
		GameTypes.PlayerCharacteristic.MUSCLE:
			return def.muscle
		GameTypes.PlayerCharacteristic.APPEARANCE:
			return def.appearance
		GameTypes.PlayerCharacteristic.CAPITAL:
			return def.capital
		GameTypes.PlayerCharacteristic.AURA:
			return def.aura
	return 0


func _compare_line(
	ctype: GameTypes.CompetitionType,
	def: RivalDefinition,
	rival_name: String,
) -> String:
	var ch: GameTypes.PlayerCharacteristic = _characteristic_for(ctype)
	var player_level: int = 0
	var gs: Node = _service("/root/GameState")
	if gs != null:
		player_level = int(gs.call("get_characteristic", ch))
	var rival_level: int = _rival_level(def, ch)
	return "%s: Ты %d / %s %d" % [
		_characteristic_label(ch),
		player_level,
		rival_name,
		rival_level,
	]


func _lock_reason(ctype: GameTypes.CompetitionType) -> String:
	var perk_id: StringName = &""
	match ctype:
		GameTypes.CompetitionType.MONEY:
			perk_id = PerkIds.CAPITAL_PAYABLE_INTENT
		GameTypes.CompetitionType.SIGMA:
			perk_id = PerkIds.AURA_PRESENCE_REGISTERED
		_:
			return "Состязание недоступно"
	var perk_name: String = _perk_display_name(perk_id)
	return "Нужен перк «%s»" % perk_name


func _perk_display_name(perk_id: StringName) -> String:
	var db: Node = _service("/root/ContentDB")
	if db != null and db.has_method("get_perk"):
		var def: PerkDefinition = db.call("get_perk", perk_id) as PerkDefinition
		if def != null and def.display_name.strip_edges() != "":
			return def.display_name
	match perk_id:
		PerkIds.CAPITAL_PAYABLE_INTENT:
			return "Платёжеспособное намерение"
		PerkIds.AURA_PRESENCE_REGISTERED:
			return "Присутствие зарегистрировано"
	return String(perk_id)
