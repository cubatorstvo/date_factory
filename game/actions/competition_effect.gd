class_name CompetitionEffect
extends ActionEffect

@export var competition_id: StringName = &""

var _last_result: CompetitionResult


func apply() -> void:
	var competitions: Variant = _competition_service()
	if competitions == null:
		_last_result = null
		return
	var result: CompetitionResult = competitions.resolve_competition(competition_id)
	_last_result = result
	if result != null:
		competitions.complete_competition(result)


func get_description() -> String:
	if _last_result == null:
		return ""
	var display_name: String = String(_last_result.rival_id)
	var rivals: Variant = _rivals_service()
	if rivals != null:
		var definition: RivalDefinition = rivals.get_definition(_last_result.rival_id)
		if definition != null:
			display_name = definition.display_name
	if _last_result.won:
		var payout_text: String = ""
		var competitions: Variant = _competition_service()
		if competitions != null:
			var competition: CompetitionDefinition = competitions.get_catalog().get_competition(_last_result.competition_id)
			if competition != null:
				payout_text = "\nПолучено: %d." % (competition.entry_fee * 2)
		return "Победа.\n\nСоперник %s побеждён.%s" % [display_name, payout_text]
	return "Поражение.\n\n%s остаётся доступен для реванша." % display_name


func _competition_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("CompetitionService")
	if not is_instance_valid(node):
		return null
	return node


func _rivals_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("RivalsService")
	if not is_instance_valid(node):
		return null
	return node
