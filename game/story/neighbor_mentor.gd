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
const FRIEND_TEXT: String = (
	"СОСЕДКА:\nНу как? Я рассказала всё, что знаю. Дальше сам — у меня куча дел."
)

@onready var _character: CharacterActor = $CharacterActor
@onready var _dialogue_root: Control = $DialogueLayer/Root
@onready var _body: Label = $DialogueLayer/Root/Panel/Margin/VBox/Body
@onready var _continue_button: Button = $DialogueLayer/Root/Panel/Margin/VBox/Continue

var _active_player: PlayerController = null
var _grants_briefing_on_close: bool = false


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
	if gs != null:
		briefed = bool(
			gs.call("get_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE)
		)
		tutorial_complete = bool(
			gs.call("get_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE)
		)
	_grants_briefing_on_close = not briefed
	if tutorial_complete:
		_body.text = FRIEND_TEXT
	elif briefed:
		_body.text = REMINDER_TEXT
	else:
		_body.text = BRIEFING_TEXT
	_continue_button.text = "Понятно" if not tutorial_complete else "До встречи"
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
	if _grants_briefing_on_close:
		var gs: Node = get_node_or_null("/root/GameState")
		if gs != null:
			gs.call("set_story_flag", StoryIds.FLAG_NEIGHBOR_BRIEFING_COMPLETE, true)
	_grants_briefing_on_close = false
	if _active_player != null and is_instance_valid(_active_player):
		_active_player.enter_gameplay()
	_active_player = null
