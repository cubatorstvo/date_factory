class_name SecondaryTraitEvaluator
extends RefCounted
## Pure Secondary Trait evaluation over 4 decision records (MODULE 09).


static func evaluate(
	secondary_trait: GameTypes.SecondaryGirlTrait,
	records: Array[DatingDecisionRecord],
) -> int:
	if records.size() != 4:
		push_error("[SecondaryTraitEvaluator] expected 4 records, got %s" % records.size())
		return 0
	match secondary_trait:
		GameTypes.SecondaryGirlTrait.SCANDALOUS:
			return _scandalous(records)
		GameTypes.SecondaryGirlTrait.CONSISTENT:
			return _consistent(records)
		GameTypes.SecondaryGirlTrait.VARIETY_SEEKING:
			return _variety(records)
		GameTypes.SecondaryGirlTrait.DEMANDING:
			return _demanding(records)
	return 0


static func _scandalous(records: Array[DatingDecisionRecord]) -> int:
	var any_public_conflict: bool = false
	var all_private: bool = true
	for rec in records:
		if rec.was_public:
			all_private = false
			if rec.final_tags.has(GameTypes.ActionTag.CONFLICT):
				any_public_conflict = true
	if any_public_conflict:
		return 1
	if all_private:
		return -1
	return 0


static func _consistent(records: Array[DatingDecisionRecord]) -> int:
	var counts: Dictionary = {}
	for rec in records:
		var key: int = int(rec.characteristic)
		counts[key] = int(counts.get(key, 0)) + 1
	for key in counts.keys():
		if int(counts[key]) >= 3:
			return 1
	if counts.size() == 4:
		return -1
	return 0


static func _variety(records: Array[DatingDecisionRecord]) -> int:
	var counts: Dictionary = {}
	for rec in records:
		var key: int = int(rec.characteristic)
		counts[key] = int(counts.get(key, 0)) + 1
	if counts.size() >= 3:
		return 1
	for key in counts.keys():
		if int(counts[key]) >= 3:
			return -1
	return 0


static func _demanding(records: Array[DatingDecisionRecord]) -> int:
	var pos: int = 0
	var neg: int = 0
	for rec in records:
		if rec.primary_reaction > 0:
			pos += 1
		elif rec.primary_reaction < 0:
			neg += 1
	if neg == 0 and pos >= 2:
		return 1
	if neg >= 2:
		return -1
	return 0
