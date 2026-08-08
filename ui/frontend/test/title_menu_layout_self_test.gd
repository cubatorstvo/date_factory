extends Node
## Visual Playtest Phase B1 — Main Menu centering at ui_scale 100/125/150.
## Run: --path . --headless --quit-after 12000 res://ui/frontend/test/title_menu_layout_test.tscn


const CENTER_TOLERANCE_PX: float = 12.0
const OUTSIDE_SLACK_PX: float = 2.0
const SCALES: Array[float] = [1.0, 1.25, 1.5]

var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	await _run_all()
	if _failed == 0:
		print("TITLE_MENU_LAYOUT: ALL PASS (%s)" % _passed)
	else:
		print("TITLE_MENU_LAYOUT: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	var resized: bool = false
	if DisplayServer.window_can_draw():
		DisplayServer.window_set_size(Vector2i(1280, 720))
		resized = true
		await get_tree().process_frame
		await get_tree().process_frame

	var menu: TitleMenu = TitleMenu.new()
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame

	var vp: Viewport = get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size
	print(
		"TITLE_MENU_LAYOUT: viewport=%sx%s window_resize_attempted=%s"
		% [int(vp_size.x), int(vp_size.y), resized]
	)

	for scale_value in SCALES:
		await _assert_scale(menu, scale_value)

	UiScaleHelper.set_ui_scale(UiScaleHelper.PRESET_100)
	var root_reset: Control = menu.get_node_or_null("Root") as Control
	if root_reset != null:
		UiScaleHelper.apply_to_control(root_reset)


func _assert_scale(menu: TitleMenu, scale_value: float) -> void:
	UiScaleHelper.set_ui_scale(scale_value)
	var root: Control = menu.get_node_or_null("Root") as Control
	if root == null:
		_fail("scale=%s missing Root" % scale_value)
		return
	UiScaleHelper.apply_to_control(root)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout

	var panel: PanelContainer = _find_menu_panel(root)
	if panel == null:
		_fail("scale=%s missing PanelContainer under CenterContainer" % scale_value)
		return

	var vp_rect: Rect2 = get_viewport().get_visible_rect()
	var vp_center_x: float = vp_rect.position.x + vp_rect.size.x * 0.5
	var panel_rect: Rect2 = panel.get_global_rect()
	var panel_center_x: float = panel_rect.position.x + panel_rect.size.x * 0.5
	var dx: float = absf(panel_center_x - vp_center_x)
	if dx <= CENTER_TOLERANCE_PX:
		_pass("scale=%s panel center dx=%.2f" % [scale_value, dx])
	else:
		_fail(
			"scale=%s panel center dx=%.2f (panel_cx=%.2f vp_cx=%.2f)"
			% [scale_value, dx, panel_center_x, vp_center_x]
		)

	if _rect_within_viewport(panel_rect, vp_rect, OUTSIDE_SLACK_PX):
		_pass("scale=%s panel inside viewport" % scale_value)
	else:
		_fail("scale=%s panel outside viewport rect=%s vp=%s" % [scale_value, panel_rect, vp_rect])

	var buttons: Array[Button] = _collect_menu_buttons(panel)
	if buttons.size() == 5:
		_pass("scale=%s five menu buttons found" % scale_value)
	else:
		_fail("scale=%s expected 5 menu buttons, found %s" % [scale_value, buttons.size()])
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		var btn_rect: Rect2 = btn.get_global_rect()
		if _rect_within_viewport(btn_rect, vp_rect, OUTSIDE_SLACK_PX):
			_pass("scale=%s button[%s] inside viewport" % [scale_value, i])
		else:
			_fail("scale=%s button[%s] outside viewport rect=%s" % [scale_value, i, btn_rect])

	var version_label: Label = _find_version_label(menu)
	if version_label == null:
		_fail("scale=%s missing version Label" % scale_value)
		return
	var version_rect: Rect2 = version_label.get_global_rect()
	if _rect_within_viewport(version_rect, vp_rect, OUTSIDE_SLACK_PX):
		_pass("scale=%s version label inside viewport" % scale_value)
	else:
		_fail("scale=%s version label outside viewport rect=%s" % [scale_value, version_rect])


func _find_menu_panel(root: Control) -> PanelContainer:
	for child in root.get_children():
		if child is CenterContainer:
			var center: CenterContainer = child as CenterContainer
			for nested in center.get_children():
				if nested is PanelContainer:
					return nested as PanelContainer
	return null


func _collect_menu_buttons(panel: PanelContainer) -> Array[Button]:
	var out: Array[Button] = []
	_collect_buttons_recursive(panel, out)
	return out


func _collect_buttons_recursive(node: Node, out: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button:
			out.append(child as Button)
		_collect_buttons_recursive(child, out)


func _find_version_label(menu: TitleMenu) -> Label:
	for child in menu.get_children():
		if child is Label:
			var lab: Label = child as Label
			if String(lab.text).begins_with("v"):
				return lab
	return null


func _rect_within_viewport(rect: Rect2, vp: Rect2, slack: float) -> bool:
	return (
		rect.position.x >= vp.position.x - slack
		and rect.position.y >= vp.position.y - slack
		and rect.end.x <= vp.end.x + slack
		and rect.end.y <= vp.end.y + slack
	)


func _pass(label: String) -> void:
	_passed += 1
	print("TITLE_MENU_LAYOUT PASS: %s" % label)


func _fail(label: String) -> void:
	_failed += 1
	push_error("[TITLE_MENU_LAYOUT] FAIL: %s" % label)
	print("TITLE_MENU_LAYOUT FAIL: %s" % label)
