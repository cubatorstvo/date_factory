extends Node

signal objective_changed

var _current: ObjectiveView = ObjectiveView.new()


func _ready() -> void:
	_connect_sources()
	rebuild()


func get_current() -> ObjectiveView:
	if _current == null:
		rebuild()
	return _current


func rebuild() -> void:
	_current = _build_view()
	objective_changed.emit()


func marker_suffix(target_type: StringName, target_id: StringName = &"", location_id: StringName = &"") -> String:
	var view: ObjectiveView = get_current()
	if view == null or view.completed:
		return ""
	if location_id != &"" and view.target_location_id == location_id:
		return ObjectiveView.MARKER_SUFFIX
	if target_type == ObjectiveView.TARGET_FACTORY and view.target_type == ObjectiveView.TARGET_FACTORY:
		return ObjectiveView.MARKER_SUFFIX
	if target_type != &"" and view.target_type == target_type and view.target_id == target_id:
		return ObjectiveView.MARKER_SUFFIX
	return ""

func _connect_sources() -> void:
	var stages: Variant = _stage_service()
	if stages != null:
		_connect_signal(stages, "stage_changed", _on_source_changed)
		_connect_signal(stages, "stage_progress_changed", _on_source_changed)
	var girls: Variant = _girls_service()
	if girls != null:
		_connect_signal(girls, "girl_discovered", _on_source_changed)
		_connect_signal(girls, "girl_relationship_changed", _on_source_changed)
		_connect_signal(girls, "girl_access_changed", _on_source_changed)
	var rivals: Variant = _rivals_service()
	if rivals != null:
		_connect_signal(rivals, "rival_defeated", _on_source_changed)
	var rating: Variant = _rating_service()
	if rating != null:
		_connect_signal(rating, "rating_changed", _on_source_changed)
	var automation: Variant = _automation_service()
	if automation != null:
		_connect_signal(automation, "expansion_changed", _on_source_changed)
		_connect_signal(automation, "automation_unlocked", _on_source_changed)
	var clock: Variant = _time_service()
	if clock != null:
		_connect_signal(clock, "time_advanced", _on_source_changed)
	var equipment: Variant = _equipment_service()
	if equipment != null:
		_connect_signal(equipment, "outfit_equipped", _on_source_changed)
		_connect_signal(equipment, "outfit_owned", _on_source_changed)


func _connect_signal(host: Variant, signal_name: String, callback: Callable) -> void:
	if host.has_signal(signal_name) and not host.is_connected(signal_name, callback):
		host.connect(signal_name, callback)


func _on_source_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
	rebuild()


func _build_view() -> ObjectiveView:
	var view: ObjectiveView = ObjectiveView.new()
	var stages: Variant = _stage_service()
	if stages == null:
		return view
	var definition: StageDefinition = stages.get_current_definition() as StageDefinition
	if definition == null:
		return view
	view.stage = int(stages.get_current_stage())
	view.title = definition.objective_title if not definition.objective_title.is_empty() else definition.display_name
	view.description = definition.objective_description
	if bool(stages.is_finale_reached()):
		view.completed = true
		view.progress_text = "100%"
		return view
	if view.stage == 2 and not _owns_dressed_outfit():
		_fill_dress_up_current(view)
		return view
	var requirement: StageRequirement = stages.get_current_requirement() as StageRequirement
	if requirement is GirlRelationshipRequirement:
		_fill_story_girl(view, requirement as GirlRelationshipRequirement)
	elif requirement is WorldReachRequirement:
		_fill_factory(view)
	_mark_current(view)
	return view

