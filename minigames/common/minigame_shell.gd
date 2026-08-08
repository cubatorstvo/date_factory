class_name MinigameShell
extends RefCounted
## Shared minigame presentation helpers (MODULE 22). No gameplay formulas.


const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const RESULT_HOLD_SEC: float = 1.0
const TRACK_SIDE_MARGIN: float = 48.0
const MIN_TRACK_WIDTH: float = 240.0


static func apply_theme(root: Control) -> void:
	if root == null:
		return
	if ResourceLoader.exists(THEME_PATH):
		var theme_res: Resource = load(THEME_PATH)
		if theme_res is Theme:
			root.theme = theme_res as Theme


static func format_score(player_score: int, rival_score: int, target_score: int) -> String:
	return "Ты %d  :  %d Соперник    цель %d" % [
		player_score,
		rival_score,
		target_score,
	]


static func outcome_title(outcome: GameTypes.RivalCompetitionOutcome) -> String:
	if outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		return "ПОБЕДА"
	if outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS:
		return "ПОРАЖЕНИЕ"
	return "ИТОГ"


static func outcome_color(outcome: GameTypes.RivalCompetitionOutcome) -> Color:
	if outcome == GameTypes.RivalCompetitionOutcome.PLAYER_WIN:
		return Color(0.55, 0.92, 0.62, 1.0)
	if outcome == GameTypes.RivalCompetitionOutcome.PLAYER_LOSS:
		return Color(0.95, 0.55, 0.50, 1.0)
	return Color(0.92, 0.92, 0.90, 1.0)


static func reason_line(result: RivalCompetitionResult) -> String:
	if result == null:
		return ""
	var summary: String = result.debug_score_summary.strip_edges()
	if summary != "":
		return summary
	return ""


static func responsive_track_width(viewport: Viewport, designed: float) -> float:
	var designed_w: float = maxf(designed, MIN_TRACK_WIDTH)
	if viewport == null:
		return designed_w
	var available: float = viewport.get_visible_rect().size.x - TRACK_SIDE_MARGIN * 2.0
	return minf(designed_w, maxf(available, MIN_TRACK_WIDTH))


static func build_result_overlay(parent: Control, result: RivalCompetitionResult) -> Control:
	## No Authority line — exhibition / normal rival UI owns that presentation.
	if parent == null or result == null:
		return null
	var existing: Node = parent.get_node_or_null("ResultOverlay")
	if existing != null:
		existing.queue_free()
	var overlay: PanelContainer = PanelContainer.new()
	overlay.name = "ResultOverlay"
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -220.0
	overlay.offset_right = 220.0
	overlay.offset_top = -90.0
	overlay.offset_bottom = 90.0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 20
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	overlay.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var title: Label = Label.new()
	title.name = "OutcomeTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", outcome_color(result.outcome))
	title.text = outcome_title(result.outcome)
	vbox.add_child(title)
	var detail: Label = Label.new()
	detail.name = "OutcomeDetail"
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_size_override("font_size", 18)
	detail.text = reason_line(result)
	vbox.add_child(detail)
	parent.add_child(overlay)
	return overlay
