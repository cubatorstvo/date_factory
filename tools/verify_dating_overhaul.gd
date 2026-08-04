extends SceneTree
## Headless static checks for dating overhaul wiring (no autoload Game/EventBus).

func _init() -> void:
	var fails: PackedStringArray = PackedStringArray()
	var stage_src := FileAccess.get_file_as_string("res://scenes/dating/date_stage.gd")
	if not stage_src.contains("APARTMENT_VISUAL_SCENE"):
		fails.append("DateStage missing APARTMENT_VISUAL_SCENE")
	if not stage_src.contains("_add_backdrop(_root, _place_id)"):
		fails.append("DateStage does not pass place_id to backdrop")
	if stage_src.contains("func _add_backdrop(parent: Node3D) -> void:"):
		fails.append("DateStage still has restaurant-only _add_backdrop signature")
	if not stage_src.contains("ApartmentVisual"):
		fails.append("DateStage never names ApartmentVisual")
	if not ResourceLoader.exists("res://scenes/ui/shop_ui.gd"):
		fails.append("shop_ui.gd missing")
	var shop_src := FileAccess.get_file_as_string("res://scenes/ui/shop_ui.gd")
	if not shop_src.contains("shop_ui"):
		fails.append("shop_ui missing group")
	if not shop_src.contains("func open("):
		fails.append("shop_ui missing open()")
	var router_src := FileAccess.get_file_as_string("res://modules/interaction/interaction_router.gd")
	if not router_src.contains("skip_to_minutes"):
		fails.append("router missing early restaurant time skip")
	if not router_src.contains("shop_ui"):
		fails.append("router not wired to shop_ui")
	var shop_fn := router_src.find("func _open_shop_menu")
	if shop_fn >= 0:
		var chunk := router_src.substr(shop_fn, 700)
		if chunk.contains("open_runtime_event"):
			fails.append("shop still opens via event UI")
	var dating_src := FileAccess.get_file_as_string("res://modules/dating/dating_api.gd")
	if not dating_src.contains("_toast_factor_breakdown"):
		fails.append("dating_api missing factor toast")
	if not dating_src.contains("\"optional\":"):
		fails.append("gift factor missing optional flag")
	var places_src := FileAccess.get_file_as_string("res://modules/dating/date_places.gd")
	if not places_src.contains("\"id\": \"home\"") or not places_src.contains("\"id\": \"restaurant\""):
		fails.append("DatePlaces missing home/restaurant")
	var apt := FileAccess.get_file_as_string("res://scenes/world/vertical_slice/apartment.tscn")
	if not apt.contains("GirlSeat") or not apt.contains("HeroSeat") or not apt.contains("GirlEntrance"):
		fails.append("apartment missing date markers")
	var main_src := FileAccess.get_file_as_string("res://scenes/boot/main.gd")
	if not main_src.contains("shop_ui.gd"):
		fails.append("main.gd does not spawn ShopUI")
	if fails.is_empty():
		print("DATING_OVERHAUL_VERIFY_OK")
		quit(0)
	else:
		print("DATING_OVERHAUL_VERIFY_FAIL:")
		for f in fails:
			print(" - ", f)
		quit(1)
