extends CanvasLayer
## Physical photo-studio loop: outfit/backdrop → pose on Hero → SubViewport capture → journal publish.

const UiEscapeScript := preload("res://core/ui_escape.gd")
const HERO_SCENE := "res://assets/characters/hero_base/prefabs/Hero.tscn"

const BACKDROPS := [
	{"id": "neutral", "label": "Нейтральный", "color": Color(0.82, 0.82, 0.86)},
	{"id": "business", "label": "Бизнес", "color": Color(0.22, 0.28, 0.38)},
	{"id": "romantic", "label": "Романтика", "color": Color(0.55, 0.28, 0.4)},
	{"id": "creative", "label": "Креатив", "color": Color(0.35, 0.55, 0.7)},
	{"id": "sport", "label": "Спорт", "color": Color(0.25, 0.45, 0.3)},
]

const POSES := [
	{"id": "idle", "label": "Стойка"},
	{"id": "gesture", "label": "Жест"},
	{"id": "react", "label": "Реакция"},
	{"id": "walk", "label": "Шаг"},
]

const CAPTIONS := [
	"Новый день, новый образ",
	"Готов к свиданиям",
	"Корпоративный романтик",
	"Спокойная уверенность",
	"Снимаю, значит живу",
]

var _root: Control
var _panel: PanelContainer
var _title: Label
var _hint: Label
var _body: VBoxContainer
var _phase: String = "pick"
var _outfit: String = ""
var _backdrop: String = "neutral"
var _pose: String = "idle"
var _timer_left: float = 0.0
var _counting: bool = false
var _pending_photo: Dictionary = {}
var _viewport: SubViewport
var _hero: Node3D
var _backdrop_mesh: MeshInstance3D
var _preview: TextureRect
var _prev_outfit: StringName = &""
var _journal_layout: String = "center"
var _journal_caption: String = "Новый день, новый образ"


func _ready() -> void:
	add_to_group("photo_studio_ui")
	layer = 27
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.05, 0.1, 0.62)
	_root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -320.0
	_panel.offset_top = -260.0
	_panel.offset_right = 320.0
	_panel.offset_bottom = 260.0
	_root.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)
	_title = Label.new()
	_title.text = "Фотостудия Agency Row"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint)
	_preview = TextureRect.new()
	_preview.custom_minimum_size = Vector2(0, 140)
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.visible = false
	vbox.add_child(_preview)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	vbox.add_child(_body)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)
	_ensure_capture_rig()


func _ensure_capture_rig() -> void:
	if _viewport != null:
		return
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(512, 512)
	# Isolate capture Hero from the apartment/city World3D (default shared world leaks the mesh at origin).
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.transparent_bg = false
	add_child(_viewport)
	var world_root := Node3D.new()
	world_root.name = "CaptureRoot"
	_viewport.add_child(world_root)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 40, 0)
	light.light_energy = 1.1
	world_root.add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.35, 2.4)
	cam.current = true
	world_root.add_child(cam)
	cam.look_at(Vector3(0, 1.1, 0))
	_backdrop_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.5, 3.2)
	_backdrop_mesh.mesh = plane
	_backdrop_mesh.position = Vector3(0, 1.4, -1.2)
	_backdrop_mesh.rotation_degrees = Vector3(90, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.82, 0.86)
	_backdrop_mesh.material_override = mat
	world_root.add_child(_backdrop_mesh)
	var packed := load(HERO_SCENE) as PackedScene
	if packed:
		_hero = packed.instantiate() as Node3D
		if _hero:
			_hero.position = Vector3(0, 0, 0)
			world_root.add_child(_hero)


func open() -> void:
	if not DatePlaces.is_agency_row_unlocked():
		EventBus.toast("Фотостудия откроется с районом агентства (stage_3)", &"warn")
		return
	if Game.city != null and not Game.city.can_shoot_photo_today() and _pending_photo.is_empty():
		EventBus.toast("Сегодня уже снимали — приходи завтра или опубликуй кадр", &"warn")
		# Still allow journal if unpublished shots exist.
		var has_draft := false
		for p in Game.city.profile_photos:
			if not bool(p.get("published", false)):
				has_draft = true
				_pending_photo = (p as Dictionary).duplicate(true)
				break
		if has_draft:
			_show_journal()
			visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		return
	_prev_outfit = Game.inventory.equipped_outfit if Game.inventory != null else &""
	_outfit = str(_prev_outfit)
	_backdrop = "neutral"
	_pose = "idle"
	_pending_photo.clear()
	_preview.visible = false
	_phase = "pick"
	_counting = false
	_rebuild_pick()
	_place_player_on_mark()
	_ensure_capture_rig()
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	_counting = false
	if Game.inventory != null and _prev_outfit != &"" and Game.inventory.own_outfit(_prev_outfit):
		Game.inventory.equip_outfit(_prev_outfit)
	var player := get_tree().get_first_node_in_group("player") as Node
	if player != null:
		player.set("_date_lock", false)
	visible = false
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()


