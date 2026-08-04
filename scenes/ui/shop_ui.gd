extends CanvasLayer
## Minimal shop panel: list, price, buy, stays open until closed.

const UiEscapeScript := preload("res://core/ui_escape.gd")

var _panel: PanelContainer
var _title: Label
var _money: Label
var _list: ItemList
var _buy_btn: Button
var _close_btn: Button
var _shop_id: String = ""
var _kind: String = "gift"
var _items: Array = []


func _ready() -> void:
	add_to_group("shop_ui")
	layer = UiLayers.SHOP
	visible = false
	_build()
	EventBus.notify.connect(_on_notify)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -220.0
	_panel.offset_top = -210.0
	_panel.offset_right = 220.0
	_panel.offset_bottom = 210.0
	root.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title)
	_money = Label.new()
	_money.add_theme_font_size_override("font_size", 14)
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_money)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 240)
	_list.item_selected.connect(_on_item_selected)
	_list.item_activated.connect(_on_item_activated)
	vbox.add_child(_list)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	_buy_btn = Button.new()
	_buy_btn.text = "Купить"
	_buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buy_btn.pressed.connect(_buy_selected)
	row.add_child(_buy_btn)
	_close_btn = Button.new()
	_close_btn.text = "Закрыть"
	_close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_btn.pressed.connect(close)
	row.add_child(_close_btn)


func _on_notify(message: String, kind: StringName) -> void:
	if kind != &"ui":
		return
	if message.begins_with("SHOP_OPEN:"):
		open(message.trim_prefix("SHOP_OPEN:"))


func open(shop_id: String) -> void:
	var catalog: Dictionary = DatePlaces.shop_catalog().get(shop_id, {})
	if catalog.is_empty():
		EventBus.toast("Магазин пуст", &"warn")
		return
	_shop_id = shop_id
	_kind = str(catalog.get("kind", "gift"))
	_items.clear()
	if _kind == "outfit":
		for raw_id in DatePlaces.clothing_shop_items():
			_items.append(str(raw_id))
	elif _kind == "homeware":
		_items.append("homeware_next")
	else:
		for raw_id in catalog.get("items", []):
			_items.append(str(raw_id))
	if _items.is_empty():
		EventBus.toast("Магазин пуст", &"warn")
		return
	_title.text = str(catalog.get("name", "Магазин"))
	_buy_btn.text = "Купить"
	_money.visible = true
	_refresh_list()
	UiLayers.raise_popup(self, UiLayers.SHOP)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _list.item_count > 0:
		_list.select(0)


func open_home_prep(kind: String) -> void:
	## Apartment fridge (food) / KitchenDrawers (drink) selection — reuses this list UI.
	var prep_kind: String = kind.strip_edges().to_lower()
	if prep_kind != "food" and prep_kind != "drink":
		EventBus.toast("Неизвестный тип выбора", &"warn")
		return
	var options: Array = DatePlaces.food_options() if prep_kind == "food" else DatePlaces.drink_options()
	_items.clear()
	for raw in options:
		var opt: Dictionary = raw as Dictionary
		var oid: String = str(opt.get("id", ""))
		if not oid.is_empty():
			_items.append(oid)
	if _items.is_empty():
		EventBus.toast("Пусто — нечего выбрать", &"warn")
		return
	_shop_id = "home_%s" % prep_kind
	_kind = "home_food" if prep_kind == "food" else "home_drink"
	_title.text = "Холодильник" if prep_kind == "food" else "Кухонные ящики"
	_buy_btn.text = "Взять"
	_money.visible = true
	_refresh_list()
	UiLayers.raise_popup(self, UiLayers.SHOP)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _list.item_count > 0:
		_list.select(0)


