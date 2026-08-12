class_name StoryIds
extends RefCounted
## Canonical reserved story girl/rival IDs and story flags (MODULE 11).
## Values must match ContentDB.RESERVED_STORY_* / stage catalog exactly.


const GIRL_NEIGHBOR: StringName = &"girl_neighbor"
const GIRL_ACTRESS: StringName = &"girl_actress"
const GIRL_MINE_BOSS: StringName = &"girl_mine_boss"
const GIRL_MAGAZINE_EDITOR: StringName = &"girl_magazine_editor"
const GIRL_SCIENTIST: StringName = &"girl_scientist"
const GIRL_PRESIDENT: StringName = &"girl_president"
const GIRL_FINAL_TARGET: StringName = &"girl_final_target"

const RIVAL_ACTRESS: StringName = &"rival_actress"
const RIVAL_MINE_BOSS: StringName = &"rival_mine_boss"
const RIVAL_MAGAZINE_EDITOR: StringName = &"rival_magazine_editor"
const RIVAL_SCIENTIST: StringName = &"rival_scientist"
const RIVAL_PRESIDENT: StringName = &"rival_president"

const FLAG_HEART_CARD_CLAIMED: StringName = &"prologue_heart_card_claimed"
const FLAG_HUD_AUTHORITY_REVEALED: StringName = &"hud_authority_revealed"
const FLAG_HUD_POINTS_REVEALED: StringName = &"hud_points_revealed"
const FLAG_NEIGHBOR_BRIEFING_COMPLETE: StringName = &"prologue_neighbor_briefing_complete"
const FLAG_TUTORIAL_FOOD_READY: StringName = &"prologue_tutorial_food_ready"
const FLAG_TUTORIAL_DRINK_READY: StringName = &"prologue_tutorial_drink_ready"
const FLAG_TUTORIAL_OUTFIT_READY: StringName = &"prologue_tutorial_outfit_ready"
const FLAG_TUTORIAL_DATE_COMPLETE: StringName = &"prologue_tutorial_date_complete"
const FLAG_TUTORIAL_UPGRADE_POINT: StringName = &"prologue_tutorial_upgrade_point"
const FLAG_TUTORIAL_UPGRADE_AWAITING_RECLAIM: StringName = &"prologue_tutorial_upgrade_awaiting_reclaim"
const FLAG_TUTORIAL_UPGRADE_JOKE_DONE: StringName = &"prologue_tutorial_upgrade_joke_done"
const FLAG_WORLD_EXPANSION_COMPLETE: StringName = &"story_world_expansion_complete"


static func all_story_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = [
		GIRL_NEIGHBOR,
		GIRL_ACTRESS,
		GIRL_MINE_BOSS,
		GIRL_MAGAZINE_EDITOR,
		GIRL_SCIENTIST,
		GIRL_PRESIDENT,
		GIRL_FINAL_TARGET,
	]
	return out


static func all_story_rival_ids() -> Array[StringName]:
	var out: Array[StringName] = [
		RIVAL_ACTRESS,
		RIVAL_MINE_BOSS,
		RIVAL_MAGAZINE_EDITOR,
		RIVAL_SCIENTIST,
		RIVAL_PRESIDENT,
	]
	return out


static func is_story_girl(girl_id: StringName) -> bool:
	if String(girl_id) == "":
		return false
	return all_story_girl_ids().has(girl_id)


static func is_story_rival(rival_id: StringName) -> bool:
	if String(rival_id) == "":
		return false
	return all_story_rival_ids().has(rival_id)
