class_name DialogueSequence
extends Resource

@export var title: String = ""
@export var title_key: String = ""
@export var allow_skip := true
@export var lines: Array[Resource] = []
@export_category("Gałęzie kampanii")
@export var intro_lines: Array[Resource] = []
@export var victory_lines: Array[Resource] = []
@export var defeat_lines: Array[Resource] = []
