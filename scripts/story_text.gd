extends RefCounted

# Polish is the source language. Unfinished locales deliberately use English.
static var locale := "pl"
static var _english: Dictionary = {}
const TEXT_FIELDS := ["name", "narrator", "speech", "text", "reply", "victory", "defeat", "before", "choice_speaker", "intro", "description"]

static func text(source: String) -> String:
	if locale == "pl":
		return source
	if _english.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://translation/story_en.json"))
		if parsed is Dictionary:
			_english = parsed
	return str(_english.get(source, source))

static func localize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = value.duplicate(true)
		for key in result:
			if key in TEXT_FIELDS and result[key] is String:
				result[key] = text(result[key])
			elif result[key] is Dictionary or result[key] is Array:
				result[key] = localize(result[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(localize(item))
		return result
	return value
