class_name DateEpisodeView
extends RefCounted

var phase: DateTypes.DatePhase = DateTypes.DatePhase.OPENING
var episode_index: int = 0
var index_in_phase: int = 0
var situation: DateSituation
var base_options: Array[DateMoveOption] = []
var source_views: Array[DateMoveSourceView] = []