func _rebuild_pick() -> void:
	_phase = "pick"
	_title.text = "Фотостудия — образ"
	_hint.text = "Выбери одежду (из своих) и фон. Потом встань на метку и выбери позу."
	_clear_body()
	var outfits: Array = Game.inventory.owned_outfits if Game.inventory != null else []
	if outfits.is_empty():
		outfits = [&"casual"]
	var o_row := HBoxContainer.new()
	_body.add_child(o_row)
	for oid in outfits:
		var btn := Button.new()
		btn.text = str(oid)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured := str(oid)
		btn.pressed.connect(func() -> void:
			_outfit = captured
			if Game.inventory != null:
				Game.inventory.equip_outfit(StringName(captured))
			_hint.text = "Одежда: %s" % captured
		)
		o_row.add_child(btn)
	var b_row := HBoxContainer.new()
	_body.add_child(b_row)
	for bd in BACKDROPS:
		var b := Button.new()
		b.text = str(bd.get("label", bd.get("id", "")))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bid := str(bd.get("id", "neutral"))
		var col: Color = bd.get("color", Color.WHITE)
		b.pressed.connect(func() -> void:
			_backdrop = bid
			_set_backdrop_color(col)
			_hint.text = "Фон: %s" % bid
		)
		b_row.add_child(b)
	var next := Button.new()
	next.text = "К позам на метке"
	next.pressed.connect(_rebuild_pose)
	_body.add_child(next)


func _set_backdrop_color(col: Color) -> void:
	if _backdrop_mesh == null:
		return
	var mat := _backdrop_mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		_backdrop_mesh.material_override = mat
	mat.albedo_color = col


func _place_player_on_mark() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	var world := tree.get_first_node_in_group("world_root") as Node
	if player == null or world == null:
		return
	var city_visual := world.find_child("CityVisual", true, false) as Node3D
	if city_visual == null:
		return
	var mark := city_visual.get_node_or_null("Markers/PhotoMark") as Node3D
	if mark == null:
		mark = city_visual.find_child("PhotoMark", true, false) as Node3D
	if mark == null:
		return
	player.global_position = mark.global_position + Vector3(0, 0.05, 0)
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.set("_date_lock", true)


func _rebuild_pose() -> void:
	_phase = "pose"
	_title.text = "Фотостудия — поза"
	_hint.text = "Ты на метке. Выбери позу — она видна на Hero в кадре."
	_clear_body()
	_apply_pose(_pose)
	var row := HBoxContainer.new()
	_body.add_child(row)
	for p in POSES:
		var btn := Button.new()
		btn.text = str(p.get("label", p.get("id", "")))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var pid := str(p.get("id", "idle"))
		btn.pressed.connect(func() -> void:
			_pose = pid
			_apply_pose(pid)
			_hint.text = "Поза: %s" % pid
		)
		row.add_child(btn)
	var shoot := Button.new()
	shoot.text = "Снять (таймер 2с)"
	shoot.pressed.connect(_start_timer)
	_body.add_child(shoot)


func _apply_pose(alias: String) -> void:
	if _hero == null:
		return
	if _hero.has_method("play_alias"):
		_hero.call("play_alias", alias)
	elif _hero.has_method("has_alias") and bool(_hero.call("has_alias", alias)):
		_hero.call("play_alias", alias)


func _start_timer() -> void:
	_phase = "timer"
	_timer_left = 2.0
	_counting = true
	_hint.text = "Съёмка через 2.0…"
	_clear_body()


func _process(delta: float) -> void:
	if not visible or not _counting:
		return
	_timer_left -= delta
	_hint.text = "Съёмка через %.1f…" % maxf(0.0, _timer_left)
	if _timer_left <= 0.0:
		_counting = false
		_capture()


func _capture() -> void:
	_ensure_capture_rig()
	_apply_pose(_pose)
	await get_tree().process_frame
	await get_tree().process_frame
	var tex: ViewportTexture = _viewport.get_texture()
	if tex == null:
		EventBus.toast("Камера не готова", &"warn")
		return
	var img: Image = tex.get_image()
	if img == null:
		EventBus.toast("Пустой кадр", &"warn")
		return
	_preview.texture = ImageTexture.create_from_image(img)
	_preview.visible = true
	var meta := {"outfit": _outfit, "backdrop": _backdrop, "pose": _pose}
	var result: Dictionary = Game.city.store_profile_photo(meta, img) if Game.city != null else {}
	if not bool(result.get("ok", false)):
		return
	_pending_photo = result.get("photo", {})
	EventBus.toast("Кадр сохранён", &"ok")
	_show_journal()


func _show_journal() -> void:
	_phase = "journal"
	_title.text = "Стол вёрстки"
	_hint.text = "Размести фото и выбери подпись, затем опубликуй."
	_clear_body()
	if _pending_photo.is_empty() and Game.city != null:
		for p in Game.city.profile_photos:
			if not bool(p.get("published", false)):
				_pending_photo = (p as Dictionary).duplicate(true)
				break
	_journal_layout = "center"
	_journal_caption = str(CAPTIONS[0])
	var l_row := HBoxContainer.new()
	_body.add_child(l_row)
	for lid_raw in ["cover", "center", "side"]:
		var lid: String = str(lid_raw)
		var btn := Button.new()
		btn.text = lid
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured_l: String = lid
		btn.pressed.connect(func() -> void:
			_journal_layout = captured_l
			_hint.text = "Макет: %s" % _journal_layout
		)
		l_row.add_child(btn)
	var cap_box := VBoxContainer.new()
	_body.add_child(cap_box)
	for c_raw in CAPTIONS:
		var c: String = str(c_raw)
		var cb := Button.new()
		cb.text = c
		var captured_c: String = c
		cb.pressed.connect(func() -> void:
			_journal_caption = captured_c
			_hint.text = "Подпись: %s" % _journal_caption
		)
		cap_box.add_child(cb)
	var pub := Button.new()
	pub.text = "Опубликовать профиль"
	pub.pressed.connect(func() -> void:
		if _pending_photo.is_empty() or Game.city == null:
			EventBus.toast("Нет кадра", &"warn")
			return
		Game.city.publish_profile_photo(str(_pending_photo.get("id", "")), _journal_layout, _journal_caption)
		_pending_photo.clear()
		close()
	)
	_body.add_child(pub)
