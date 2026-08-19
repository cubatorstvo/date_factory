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
	catalog.stages.append(_make_stage(1, "Stage 1", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_ACTRESS)), empty_effects))
	catalog.stages.append(_make_stage(2, "Stage 2", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_MINE_BOSS)), empty_effects))
	catalog.stages.append(_make_stage(3, "Stage 3", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_MAGAZINE_EDITOR)), empty_effects))
	catalog.stages.append(_make_stage(4, "Stage 4", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_SCIENTIST)), empty_effects))
	catalog.stages.append(_make_stage(5, "Stage 5", make_girl_relationship_requirement(girls.get_girl(GirlCatalog.ID_PRESIDENT)), empty_effects))
	catalog.stages.append(_make_stage(6, "Stage 6", null, empty_effects))
	return catalog


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
	on_enter_effects: Array[StageEnterEffect]
) -> StageDefinition:
	var definition: StageDefinition = StageDefinition.new()
	definition.stage = stage
	definition.display_name = display_name
	definition.completion_requirement = completion_requirement
	definition.on_enter_effects = on_enter_effects.duplicate()
	return definition
