class_name MediaAttentionVisual
extends Node3D
## Presentation-only Attention threshold cue (MODULE 15).
## Toggles a visual subtree when Attention >= min_attention. No gameplay effect.

@export var min_attention: int = 15
@export var visual_root: NodePath = NodePath("Visual")


func _ready() -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_signal("attention_changed"):
		if not media.is_connected("attention_changed", _on_attention_changed):
			media.connect("attention_changed", _on_attention_changed)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	refresh()


func refresh() -> void:
	var show: bool = _query_attention() >= min_attention
	var visual: Node = get_node_or_null(visual_root)
	if visual is Node3D:
		(visual as Node3D).visible = show
		return
	if visual is CanvasItem:
		(visual as CanvasItem).visible = show
		return
	# Fallback: hide/show direct children named Visual is preferred; else self.
	visible = show


func _query_attention() -> int:
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_method("get_attention"):
		return int(media.call("get_attention"))
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_method("get_media_attention"):
		return int(gs.call("get_media_attention"))
	return 0


func _on_attention_changed(_new_value: int, _delta: int) -> void:
	refresh()


func _on_state_reset() -> void:
	refresh()
