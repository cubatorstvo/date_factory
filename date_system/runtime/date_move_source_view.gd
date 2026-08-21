class_name DateMoveSourceView
extends RefCounted

var source: DateTypes.DateMoveSource = DateTypes.DateMoveSource.CHARACTERISTIC
var display_name: String = ""
var visible: bool = false
var used: bool = false
var state: DateTypes.DateMoveSourceState = DateTypes.DateMoveSourceState.BLOCKED
var options: Array[DateMoveOption] = []
