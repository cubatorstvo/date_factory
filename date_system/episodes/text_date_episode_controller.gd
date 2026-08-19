class_name TextDateEpisodeController
extends DateEpisodeController

var _title: Label
var _body: RichTextLabel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	_title = Label.new()
	_title.theme_type_variation = "HeaderSmall"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	box.add_child(_body)


func start_episode() -> void:
	if situation != null:
		_title.text = situation.display_name
		_body.text = situation.situation_text
	super.start_episode()
