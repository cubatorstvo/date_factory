class_name AudioIds
## Semantic sound / music IDs for MODULE 23 (presentation only).
## Gameplay code should call AudioDirector with these IDs — never raw paths.


# --- Music states ---
const MUSIC_MANUAL: StringName = &"MANUAL"
const MUSIC_MEDIA: StringName = &"MEDIA"
const MUSIC_CLONE: StringName = &"CLONE"
const MUSIC_FINAL: StringName = &"FINAL"


# --- UI ---
const UI_CLICK: StringName = &"ui_click"
const UI_BACK: StringName = &"ui_back"
const UI_DENIED: StringName = &"ui_denied"
const UI_PURCHASE: StringName = &"ui_purchase"


# --- Rewards / story beats ---
const REWARD_SMALL: StringName = &"reward_small"
const REWARD_MAJOR: StringName = &"reward_major"
const STAGE_ADVANCE: StringName = &"stage_advance"
const RELATIONSHIP_POSITIVE: StringName = &"relationship_positive"
const RELATIONSHIP_NEUTRAL: StringName = &"relationship_neutral"
const RELATIONSHIP_NEGATIVE: StringName = &"relationship_negative"
const RIVAL_WIN: StringName = &"rival_win"
const RIVAL_LOSS: StringName = &"rival_loss"
const CAMERA_SHUTTER: StringName = &"camera_shutter"
const CLONE_COMPLETE: StringName = &"clone_complete"
const REACH_MILESTONE: StringName = &"reach_milestone"
const FINAL_SIGNAL: StringName = &"final_signal"


# --- Minigame: slap ---
const SLAP_HIT: StringName = &"slap_hit"
const SLAP_PERFECT: StringName = &"slap_perfect"
const SLAP_BLOCK: StringName = &"slap_block"
const SLAP_PERFECT_BLOCK: StringName = &"slap_perfect_block"
const SLAP_MISS: StringName = &"slap_miss"


# --- Minigame: dance ---
const DANCE_PROMPT: StringName = &"dance_prompt"
const DANCE_CORRECT: StringName = &"dance_correct"
const DANCE_WRONG: StringName = &"dance_wrong"
const DANCE_SEQUENCE_SUCCESS: StringName = &"dance_sequence_success"


# --- Minigame: sigma ---
const SIGMA_ZONE_ENTER: StringName = &"sigma_zone_enter"
const SIGMA_DISTURBANCE: StringName = &"sigma_disturbance"
const SIGMA_SUCCESS: StringName = &"sigma_success"


# --- Minigame: money ---
const MONEY_STAKE_RAISE: StringName = &"money_stake_raise"
const MONEY_SPENT: StringName = &"money_spent"
const MONEY_RIVAL_RAISE: StringName = &"money_rival_raise"
const MONEY_WIN: StringName = &"money_win"
const MONEY_LOSS: StringName = &"money_loss"


# --- Salary / media / clone / late / final ---
const SALARY_HOLD_START: StringName = &"salary_hold_start"
const SALARY_PAYOUT: StringName = &"salary_payout"
const MEDIA_POSE_CONFIRM: StringName = &"media_pose_confirm"
const MEDIA_PUBLISH: StringName = &"media_publish"
const MEDIA_INCOMING: StringName = &"media_incoming"
const MEDIA_FEED_BOOST: StringName = &"media_feed_boost"
const CLONE_CALIBRATE_ACCEPT: StringName = &"clone_calibrate_accept"
const CLONE_CALIBRATE_REJECT: StringName = &"clone_calibrate_reject"
const CLONE_MACHINE_CHARGE: StringName = &"clone_machine_charge"
const CLONE_ASSIGN: StringName = &"clone_assign"
const LATE_UPGRADE: StringName = &"late_upgrade"
const LATE_MANUAL_EVENT: StringName = &"late_manual_event"
const FINAL_ZONE_GATE: StringName = &"final_zone_gate"
const FINAL_ALIEN_ENTRANCE: StringName = &"final_alien_entrance"
const FINAL_FAILURE: StringName = &"final_failure"
const FINAL_ENDING: StringName = &"final_ending"


## Music state → loop path. Missing files are registered but skipped safely at play time.
static func music_paths() -> Dictionary:
	return {
		MUSIC_MANUAL: "res://assets/audio/music/manual_apartment_chill.ogg",
		MUSIC_MEDIA: "res://assets/audio/music/media_street_night.ogg",
		MUSIC_CLONE: "res://assets/audio/music/clone_restaurant_warm.ogg",
		MUSIC_FINAL: "res://assets/audio/music/final_sparse.wav",
	}


