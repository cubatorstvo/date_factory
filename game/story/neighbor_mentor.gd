class_name NeighborMentor
extends Interactable
## Story-only Neighbor interaction. Never enters discovery or relationship systems.

const BRIEFING_TEXT: String = (
	"ГЕРОЙ:\nНаучишь меня ходить на свидания?\n\n"
	+ "СОСЕДКА:\nЛадно. Скоро приду — подготовь всё по списку: еду, "
	+ "напитки и приведи себя в порядок. Обстановка тоже важна."
)
const REMINDER_TEXT: String = (
	"СОСЕДКА:\nЯ скоро подойду. Подготовь еду, напитки и выбери одежду."
)
const UPGRADE_GRANT_TEXT: String = (
	"СОСЕДКА:\nСлушай. Когда у девушки станет +5 — сердце покорено. "
	+ "И за это тебе дают балл прокачки.\n\n"
	+ "Вот, держи учебный. Открой телефон → ПРОКАЧКА и купи самый дешёвый перк. "
	+ "Стоит один."
)
const UPGRADE_REMIND_TEXT: String = (
	"СОСЕДКА:\nНу? Телефон → ПРОКАЧКА. Купи перк за 1 балл, "
	+ "пока я добрый учебный спонсор."
)
const UPGRADE_RECLAIM_TEXT: String = (
	"СОСЕДКА:\nАга, купил. Так вот: каждый балл — только за реально покорённое сердце.\n\n"
	+ "Учебный не считается. Перк забираю. Баллы снова ноль — "
	+ "пока не дойдёшь до настоящего +5."
)
const FRIEND_TEXT: String = (
	"СОСЕДКА:\nНу как? Я рассказала всё, что знаю. Дальше сам — у меня куча дел."
)

enum _CloseAction {
	NONE,
	GRANT_BRIEFING,
	GRANT_TUTORIAL_POINT,
	RECLAIM_TUTORIAL,
}

@onready var _character: CharacterActor = $CharacterActor
@onready var _dialogue_root: Control = $DialogueLayer/Root
@onready var _body: Label = $DialogueLayer/Root/Panel/Margin/VBox/Body
@onready var _continue_button: Button = $DialogueLayer/Root/Panel/Margin/VBox/Continue

var _active_player: PlayerController = null
var _close_action: int = _CloseAction.NONE


func _ready() -> void:
	prompt_action = "Поговорить с соседкой"
	monitoring = false
	monitorable = true
	_dialogue_root.visible = false
	_continue_button.pressed.connect(_close_dialogue)
	if _character != null:
		_character.apply_appearance(&"appearance_female_neighbor")
		var animation: CharacterAnimationController = _character.get_animation_controller()
		if animation != null:
			animation.play_semantic(&"idle")


func get_interaction_prompt(_player: Node) -> String:
	return "[E] Поговорить с соседкой"


func _on_interact(player: Node) -> void:
	if not (player is PlayerController) or _dialogue_root.visible:
		return
	_active_player = player as PlayerController
	_active_player.enter_modal_ui()
	var gs: Node = get_node_or_null("/root/GameState")
	var briefed: bool = false
	var tutorial_complete: bool = false
	var joke_done: bool = false
	var has_tutorial_point: bool = false
	var awaiting_reclaim: bool = false
	if gs != null:
		briefed = bool(
			gs.call("get_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE)
		)
		tutorial_complete = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE)
		)
		joke_done = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_JOKE_DONE)
		)
		has_tutorial_point = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_POINT)
		)
		awaiting_reclaim = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_UPGRADE_AWAITING_RECLAIM)
		)
	_close_action = _CloseAction.NONE
	if tutorial_complete and not joke_done:
		if awaiting_reclaim:
			_body.text = UPGRADE_RECLAIM_TEXT
			_close_action = _CloseAction.RECLAIM_TUTORIAL
			_continue_button.text = "Понятно"
		elif has_tutorial_point:
			_body.text = UPGRADE_REMIND_TEXT
			_continue_button.text = "Сейчас"
		else:
			_body.text = UPGRADE_GRANT_TEXT
			_close_action = _CloseAction.GRANT_TUTORIAL_POINT
			_continue_button.text = "Понятно"
	elif tutorial_complete:
		_body.text = FRIEND_TEXT
		_continue_button.text = "До встречи"
	elif briefed:
		_body.text = REMINDER_TEXT
		_continue_button.text = "Понятно"
	else:
		_body.text = BRIEFING_TEXT
		_close_action = _CloseAction.GRANT_BRIEFING
		_continue_button.text = "Понятно"
	_dialogue_root.visible = true
	_continue_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _dialogue_root.visible and event.is_action_pressed("ui_cancel"):
		_close_dialogue()
		get_viewport().set_input_as_handled()


func _close_dialogue() -> void:
	if not _dialogue_root.visible:
		return
	_dialogue_root.visible = false
	var gs: Node = get_node_or_null("/root/GameState")
	match _close_action:
		_CloseAction.GRANT_BRIEFING:
			if gs != null:
				gs.call("set_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE, true)
		_CloseAction.GRANT_TUTORIAL_POINT:
			if gs != null and gs.has_method("grant_tutorial_upgrade_point"):
				gs.call("grant_tutorial_upgrade_point")
		_CloseAction.RECLAIM_TUTORIAL:
			if gs != null and gs.has_method("complete_tutorial_upgrade_joke"):
				gs.call("complete_tutorial_upgrade_joke")
		_:
			pass
	_close_action = _CloseAction.NONE
	if _active_player != null and is_instance_valid(_active_player):
		_active_player.enter_gameplay()
	_active_player = null
