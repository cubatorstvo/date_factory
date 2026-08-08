class_name TutorialPrompt
extends RefCounted
## Lightweight first-use tutorial prompts (MODULE 22). Runtime-only flags; no autoload.

enum PromptId {
	FIRST_MOVEMENT,
	FIRST_PHONE,
	FIRST_RIVAL,
	FIRST_DATE,
	FIRST_UPGRADE_POINT,
	FIRST_CLONE,
	FIRST_STAGE6,
}

const DISPLAY_SECONDS: float = 5.0

const COPY := {
	PromptId.FIRST_MOVEMENT: "WASD — движение\nМышь — обзор\nE — взаимодействие",
	PromptId.FIRST_PHONE: "Телефон хранит сюжет, девушек и текущие системы.",
	PromptId.FIRST_RIVAL: "Самец выбирает или предлагает состязание.\nСравни характеристики до начала.",
	PromptId.FIRST_DATE: "Требования действий видны заранее.\nПосле выбора реакция всегда показывает +1 / 0 / -1.",
	PromptId.FIRST_UPGRADE_POINT: "Каждая новая Опытность даёт 1 Балл прокачки.",
	PromptId.FIRST_CLONE: "Терминал лаборатории распределяет клонов между Работой и Свиданиями.",
	PromptId.FIRST_STAGE6: "Охват Земли растёт от новых автоматических свиданий.",
}

var _seen: Dictionary = {}
var _queue: Array[int] = []
var _active_id: int = -1


func reset_runtime() -> void:
	_seen.clear()
	_queue.clear()
	_active_id = -1


func request(prompt_id: PromptId) -> void:
	var id: int = int(prompt_id)
	if bool(_seen.get(id, false)):
		return
	if _active_id == id:
		return
	if _queue.has(id):
		return
	_queue.append(id)


func has_pending() -> bool:
	return not _queue.is_empty()


func is_showing() -> bool:
	return _active_id >= 0


func peek_pending() -> int:
	if _queue.is_empty():
		return -1
	return int(_queue[0])


func begin_next() -> Dictionary:
	if _queue.is_empty():
		return {}
	var id: int = int(_queue.pop_front())
	_active_id = id
	_seen[id] = true
	return {
		"id": id,
		"text": String(COPY.get(id, "")),
		"seconds": DISPLAY_SECONDS,
	}


func dismiss_active() -> void:
	_active_id = -1


func mark_seen(prompt_id: PromptId) -> void:
	_seen[int(prompt_id)] = true
