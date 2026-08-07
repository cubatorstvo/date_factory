extends Node
## MODULE 15 Media / Attention core self-test (spec §§101–142 subset).
## Run: res://game/media/test/media_test.tscn --quit-after 40000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _day: Node = null
var _media: Node = null
var _story: Node = null
var _gd: Node = null
var _content: Node = null
var _overload_count: int = 0
var _pass_labels: Array[String] = []


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_day = get_node("/root/GameDay")
	_media = get_node("/root/Media")
	_story = get_node("/root/Story")
	_gd = get_node("/root/GirlDiscovery")
	_content = get_node("/root/ContentDB")
	await get_tree().process_frame
	if _media.has_signal("overload_ready") and not _media.is_connected("overload_ready", _on_overload):
		_media.connect("overload_ready", _on_overload)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_15_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_15_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_15_TEST PASS: %s" % label)
	else:
		DfLog.error("MODULE_15_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_15_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_overload() -> void:
	_overload_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_15_TEST] FAIL: %s" % label)
		print("MODULE_15_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_overload_count = 0
	if _gd.has_method("clear_content_overrides"):
		_gd.call("clear_content_overrides")
	if _gd.has_method("force_clear_attempt"):
		_gd.call("force_clear_attempt")


func _unlock_stage4(appearance: int = 0, experience: int = 4) -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	if experience > 0:
		_gs.call("add_experience", experience)
	if appearance > 0:
		_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, appearance)


func _base_poses() -> Dictionary:
	return {
		MediaContent.PHOTO_PROFILE: &"pose_media_profile_normal",
		MediaContent.PHOTO_CHAIR: &"pose_media_chair_sit",
		MediaContent.PHOTO_COVER: &"pose_media_cover_stand",
	}


func _editorial_poses() -> Dictionary:
	return {
		MediaContent.PHOTO_PROFILE: &"pose_media_profile_wrong_target",
		MediaContent.PHOTO_CHAIR: &"pose_media_chair_argument",
		MediaContent.PHOTO_COVER: &"pose_media_cover_half_frame",
	}


func _complete_session(poses: Dictionary) -> bool:
	return bool(_media.call("complete_photo_session", poses))


func _run_all() -> void:
	_test_candidates_exist()
	_test_initial_stage4()
	_test_interactable_stage3()
	_test_interactable_stage4()
	await _test_shot_requirements()
	_test_no_hidden_stat_effect()
	await _test_abort_session()
	_test_complete_base_session()
	_test_first_incoming_at_article()
	_test_media_contact()
	_test_already_contacted_candidate()
	_test_conquered_candidate()
	_test_article_not_daily_quota()
	_test_publish_base_photo()
	_test_daily_limit()
	_test_next_day_no_attention_tick()
	_test_base_progression_thresholds()
	_test_editorial_progression()
	_test_threshold_jump_recovery()
	_test_fourth_offer()
	_test_max_attention()
	_test_publish_duplicate()
	_test_unknown_photo()
	_test_photo_before_session()
	_test_photo_value_from_stored_pose()
	_test_appearance_change_after_session()
	_test_incoming_priority()
	_test_required_experience_skip()
	_test_offer_read()
	_test_ignored_offer()
	_test_feed_order()
	_test_overload_ready_once()
	_test_no_story_advance()
	_test_no_scientist()
	_test_no_schedule_fields()
	await _test_no_attention_tick()
	_test_gameday_no_attention_tick()
	_test_no_reward_contamination()
	_test_session_idempotent()
	_test_locked_without_feature()
	_test_phone_media_section()
	_reset()

func _test_locked_without_feature() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	var pub: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(pub != null and pub.error == MediaTypes.PublishError.LOCKED, "15 LOCKED before MEDIA")
	_ok(not _complete_session(_base_poses()), "15 complete rejected stage3")


