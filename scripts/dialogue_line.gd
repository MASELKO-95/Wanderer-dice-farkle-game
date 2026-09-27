class_name DialogueLine
extends Resource

@export_category("Tekst")
@export var speaker: String = ""
@export var speaker_key: String = ""
@export_multiline var text: String = ""
@export var text_key: String = ""

@export_category("Postać")
@export var portrait_id: String = ""
@export_enum("left", "right", "narrator") var portrait_side: String = "left"

@export_category("Wyświetlanie")
@export_enum("tavern", "royal", "forest") var backdrop: String = "tavern"
@export_range(10.0, 120.0, 1.0) var characters_per_second: float = 42.0

@export_category("Wybory")
@export var choices: Array[Resource] = []

@export var next_line_index: int = -1
@export var illustration: Texture2D
