class_name MediaContent
extends RefCounted
## Fixed Media shot / pose / threshold constants (MODULE 15).
## Not ContentDB — authored semantic records only.


const ATTENTION_MIN: int = 0
const ATTENTION_MAX: int = 100
const ARTICLE_ATTENTION: int = 15
const OVERLOAD_READY_ATTENTION: int = 45
const OVERLOAD_READY_OFFERS: int = 3
const MAX_THRESHOLD_OFFERS: int = 4

const PHOTO_PROFILE: StringName = &"media_photo_profile"
const PHOTO_CHAIR: StringName = &"media_photo_chair"
const PHOTO_COVER: StringName = &"media_photo_cover"

const FEED_ARTICLE_EDITOR: StringName = &"feed_article_editor"

const ARTICLE_HEADLINE: String = "Редакция подтверждает воспроизводимую странность городского самца"
const ARTICLE_SUBLINE: String = "Субъект отказался объяснять часть поз и тем самым подтвердил их редакционную ценность."

const PHOTO_SESSION_PROMPT: String = "Фотосессия у Редактора"
const PHOTO_SESSION_DONE_PROMPT: String = "Съёмка завершена"

const ATTENTION_THRESHOLDS: Array[int] = [15, 30, 45, 60]

const CANDIDATE_PRIORITY: Array[StringName] = [
	&"girl_appearance_flash",
	&"girl_public_sculpture",
	&"girl_cafe_receipt_notes",
	&"girl_gym_chalk",
	&"girl_appearance_ritual",
	&"girl_cafe_laptop",
	&"girl_city_bicycle",
	&"girl_city_umbrella",
	&"girl_cafe_spoon_stack",
	&"girl_city_lanyard",
	&"girl_gym_timer",
	&"girl_city_crosswalk",
	&"girl_appearance_coat_check",
	&"girl_cafe_hot_sauce",
	&"girl_appearance_mannequin",
	&"girl_cafe_sugar_geometry",
]

const SHOT_IDS: Array[StringName] = [
	PHOTO_PROFILE,
	PHOTO_CHAIR,
	PHOTO_COVER,
]

const PHOTO_TITLES: Dictionary = {
	PHOTO_PROFILE: "Профиль",
	PHOTO_CHAIR: "Стул",
	PHOTO_COVER: "Обложка",
}

const POSE_ATTENTION: Dictionary = {
	&"pose_media_profile_normal": 10,
	&"pose_media_profile_registered": 15,
	&"pose_media_profile_wrong_target": 20,
	&"pose_media_chair_sit": 10,
	&"pose_media_chair_sideways": 15,
	&"pose_media_chair_argument": 20,
	&"pose_media_cover_stand": 10,
	&"pose_media_cover_turn": 15,
	&"pose_media_cover_half_frame": 20,
}

const POSE_REQUIRED_APPEARANCE: Dictionary = {
	&"pose_media_profile_normal": 0,
	&"pose_media_profile_registered": 1,
	&"pose_media_profile_wrong_target": 2,
	&"pose_media_chair_sit": 0,
	&"pose_media_chair_sideways": 1,
	&"pose_media_chair_argument": 2,
	&"pose_media_cover_stand": 0,
	&"pose_media_cover_turn": 1,
	&"pose_media_cover_half_frame": 2,
}

const POSE_TIER: Dictionary = {
	&"pose_media_profile_normal": MediaTypes.PoseTier.BASE,
	&"pose_media_profile_registered": MediaTypes.PoseTier.STAGED,
	&"pose_media_profile_wrong_target": MediaTypes.PoseTier.EDITORIAL,
	&"pose_media_chair_sit": MediaTypes.PoseTier.BASE,
	&"pose_media_chair_sideways": MediaTypes.PoseTier.STAGED,
	&"pose_media_chair_argument": MediaTypes.PoseTier.EDITORIAL,
	&"pose_media_cover_stand": MediaTypes.PoseTier.BASE,
	&"pose_media_cover_turn": MediaTypes.PoseTier.STAGED,
	&"pose_media_cover_half_frame": MediaTypes.PoseTier.EDITORIAL,
}

