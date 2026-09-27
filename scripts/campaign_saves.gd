extends RefCounted

const SLOT_COUNT := 6

static func path(slot: int) -> String:
	return "user://campaign_slot_%d.cfg" % (slot + 1)

static func read_slot(slot: int) -> ConfigFile:
	if slot < 0 or slot >= SLOT_COUNT:
		return null
	var config := ConfigFile.new()
	return config if config.load(path(slot)) == OK else null

static func write_slot(slot: int, config: ConfigFile) -> Error:
	if slot < 0 or slot >= SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	config.set_value("campaign", "updated", Time.get_datetime_string_from_system(false, true))
	var temporary := path(slot) + ".tmp"
	var result := config.save(temporary)
	if result != OK:
		return result
	return DirAccess.rename_absolute(temporary, path(slot))
