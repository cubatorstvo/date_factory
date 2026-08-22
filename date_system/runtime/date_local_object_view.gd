class_name DateLocalObjectView
extends RefCounted

var object_id: StringName = &""
var display_name: String = ""
var used: bool = false
var options: Array[DateMoveOption] = []


static func grouped_from_options(options: Array[DateMoveOption]) -> Array[DateLocalObjectView]:
	var views: Array[DateLocalObjectView] = []
	var index_by_id: Dictionary = {}
	for option in options:
		if option == null:
			continue
		var object_id: StringName = option.local_object_id
		if object_id == &"":
			object_id = StringName("_move_%s" % String(option.move_id))
		var view: DateLocalObjectView
		if index_by_id.has(object_id):
			view = views[int(index_by_id[object_id])]
		else:
			view = DateLocalObjectView.new()
			view.object_id = option.local_object_id
			view.display_name = option.local_object_display_name
			if view.display_name.is_empty():
				view.display_name = String(option.local_object_id)
			index_by_id[object_id] = views.size()
			views.append(view)
		view.options.append(option)
		if option.availability == DateTypes.MoveAvailability.USED:
			view.used = true
	return views