func _test_phone_media_section() -> void:
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	_ok(packed != null, "phone scene load")
	if packed == null:
		return
	var phone: PhoneJournal = packed.instantiate() as PhoneJournal
	_ok(phone != null, "phone instantiate")
	if phone == null:
		return
	add_child(phone)
	_reset()
	phone.open(null)
	_ok(not phone.has_media_section_visible(), "phone MEDIA hidden pre-unlock")
	_unlock_stage4()
	phone.refresh()
	_ok(phone.has_media_section_visible(), "phone MEDIA visible")
	_ok(phone.get_media_pre_session_text().contains("Фотосессия"), "phone pre-session hint")
	_ok(phone.get_story_text().contains("Фотосессия у Редактора"), "phone story handoff pre")
	_complete_session(_base_poses())
	phone.refresh()
	_ok(phone.get_media_attention_text().contains("15 / 100"), "phone Attention 15")
	_ok(phone.get_media_feed_text().contains("Редакция подтверждает"), "phone feed article")
	_ok(phone.get_story_text().contains("Публикуй фотографии"), "phone story handoff post")
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	phone.refresh()
	_ok(phone.get_story_text().contains("Спрос растёт быстрее обычного"), "phone story overload handoff")
	phone.close()
	phone.queue_free()


func _test_candidates_exist() -> void:
	_reset()
	for gid in [
		&"girl_appearance_flash",
		&"girl_public_sculpture",
		&"girl_cafe_receipt_notes",
		&"girl_gym_chalk",
	]:
		var def: GirlDefinition = _content.call("get_girl", gid) as GirlDefinition
		_ok(def != null and not def.is_story, "100 candidate %s" % String(gid))


func _test_initial_stage4() -> void:
	_unlock_stage4()
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "101 MEDIA_ATTENTION")
	_ok(not bool(_media.call("is_photo_session_completed")), "101 session false")
	_ok(int(_media.call("get_attention")) == 0, "101 Attention0")
	_ok((_media.call("get_feed_event_ids") as Array).is_empty(), "101 feed empty")
	_ok(int(_media.call("get_incoming_offer_count")) == 0, "101 offers empty")
	_ok(not bool(_media.call("is_feed_active")), "101 feed inactive")


func _test_interactable_stage3() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	var node: PhotoSessionInteractable = PhotoSessionInteractable.new()
	add_child(node)
	_ok(not bool(_media.call("is_photo_session_available")), "102 session unavailable stage3")
	_ok(node.get_interaction_prompt(null) == "", "102 prompt empty stage3")
	node.queue_free()


func _test_interactable_stage4() -> void:
	_unlock_stage4()
	var node: PhotoSessionInteractable = PhotoSessionInteractable.new()
	add_child(node)
	_ok(bool(_media.call("is_photo_session_available")), "103 available stage4")
	_ok(node.get_interaction_prompt(null) == "[E] Фотосессия у Редактора", "103 prompt")
	node.queue_free()


func _test_shot_requirements() -> void: # awaited from _run_all
	_unlock_stage4(0)
	var session: MediaPhotoSession = _media.call("start_photo_session", null) as MediaPhotoSession
	_ok(session != null, "104 session start")
	session.continue_session()
	var choices0: Array[Dictionary] = session.get_current_shot_pose_choices()
	_ok(choices0.size() == 3, "104 three choices")
	_ok(bool(choices0[0]["available"]) and not bool(choices0[1]["available"]) and not bool(choices0[2]["available"]), "104 appearance0 gates")
	session.abort_session()
	await get_tree().process_frame
	_unlock_stage4(1)
	session = _media.call("start_photo_session", null) as MediaPhotoSession
	session.continue_session()
	var choices1: Array[Dictionary] = session.get_current_shot_pose_choices()
	_ok(bool(choices1[0]["available"]) and bool(choices1[1]["available"]) and not bool(choices1[2]["available"]), "104 appearance1 gates")
	session.abort_session()
	await get_tree().process_frame
	_unlock_stage4(2)
	session = _media.call("start_photo_session", null) as MediaPhotoSession
	session.continue_session()
	var choices2: Array[Dictionary] = session.get_current_shot_pose_choices()
	_ok(bool(choices2[0]["available"]) and bool(choices2[1]["available"]) and bool(choices2[2]["available"]), "104 appearance2 all")
	session.abort_session()


func _test_no_hidden_stat_effect() -> void:
	_unlock_stage4(8)
	_ok(_complete_session(_base_poses()), "105 complete")
	_ok(int(_media.call("get_attention")) == 15, "105 article still +15")
	var pub: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(pub != null and pub.ok and pub.attention_gained == 10, "105 base pose +10 not appearance-scaled")


