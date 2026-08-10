class_name UiLayoutAuditor
extends RefCounted
## Audits visible Control bounds for visual playtest reports.


const OUTSIDE_PX: float = 2.0
const OFF_CENTER_FRAC: float = 0.05


func audit_title_menu(menu_root: Node) -> Array:
	var defects: Array = []
	if menu_root == null:
		defects.append(_defect("ERROR", "", "title menu root missing", {}))
		return defects
	var viewport_rect: Rect2 = _viewport_rect(menu_root)
	var essentials: Array[Control] = []
	_collect_title_essentials(menu_root, essentials)
	if essentials.is_empty():
		defects.append(_defect("WARNING", str(menu_root.get_path()), "no essential title controls found", {}))
	for ctrl: Control in essentials:
		defects.append_array(_audit_control(ctrl, viewport_rect, true))
	# Centered panel check: PanelContainer under CenterContainer.
	var panels: Array[Control] = []
	_collect_by_class(menu_root, "PanelContainer", panels)
	for panel: Control in panels:
		if not panel.is_visible_in_tree():
			continue
		var parent: Node = panel.get_parent()
		if parent is CenterContainer:
			defects.append_array(_check_centered_panel(panel, viewport_rect))
	return defects


func audit_visible_tree(root: Node, mark_all_essential: bool = false) -> Array:
	var defects: Array = []
	if root == null:
		return defects
	var viewport_rect: Rect2 = _viewport_rect(root)
	var controls: Array[Control] = []
	_collect_visible_controls(root, controls)
	for ctrl: Control in controls:
		defects.append_array(_audit_control(ctrl, viewport_rect, mark_all_essential))
	return defects


func control_snapshot(root: Node) -> Array:
	var rows: Array = []
	if root == null:
		return rows
	var viewport_rect: Rect2 = _viewport_rect(root)
	var controls: Array[Control] = []
	_collect_visible_controls(root, controls)
	for ctrl: Control in controls:
		var gr: Rect2 = ctrl.get_global_rect()
		rows.append({
			"path": str(ctrl.get_path()),
			"class": ctrl.get_class(),
			"visible": ctrl.is_visible_in_tree(),
			"global_rect": {"x": gr.position.x, "y": gr.position.y, "w": gr.size.x, "h": gr.size.y},
			"viewport": {"x": viewport_rect.position.x, "y": viewport_rect.position.y, "w": viewport_rect.size.x, "h": viewport_rect.size.y},
			"anchors": {
				"left": ctrl.anchor_left,
				"top": ctrl.anchor_top,
				"right": ctrl.anchor_right,
				"bottom": ctrl.anchor_bottom,
			},
		})
	return rows


func _audit_control(ctrl: Control, viewport_rect: Rect2, essential: bool) -> Array:
	var defects: Array = []
	if ctrl == null or not ctrl.is_visible_in_tree():
		return defects
	var gr: Rect2 = ctrl.get_global_rect()
	if gr.size.x <= 0.0 or gr.size.y <= 0.0:
		return defects
	var outside: bool = _is_outside(gr, viewport_rect, OUTSIDE_PX)
	if outside and _is_scroll_content(ctrl):
		return defects
	if outside and essential:
		defects.append(_defect(
			"ERROR",
			str(ctrl.get_path()),
			"essential control outside viewport by >%.0fpx" % OUTSIDE_PX,
			{"global_rect": _rect_dict(gr), "viewport": _rect_dict(viewport_rect)},
		))
	elif outside:
		defects.append(_defect(
			"WARNING",
			str(ctrl.get_path()),
			"control outside viewport by >%.0fpx" % OUTSIDE_PX,
			{"global_rect": _rect_dict(gr), "viewport": _rect_dict(viewport_rect)},
		))
	return defects


func _is_scroll_content(ctrl: Control) -> bool:
	var parent: Node = ctrl.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false


func _check_centered_panel(panel: Control, viewport_rect: Rect2) -> Array:
	var defects: Array = []
	var gr: Rect2 = panel.get_global_rect()
	var panel_center_x: float = gr.position.x + gr.size.x * 0.5
	var view_center_x: float = viewport_rect.position.x + viewport_rect.size.x * 0.5
	var delta: float = absf(panel_center_x - view_center_x)
	var threshold: float = viewport_rect.size.x * OFF_CENTER_FRAC
	if delta > threshold:
		defects.append(_defect(
			"WARNING",
			str(panel.get_path()),
			"centered panel off-center by >5%% viewport width (delta=%.1f threshold=%.1f)" % [delta, threshold],
			{"global_rect": _rect_dict(gr), "viewport": _rect_dict(viewport_rect)},
		))
	return defects


func _collect_title_essentials(node: Node, out: Array[Control]) -> void:
	if node is PanelContainer:
		var pc: PanelContainer = node as PanelContainer
		if pc.is_visible_in_tree():
			out.append(pc)
	elif node is Button:
		var btn: Button = node as Button
		if btn.is_visible_in_tree():
			out.append(btn)
	elif node is Label:
		var lab: Label = node as Label
		if lab.is_visible_in_tree():
			var text_l: String = lab.text.to_lower()
			if text_l.begins_with("v") or text_l.contains("version") or lab.name.to_lower().contains("version"):
				out.append(lab)
			elif lab.text == "DATE FACTORY":
				out.append(lab)
	for child: Node in node.get_children():
		_collect_title_essentials(child, out)


func _collect_by_class(node: Node, class_name_str: String, out: Array[Control]) -> void:
	if node.get_class() == class_name_str and node is Control:
		out.append(node as Control)
	for child: Node in node.get_children():
		_collect_by_class(child, class_name_str, out)


func _collect_visible_controls(node: Node, out: Array[Control]) -> void:
	if node is Control:
		var ctrl: Control = node as Control
		if ctrl.is_visible_in_tree():
			out.append(ctrl)
	for child: Node in node.get_children():
		_collect_visible_controls(child, out)


func _viewport_rect(node: Node) -> Rect2:
	var viewport: Viewport = node.get_viewport()
	if viewport == null:
		return Rect2(Vector2.ZERO, Vector2(1280, 720))
	return Rect2(Vector2.ZERO, viewport.get_visible_rect().size)


func _is_outside(gr: Rect2, viewport_rect: Rect2, slack: float) -> bool:
	return (
		gr.position.x < viewport_rect.position.x - slack
		or gr.position.y < viewport_rect.position.y - slack
		or gr.end.x > viewport_rect.end.x + slack
		or gr.end.y > viewport_rect.end.y + slack
	)


func _rect_dict(r: Rect2) -> Dictionary:
	return {"x": r.position.x, "y": r.position.y, "w": r.size.x, "h": r.size.y}


func _defect(severity: String, path: String, message: String, details: Dictionary) -> Dictionary:
	return {
		"severity": severity,
		"path": path,
		"message": message,
		"details": details,
	}