func _fill_story_girl(view: ObjectiveView, requirement: GirlRelationshipRequirement) -> void:
	var girls: Variant = _girls_service()
	if girls == null:
		return
	var girl_id: StringName = requirement.girl_id
	var girl: GirlDefinition = girls.get_definition(girl_id) as GirlDefinition
	if girl == null:
		return
	var girl_name: String = girl.display_name
	var discovered: bool = bool(girls.is_discovered(girl_id))
	var filler_met: bool = true
	var rating_met: bool = true
	var has_filler_gate: bool = false
	for meet_requirement in girl.meet_requirements:
		if meet_requirement is MinStoryStageGirlRequirement:
			continue
		if meet_requirement is MinCityStageGirlRequirement:
			continue
		var meet_list: Array[GirlAccessRequirement] = []
		meet_list.append(meet_requirement)
		var statuses: Array[RequirementStatus] = girls.build_requirement_status_list(girl_id, meet_list)
		if statuses.is_empty():
			continue
		var status: RequirementStatus = statuses[0]
		var subgoal: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
		subgoal.id = &"meet_%s" % String(meet_requirement.get_script().resource_path.get_file().get_basename()) if meet_requirement.get_script() != null else &"meet_requirement"
		if meet_requirement != null and meet_requirement.get_script() != null and String(meet_requirement.get_script().resource_path).ends_with("current_stage_filler_max_girl_requirement.gd"):
			subgoal.id = &"meet_filler_max"
			subgoal.label = "Девушки этапа"
			filler_met = status.is_met
			has_filler_gate = true
		elif meet_requirement is RatingGirlRequirement:
			subgoal.id = &"meet_rating"
			subgoal.label = "Рейтинг для знакомства"
			rating_met = status.is_met
		else:
			subgoal.label = status.description
		subgoal.progress_text = status.progress_text
		subgoal.completed = status.is_met
		view.subgoals.append(subgoal)
	var meet_subgoal: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
	meet_subgoal.id = &"meet_girl"
	meet_subgoal.label = "Познакомиться с %s" % girl_name
	meet_subgoal.completed = discovered
	meet_subgoal.target_type = ObjectiveView.TARGET_GIRL
	meet_subgoal.target_id = girl_id
	meet_subgoal.target_location_id = girl.location_id
	view.subgoals.append(meet_subgoal)
	var rival_defeated: bool = true
	var rival_display_name: String = ""
	for date_requirement in girl.date_requirements:
		if not (date_requirement is RivalDefeatedGirlRequirement):
			continue
		var rival_requirement: RivalDefeatedGirlRequirement = date_requirement as RivalDefeatedGirlRequirement
		var date_list: Array[GirlAccessRequirement] = []
		date_list.append(date_requirement)
		var statuses: Array[RequirementStatus] = girls.build_requirement_status_list(girl_id, date_list)
		var status: RequirementStatus = statuses[0] if not statuses.is_empty() else RequirementStatus.new()
		var rival_subgoal: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
		rival_subgoal.id = StringName("date_rival_%s" % String(rival_requirement.rival_id))
		rival_subgoal.label = status.description if not status.description.is_empty() else "Победить соперника"
		rival_subgoal.completed = status.is_met
		rival_subgoal.target_type = ObjectiveView.TARGET_RIVAL
		rival_subgoal.target_id = rival_requirement.rival_id
		rival_defeated = status.is_met
		var rivals: Variant = _rivals_service()
		if rivals != null:
			var rival: RivalDefinition = rivals.get_definition(rival_requirement.rival_id) as RivalDefinition
			if rival != null:
				rival_subgoal.target_location_id = rival.location_id
				rival_display_name = rival.display_name
		view.subgoals.append(rival_subgoal)
	var relationship: int = int(girls.get_relationship(girl_id))
	var relationship_max: int = int(girls.get_relationship_max(girl_id))
	var relationship_subgoal: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
	relationship_subgoal.id = &"relationship"
	relationship_subgoal.label = "Отношения с %s" % girl_name
	relationship_subgoal.progress_text = "%d / %d" % [relationship, relationship_max]
	relationship_subgoal.completed = relationship >= relationship_max and relationship_max > 0
	relationship_subgoal.target_type = ObjectiveView.TARGET_DATING
	relationship_subgoal.target_id = girl_id
	view.subgoals.append(relationship_subgoal)
	view.progress_text = relationship_subgoal.progress_text
	if has_filler_gate:
		_apply_story_girl_phase_copy(view, girl_name, discovered, filler_met, rating_met, rival_defeated, rival_display_name, relationship, relationship_max)


func _apply_story_girl_phase_copy(
	view: ObjectiveView,
	girl_name: String,
	discovered: bool,
	filler_met: bool,
	rating_met: bool,
	rival_defeated: bool,
	rival_display_name: String,
	relationship: int,
	relationship_max: int
) -> void:
	if not filler_met or not rating_met:
		view.title = "Повышай Рейтинг"
		view.description = "Заверши отношения с любыми 2 из 3 девушек этого этапа."
		return
	if not discovered:
		view.title = "Познакомься с %s." % girl_name
		view.description = ""
		return
	if not rival_defeated:
		var rival_name: String = rival_display_name if not rival_display_name.is_empty() else "соперника"
		view.title = "Победи %s." % rival_name
		view.description = ""
		return
	view.title = "Отношения с %s: %d / %d" % [girl_name, relationship, relationship_max]
	view.description = "Доведи отношения с %s до MAX." % girl_name

func _fill_dress_up_current(view: ObjectiveView) -> void:
	view.title = "Приоденься"
	view.description = "Купи любой образ выше «Повседневного» в магазине одежды."
	view.next_step_text = "Марина работает в магазине одежды. Хорошие отношения с ней могут оказаться полезны."
	view.target_type = ObjectiveView.TARGET_LOCATION
	view.target_location_id = LocationCatalog.ID_CLOTHING_STORE
	view.completed = false


func _owns_dressed_outfit() -> bool:
	var equipment: Variant = _equipment_service()
	return equipment != null and bool(equipment.owns_dressed_outfit())