## Semantic one-shot ID → path. Prefer real assets when present.
static func sfx_paths() -> Dictionary:
	return {
		UI_CLICK: "res://assets/audio/sfx/ui/click.ogg",
		UI_BACK: "res://assets/audio/sfx/ui/back.ogg",
		UI_DENIED: "res://assets/audio/sfx/ui/error.ogg",
		UI_PURCHASE: "res://assets/audio/sfx/ui/confirm.ogg",
		REWARD_SMALL: "res://assets/audio/sfx/ui/tick.ogg",
		REWARD_MAJOR: "res://assets/audio/sfx/world/event_chime.ogg",
		STAGE_ADVANCE: "res://assets/audio/sfx/world/event_chime.ogg",
		RELATIONSHIP_POSITIVE: "res://assets/audio/sfx/impact/result_success.ogg",
		RELATIONSHIP_NEUTRAL: "res://assets/audio/sfx/ui/toggle.ogg",
		RELATIONSHIP_NEGATIVE: "res://assets/audio/sfx/impact/result_fail.ogg",
		RIVAL_WIN: "res://assets/audio/sfx/impact/result_success.ogg",
		RIVAL_LOSS: "res://assets/audio/sfx/impact/result_fail.ogg",
		CAMERA_SHUTTER: "res://assets/audio/sfx/ui/click.ogg",
		CLONE_COMPLETE: "res://assets/audio/sfx/world/event_chime.ogg",
		REACH_MILESTONE: "res://assets/audio/sfx/world/event_chime.ogg",
		FINAL_SIGNAL: "res://assets/audio/sfx/world/event_chime.ogg",
		SLAP_HIT: "res://assets/audio/sfx/impact/soft_impact.ogg",
		SLAP_PERFECT: "res://assets/audio/sfx/impact/result_success.ogg",
		SLAP_BLOCK: "res://assets/audio/sfx/impact/soft_impact.ogg",
		SLAP_PERFECT_BLOCK: "res://assets/audio/sfx/impact/result_success.ogg",
		SLAP_MISS: "res://assets/audio/sfx/impact/soft_impact.ogg",
		DANCE_PROMPT: "res://assets/audio/sfx/ui/tick.ogg",
		DANCE_CORRECT: "res://assets/audio/sfx/steps/step_1.ogg",
		DANCE_WRONG: "res://assets/audio/sfx/ui/error.ogg",
		DANCE_SEQUENCE_SUCCESS: "res://assets/audio/sfx/impact/result_success.ogg",
		SIGMA_ZONE_ENTER: "res://assets/audio/sfx/ui/toggle.ogg",
		SIGMA_DISTURBANCE: "res://assets/audio/sfx/ui/open.ogg",
		SIGMA_SUCCESS: "res://assets/audio/sfx/impact/result_success.ogg",
		MONEY_STAKE_RAISE: "res://assets/audio/sfx/ui/tick.ogg",
		MONEY_SPENT: "res://assets/audio/sfx/ui/confirm.ogg",
		MONEY_RIVAL_RAISE: "res://assets/audio/sfx/ui/toggle.ogg",
		MONEY_WIN: "res://assets/audio/sfx/impact/result_success.ogg",
		MONEY_LOSS: "res://assets/audio/sfx/impact/result_fail.ogg",
		SALARY_HOLD_START: "res://assets/audio/sfx/ui/open.ogg",
		SALARY_PAYOUT: "res://assets/audio/sfx/ui/confirm.ogg",
		MEDIA_POSE_CONFIRM: "res://assets/audio/sfx/ui/confirm.ogg",
		MEDIA_PUBLISH: "res://assets/audio/sfx/world/event_chime.ogg",
		MEDIA_INCOMING: "res://assets/audio/sfx/ui/open.ogg",
		MEDIA_FEED_BOOST: "res://assets/audio/sfx/ui/tick.ogg",
		CLONE_CALIBRATE_ACCEPT: "res://assets/audio/sfx/ui/confirm.ogg",
		CLONE_CALIBRATE_REJECT: "res://assets/audio/sfx/ui/error.ogg",
		CLONE_MACHINE_CHARGE: "res://assets/audio/sfx/ui/open.ogg",
		CLONE_ASSIGN: "res://assets/audio/sfx/ui/confirm.ogg",
		LATE_UPGRADE: "res://assets/audio/sfx/world/event_chime.ogg",
		LATE_MANUAL_EVENT: "res://assets/audio/sfx/world/event_chime.ogg",
		FINAL_ZONE_GATE: "res://assets/audio/sfx/world/door_open.ogg",
		FINAL_ALIEN_ENTRANCE: "res://assets/audio/sfx/world/event_chime.ogg",
		FINAL_FAILURE: "res://assets/audio/sfx/impact/result_fail.ogg",
		FINAL_ENDING: "res://assets/audio/sfx/world/event_chime.ogg",
	}


## IDs that may use a tiny procedural WAV if the mapped file is not yet imported.
static func critical_oneshot_ids() -> Array[StringName]:
	return [
		UI_CLICK,
		UI_BACK,
		UI_DENIED,
		UI_PURCHASE,
		SLAP_MISS,
	]


## Game stage → music state (MODULE 23 §7).
static func music_state_for_stage(stage: int) -> StringName:
	match stage:
		GameTypes.GameStage.PROLOGUE, GameTypes.GameStage.STAGE_1, GameTypes.GameStage.STAGE_2, GameTypes.GameStage.STAGE_3:
			return MUSIC_MANUAL
		GameTypes.GameStage.STAGE_4:
			return MUSIC_MEDIA
		GameTypes.GameStage.STAGE_5, GameTypes.GameStage.STAGE_6:
			return MUSIC_CLONE
		GameTypes.GameStage.FINALE:
			return MUSIC_FINAL
		_:
			return MUSIC_MANUAL
