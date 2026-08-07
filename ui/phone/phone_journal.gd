class_name PhoneJournal
extends Control
## Functional phone journal for discovered girls (MODULE 08).
## No Dating CTA / messaging / scheduling.

signal opened()
signal closed()

var _list: ItemList = null
var _detail: RichTextLabel = null
var _title: Label = null
var _close_btn: Button = null
var _player: Node = null
var _is_open: bool = false
var _listed_ids: Array[StringName] = []


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func open(player: Node = null) -> void:
	_player = player
	if _player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			_player = tree.get_first_node_in_group("player")
	if _player != null and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	_refresh_list()
	visible = true
	_is_open = true
	opened.emit()


func close() -> void:
	if not _is_open and not visible:
		return
	visible = false
	_is_open = false
	if _player != null and _player.has_method("enter_gameplay"):
		_player.call("enter_gameplay")
	closed.emit()


func is_open() -> bool:
	return _is_open


func get_listed_girl_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for gid in _listed_ids:
		out.append(gid)
	return out


func get_detail_text() -> String:
	if _detail == null:
		return ""
	return String(_detail.text)


func select_girl_by_id(girl_id: StringName) -> bool:
	for i in range(_listed_ids.size()):
		if _listed_ids[i] == girl_id:
			_list.select(i)
			_show_detail(girl_id)
			return true
	return false


func refresh() -> void:
	_refresh_list()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 40)
	root.add_theme_constant_override("margin_right", 40)
	root.add_theme_constant_override("margin_top", 30)
	root.add_theme_constant_override("margin_bottom", 30)
	add_child(root)
	var vbox := VBoxContainer.new()
	root.add_child(vbox)
	_title = Label.new()
	_title.text = "Телефон — Журнал"
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(220, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	split.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail.fit_content = false
	split.add_child(_detail)
	_close_btn = Button.new()
	_close_btn.text = "Закрыть"
	_close_btn.pressed.connect(close)
	vbox.add_child(_close_btn)


func _refresh_list() -> void:
	_listed_ids.clear()
	if _list != null:
		_list.clear()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ids: Array = gs.call("get_discovered_girl_ids") as Array
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	for entry in ids:
		var gid: StringName = entry as StringName
		_listed_ids.append(gid)
		var display: String = String(gid)
		if gd != null:
			var def: GirlDefinition = gd.call("get_girl_definition", gid) as GirlDefinition
			if def != null and def.display_name.strip_edges() != "":
				display = def.display_name
		var has_contact: bool = bool(gs.call("has_girl_contact", gid))
		var status: String = "Номер получен" if has_contact else "Номера нет"
		_list.add_item("%s — %s" % [display, status])
	if _listed_ids.is_empty():
		_detail.text = "Пока нет записей."
	elif _list.get_selected_items().is_empty():
		_list.select(0)
		_show_detail(_listed_ids[0])


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _listed_ids.size():
		return
	_show_detail(_listed_ids[index])


func _show_detail(girl_id: StringName) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	var db: Node = get_node_or_null("/root/ContentDB")
	if gs == null or gd == null:
		_detail.text = ""
		return
	var def: GirlDefinition = gd.call("get_girl_definition", girl_id) as GirlDefinition
	var lines: PackedStringArray = PackedStringArray()
	var name: String = String(girl_id)
	if def != null and def.display_name.strip_edges() != "":
		name = def.display_name
	lines.append("[b]%s[/b]" % name)
	if bool(gs.call("has_girl_contact", girl_id)):
		lines.append("Статус: Номер получен")
	else:
		lines.append("Статус: Номера нет")
	lines.append("")
	lines.append("[b]Наблюдения[/b]")
	var known: Array = gs.call("get_known_girl_clue_indices", girl_id) as Array
	if known.is_empty():
		lines.append("Пока нет наблюдений")
	elif def != null:
		for k in known:
			var idx: int = int(k)
			if idx >= 0 and idx < def.clue_notes.size():
				lines.append("- %s" % def.clue_notes[idx])
	lines.append("")
	if bool(gs.call("is_primary_trait_revealed", girl_id)) and def != null and db != null:
		var trait_def: PrimaryTraitDefinition = db.call("get_primary_trait", def.primary_trait) as PrimaryTraitDefinition
		if trait_def != null:
			lines.append("[b]Основная черта:[/b] %s" % trait_def.display_name)
			lines.append("Нравится: %s" % _format_tags(trait_def.liked_tags))
			lines.append("Не нравится: %s" % _format_tags(trait_def.disliked_tags))
		else:
			lines.append("Характер: ?")
	else:
		lines.append("Характер: ?")
	lines.append("")
	lines.append("[b]Известные реакции[/b]")
	var reactions: Dictionary = gs.call("get_girl_known_reactions", girl_id) as Dictionary
	if reactions.is_empty():
		lines.append("Пока нет наблюдений")
	else:
		for source_key in reactions.keys():
			var source_id: StringName = source_key as StringName
			var reaction: int = int(reactions[source_key])
			var label: String = _resolve_reaction_source_label(source_id)
			if label == "":
				continue
			lines.append("- %s: %s" % [label, _reaction_text(reaction)])
	_detail.text = "\n".join(lines)


func _format_tags(tags: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tag in tags:
		parts.append(String(GameTypes.ActionTag.find_key(int(tag))))
	return ", ".join(parts)


func _reaction_text(reaction: int) -> String:
	match reaction:
		-1:
			return "негативная"
		0:
			return "нейтральная"
		1:
			return "позитивная"
	return str(reaction)


func _resolve_reaction_source_label(source_id: StringName) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null and db.has_method("get_dating_event"):
		var ev: DatingEventDefinition = db.call("get_dating_event", source_id) as DatingEventDefinition
		if ev != null:
			return String(ev.id)
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	if gd != null:
		var approach: DiscoveryApproachDefinition = gd.call("find_discovery_approach", source_id) as DiscoveryApproachDefinition
		if approach != null and approach.label.strip_edges() != "":
			return approach.label
	# Production UI: skip unresolved technical IDs.
	if OS.is_debug_build() or OS.has_feature("editor"):
		push_warning("[PhoneJournal] unresolved reaction source: %s" % String(source_id))
	return ""