func close() -> void:
	if not visible:
		return
	visible = false
	_shop_id = ""
	_kind = "gift"
	_items.clear()
	_list.clear()
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh_list() -> void:
	var selected := _list.get_selected_items()
	var keep := selected[0] if not selected.is_empty() else 0
	_list.clear()
	match _kind:
		"outfit":
			for oid in _items:
				var def: Dictionary = ContentDB.outfit(StringName(oid))
				var price: float = float(def.get("price", def.get("cost", 20)))
				var owned: bool = Game.inventory.own_outfit(StringName(oid))
				var mark: String = "✓" if owned else "%.0f$" % price
				_list.add_item("%s — %s" % [str(def.get("name", oid)), mark])
				_list.set_item_metadata(_list.item_count - 1, oid)
		"homeware":
			var lvl: int = Game.dating.schedule.homeware_level
			if lvl >= 4:
				_list.add_item("Посуда уже максимальная")
				_list.set_item_metadata(0, "homeware_max")
			else:
				var costs: Array = [0, 25, 60, 120]
				var next: int = lvl + 1
				var price: float = float(costs[mini(next - 1, costs.size() - 1)])
				_list.add_item("Улучшить до «%s» — %.0f$" % [DatePlaces.homeware_label(next), price])
				_list.set_item_metadata(0, "homeware_next")
		"home_food":
			for fid in _items:
				var fopt: Dictionary = {}
				for raw_f in DatePlaces.food_options():
					var cand_f: Dictionary = raw_f as Dictionary
					if str(cand_f.get("id", "")) == str(fid):
						fopt = cand_f
						break
				var fblurb: String = str(fopt.get("blurb", ""))
				var flabel: String = str(fopt.get("name", fid))
				if fblurb != "":
					flabel = "%s — %s" % [flabel, fblurb]
				_list.add_item(flabel)
				_list.set_item_metadata(_list.item_count - 1, fid)
		"home_drink":
			for did in _items:
				var dopt: Dictionary = {}
				for raw_d in DatePlaces.drink_options():
					var cand_d: Dictionary = raw_d as Dictionary
					if str(cand_d.get("id", "")) == str(did):
						dopt = cand_d
						break
				var dblurb: String = str(dopt.get("blurb", ""))
				var dlabel: String = str(dopt.get("name", did))
				if dblurb != "":
					dlabel = "%s — %s" % [dlabel, dblurb]
				_list.add_item(dlabel)
				_list.set_item_metadata(_list.item_count - 1, did)
		_:
			for gid in _items:
				var gdef: Dictionary = ContentDB.gift(StringName(gid))
				var gprice: float = float(gdef.get("price", gdef.get("cost", 10)))
				var owned_n: int = Game.inventory.gift_count(StringName(gid))
				_list.add_item("%s — %.0f$  (у тебя: %d)" % [str(gdef.get("name", gid)), gprice, owned_n])
				_list.set_item_metadata(_list.item_count - 1, gid)
	if _kind == "home_food" or _kind == "home_drink":
		_money.text = "Выбери и возьми в руки"
	else:
		_money.text = "Баланс: $%d" % int(Game.economy.get_value(&"money"))
	if _list.item_count > 0:
		_list.select(clampi(keep, 0, _list.item_count - 1))


func _on_item_selected(_index: int) -> void:
	pass


func _on_item_activated(_index: int) -> void:
	_buy_selected()


func _buy_selected() -> void:
	var selected := _list.get_selected_items()
	if selected.is_empty():
		EventBus.toast("Выбери товар", &"info")
		return
	var item_id := StringName(str(_list.get_item_metadata(selected[0])))
	match _kind:
		"outfit":
			if Game.inventory.own_outfit(item_id):
				if Game.inventory.equip_outfit(item_id):
					EventBus.toast("Надето: %s" % str(ContentDB.outfit(item_id).get("name", item_id)), &"ok")
				_refresh_list()
				return
			if Game.inventory.buy_outfit(item_id):
				Game.inventory.equip_outfit(item_id)
				_refresh_list()
			else:
				EventBus.toast("Не хватает денег", &"warn")
				_refresh_list()
		"homeware":
			if str(item_id) == "homeware_max":
				EventBus.toast("Посуда уже лучшая", &"info")
				return
			if Game.dating.schedule.upgrade_homeware():
				_refresh_list()
			else:
				_refresh_list()
		"home_food":
			InteractionRouter.route(&"take_food", self, self, {"food_id": str(item_id)})
			close()
		"home_drink":
			InteractionRouter.route(&"take_drink", self, self, {"drink_id": str(item_id)})
			close()
		_:
			if Game.inventory.buy_gift(item_id):
				Game.quests.complete("s1_money")
				_refresh_list()
			else:
				EventBus.toast("Не хватает денег", &"warn")
				_refresh_list()
