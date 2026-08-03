extends Control
## Phone overlay with tabs.

@onready var panel: PanelContainer = $Panel
@onready var tabs: TabContainer = $Panel/Margin/Body/Tabs
@onready var candidates_list: ItemList = $Panel/Margin/Body/Tabs/Candidates/List
@onready var relations_list: ItemList = $Panel/Margin/Body/Tabs/Relations/List
@onready var upgrades_list: ItemList = $Panel/Margin/Body/Tabs/Upgrades/List
@onready var staff_list: ItemList = $Panel/Margin/Body/Tabs/Staff/List
@onready var clones_list: ItemList = $Panel/Margin/Body/Tabs/Clones/List
@onready var stats_label: Label = $Panel/Margin/Body/Tabs/Stats/Label
@onready var twitch_edit: LineEdit = $Panel/Margin/Body/Tabs/Twitch/Channel
@onready var twitch_status: Label = $Panel/Margin/Body/Tabs/Twitch/Status
@onready var schedule_label: Label = $Panel/Margin/Body/Tabs/Schedule/Label

var _open: bool = false
var _upgrade_ids: Array = []
var _staff_ids: Array = []
var _candidate_ids: Array = []


func _ready() -> void:
	add_to_group("phone_ui")
	visible = false
	if panel:
		panel.visible = false
	# Prevent Twitch LineEdit from eating WASD.
	if twitch_edit:
		twitch_edit.focus_mode = Control.FOCUS_CLICK
	var start_btn := get_node_or_null("Panel/Margin/Body/Tabs/Candidates/Start") as Button
	if start_btn:
		start_btn.text = "Подготовить и начать"
	var prepare_btn := get_node_or_null("Panel/Margin/Body/Tabs/Candidates/Prepare") as Button
	if prepare_btn:
		prepare_btn.text = "Только подготовить"
	$Panel/Margin/Body/Tabs/Upgrades/Buy.pressed.connect(_buy_selected_upgrade)
	$Panel/Margin/Body/Tabs/Staff/Hire.pressed.connect(_hire_selected)
	$Panel/Margin/Body/Tabs/Candidates/Prepare.pressed.connect(_prepare_selected)
	$Panel/Margin/Body/Tabs/Candidates/Start.pressed.connect(_start_selected)
	$Panel/Margin/Body/Tabs/Twitch/Connect.pressed.connect(_connect_twitch)
	$Panel/Margin/Body/Tabs/Clones/Create.pressed.connect(func(): Game.clones.create_clone(); _refresh())
	$Panel/Margin/Body/Tabs/Stats/Save.pressed.connect(func(): Game.save_game())
	$Panel/Margin/Body/Tabs/Stats/Load.pressed.connect(func(): Game.load_game(); _refresh())
	Game.girls.girls_changed.connect(_refresh)
	Game.upgrades.upgrades_changed.connect(_refresh)
	Game.staff.staff_changed.connect(_refresh)
	Game.clones.clones_changed.connect(_refresh)


func force_close() -> void:
	_open = false
	var focus := get_viewport().gui_get_focus_owner()
	if focus and is_ancestor_of(focus):
		focus.release_focus()
	if twitch_edit:
		twitch_edit.release_focus()
	visible = false
	if panel:
		panel.visible = false
		panel.modulate.a = 1.0
		panel.scale = Vector2.ONE


func set_open(open: bool) -> void:
	_open = open
	if open:
		visible = true
		if panel:
			panel.visible = true
			panel.modulate.a = 0.0
			panel.scale = Vector2(0.94, 0.94)
			var tween := create_tween().set_parallel()
			tween.tween_property(panel, "modulate:a", 1.0, 0.18)
			tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Game.quests.on_phone_opened()
		_refresh()
		Sfx.play_ui(&"click")
	else:
		force_close()
		Sfx.play_ui(&"cancel")