func _test_abort_session() -> void: # awaited from _run_all
	_unlock_stage4(2)
	var session: MediaPhotoSession = _media.call("start_photo_session", null) as MediaPhotoSession
	session.continue_session()
	session.select_pose(&"pose_media_profile_normal")
	session.select_pose(&"pose_media_chair_sit")
	session.abort_session()
	await get_tree().process_frame
	_ok(not bool(_media.call("is_photo_session_completed")), "106 completed false")
	_ok(int(_media.call("get_attention")) == 0, "106 Attention0")
	_ok((_media.call("get_feed_event_ids") as Array).is_empty(), "106 feed empty")
	_ok(String(_gs.call("get_media_photo_pose", MediaContent.PHOTO_PROFILE) as StringName) == "", "106 pose not committed")


func _test_complete_base_session() -> void:
	_unlock_stage4(0)
	_ok(_complete_session(_base_poses()), "107 complete")
	_ok(bool(_media.call("is_photo_session_completed")), "107 completed")
	_ok(int(_media.call("get_attention")) == 15, "107 Attention15")
	var feed: Array = _media.call("get_feed_event_ids") as Array
	_ok(feed.has(MediaContent.FEED_ARTICLE_EDITOR), "107 article feed")
	_ok(int(_media.call("get_photo_attention_value", MediaContent.PHOTO_PROFILE)) == 10, "107 profile10")
	_ok(int(_media.call("get_photo_attention_value", MediaContent.PHOTO_CHAIR)) == 10, "107 chair10")
	_ok(int(_media.call("get_photo_attention_value", MediaContent.PHOTO_COVER)) == 10, "107 cover10")
	var node: PhotoSessionInteractable = PhotoSessionInteractable.new()
	add_child(node)
	_ok(node.get_interaction_prompt(null) == "Съёмка завершена", "107 done prompt")
	node.queue_free()


func _test_first_incoming_at_article() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_ok(int(_media.call("get_incoming_offer_count")) == 1, "108 offer count1")
	var offers: Array = _media.call("get_incoming_offer_girl_ids") as Array
	_ok(offers.size() == 1 and offers[0] == &"girl_appearance_flash", "108 first candidate flash")


func _test_media_contact() -> void:
	_unlock_stage4()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_GOOD_PROFILE])
	_complete_session(_base_poses())
	var gid: StringName = &"girl_appearance_flash"
	_ok(bool(_gs.call("is_girl_discovered", gid)), "109 discovered")
	_ok(bool(_gs.call("has_girl_contact", gid)), "109 contact")
	_ok(bool(_gs.call("is_girl_clue_known", gid, 0)), "109 clue0")
	_ok(not bool(_gs.call("is_girl_clue_known", gid, 1)), "109 no GoodProfile clue1")
	_ok(int(_gs.call("get_girl_relationship", gid)) == 0, "109 relationship unchanged")


func _test_already_contacted_candidate() -> void:
	_unlock_stage4()
	var gid: StringName = &"girl_appearance_flash"
	_gs.call("add_girl_contact", gid)
	_gs.call("set_girl_relationship", gid, 2)
	_complete_session(_base_poses())
	var offers: Array = _media.call("get_incoming_offer_girl_ids") as Array
	_ok(offers.has(gid), "110 offer still added")
	_ok(int(_gs.call("get_girl_relationship", gid)) == 2, "110 relationship kept")


func _test_conquered_candidate() -> void:
	_unlock_stage4()
	var gid: StringName = &"girl_appearance_flash"
	_gs.call("add_girl_contact", gid)
	_gs.call("mark_girl_conquered", gid)
	var xp_before: int = int(_gs.call("get_experience"))
	_complete_session(_base_poses())
	_ok((_media.call("get_incoming_offer_girl_ids") as Array).has(gid), "111 conquered still offered")
	_ok(int(_gs.call("get_experience")) == xp_before, "111 no XP")


func _test_article_not_daily_quota() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_ok(bool(_media.call("can_publish_photo_today")), "112 photo still available same day")


func _test_publish_base_photo() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var pub: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(pub != null and pub.ok, "113 publish ok")
	_ok(int(_media.call("get_attention")) == 25, "113 Attention25")
	_ok(bool(_media.call("is_photo_published", MediaContent.PHOTO_PROFILE)), "113 published")
	var feed: Array = _media.call("get_feed_event_ids") as Array
	_ok(feed.has(MediaContent.feed_photo_event_id(MediaContent.PHOTO_PROFILE)), "113 feed photo")
	_ok(int(_media.call("get_incoming_offer_count")) == 1, "113 no threshold30 yet")


