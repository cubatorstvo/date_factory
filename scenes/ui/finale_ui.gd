class_name FinaleUI
extends CanvasLayer
## Postgame finale and credits overlay.

@onready var body: Label = $Center/Panel/Content/Body
@onready var continue_button: Button = $Center/Panel/Content/Continue
@onready var credits_button: Button = $Center/Panel/Content/Credits
@onready var main_menu_button: Button = $Center/Panel/Content/MainMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("finale_ui")
	visible = false
	continue_button.pressed.connect(close)
	credits_button.pressed.connect(_show_credits)
	main_menu_button.pressed.connect(_main_menu)


func open() -> void:
	var culture := ""
	if Game.trait_influence != null:
		culture = "\n\n" + Game.trait_influence.culture_summary()
	body.text = "Алгоритм Любви синхронизирован.\nОн читает не шаблон, а культуру твоей орбиты.\nЛегенда держится. Фабрика работает. Любовь — тоже.\nПостгейм открыт." + culture
	visible = true
	get_tree().paused = true
	Game.facility.set_flag("finale_complete", true)


func close() -> void:
	visible = false
	get_tree().paused = false


func _show_credits() -> void:
	body.text = "DATE FACTORY\nКорпорация одного мужчины\n\nНаблюдения · Дубли · Легенда · Орбита\n\nСпасибо, что масштабировал себя.\n\nТитры · Постгейм"
	Game.facility.set_flag("credits_seen", true)


func _main_menu() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/boot/boot.tscn")
