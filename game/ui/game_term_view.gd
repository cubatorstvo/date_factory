class_name GameTermView
extends RefCounted


static func create(text: String, tag_knowledge: Dictionary = {}, registry: GameTermRegistry = null) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rtl.add_theme_color_override("default_color", LabUi.TEXT)
	apply(rtl, text, tag_knowledge, registry)
	return rtl


static func apply(rtl: RichTextLabel, text: String, tag_knowledge: Dictionary = {}, registry: GameTermRegistry = null) -> void:
	if rtl == null:
		return
	GameTermTooltipLayer.ensure(rtl)
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.meta_underlined = false
	rtl.mouse_filter = Control.MOUSE_FILTER_STOP
	if registry != null:
		rtl.set_meta("_game_term_registry", registry)
	elif rtl.has_meta("_game_term_registry"):
		rtl.remove_meta("_game_term_registry")
	rtl.text = GameTermFormatter.format_bbcode(text, tag_knowledge, registry)
	if rtl.get_meta("_game_term_bound", false):
		return
	rtl.meta_hover_started.connect(func(meta: Variant) -> void:
		_on_meta_hover(rtl, meta)
	)
	rtl.meta_hover_ended.connect(func(_meta: Variant) -> void:
		_on_meta_end(rtl)
	)
	rtl.set_meta("_game_term_bound", true)


static func _on_meta_hover(rtl: RichTextLabel, meta: Variant) -> void:
	var terms: GameTermRegistry = null
	if rtl.has_meta("_game_term_registry"):
		terms = rtl.get_meta("_game_term_registry") as GameTermRegistry
	if terms == null:
		terms = GameTermRegistry.from_shared_catalog()
	var term_id: StringName = GameTermFormatter.parse_meta(meta)
	var term: GameTerm = terms.find_term(term_id) if terms != null else null
	var layer: GameTermTooltipLayer = GameTermTooltipLayer.ensure(rtl)
	if layer != null:
		layer.show_term(term)


static func _on_meta_end(rtl: RichTextLabel) -> void:
	var layer: GameTermTooltipLayer = GameTermTooltipLayer.ensure(rtl)
	if layer != null:
		layer.hide_tooltip()
