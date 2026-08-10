class_name CityPOITenant
extends Node3D
## Functional POI tenant living under a CityPOIBuilding (or standalone WorldActivity).
##
## Expected children (soft):
##   EntranceAnchor, InteractionArea, PromptAnchor, SignAnchor, Signage,
##   LocalLights, IdentityProps
## Optional multi-action folder: InteractionAreas/ with sibling Interactable nodes.
##
## Multi-action POIs (InternetCafe×3, Gym×2, Arcade×2, Bus×2):
##   - Primary InteractionArea (Interactable) uses this node's action_id exports.
##   - Extra actions are sibling Interactable nodes under this tenant (or under
##     InteractionAreas/) — each with its own action_id. All non-empty action_id
##     Interactables are registered into group "city_poi_interact".
##
## REPLACEMENT RULE (tenant-level)
## -------------------------------
## MAY replace later:
##   - EntranceAnchor local pose
##   - Signage / IdentityProps / LocalLights contents
##   - InteractionArea collision shape size/local offset
## MUST NOT change:
##   - poi_id / action_id contract (and multi-action sibling action_ids)
##   - save schema / interaction routing

@export var poi_id: String = ""
## Primary action; multi-action uses child Interactables with their own ids.
@export var action_id: StringName = &""
@export var prompt_text: String = ""
## VenueEntrancePOI | StorefrontPOI | WorldActivityPOI
@export var functional_type: String = "VenueEntrancePOI"
@export var progression_stage: int = 0
@export var display_name: String = ""
@export var action_label: String = ""
## Optional extras (venue_id, etc.). art_backed defaults to true unless provided.
@export var payload: Dictionary = {}


func _ready() -> void:
	add_to_group("city_poi_tenant")
	if poi_id != "":
		set_meta("poi_id", poi_id)
	if action_id != &"":
		set_meta("action_id", action_id)
	if functional_type != "":
		set_meta("functional_type", functional_type)
	_configure_primary_interaction_area()
	_register_all_descendant_interacts()


func get_entrance_global() -> Vector3:
	var anchor: Node3D = get_node_or_null("EntranceAnchor") as Node3D
	if anchor != null:
		return anchor.global_position
	var area: Node3D = get_node_or_null("InteractionArea") as Node3D
	if area != null:
		return area.global_position
	return global_position


func _configure_primary_interaction_area() -> void:
	var area_node: Node = get_node_or_null("InteractionArea")
	if area_node == null:
		return
	if not (area_node is Interactable):
		return
	var ia: Interactable = area_node as Interactable
	if action_id != &"":
		ia.action_id = action_id
	if display_name != "":
		ia.display_name = display_name
	elif prompt_text != "":
		ia.display_name = prompt_text
	if action_label != "":
		ia.action_label = action_label
	elif prompt_text != "":
		ia.action_label = prompt_text
	## Primary: tenant exports win over scene defaults on InteractionArea.
	ia.payload = _merged_primary_payload(ia.payload)
	if not ia.is_in_group("city_poi_interact"):
		ia.add_to_group("city_poi_interact")


func _register_all_descendant_interacts() -> void:
	_register_interacts_under(self)


func _register_interacts_under(node: Node) -> void:
	for child in node.get_children():
		if child is Interactable:
			var ia: Interactable = child as Interactable
			if ia.action_id != &"":
				## Sibling multi-action Interactables keep their own payload; only fill gaps.
				ia.payload = _ensure_art_backed_payload(ia.payload)
				if not ia.is_in_group("city_poi_interact"):
					ia.add_to_group("city_poi_interact")
		_register_interacts_under(child)


func _merged_primary_payload(existing: Dictionary) -> Dictionary:
	var merged: Dictionary = existing.duplicate()
	for key in payload.keys():
		merged[key] = payload[key]
	if not merged.has("art_backed"):
		merged["art_backed"] = true
	if poi_id != "" and not merged.has("poi_id"):
		merged["poi_id"] = poi_id
	return merged


func _ensure_art_backed_payload(existing: Dictionary) -> Dictionary:
	var merged: Dictionary = existing.duplicate()
	if not merged.has("art_backed"):
		merged["art_backed"] = true
	if poi_id != "" and not merged.has("poi_id"):
		merged["poi_id"] = poi_id
	return merged
