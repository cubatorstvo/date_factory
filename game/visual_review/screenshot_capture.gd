class_name ScreenshotCapture
extends RefCounted
## Development-only viewport PNG capture with settle delay.


var _host: Node = null
var _out_root: String = ""
var _res_label: String = ""
var _mode: String = "layout"
var _captured: Array[String] = []


func setup(host: Node, out_root: String, res_label: String, mode: String = "layout") -> void:
	_host = host
	_out_root = out_root.replace("\\", "/")
	_res_label = res_label
	_mode = mode.strip_edges().to_lower()
	if _mode.is_empty():
		_mode = "layout"
	_captured.clear()


func get_captured() -> Array[String]:
	return _captured.duplicate()


func settle() -> void:
	if _host == null:
		return
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		return
	await tree.process_frame
	await tree.process_frame
	await tree.create_timer(0.2).timeout


func capture(shot_name: String) -> String:
	if _host == null or _out_root.is_empty() or _res_label.is_empty():
		push_error("[ScreenshotCapture] not configured")
		return ""
	await settle()
	var file_name: String = shot_name
	if not file_name.ends_with(".png"):
		file_name = "%s.png" % file_name
	# Mode subdir prevents gallery/playthrough/layout from overwriting each other.
	var dir_path: String = "%s/%s/%s" % [_out_root, _mode, _res_label]
	var mk_err: Error = DirAccess.make_dir_recursive_absolute(dir_path)
	if mk_err != OK and not DirAccess.dir_exists_absolute(dir_path):
		push_error("[ScreenshotCapture] mkdir failed: %s (%s)" % [dir_path, error_string(mk_err)])
		return ""
	var full_path: String = "%s/%s" % [dir_path, file_name]
	var viewport: Viewport = _host.get_viewport()
	if viewport == null:
		push_error("[ScreenshotCapture] no viewport")
		return ""
	var tex: ViewportTexture = viewport.get_texture()
	if tex == null:
		push_error("[ScreenshotCapture] no viewport texture")
		return ""
	var img: Image = tex.get_image()
	if img == null:
		push_error("[ScreenshotCapture] get_image failed")
		return ""
	var save_err: Error = img.save_png(full_path)
	if save_err != OK:
		push_error("[ScreenshotCapture] save_png failed: %s (%s)" % [full_path, error_string(save_err)])
		return ""
	_captured.append(full_path)
	print("[ScreenshotCapture] wrote %s" % full_path)
	return full_path
