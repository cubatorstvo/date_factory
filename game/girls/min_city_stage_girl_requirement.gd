class_name MinCityStageGirlRequirement
extends GirlAccessRequirement

@export var minimum_city_stage: int = 1


func is_met(_girl_id: StringName) -> bool:
	return CityProgressionService.get_city_stage() >= minimum_city_stage


func get_description(_girl_id: StringName) -> String:
	return "Этап города"


func get_progress_text(_girl_id: StringName) -> String:
	return "%d / %d" % [CityProgressionService.get_city_stage(), minimum_city_stage]
