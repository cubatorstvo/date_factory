class_name FirstCloneTypes
extends RefCounted
## Shared First Clone enums / constants (MODULE 17).


enum MachineAvailability {
	AVAILABLE = 0,
	OVERLOAD_NOT_RECOGNIZED = 1,
	SCIENTIST_NOT_COMPLETED = 2,
	LAB_LOCKED = 3,
	ALREADY_CREATED = 4,
	SEQUENCE_ACTIVE = 5,
	NOT_IN_LAB = 6,
}


enum Assignment {
	NONE = 0,
	WORK = 1,
	DATING = 2,
}


enum CalibrationPhase {
	INTRO = 0,
	CALIBRATION = 1,
	PASS_FEEDBACK = 2,
	COMPLETE = 3,
	FINISHED = 4,
}


enum CalibrationPass {
	BODY = 0,
	FACE = 1,
	CONFIDENCE = 2,
}


const SCIENTIST_GIRL_ID: StringName = &"girl_scientist"
const LOCATION_LABORATORY: StringName = &"laboratory"

const APPEARANCE_FIRST_CLONE: StringName = &"appearance_male_first_clone"
const APPEARANCE_FALLBACK: StringName = &"appearance_male_base"
const APPEARANCE_FIRST_CLONE_PATH: String = "res://data/content/appearances/appearance_male_first_clone.tres"

const MARKER_MACHINE: String = "story_point_clone_machine"
const MARKER_OUTPUT: String = "story_point_clone_output"
const MARKER_WORK: String = "story_point_clone_work_station"
const MARKER_DATE: String = "story_point_clone_date_station"

const BODY_LABEL: String = "СОВПАДЕНИЕ ТЕЛА"
const BODY_CENTER: float = 0.35
const BODY_WIDTH: float = 0.28
const BODY_SPEED: float = 0.55

const FACE_LABEL: String = "СОВПАДЕНИЕ ЛИЦА"
const FACE_CENTER: float = 0.62
const FACE_WIDTH: float = 0.22
const FACE_SPEED: float = 0.70

const CONFIDENCE_LABEL: String = "СОВПАДЕНИЕ УВЕРЕННОСТИ"
const CONFIDENCE_CENTER: float = 0.48
const CONFIDENCE_WIDTH: float = 0.16
const CONFIDENCE_SPEED: float = 0.85

const MISS_FEEDBACK_SEC: float = 0.45
const REVEAL_DELAY_SEC: float = 2.0
const ASSIGN_TWEEN_SEC: float = 1.5

const INTRO_TITLE: String = "КАЛИБРОВКА ОРИГИНАЛА"
const INTRO_BODY: String = "Система создаст копию настолько точную,\nнасколько это позволяет текущая юридическая ситуация.\n\nНажимай SPACE, когда сканер находится в зоне."

const FEEDBACK_BODY: String = "ТЕЛО: СОВПАЛО"
const FEEDBACK_FACE: String = "ЛИЦО: СОВПАЛО"
const FEEDBACK_CONFIDENCE: String = "УВЕРЕННОСТЬ: ВНЕ РЕКОМЕНДУЕМОГО ДИАПАЗОНА\nКОПИРОВАНИЕ РАЗРЕШЕНО РУЧНЫМ РЕШЕНИЕМ"
const FEEDBACK_MISS: String = "КАЛИБРОВКА НЕ ПРИНЯТА\nПОВТОРИТЬ СКАН"
const FEEDBACK_COMPLETE: String = "КАЛИБРОВКА ЗАВЕРШЕНА\nПЕЧАТЬ ЧЕЛОВЕКА"

const MACHINE_PROMPT: String = "Запустить установку клонирования"
const MACHINE_DONE_PROMPT: String = "Первый клон уже создан."

const ASSIGNMENT_TITLE: String = "КУДА ОТПРАВИТЬ ПЕРВОГО КЛОНА?"
const ASSIGNMENT_WORK: String = "РАБОТАТЬ"
const ASSIGNMENT_DATING: String = "НА СВИДАНИЯ"

const CLONE_LINE: String = "Я тоже считаю, что проблема была в количестве тебя."


static func pass_label(pass_index: int) -> String:
	match pass_index:
		int(CalibrationPass.BODY):
			return BODY_LABEL
		int(CalibrationPass.FACE):
			return FACE_LABEL
		int(CalibrationPass.CONFIDENCE):
			return CONFIDENCE_LABEL
	return ""


static func pass_center(pass_index: int) -> float:
	match pass_index:
		int(CalibrationPass.BODY):
			return BODY_CENTER
		int(CalibrationPass.FACE):
			return FACE_CENTER
		int(CalibrationPass.CONFIDENCE):
			return CONFIDENCE_CENTER
	return 0.5


static func pass_width(pass_index: int) -> float:
	match pass_index:
		int(CalibrationPass.BODY):
			return BODY_WIDTH
		int(CalibrationPass.FACE):
			return FACE_WIDTH
		int(CalibrationPass.CONFIDENCE):
			return CONFIDENCE_WIDTH
	return 0.2


static func pass_speed(pass_index: int) -> float:
	match pass_index:
		int(CalibrationPass.BODY):
			return BODY_SPEED
		int(CalibrationPass.FACE):
			return FACE_SPEED
		int(CalibrationPass.CONFIDENCE):
			return CONFIDENCE_SPEED
	return 0.5


static func pass_success_feedback(pass_index: int) -> String:
	match pass_index:
		int(CalibrationPass.BODY):
			return FEEDBACK_BODY
		int(CalibrationPass.FACE):
			return FEEDBACK_FACE
		int(CalibrationPass.CONFIDENCE):
			return FEEDBACK_CONFIDENCE
	return ""


static func resolve_clone_appearance_id() -> StringName:
	if ResourceLoader.exists(APPEARANCE_FIRST_CLONE_PATH):
		return APPEARANCE_FIRST_CLONE
	var loop: MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		var tree: SceneTree = loop as SceneTree
		var db: Node = tree.root.get_node_or_null("ContentDB")
		if db != null and db.has_method("has_appearance"):
			if bool(db.call("has_appearance", APPEARANCE_FIRST_CLONE)):
				return APPEARANCE_FIRST_CLONE
		elif db != null and db.has_method("get_appearance"):
			var profile: Variant = db.call("get_appearance", APPEARANCE_FIRST_CLONE)
			if profile != null:
				return APPEARANCE_FIRST_CLONE
	return APPEARANCE_FALLBACK
