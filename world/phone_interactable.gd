class_name PhoneInteractable
extends Interactable
## Thin apartment phone adapter -> PhoneJournal.open (MODULE 12).


func _ready() -> void:
	prompt_action = "Телефон"
	monitoring = false
	monitorable = true
	collision_layer = 4
	collision_mask = 0


func get_interaction_prompt(_player: Node) -> String:
	return "[E] Телефон"


func _on_interact(player: Node) -> void:
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("open_phone_journal"):
		world.call("open_phone_journal", player)
		return
	# Fallback for isolated tests without World host phone.
	var existing: Node = get_tree().get_first_node_in_group("phone_journal")
	if existing != null and existing.has_method("open"):
		existing.call("open", player)
		return
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	if packed == null:
		push_error("[PhoneInteractable] PhoneJournal scene missing")
		return
	var phone: Node = packed.instantiate()
	if phone == null:
		push_error("[PhoneInteractable] PhoneJournal instantiate failed")
		return
	phone.add_to_group("phone_journal")
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		push_error("[PhoneInteractable] no SceneTree")
		phone.free()
		return
	tree.root.add_child(phone)
	if phone.has_method("open"):
		phone.call("open", player)
