extends SceneTree

const ECONOMY := preload("res://scripts/campaign_economy.gd")
var failures := 0


func _init() -> void:
	var wallet := ECONOMY.new()
	check(wallet.silver == 0 and wallet.loadout == [1, 1, 1, 1, 1, 1], "penniless peasant starting inventory")
	check(not wallet.buy(0), "no purchases before earning silver")
	check(not wallet.place_wager(0, 1), "cannot wager without silver")
	check(wallet.place_wager(0, 0) and wallet.settle_wager(true) == 0, "free play remains possible")
	wallet.silver = 100
	check(not wallet.place_wager(0, 1), "first opponent never accepts wagers")
	check(not wallet.place_wager(2, 10), "opponent without betting rejects stake")
	check(not wallet.place_wager(1, 101) and not wallet.place_wager(0, -1), "opponent limit and negative stake")
	check(wallet.place_wager(1, 25) and wallet.silver == 75, "stake debited once")
	check(not wallet.place_wager(1, 25), "cannot place a second active stake")
	check(wallet.settle_wager(true) == 50 and wallet.silver == 125, "win returns two times stake, including stake")
	check(wallet.settle_wager(true) == 0 and wallet.silver == 125, "no duplicate payout")
	check(wallet.place_wager(1, 100) and wallet.silver == 25, "different opponent accepts larger stake")
	check(wallet.settle_wager(false) == 0 and wallet.silver == 25, "loss forfeits stake")
	check(wallet.place_wager(1, 25), "place wager before leaving")
	var wager_save := ConfigFile.new()
	wallet.write_save(wager_save)
	var reloaded := ECONOMY.new()
	reloaded.read_save(wager_save, 0)
	check(reloaded.silver == 0 and reloaded.active_wager == 0 and reloaded.settle_wager(true) == 0, "reloading cannot recover or pay abandoned wager")
	wallet.silver = 200
	check(not wallet.buy(-1) and not wallet.buy(8), "invalid purchases rejected")
	check(not wallet.buy(4) and wallet.silver == 200, "insufficient funds do not change balance")
	check(wallet.buy(3) and wallet.silver == 60 and wallet.owned[3] == 1, "purchase charges one die")
	check(wallet.equip(0, 3) and not wallet.equip(1, 3), "a single die cannot fill two slots")
	check(not wallet.equip(-1, 3) and not wallet.equip(6, 3) and not wallet.equip(0, 8), "invalid equipment rejected")
	check(wallet.equip(0, 1) and wallet.equip(1, 3), "unequipping releases the die")
	wallet.silver = 10000
	for index in range(5):
		check(wallet.buy(3), "multiple copies can be bought")
	var before: int = wallet.silver
	check(not wallet.buy(3) and wallet.silver == before and wallet.owned[3] == 6, "six-copy limit")
	for slot in range(6):
		check(wallet.equip(slot, 3), "six owned copies can fill all slots")
	var config := ConfigFile.new()
	wallet.write_save(config)
	check(config.save("user://economy_test.cfg") == OK, "save file written")
	var disk := ConfigFile.new()
	check(disk.load("user://economy_test.cfg") == OK, "save file loaded")
	var restored := ECONOMY.new()
	restored.read_save(disk, 0)
	check(restored.silver == wallet.silver and restored.owned == wallet.owned and restored.loadout == wallet.loadout, "full save round trip")
	var legacy := ECONOMY.new()
	legacy.read_save(ConfigFile.new(), 2)
	check(legacy.silver == 325, "old saves receive completed chapter rewards")
	legacy.write_save(config)
	legacy.read_save(config, 2)
	check(legacy.silver == 325, "migration does not award twice")
	config.set_value("campaign", "silver", -10)
	config.set_value("campaign", "owned_dice", [0, 0, 0, 1, 0, 0, 0, 0])
	config.set_value("campaign", "loadout", [3, 3, -1, 99, 4, 1])
	restored.read_save(config, 0)
	check(restored.silver == 0 and restored.loadout == [3, 1, 1, 1, 1, 1] and restored.owned[1] == 6, "invalid save inventory repaired")
	check(ECONOMY.victory_reward(0, true) == 150 and ECONOMY.victory_reward(0, false) == 50, "first and repeat win rewards")
	check(ECONOMY.victory_reward(11, true) == 425 and ECONOMY.victory_reward(12, true) == 0, "last and invalid chapter rewards")
	if failures == 0:
		print("PASS: campaign purchases, ownership, equipment, rewards, save and migration")
	quit(0 if failures == 0 else 1)


func check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: " + message)
		failures += 1
