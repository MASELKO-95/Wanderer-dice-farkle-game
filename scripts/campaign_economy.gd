extends RefCounted

const STARTING_SILVER := 0
const PRICES := [40, 0, 80, 140, 240, 320, 400, 480]
const CAMPAIGN := preload("res://scripts/campaign_catalog.gd")

var silver := STARTING_SILVER
var active_wager := 0
var owned: Array[int] = [0, 6, 0, 0, 0, 0, 0, 0]
var loadout: Array[int] = [1, 1, 1, 1, 1, 1]


static func victory_reward(chapter_index: int, first_win: bool) -> int:
	if chapter_index < 0 or chapter_index >= CAMPAIGN.CHAPTERS.size():
		return 0
	return 150 + chapter_index * 25 if first_win else 50 + chapter_index * 10


func can_buy(type_index: int) -> bool:
	return type_index >= 0 and type_index < PRICES.size() and owned[type_index] < 6 and silver >= PRICES[type_index]


func place_wager(chapter_index: int, amount: int) -> bool:
	if CAMPAIGN.chapter(chapter_index).is_empty():
		return false
	if active_wager != 0 or amount < 0 or amount > silver or amount > CAMPAIGN.wager_limit(chapter_index):
		return false
	silver -= amount
	active_wager = amount
	return true


func settle_wager(won: bool) -> int:
	var payout := active_wager * 2 if won else 0
	active_wager = 0
	silver += payout
	return payout


func buy(type_index: int) -> bool:
	if not can_buy(type_index):
		return false
	silver -= PRICES[type_index]
	owned[type_index] += 1
	return true


func can_equip(slot: int, type_index: int) -> bool:
	if slot < 0 or slot >= 6 or type_index < 0 or type_index >= owned.size():
		return false
	return loadout[slot] == type_index or loadout.count(type_index) < owned[type_index]


func equip(slot: int, type_index: int) -> bool:
	if not can_equip(slot, type_index):
		return false
	loadout[slot] = type_index
	return true


func write_save(config: ConfigFile) -> void:
	config.set_value("campaign", "silver", silver)
	config.set_value("campaign", "owned_dice", owned)
	config.set_value("campaign", "loadout", loadout)


func read_save(config: ConfigFile, progress: int) -> void:
	active_wager = 0
	# Older saves receive the rewards for chapters already completed, once.
	var initial_silver := STARTING_SILVER
	for index in range(CAMPAIGN.clamped_progress(progress)):
		initial_silver += victory_reward(index, true)
	silver = maxi(0, int(config.get_value("campaign", "silver", initial_silver)))
	owned.assign([0, 6, 0, 0, 0, 0, 0, 0])
	var saved_owned: Variant = config.get_value("campaign", "owned_dice", [])
	if saved_owned is Array and saved_owned.size() == owned.size():
		for index in range(owned.size()):
			owned[index] = clampi(int(saved_owned[index]), 0, 6)
	owned[1] = 6
	loadout.assign([1, 1, 1, 1, 1, 1])
	var saved_loadout: Variant = config.get_value("campaign", "loadout", [])
	if saved_loadout is Array and saved_loadout.size() == 6:
		for slot in range(6):
			equip(slot, int(saved_loadout[slot]))