func _test_daily_limit() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	var att: int = int(_media.call("get_attention"))
	var second: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_CHAIR) as MediaPublishResult
	_ok(second != null and not second.ok, "114 not ok")
	_ok(second.error == MediaTypes.PublishError.DAILY_LIMIT, "114 DAILY_LIMIT")
	_ok(int(_media.call("get_attention")) == att, "114 attention unchanged")
	_ok(not bool(_media.call("is_photo_published", MediaContent.PHOTO_CHAIR)), "114 chair unpublished")


func _test_next_day_no_attention_tick() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	var att: int = int(_media.call("get_attention"))
	_day.call("advance_day")
	_ok(int(_media.call("get_attention")) == att, "115 no auto Attention")
	_ok(bool(_media.call("can_publish_photo_today")), "115 publish available next day")
	var pub: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_CHAIR) as MediaPublishResult
	_ok(pub != null and pub.ok, "115 second day publish ok")


func _test_base_progression_thresholds() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_ok(int(_media.call("get_incoming_offer_count")) == 1, "116 offer@15")
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_ok(int(_media.call("get_attention")) == 25, "116 att25")
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_ok(int(_media.call("get_attention")) == 35, "116 att35")
	_ok(int(_media.call("get_incoming_offer_count")) == 2, "116 offer@30")
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	_ok(int(_media.call("get_attention")) == 45, "116 att45")
	_ok(int(_media.call("get_incoming_offer_count")) == 3, "116 offer@45")
	_ok(bool(_media.call("is_overload_ready")), "116 overload_ready")


func _test_editorial_progression() -> void:
	_unlock_stage4(2)
	_complete_session(_editorial_poses())
	_ok(int(_media.call("get_attention")) == 15, "117 article15")
	var p1: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(p1 != null and p1.ok and int(_media.call("get_attention")) == 35, "117 +20 ->35")
	_ok(int(_media.call("get_incoming_offer_count")) == 2, "117 offer2")
	_day.call("advance_day")
	var p2: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_CHAIR) as MediaPublishResult
	_ok(p2 != null and p2.ok and int(_media.call("get_attention")) == 55, "117 +20 ->55")
	_ok(int(_media.call("get_incoming_offer_count")) == 3, "117 offer3")
	_ok(bool(_media.call("is_overload_ready")), "117 overload_ready")


func _test_threshold_jump_recovery() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_ok(int(_media.call("get_incoming_offer_count")) == 1, "118 one offer")
	# Produce Attention25 with still one offer by publishing base photo.
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_ok(int(_media.call("get_attention")) == 25, "118 att25")
	_ok(int(_media.call("get_incoming_offer_count")) == 1, "118 still one")
	# Jump +20 via editorial chair after swapping pose is not possible post-session;
	# use set_media_attention path then add20.
	_gs.call("set_media_attention", 25)
	_day.call("advance_day")
	# Force pose value path: add attention directly simulating jump.
	_gs.call("add_media_attention", 20)
	_ok(int(_media.call("get_attention")) == 45, "118 att45")
	_ok(int(_media.call("get_incoming_offer_count")) == 3, "118 fills offer2+3")


func _test_fourth_offer() -> void:
	_unlock_stage4(2)
	_complete_session(_editorial_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	_ok(int(_media.call("get_attention")) == 75, "119 att75")
	_ok(int(_media.call("get_incoming_offer_count")) == 4, "119 fourth offer")
	_gs.call("add_media_attention", 10)
	_ok(int(_media.call("get_incoming_offer_count")) == 4, "119 no fifth")


func _test_max_attention() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_gs.call("set_media_attention", 95)
	var before: int = int(_media.call("get_attention"))
	var after: int = int(_gs.call("add_media_attention", 20))
	_ok(after == 100, "120 clamp100")
	_ok(after - before == 5, "120 delta+5")


func _test_publish_duplicate() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	var att: int = int(_media.call("get_attention"))
	var dup: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(dup != null and dup.error == MediaTypes.PublishError.ALREADY_PUBLISHED, "121 ALREADY_PUBLISHED")
	_ok(int(_media.call("get_attention")) == att, "121 no Attention")


func _test_unknown_photo() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var bad: MediaPublishResult = _media.call("publish_photo", &"media_photo_unknown") as MediaPublishResult
	_ok(bad != null and bad.error == MediaTypes.PublishError.UNKNOWN_PHOTO, "122 UNKNOWN_PHOTO")


func _test_photo_before_session() -> void:
	_unlock_stage4()
	var early: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_PROFILE) as MediaPublishResult
	_ok(early != null and early.error == MediaTypes.PublishError.PHOTO_SESSION_REQUIRED, "123 PHOTO_SESSION_REQUIRED")