func _fill_factory(view: ObjectiveView) -> void:
	var automation: Variant = _automation_service()
	if automation == null:
		return
	var scope: StringName = automation.get_current_expansion_scope()
	var progress: int = int(automation.get_expansion_progress())
	var required: int = int(automation.get_required_expansion_progress())
	var complete: bool = bool(automation.is_current_expansion_complete())
	var next_scope: StringName = automation.get_next_expansion_scope()
	if scope != &"city":
		var city_done: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
		city_done.id = &"factory_scope_city"
		city_done.label = "Масштаб: Город"
		city_done.completed = true
		view.subgoals.append(city_done)
	if scope == &"world":
		var country_done: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
		country_done.id = &"factory_scope_country"
		country_done.label = "Масштаб: Страна"
		country_done.completed = true
		view.subgoals.append(country_done)
	var reach: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
	reach.id = &"factory_reach"
	reach.target_type = ObjectiveView.TARGET_FACTORY
	reach.target_id = scope
	reach.label = _factory_reach_label(scope)
	if scope == &"world" and complete:
		reach.progress_text = "100%"
	else:
		reach.progress_text = "%d / %d" % [progress, required]
	reach.completed = complete
	view.subgoals.append(reach)
	if complete and next_scope != &"":
		var expand: ObjectiveSubgoalView = ObjectiveSubgoalView.new()
		expand.id = &"factory_expand"
		expand.label = _factory_expand_label(next_scope)
		expand.progress_text = _format_grouped_int(int(automation.get_expansion_cost(next_scope)))
		expand.completed = false
		expand.target_type = ObjectiveView.TARGET_FACTORY
		expand.target_id = next_scope
		view.subgoals.append(expand)
	view.completed = complete and next_scope == &""
	view.progress_text = reach.progress_text

func _factory_reach_label(scope: StringName) -> String:
	match scope:
		&"city":
			return "Охват города"
		&"country":
			return "Охват страны"
		&"world":
			return "Охват мира"
		_:
			return "Охват"


func _factory_expand_label(next_scope: StringName) -> String:
	match next_scope:
		&"country":
			return "Расширить до масштабов страны"
		&"world":
			return "Расширить до масштабов мира"
		_:
			return "Расширить"

func _mark_current(view: ObjectiveView) -> void:
	var current: ObjectiveSubgoalView = null
	for subgoal in view.subgoals:
		subgoal.is_current = false
		if current == null and not subgoal.completed:
			current = subgoal
	if current != null:
		current.is_current = true
		view.target_type = current.target_type
		view.target_id = current.target_id
		view.target_location_id = current.target_location_id
		view.next_step_text = _next_step_text(current)
		view.completed = false
	elif not view.subgoals.is_empty():
		view.completed = true
		var last: ObjectiveSubgoalView = view.subgoals[view.subgoals.size() - 1]
		view.progress_text = last.progress_text


func _next_step_text(subgoal: ObjectiveSubgoalView) -> String:
	if subgoal.id == &"relationship":
		return _relationship_next_step(subgoal)
	if subgoal.progress_text.is_empty():
		return "Следующий шаг: %s" % subgoal.label
	return "Следующий шаг: %s — %s" % [subgoal.label, subgoal.progress_text]


func _relationship_next_step(subgoal: ObjectiveSubgoalView) -> String:
	var girl_id: StringName = subgoal.target_id
	var girls: Variant = _girls_service()
	var dating: Variant = _dating_service()
	var girl_name: String = subgoal.label.replace("Отношения с ", "")
	if girls != null:
		var girl: GirlDefinition = girls.get_definition(girl_id) as GirlDefinition
		if girl != null:
			girl_name = girl.display_name
	var remaining: int = 0
	if dating != null:
		remaining = int(dating.get_date_cooldown_remaining_minutes(girl_id))
	if remaining > 0:
		return "Сегодня уже встречались. Следующая встреча: завтра."
	return "Следующий шаг: Пригласить %s на свидание" % _accusative_name(girl_name)


func _accusative_name(display_name: String) -> String:
	if display_name.ends_with("а") and display_name != "Актриса":
		return display_name
	if display_name == "Актриса":
		return "Актрису"
	if display_name == "Начальница шахты":
		return "Начальницу шахты"
	if display_name == "Учёная":
		return "Учёную"
	return display_name


func _format_grouped_int(value: int) -> String:
	var digits: String = str(absi(value))
	var grouped: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			grouped = " " + grouped
		grouped = digits.substr(i, 1) + grouped
		count += 1
	if value < 0:
		return "-" + grouped
	return grouped


func _stage_service() -> Variant:
	return _tree_node("StageService")


func _girls_service() -> Variant:
	return _tree_node("GirlsService")


func _rivals_service() -> Variant:
	return _tree_node("RivalsService")


func _rating_service() -> Variant:
	return _tree_node("RatingService")


func _automation_service() -> Variant:
	return _tree_node("AutomationService")


func _time_service() -> Variant:
	return _tree_node("TimeService")


func _dating_service() -> Variant:
	return _tree_node("DatingService")

func _equipment_service() -> Variant:
	return _tree_node("EquipmentService")


func _tree_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null(node_name)
	if not is_instance_valid(node):
		return null
	return node
