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
var _items: Array = []


func _ready() -> void:
	add_to_group("shop_ui")
	layer = 25
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
	_items.clear()
	for raw_id in catalog.get("items", []):
		_items.append(str(raw_id))
	_title.text = str(catalog.get("name", "Магазин"))
	_refresh_list()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _list.item_count > 0:
		_list.select(0)


func close() -> void:
	if not visible:
		return
	visible = false
	_shop_id = ""
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
	for gid in _items:
		var def: Dictionary = ContentDB.gift(StringName(gid))
		var price: float = float(def.get("price", def.get("cost", 10)))
		var owned: int = Game.inventory.gift_count(StringName(gid))
		_list.add_item("%s — %.0f$  (у тебя: %d)" % [str(def.get("name", gid)), price, owned])
		_list.set_item_metadata(_list.item_count - 1, gid)
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
	var gid := StringName(str(_list.get_item_metadata(selected[0])))
	if Game.inventory.buy_gift(gid):
		Game.quests.complete("s1_money")
		_refresh_list()
	else:
		EventBus.toast("Не хватает денег", &"warn")
		_refresh_list()