func _test_photo_value_from_stored_pose() -> void:
	_unlock_stage4(1)
	var poses: Dictionary = _base_poses()
	poses[MediaContent.PHOTO_CHAIR] = &"pose_media_chair_sideways"
	_complete_session(poses)
	var pub: MediaPublishResult = _media.call("publish_photo", MediaContent.PHOTO_CHAIR) as MediaPublishResult
	_ok(pub != null and pub.ok and pub.attention_gained == 15, "124 staged chair +15")


func _test_appearance_change_after_session() -> void:
	_unlock_stage4(0)
	_complete_session(_base_poses())
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 2)
	_ok(int(_media.call("get_photo_attention_value", MediaContent.PHOTO_PROFILE)) == 10, "125 pose value unchanged")


func _test_incoming_priority() -> void:
	_unlock_stage4(2)
	_complete_session(_editorial_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	var offers: Array = _media.call("get_incoming_offer_girl_ids") as Array
	_ok(offers.size() >= 4, "126 four offers")
	_ok(offers[0] == &"girl_appearance_flash", "126 #1 flash")
	_ok(offers[1] == &"girl_public_sculpture", "126 #2 sculpture")
	_ok(offers[2] == &"girl_cafe_receipt_notes", "126 #3 receipt")
	_ok(offers[3] == &"girl_gym_chalk", "126 #4 chalk")


func _test_required_experience_skip() -> void:
	_unlock_stage4(0, 4)
	var flash: GirlDefinition = _content.call("get_girl", &"girl_appearance_flash") as GirlDefinition
	_ok(flash != null, "127 flash exists")
	var override: GirlDefinition = flash.duplicate(true) as GirlDefinition
	override.required_experience = 99
	_gd.call("register_girl_definition", override)
	_complete_session(_base_poses())
	var offers: Array = _media.call("get_incoming_offer_girl_ids") as Array
	_ok(offers.size() == 1, "127 one offer")
	_ok(offers[0] == &"girl_public_sculpture", "127 skipped to sculpture")
	_ok(not bool(_gs.call("has_girl_contact", &"girl_appearance_flash")), "127 no invalid contact")
	_gd.call("clear_content_overrides")


func _test_offer_read() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var gid: StringName = &"girl_appearance_flash"
	var rel: int = int(_gs.call("get_girl_relationship", gid))
	var cd: int = int(_gs.call("get_girl_date_cooldown_days_remaining", gid))
	_ok(not bool(_media.call("is_offer_read", gid)), "128 NEW")
	_ok(bool(_media.call("mark_offer_read", gid)), "128 mark read")
	_ok(bool(_media.call("is_offer_read", gid)), "128 READ")
	_ok((_media.call("get_incoming_offer_girl_ids") as Array).has(gid), "128 remains")
	_ok(int(_gs.call("get_girl_relationship", gid)) == rel, "128 rel unchanged")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", gid)) == cd, "128 cooldown unchanged")


func _test_ignored_offer() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var gid: StringName = &"girl_appearance_flash"
	var money: int = int(_gs.call("get_money"))
	var auth: int = int(_gs.call("get_authority"))
	_day.call("advance_day")
	_day.call("advance_day")
	_day.call("advance_day")
	_ok((_media.call("get_incoming_offer_girl_ids") as Array).has(gid), "131 offer remains")
	_ok(not bool(_media.call("is_offer_read", gid)), "131 still unread")
	_ok(int(_gs.call("get_money")) == money, "131 no money penalty")
	_ok(int(_gs.call("get_authority")) == auth, "131 no authority penalty")


func _test_feed_order() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	var feed: Array = _media.call("get_feed_event_ids") as Array
	_ok(feed.size() >= 3, "132 feed size")
	_ok(feed[0] == MediaContent.FEED_ARTICLE_EDITOR, "132 article first")
	_ok(feed[1] == MediaContent.feed_inbound_event_id(&"girl_appearance_flash"), "132 inbound1")
	_ok(feed[2] == MediaContent.feed_photo_event_id(MediaContent.PHOTO_PROFILE), "132 photo1")


func _test_overload_ready_once() -> void:
	_unlock_stage4()
	_overload_count = 0
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	_ok(bool(_media.call("is_overload_ready")), "136 ready")
	_ok(_overload_count == 1, "136 signal once")
	_gs.call("add_media_attention", 10)
	_ok(_overload_count == 1, "136 no duplicate")
	_ok(bool(_media.call("is_overload_ready")), "136 remains true")


func _test_no_story_advance() -> void:
	_unlock_stage4(2)
	_complete_session(_editorial_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_COVER)
	_gs.call("add_media_attention", 50)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4), "137 stage stays4")
	_ok(int(_media.call("get_attention")) == 100, "137 attention100")


