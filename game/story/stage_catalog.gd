class_name StageCatalog
extends Resource

@export var stages: Array[StageDefinition] = []


func get_stage(stage: int) -> StageDefinition:
	for definition in stages:
		if definition != null and definition.stage == stage:
			return definition
	return null


func get_all_stages() -> Array[StageDefinition]:
	var result: Array[StageDefinition] = []
	for definition in stages:
		if definition != null:
			result.append(definition)
	return result


static func create_seed(girl_catalog: GirlCatalog = null) -> StageCatalog:
	var girls: GirlCatalog = girl_catalog
	if girls == null:
		girls = GirlCatalog.create_seed()
	var catalog: StageCatalog = StageCatalog.new()
	var empty_effects: Array[StageEnterEffect] = []
	catalog.stages.append(_make_stage(1, "Stage 1", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_ACTRESS)), empty_effects, "Актриса", "Добейся внимания Актрисы. Для знакомства понадобится достаточный Рейтинг, а её нынешний ухажёр уступать место не собирается."))
	catalog.stages.append(_make_stage(2, "Stage 2", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_MINE_BOSS)), make_stage_2_enter_effects(), "Начальница шахты", "Добейся расположения Начальницы шахты. Сначала докажи свой уровень, затем разберись с её нынешним ухажёром."))
	catalog.stages.append(_make_stage(3, "Stage 3", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_MAGAZINE_EDITOR)), make_stage_3_enter_effects(), "Редактор журнала", "Заинтересуй Редактора журнала. Твой Рейтинг должен соответствовать её кругу, а рядом уже есть конкурент."))
	catalog.stages.append(_make_stage(4, "Stage 4", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_SCIENTIST)), make_stage_4_enter_effects(), "Учёная", "Добейся Учёной. Для знакомства понадобится высокий Рейтинг, а её нынешний соперник уже считает эту гонку своей."))
	catalog.stages.append(_make_stage(5, "Stage 5", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_PRESIDENT)), make_stage_5_enter_effects(), "Президент", "Добейся Президента. Сначала достигни нужного Рейтинга, затем реши вопрос с человеком, который уже занимает место рядом с ней."))
	catalog.stages.append(_make_stage(6, "Stage 6", WorldReachRequirement.new(), empty_effects, "Date Factory", "Расширь Date Factory до мирового масштаба и доведи охват Мира до 100%."))
	return catalog


static func make_stage_2_enter_effects() -> Array[StageEnterEffect]:
	var effects: Array[StageEnterEffect] = []
	var city_stage_2: SetCityStageStageEffect = SetCityStageStageEffect.new()
	city_stage_2.city_stage = 2
	effects.append(city_stage_2)
	var unlock_restaurant: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
	unlock_restaurant.location_id = LocationCatalog.ID_RESTAURANT
	effects.append(unlock_restaurant)
	var unlock_leisure: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
	unlock_leisure.location_id = LocationCatalog.ID_LEISURE_CENTER
	effects.append(unlock_leisure)
	var unlock_furniture: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
	unlock_furniture.location_id = LocationCatalog.ID_FURNITURE_STORE
	effects.append(unlock_furniture)
	var unlock_clothing: UnlockLocationStageEffect = UnlockLocationStageEffect.new()
	unlock_clothing.location_id = LocationCatalog.ID_CLOTHING_STORE
	effects.append(unlock_clothing)
	var unlock_cafe_venue: UnlockDateVenueStageEffect = UnlockDateVenueStageEffect.new()
	unlock_cafe_venue.date_venue_id = &"cafe"
	effects.append(unlock_cafe_venue)
	var unlock_leisure_venue: UnlockDateVenueStageEffect = UnlockDateVenueStageEffect.new()
	unlock_leisure_venue.date_venue_id = &"leisure_center"
	effects.append(unlock_leisure_venue)
	return effects


static func make_stage_3_enter_effects() -> Array[StageEnterEffect]:
	var effects: Array[StageEnterEffect] = []
	var unlock_restaurant_venue: UnlockDateVenueStageEffect = UnlockDateVenueStageEffect.new()
	unlock_restaurant_venue.date_venue_id = &"restaurant"
	effects.append(unlock_restaurant_venue)
	return effects


static func make_stage_4_enter_effects() -> Array[StageEnterEffect]:
	var effects: Array[StageEnterEffect] = []
	var city_stage_3: SetCityStageStageEffect = SetCityStageStageEffect.new()
	city_stage_3.city_stage = 3
	effects.append(city_stage_3)
	return effects

static func make_stage_5_enter_effects() -> Array[StageEnterEffect]:
	var effects: Array[StageEnterEffect] = []
	effects.append(UnlockAutomationStageEffect.new())
	effects.append(GrantInitialClonesStageEffect.new())
	return effects


func apply_canonical_enter_effects() -> void:
	for definition in stages:
		if definition == null:
			continue
		definition.on_enter_effects.clear()
		if definition.stage == 2:
			definition.on_enter_effects = make_stage_2_enter_effects()
		elif definition.stage == 3:
			definition.on_enter_effects = make_stage_3_enter_effects()
		elif definition.stage == 4:
			definition.on_enter_effects = make_stage_4_enter_effects()
		elif definition.stage == 5:
			definition.on_enter_effects = make_stage_5_enter_effects()

static func make_girl_relationship_requirement(definition: GirlDefinition) -> GirlRelationshipRequirement:
	var requirement: GirlRelationshipRequirement = GirlRelationshipRequirement.new()
	if definition == null:
		return requirement
	requirement.girl_id = definition.id
	requirement.target_relationship = definition.relationship_max
	return requirement


static func _make_stage(
	stage: int,
	display_name: String,
	completion_requirement: StageRequirement,
	on_enter_effects: Array[StageEnterEffect],
	objective_title: String = "",
	objective_description: String = ""
) -> StageDefinition:
	var definition: StageDefinition = StageDefinition.new()
	definition.stage = stage
	definition.display_name = display_name
	definition.objective_title = objective_title
	definition.objective_description = objective_description
	definition.completion_requirement = completion_requirement
	definition.on_enter_effects = on_enter_effects.duplicate()
	return definition