const POSE_LABELS: Dictionary = {
	&"pose_media_profile_normal": "Повернуться боком",
	&"pose_media_profile_registered": "Выставить поставленный профиль",
	&"pose_media_profile_wrong_target": "Смотреть в профиль не камеры, а ближайшего прожектора",
	&"pose_media_chair_sit": "Сесть как на стул",
	&"pose_media_chair_sideways": "Сесть боком, как будто так и было задумано",
	&"pose_media_chair_argument": "Поставить стул рядом и позировать так, будто он проиграл спор",
	&"pose_media_cover_stand": "Просто стоять",
	&"pose_media_cover_turn": "Развернуться на полшага позже команды",
	&"pose_media_cover_half_frame": "Оставить половину себя за краем кадра",
}

const SHOT_SETUP: Dictionary = {
	PHOTO_PROFILE: "Редактор просит сделать фотографию профиля, но уточняет, что профиль должен что-то сообщать.",
	PHOTO_CHAIR: "В кадр возвращают тот самый стул. Редактор говорит, что теперь он официально часть материала.",
	PHOTO_COVER: "Последний кадр должен стать обложкой. Редактор просит не пытаться выглядеть нормально.",
}

const SHOT_POSES: Dictionary = {
	PHOTO_PROFILE: [
		&"pose_media_profile_normal",
		&"pose_media_profile_registered",
		&"pose_media_profile_wrong_target",
	],
	PHOTO_CHAIR: [
		&"pose_media_chair_sit",
		&"pose_media_chair_sideways",
		&"pose_media_chair_argument",
	],
	PHOTO_COVER: [
		&"pose_media_cover_stand",
		&"pose_media_cover_turn",
		&"pose_media_cover_half_frame",
	],
}

const EDITOR_FEEDBACK: Dictionary = {
	MediaTypes.PoseTier.BASE: "Редактор: «Пригодно. Человек присутствует.»",
	MediaTypes.PoseTier.STAGED: "Редактор: «Уже похоже на решение.»",
	MediaTypes.PoseTier.EDITORIAL: "Редактор: «Не исправляй. Именно это и оставим.»",
}

const INTRO_TEXT: String = "Редактор готов к съёмке. Три кадра. Без объяснений лишнего."


static func is_known_photo(photo_id: StringName) -> bool:
	return SHOT_IDS.has(photo_id)


static func photo_title(photo_id: StringName) -> String:
	return str(PHOTO_TITLES.get(photo_id, ""))


static func pose_attention(pose_id: StringName) -> int:
	return int(POSE_ATTENTION.get(pose_id, 0))


static func pose_required_appearance(pose_id: StringName) -> int:
	return int(POSE_REQUIRED_APPEARANCE.get(pose_id, 0))


static func pose_label(pose_id: StringName) -> String:
	return str(POSE_LABELS.get(pose_id, ""))


static func pose_tier(pose_id: StringName) -> MediaTypes.PoseTier:
	return int(POSE_TIER.get(pose_id, MediaTypes.PoseTier.BASE)) as MediaTypes.PoseTier


static func shot_setup(shot_id: StringName) -> String:
	return str(SHOT_SETUP.get(shot_id, ""))


static func poses_for_shot(shot_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var raw: Variant = SHOT_POSES.get(shot_id, [])
	if raw is Array:
		for entry in raw as Array:
			out.append(entry as StringName)
	return out


static func feed_photo_event_id(photo_id: StringName) -> StringName:
	return StringName("feed_photo_%s" % String(photo_id))


static func feed_inbound_event_id(girl_id: StringName) -> StringName:
	return StringName("feed_inbound_%s" % String(girl_id))


static func desired_threshold_offer_count(attention: int) -> int:
	var count: int = 0
	for threshold in ATTENTION_THRESHOLDS:
		if attention >= threshold:
			count += 1
	return mini(count, MAX_THRESHOLD_OFFERS)
