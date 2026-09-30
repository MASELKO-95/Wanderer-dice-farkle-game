extends RefCounted

const RULES := preload("res://scripts/campaign_chronicles.gd")
const PATH := "user://achievements.cfg"
const ITEMS := [
	{"id":"first_table","name":"Pierwszy stolik","description":"Rozegraj mecz z Tomkiem Brzuchem."},
	{"id":"six_tables","name":"Cały dziedziniec","description":"Wygraj wszystkie sześć pobocznych pojedynków."},
	{"id":"rescue","name":"Otwarte drzwi","description":"Uwolnij Elarę z wieży."},
	{"id":"king","name":"Korona i obowiązek","description":"Pokonaj Marszałka."},
	{"id":"emperor","name":"Jedno cesarstwo","description":"Pokonaj Magnusa."},
	{"id":"mother","name":"Choćby na zupę","description":"Pojednaj się z Matyldą, wygrywając jej próbę."},
	{"id":"champion","name":"Kości milczą","description":"Pokonaj Aureliusza."},
	{"id":"finished","name":"Własna kronika","description":"Wybierz zakończenie kampanii."},
	{"id":"clean_run","name":"Czyste ręce, zwykłe kości","description":"Ukończ kampanię bez zakupu kości, zakładów i zmiany wyniku konsolą."},
	{"id":"shadow","name":"Korona Cienia","description":"Zejdź z galerii i dołącz do drugiego dworu.","hidden":true}
]
var unlocked: Dictionary = {}

func read_save() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		var saved = config.get_value("achievements","unlocked",{})
		if saved is Dictionary:
			unlocked = saved.duplicate(true)

func evaluate(state: Dictionary, ending: String) -> Array[String]:
	var added: Array[String] = []
	if state.get("console_used",false):
		return added
	var candidates := {
		"first_table": state.has("first_result"),
		"six_tables": state.get("side_wins",[]).size() == 6,
		"rescue": state.get("elara_wolna",false),
		"king": state.get("zostal_krolem",false),
		"emperor": state.get("zostal_cesarzem",false),
		"mother": state.get("matka_pogodzona",false),
		"champion": state.get("mistrz_swiata",false),
		"finished": not ending.is_empty(),
		"clean_run": not ending.is_empty() and RULES.clean_run(state),
		"shadow": ending == "shadow"
	}
	for id in candidates:
		if candidates[id] and not unlocked.has(id):
			unlocked[id] = Time.get_datetime_string_from_system()
			added.append(id)
	if not added.is_empty():
		var config := ConfigFile.new()
		config.set_value("achievements","unlocked",unlocked)
		if config.save(PATH + ".tmp") == OK:
			DirAccess.rename_absolute(PATH + ".tmp",PATH)
	return added
