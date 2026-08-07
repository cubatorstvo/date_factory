class_name PrimaryTraitEvaluator
extends RefCounted
## Pure Primary Trait reaction helper (MODULE 09).


static func evaluate(primary_trait: GameTypes.PrimaryGirlTrait, tags: Array[GameTypes.ActionTag]) -> int:
	if tags.size() > 2:
		push_error("[PrimaryTraitEvaluator] tags size > 2")
		return 0
	var db: Node = Engine.get_main_loop().root.get_node_or_null("/root/ContentDB")
	if db == null:
		push_error("[PrimaryTraitEvaluator] ContentDB missing")
		return 0
	var def: PrimaryTraitDefinition = db.call("get_primary_trait", primary_trait) as PrimaryTraitDefinition
	if def == null:
		return 0
	return evaluate_with_definition(def, tags)


static func evaluate_with_definition(def: PrimaryTraitDefinition, tags: Array[GameTypes.ActionTag]) -> int:
	if def == null:
		return 0
	if tags.size() > 2:
		push_error("[PrimaryTraitEvaluator] tags size > 2")
		return 0
	var has_liked: bool = false
	var has_disliked: bool = false
	for tag in tags:
		if def.liked_tags.has(tag):
			has_liked = true
		if def.disliked_tags.has(tag):
			has_disliked = true
	if has_liked and not has_disliked:
		return 1
	if (not has_liked) and has_disliked:
		return -1
	return 0