func _refresh() -> void:
	if not Game.run_started:
		return
	candidates_list.clear()
	_candidate_ids.clear()
	Game.girls.refresh_candidates(false)
	for c in Game.girls.candidates:
		_candidate_ids.append(c)
		candidates_list.add_item("%s (%s)" % [str(c.get("name", "?")), str(c.get("archetype", "Кандидатка"))])
	relations_list.clear()
	for id in Game.girls.unlocked.keys():
		var e: Dictionary = Game.girls.unlocked[id]
		if not bool(e.get("met", false)):
			continue
		relations_list.add_item("%s | уровень %d | очки %.0f" % [
			Game.girls.display_name(StringName(id)),
			int(e.get("relation_level", 0)) + 1,
			float(e.get("relation_points", 0)),
		])
	upgrades_list.clear()
	_upgrade_ids.clear()
	for u in Game.upgrades.available():
		_upgrade_ids.append(str(u.get("id", "")))
		upgrades_list.add_item("%s — %.0f$" % [str(u.get("name", "")), float(u.get("cost", 0))])
	staff_list.clear()
	_staff_ids.clear()
	for role_id in ContentDB.staff_roles.keys():
		if Game.staff.hired.has(role_id):
			continue
		if Game.staff.can_hire(StringName(role_id)):
			_staff_ids.append(role_id)
			var def: Dictionary = ContentDB.staff_roles[role_id]
			staff_list.add_item("%s — %.0f$" % [str(def.get("name", role_id)), float(def.get("cost", 0))])
	for h in Game.staff.list_hired():
		staff_list.add_item("✓ %s" % str(h.get("name", "")))
	clones_list.clear()
	for c in Game.clones.clones:
		clones_list.add_item("%s | усталость %.0f%%" % [str(c.get("name", "")), float(c.get("fatigue", 0)) * 100.0])
	stats_label.text = "Успешных свиданий: %d\nВсего свиданий: %d\nИдеальных: %d\nПровалов: %d\nКлонов: %d\nПостгейм: %s\nЧастей мегамашины: %d" % [
		Game.total_successful_dates,
		int(Game.dating.stats.get("total", 0)),
		int(Game.dating.stats.get("perfect", 0)),
		int(Game.dating.stats.get("fail", 0)),
		Game.clones.clones.size(),
		Loc.yes_no(Game.postgame),
		Game.facility.mega_parts,
	]
	var venue_names: PackedStringArray = PackedStringArray()
	for v in Game.facility.unlocked_venues:
		venue_names.append(Loc.venue_name(v))
	schedule_label.text = "Автосвиданий сейчас: %d\nУровень автоматизации: %d\nДоступные места: %s" % [
		Game.dating.active_autos.size(),
		Game.dating.automation_level,
		", ".join(venue_names),
	]
	twitch_status.text = "Статус Twitch: %s" % Loc.online(Game.names.twitch_connected)


func _buy_selected_upgrade() -> void:
	var idx := upgrades_list.get_selected_items()
	if idx.is_empty():
		return
	var i: int = idx[0]
	if i >= 0 and i < _upgrade_ids.size():
		Game.upgrades.buy(StringName(_upgrade_ids[i]))
		_refresh()


func _hire_selected() -> void:
	var idx := staff_list.get_selected_items()
	if idx.is_empty():
		return
	var i: int = idx[0]
	if i >= 0 and i < _staff_ids.size():
		Game.staff.hire(StringName(_staff_ids[i]))
		_refresh()


func _prepare_selected() -> void:
	var idx := candidates_list.get_selected_items()
	if idx.is_empty():
		EventBus.toast("Выбери кандидатку в списке", &"warn")
		return
	var c: Dictionary = _candidate_ids[idx[0]]
	Game.quests.on_profile_seen()
	var gift_id := &"flower"
	if Game.inventory.total_gifts() > 0:
		gift_id = StringName(str(Game.inventory.gift_counts.keys()[0]))
	elif Game.inventory.carried_item != &"":
		gift_id = Game.inventory.carried_item
	elif Game.inventory.can_buy_gift(&"flower"):
		Game.inventory.buy_gift(&"flower")
	var venue := &"kitchen_table"
	if Game.facility.unlocked_venues.size() > 0:
		venue = Game.facility.unlocked_venues[Game.facility.unlocked_venues.size() - 1]
	Game.dating.set_prep(str(c.get("id", "")), gift_id, venue, Game.inventory.equipped_outfit)
	EventBus.toast("Подготовлено в телефоне. Подойди к столу или нажми «Подготовить и начать».", &"info")
	Sfx.play_ui(&"confirm")


func _start_selected() -> void:
	if not Game.quests.can_do(&"start_date"):
		EventBus.toast(Game.quests.gate_hint(&"start_date"), &"warn")
		return
	var idx := candidates_list.get_selected_items()
	if idx.is_empty():
		return
	var c: Dictionary = _candidate_ids[idx[0]]
	var id := str(c.get("id", ""))
	if not Game.dating.prepared.has(id):
		_prepare_selected()
	if not Game.dating.prepared.has(id):
		return
	if Game.dating.start_manual(id, str(c.get("kind", "")) == "unique"):
		Sfx.play_ui(&"confirm")
		set_open(false)
	else:
		Sfx.play_ui(&"deny")


func _connect_twitch() -> void:
	Game.names.set_twitch_channel(twitch_edit.text)
	_refresh()