func _test_no_scientist() -> void:
	_reset()
	var girl: Variant = null
	var rival: Variant = null
	if _content.has_method("try_get_girl"):
		girl = _content.call("try_get_girl", &"girl_scientist")
	elif _content.has_method("get_girl"):
		girl = _content.call("get_girl", &"girl_scientist")
	if _content.has_method("try_get_rival"):
		rival = _content.call("try_get_rival", &"rival_scientist")
	_ok(girl == null, "138 no girl_scientist")
	_ok(rival == null, "138 no rival_scientist")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "138 no lab")


func _test_no_schedule_fields() -> void:
	var paths: Array[String] = [
		"res://game/media/media.gd",
		"res://game/media/media_types.gd",
		"res://game/media/media_content.gd",
		"res://game/media/media_photo_session.gd",
		"res://game/media/media_publish_result.gd",
		"res://game/media/photo_session_interactable.gd",
	]
	var banned: Array[String] = ["appointment_time", "calendar_slot", "deadline", "overlap_time"]
	var clean: bool = true
	for path in paths:
		var src: String = FileAccess.get_file_as_string(path)
		for token in banned:
			if src.contains(token):
				clean = false
	_ok(clean, "139 no schedule fields")


func _test_no_attention_tick() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var att: int = int(_media.call("get_attention"))
	for _i in range(30):
		await get_tree().process_frame
	_ok(int(_media.call("get_attention")) == att, "140 no frame tick")
	var src: String = FileAccess.get_file_as_string("res://game/media/media.gd")
	_ok(not src.contains("func _process"), "140 no _process in Media")


func _test_gameday_no_attention_tick() -> void:
	_unlock_stage4()
	_complete_session(_base_poses())
	var att: int = int(_media.call("get_attention"))
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_media.call("get_attention")) == att, "141 GameDay no Attention")


func _test_no_reward_contamination() -> void:
	_unlock_stage4()
	var money: int = int(_gs.call("get_money"))
	var auth: int = int(_gs.call("get_authority"))
	var xp: int = int(_gs.call("get_experience"))
	var up: int = int(_gs.call("get_upgrade_points"))
	_complete_session(_base_poses())
	_media.call("publish_photo", MediaContent.PHOTO_PROFILE)
	_day.call("advance_day")
	_media.call("publish_photo", MediaContent.PHOTO_CHAIR)
	var gid: StringName = &"girl_appearance_flash"
	_ok(int(_gs.call("get_money")) == money, "142 money")
	_ok(int(_gs.call("get_authority")) == auth, "142 authority")
	_ok(int(_gs.call("get_experience")) == xp, "142 experience")
	_ok(int(_gs.call("get_upgrade_points")) == up, "142 upgrade points")
	_ok(not bool(_gs.call("is_girl_conquered", gid)), "142 not conquered")
	_ok(int(_gs.call("get_girl_relationship", gid)) == 0, "142 relationship0")


func _test_session_idempotent() -> void:
	_unlock_stage4()
	_ok(_complete_session(_base_poses()), "78 first complete")
	var att: int = int(_media.call("get_attention"))
	var offers: int = int(_media.call("get_incoming_offer_count"))
	_ok(not _complete_session(_base_poses()), "78 second complete rejected")
	_ok(int(_media.call("get_attention")) == att, "78 no double article Attention")
	_ok(int(_media.call("get_incoming_offer_count")) == offers, "78 no duplicate offer")
