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

const SCENE_PATH: String = "res://ui/rivals/rival_encounter_ui.tscn"
const CHOICE_CARD_SCENE: String = "res://ui/common/choice_card.tscn"
const MUTED := Color(0.72, 0.74, 0.76, 1.0)
const WARNING := Color(0.78, 0.48, 0.38, 1.0)
const ACCENT := Color(0.95, 0.92, 0.55, 1.0)

var _mode: Mode = Mode.NONE
var _player: Node = null
var _exhibition: bool = false
var _restore_gameplay_on_close: bool = true
@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _stakes_label: Label = %StakesLabel
@onready var _list: VBoxContainer = %ChoiceList
@onready var _close_btn: Button = %CloseButton
var _rival_id: StringName = &""
var _pending_choice: bool = false
var _on_confirm: Callable = Callable()
var _invoke_confirm_on_close: bool = false


static func create() -> RivalEncounterUI:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	if packed == null:
		return null
	return packed.instantiate() as RivalEncounterUI


func _ready() -> void:
	UiScaleHelper.apply_to_control(_root)
	_close_btn.pressed.connect(_on_close_pressed)
	visible = false


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
	if visible:
		_audio_play_ui(AudioIds.UI_BACK)
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
		var row: ChoiceCard = _make_competition_row(ctype, def, rival_name, unlocked)
		if row != null:
			_list.add_child(row)


func _make_competition_row(
	ctype: GameTypes.CompetitionType,
	def: RivalDefinition,
	rival_name: String,
	unlocked: bool,
) -> ChoiceCard:
	var packed: PackedScene = load(CHOICE_CARD_SCENE) as PackedScene
	if packed == null:
		return null
	var card: ChoiceCard = packed.instantiate() as ChoiceCard
	if card == null:
		return null
	var detail_text: String = ""
	if unlocked:
		detail_text = _compare_line(ctype, def, rival_name)
	else:
		detail_text = _lock_reason(ctype)
	card.configure(
		_competition_short_name(ctype),
		detail_text,
		"Выбрать" if unlocked else "Недоступно"
	)
	card.detail_label.add_theme_color_override("font_color", MUTED if unlocked else WARNING)
	card.action_button.disabled = not unlocked
	if unlocked:
		var chosen: GameTypes.CompetitionType = ctype
		card.chosen.connect(func() -> void:
			_on_choose(chosen)
		)
	return card


func _on_choose(ctype: GameTypes.CompetitionType) -> void:
	_audio_play_ui(AudioIds.UI_CLICK)
	if _pending_choice or _mode != Mode.CHOOSE:
		return
	var encounters: Node = _service("/root/RivalEncounters")
	if encounters == null:
		return
	_pending_choice = true
	var out: Dictionary = encounters.call("choose_competition", ctype) as Dictionary
	if not bool(out.get("ok", false)):
		_pending_choice = false
		_audio_play_ui(AudioIds.UI_DENIED)
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
	_audio_play_sfx(AudioIds.RIVAL_WIN if won else AudioIds.RIVAL_LOSS)
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
	if def != null and def.is_story:
		# MODULE 26: story loss never changes Authority.
		loss_line = "Поражение: Авторитет не меняется"
	else:
		var gs: Node = _service("/root/GameState")
		if gs != null and bool(gs.call("has_perk", PerkIds.MUSCLE_HEROIC_DEFEAT)):
			loss_line = "Поражение: обычно -1"
	return "%s\n%s" % [win_line, loss_line]


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


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
