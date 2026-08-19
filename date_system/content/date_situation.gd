class_name DateSituation
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var situation_text: String = ""
@export var enabled: bool = true
@export var allowed_phases: Array[int] = []
@export var weight: float = 1.0
@export var custom_episode_scene: PackedScene
@export var custom_logic_script: Script


func allows_phase(phase: DateTypes.DatePhase) -> bool:
	return allowed_phases.has(int(phase))
