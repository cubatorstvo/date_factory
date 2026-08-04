class_name UiLayers
extends RefCounted
## CanvasLayer stacking policy (higher draws on top).
##
## Bands:
##   5     HUD chrome (resources, crosshair, hints)
##   15–58 Gameplay popups/modals (phone, date, shop, city services…)
##   60    Toast / transient notifications (always above gameplay UI)
##   70    Pause
##   80    Reveal
##   85    Finale
##   90    Settings
##   100   Transition (always top)
##
## Rule for new popups: call raise_popup(canvas_layer, BASE) when opening so the
## new overlay paints above older same-band UI. Toasts use TOAST (fixed).
## Esc / mouse-capture order stays in UiEscape (group priority), not layer numbers.

const HUD: int = 5
const PHONE: int = 15
const DATE: int = 20
const EVENT: int = 25
const SHOP: int = 25
const CLONE_ACCEPT: int = 25
const GYM: int = 26
const CITY_SERVICE: int = 27
const ELEVATOR: int = 28
const TOAST: int = 60
const PAUSE: int = 70
const REVEAL: int = 80
const FINALE: int = 85
const SETTINGS: int = 90
const TRANSITION: int = 100

## Dynamic bump range for gameplay modals — stays below TOAST.
const POPUP_BAND_MIN: int = 15
const POPUP_BAND_MAX: int = 58


static func raise_popup(layer_node: CanvasLayer, base_layer: int = -1) -> void:
	## Open-time bump: newer gameplay popup wins over older ones in the band.
	if layer_node == null:
		return
	var base: int = base_layer if base_layer >= 0 else clampi(layer_node.layer, POPUP_BAND_MIN, POPUP_BAND_MAX)
	var top: int = base - 1
	var tree: SceneTree = layer_node.get_tree()
	if tree != null and tree.root != null:
		top = maxi(top, _max_layer_in_band(tree.root, POPUP_BAND_MIN, POPUP_BAND_MAX, layer_node))
	layer_node.layer = clampi(maxi(base, top + 1), POPUP_BAND_MIN, POPUP_BAND_MAX)


static func _max_layer_in_band(node: Node, band_min: int, band_max: int, skip: CanvasLayer) -> int:
	var best: int = band_min - 1
	if node is CanvasLayer and node != skip:
		var cl: CanvasLayer = node as CanvasLayer
		if cl.layer >= band_min and cl.layer <= band_max and cl.visible:
			best = maxi(best, cl.layer)
	for child in node.get_children():
		best = maxi(best, _max_layer_in_band(child, band_min, band_max, skip))
	return best
