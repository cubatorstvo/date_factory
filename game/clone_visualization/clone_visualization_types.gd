class_name CloneVisualizationTypes
extends RefCounted
## Constants for MODULE 19 lab-local clone visualization (presentation only).


enum DateScene {
	CALM = 0,
	OVER_EXPLAINING = 1,
	SILENT_SUCCESS = 2,
	MUTUAL_CONFUSION = 3,
}


const MAX_LOCAL_DATE_SLOTS: int = 10
const MAX_LOCAL_WORK_VISUALS: int = 3
const MAX_LOCAL_FREE_VISUALS: int = 2
const MAX_MASS_FLOW_VISUALS: int = 2
const MAX_PRESENTATION_ACTORS: int = 27

const DATE_SCENE_INTERVAL: float = 6.0
const WORK_DEPARTURE_INTERVAL: float = 4.0
const WORK_TWEEN_SEC: float = 1.2
const MASS_INTERVAL_BASE: float = 3.0
const MASS_INTERVAL_FAST: float = 1.5
const MASS_INTERVAL_FASTER: float = 0.75
const MASS_EXTERNAL_FAST_AT: int = 20
const MASS_EXTERNAL_FASTER_AT: int = 100
const MASS_TWEEN_SEC: float = 1.0
const PRODUCTION_PULSE_SEC: float = 0.35
const PRODUCTION_LABEL_SEC: float = 1.0

const CLONE_APPEARANCE: StringName = &"appearance_male_first_clone"
const CLONE_APPEARANCE_FALLBACK: StringName = &"appearance_male_base"

const GIRL_APPEARANCES: Array[StringName] = [
	&"appearance_female_city_bicycle",
	&"appearance_female_cafe_laptop",
	&"appearance_female_gym_chalk",
	&"appearance_female_appearance_ritual",
	&"appearance_female_public_sculpture",
	&"appearance_female_cafe_receipt_notes",
	&"appearance_female_appearance_flash",
	&"appearance_female_neighbor",
	&"appearance_female_actress",
	&"appearance_female_mine_boss",
]

const DATE_SCENE_LABELS: Array[String] = [
	"ИДЁТ СВИДАНИЕ",
	"КЛОН ОБЪЯСНЯЕТ СВОЮ СИСТЕМУ",
	"НЕОЖИДАННО УСПЕШНО",
	"ОБА СДЕЛАЛИ ВИД, ЧТО ТАК И БЫЛО",
]

const LABEL_ROOM_FREE: String = "СВОБОДНО"
const LABEL_EXTERNAL_PREFIX: String = "ВНЕШНИЙ ПОТОК: "
const LABEL_PRODUCTION_READY: String = "КЛОН ГОТОВ"
const LABEL_FREE_AREA: String = "СВОБОДНЫЕ КЛОНЫ"
const LABEL_WORK_SIGN: String = "РАБОЧИЙ МАРШРУТ\n→ ЗАРПЛАТНАЯ ШАХТА"

const GROUP_CONTROLLER: StringName = &"clone_visualization_controller"

const SLOT_NAME_PREFIX: String = "clone_date_slot_"
const WORK_MARKER_PREFIX: String = "clone_work_visual_"
const WORK_EXIT_NAME: String = "clone_work_exit"
const FREE_MARKER_PREFIX: String = "clone_free_wait_"
const MASS_SPAWN_NAME: String = "mass_flow_spawn"
const MASS_EXIT_NAME: String = "mass_flow_exit"
const EXTERNAL_LABEL_NAME: String = "external_flow_label"
const PRODUCTION_LABEL_NAME: String = "clone_production_feedback_label"
const MACHINE_PULSE_NAME: String = "clone_machine_pulse"


static func slot_node_name(slot_index: int) -> String:
	return "%s%02d" % [SLOT_NAME_PREFIX, slot_index]


static func work_marker_name(index: int) -> String:
	return "%s%02d" % [WORK_MARKER_PREFIX, index]


static func free_marker_name(index: int) -> String:
	return "%s%02d" % [FREE_MARKER_PREFIX, index]


static func girl_appearance_for_slot(slot_index: int) -> StringName:
	var idx: int = clampi(slot_index - 1, 0, GIRL_APPEARANCES.size() - 1)
	return GIRL_APPEARANCES[idx]


static func date_scene_label(scene_index: int) -> String:
	var idx: int = posmod(scene_index, DATE_SCENE_LABELS.size())
	return DATE_SCENE_LABELS[idx]


static func mass_interval_for_external(external_total: int) -> float:
	if external_total >= MASS_EXTERNAL_FASTER_AT:
		return MASS_INTERVAL_FASTER
	if external_total >= MASS_EXTERNAL_FAST_AT:
		return MASS_INTERVAL_FAST
	return MASS_INTERVAL_BASE


static func resolve_clone_appearance_id() -> StringName:
	if ResourceLoader.exists("res://data/content/appearances/appearance_male_first_clone.tres"):
		return CLONE_APPEARANCE
	return CLONE_APPEARANCE_FALLBACK
