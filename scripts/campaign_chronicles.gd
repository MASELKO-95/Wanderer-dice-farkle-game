extends RefCounted

const STORY_TEXT := preload("res://scripts/story_text.gd")

const CATALOG := preload("res://scripts/campaign_catalog.gd")
const OPENING := preload("res://scripts/campaign_opening.gd")
const SEQUENCE := preload("res://scripts/dialogue_sequence.gd")
const ROUTES := ["princess", "king", "emperor", "world_champion"]
const TITLES := {"princess": "Księżniczka — wygodne życie", "king": "Uczciwa korona", "emperor": "Cesarz", "world_champion": "Mistrz Świata", "shadow": "Korona Cienia"}
const REASONS := {"theft": "kradziez", "violence": "pobicie", "laziness": "lenistwo", "gluttony": "obzarstwo", "greed": "chciwosc"}
const REASON_TEXT := {"kradziez": "kradzież", "pobicie": "pobicie", "lenistwo": "lenistwo", "obzarstwo": "obżarstwo", "chciwosc": "chciwość"}
const REASON_POINTS := {"theft": [1,-1,-1,1], "violence": [-1,-1,1,1], "laziness": [1,-1,-1,-2], "gluttony": [1,1,0,-1], "greed": [-1,1,1,1]}
static var _data: Dictionary = {}

static func data(index: int) -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://dialogues/chronicles.json"))
		if parsed is Dictionary:
			_data = parsed
	return STORY_TEXT.localize(_data.get(str(index), {}))

static func initialize(state: Dictionary, progress: int, old_save := false) -> void:
	if int(state.get("chronicles_version", 0)) >= 2:
		return
	state["chronicles_version"] = 2
	state["clean_history_known"] = not old_save
	state["dice_purchases"] = 0
	state["liczba_zakladow"] = 0
	state["events"] = {}
	state["decisions"] = {}
	state["passed"] = {}
	state["losses"] = {}
	state["side_wins"] = []
	if not state.has("ending_points"):
		state["ending_points"] = {"princess": 0, "king": 0, "emperor": 0, "world_champion": 0}
	# No old story progress is removed. New optional content stays replayable.
	if progress > 1:
		state.passed["12"] = true
		state.side_wins = [0, 1, 2, 3, 4, 5]
	if progress > 2:
		state.passed["13"] = true
	if progress >= 12:
		state.passed["14"] = true
	for pair in [[2,"pieczec"],[3,"dwor"],[4,"sekret"],[5,"klucz"],[6,"elara_wolna"],[7,"zaufanie_elary"],[8,"zostal_krolem"],[9,"szlaki"],[10,"zostal_cesarzem"],[11,"droga_do_finalu"],[12,"mistrz_swiata"]]:
		if progress >= pair[0]:
			state[pair[1]] = true
	for index in range(progress):
		state.events["win:%d" % index] = true

static func name(index: int) -> String:
	return STORY_TEXT.text(str(data(index).get("name", CATALOG.chapter(index).get("name", ""))))

static func passed(state: Dictionary, index: int) -> bool:
	return bool(state.get("passed", {}).get(str(index), false))

static func next_encounter(progress: int, state: Dictionary) -> int:
	if state.get("finished", false) or progress >= 12:
		return -1
	if progress == 1:
		for side in range(CATALOG.SIDE_TABLES.size()):
			if side not in state.get("side_wins", []):
				return 100 + side
		if not passed(state, 12):
			return 12
	if progress == 2 and not passed(state, 13):
		return 13
	if progress == 11 and not passed(state, 14):
		return 14
	return progress

static func can_enter(index: int, progress: int, state: Dictionary) -> bool:
	if state.get("finished", false):
		return false
	if index >= 100 and index < 106:
		if progress < 1:
			return false
		for requirement in CATALOG.SIDE_TABLES[index - 100].requires:
			if requirement not in state.get("side_wins", []):
				return false
		return true
	if index == 12:
		return progress >= 1 and state.get("side_wins", []).size() == 6
	if index == 13:
		return progress >= 2 and bool(state.get("pieczec", false))
	if index == 14:
		return progress >= 11
	if not CATALOG.can_play(index, progress):
		return false
	if index == 1 and (not passed(state, 12) or state.get("side_wins", []).size() < 6):
		return false
	if index == 2 and (not passed(state, 13) or not state.get("pieczec", false)):
		return false
	if index == 11 and not passed(state, 14):
		return false
	return true

static func points_once(state: Dictionary, event: String, values: Array) -> bool:
	if not state.has("events"):
		state.events = {}
	if state.events.has(event):
		return false
	state.events[event] = true
	if not state.has("ending_points"):
		state.ending_points = {}
	for i in range(4):
		state.ending_points[ROUTES[i]] = int(state.ending_points.get(ROUTES[i], 0)) + int(values[i])
	return true

static func apply_choice(state: Dictionary, index: int, section: String, option: Dictionary) -> int:
	var group := "%d:%s" % [index, section]
	if not state.has("decisions"):
		state.decisions = {}
	if state.decisions.has(group):
		return 0
	state.decisions[group] = str(option.id)
	points_once(state, "choice:" + group, option.get("points", [0,0,0,0]))
	for key in option.get("flags", {}):
		state[key] = option.flags[key]
	if index == 14 and option.id == "pokoj" and state.get("powod", "") == "lenistwo":
		points_once(state, "matka_lenistwo", [1,0,0,0])
	return int(option.get("silver", 0))

static func record_wager(state: Dictionary, amount: int) -> void:
	if amount <= 0:
		return
	state["liczba_zakladow"] = int(state.get("liczba_zakladow", 0)) + 1
	points_once(state, "wager:%d" % state.liczba_zakladow, [0,-2,1,1])

static func record_result(state: Dictionary, index: int, won: bool) -> Dictionary:
	var result := {"reward": 0, "advance": false}
	if index >= 100:
		var side: Array = state.get("side_wins", [])
		if won and index - 100 not in side:
			side.append(index - 100)
			state["side_wins"] = side
			result.reward = CATALOG.SIDE_TABLES[index - 100].reward
		return result
	var chapter := data(index)
	if chapter.is_empty():
		return result
	var event := ("win:" if won else "loss:") + str(index)
	var first := points_once(state, event, chapter.win_points if won else chapter.loss_points)
	if won:
		result.reward = int(chapter.reward) if first else 50 + index * 10 if index < 12 else 0
		for key in chapter.win_flags:
			state[key] = chapter.win_flags[key]
		if index == 6 and state.get("elara", "") == "obojetnosc":
			state.zaufanie_elary = "kruche"
		result.advance = true
	else:
		if not state.has("losses"):
			state.losses = {}
		state.losses[str(index)] = int(state.losses.get(str(index), 0)) + 1
		if index == 1:
			state["przegral_z_cieniem"] = true
		if index in [0,12]:
			result.advance = true
		if index in [3,14] and int(state.losses[str(index)]) >= 2:
			points_once(state, "mercy:" + str(index), [1,0,-1,-1] if index == 3 else [1,0,0,0])
			result.advance = true
			state["mercy_" + str(index)] = true
			if index == 3:
				state.merge({"sekret":true,"wieza":"zachodnia","klucz":"blazen"}, true)
	if index == 0 and not state.has("first_result"):
		state.first_result = "victory" if won else "defeat"
	if result.advance:
		if not state.has("passed"):
			state.passed = {}
		state.passed[str(index)] = true
	return result

static func endings(state: Dictionary, stage := "final") -> Array[String]:
	var result: Array[String] = []
	var p: Dictionary = state.get("ending_points", {})
	if stage == "king":
		if int(p.get("king",0)) >= 6 or state.get("elara", "") == "prawo":
			result.append("king")
		if state.get("elara", "") == "wygoda":
			result.append("princess")
		return result
	if stage == "emperor":
		if int(p.get("emperor",0)) >= 7 or state.get("magnus", "") == "podboj":
			result.append("emperor")
		if int(p.get("princess",0)) >= 8 or state.get("elara", "") == "wygoda":
			result.append("princess")
		return result
	for route in ROUTES:
		if int(p.get(route,0)) >= 8:
			result.append(route)
	for pair in [["princess",state.get("elara", "") == "wygoda"],["king",state.get("zostal_krolem",false) and int(p.get("king",0)) >= 6],["emperor",state.get("zostal_cesarzem",false) and int(p.get("emperor",0)) >= 7],["world_champion",state.get("mistrz_swiata",false) and state.get("elara", "") == "obojetnosc"]]:
		if pair[1] and pair[0] not in result:
			result.append(pair[0])
	if result.is_empty():
		var highest := -2147483648
		for route in ROUTES:
			highest = maxi(highest, int(p.get(route,0)))
		for route in ROUTES:
			if int(p.get(route,0)) == highest:
				result.append(route)
	if state.get("pomogl_zlodziejowi",false) and state.get("sojusz_vespera",false):
		result.append("shadow")
	return result

static func clean_run(state: Dictionary) -> bool:
	return bool(state.get("clean_history_known", false)) and int(state.get("dice_purchases",0)) == 0 and int(state.get("liczba_zakladow",0)) == 0 and not state.get("console_used",false)

static func option(state: Dictionary, index: int, section: String, id: String) -> Dictionary:
	for value in options(state,index,section):
		if str(value.id) == id:
			return value
	return {}

static func options(state: Dictionary, index: int, section: String) -> Array:
	var source: Array = data(index).get("post" if section == "victory" else "choices", [])
	var result: Array = []
	for value in source:
		if not value.has("requires") or state.get(str(value.requires), false):
			result.append(value)
	return result

static func _line(text: String, index: int, speaker := "") -> Resource:
	var line := OPENING.line(text, speaker if not speaker.is_empty() else name(index))
	var chapter := CATALOG.chapter(index)
	line.backdrop = chapter.get("theme", "tavern")
	if line.speaker != "Narrator":
		line.portrait_id = chapter.get("avatar", "procedural")
		line.portrait_side = "left"
	return line

static func build(index: int, section: String, state: Dictionary) -> Resource:
	var sequence := SEQUENCE.new()
	sequence.title = STORY_TEXT.text("Kroniki Kostek — ") + name(index)
	var lines: Array[Resource] = []
	if index >= 100:
		var side: Dictionary = CATALOG.SIDE_TABLES[index - 100]
		lines.append(_line(side.intro if section == "intro" else side.victory if section == "victory" else STORY_TEXT.text("«Dziś szczęście przy mnie. Wróć, stół nigdzie nie odjedzie.»"), index))
		sequence.lines = lines
		return sequence
	var chapter := data(index)
	if section == "intro":
		lines.append(_line(chapter.narrator,index,"Narrator"))
		var speech: String = chapter.speech.replace("{powod}", STORY_TEXT.text(REASON_TEXT.get(state.get("powod",""),STORY_TEXT.text("dawne wybryki"))))
		if index == 13:
			speech += STORY_TEXT.text(" Ojciec pamięta twoją pomoc.") if state.get("pomogl_zlodziejowi",false) else STORY_TEXT.text(" Ojciec ci nie ufa. Ja też jeszcze nie.")
			if state.get("przegral_z_cieniem",false):
				speech += STORY_TEXT.text(" Wiem też o przegranej przy jego stole. Tutaj zaczynamy od nowa.")
		lines.append(_line(speech,index,chapter.get("choice_speaker",name(index))))
	else:
		lines.append(_line(chapter.get(section,""),index))
	var choices := options(state,index,section) if section in ["intro","victory"] else []
	var group := "%d:%s" % [index,section]
	var previous := str(state.get("decisions",{}).get(group,""))
	if not previous.is_empty():
		for item in choices:
			if item.id == previous:
				lines.append(_line(item.reply,index,chapter.get("choice_speaker",name(index)) if section == "intro" else name(index)))
	elif not choices.is_empty():
		var question: Resource = lines[-1]
		var replies: Array[Resource] = []
		for item in choices:
			var choice := OPENING.choice(str(item.id),str(item.text),lines.size())
			question.choices.append(choice)
			var reply := _line(str(item.reply),index,chapter.get("choice_speaker",name(index)) if section == "intro" else name(index))
			if index == 14 and item.id == "pokoj" and state.get("powod","") == "lenistwo":
				reply.text += STORY_TEXT.text(" Do południa nadal nie wstajesz. Ale łóżko lepsze. Bóg mi świadkiem, że to już sukces.")
			lines.append(reply)
			replies.append(reply)
		for reply in replies:
			reply.next_line_index = lines.size()
	if section == "intro":
		lines.append(_line(chapter.get("before",STORY_TEXT.text("Siadaj. Niech kości przemówią.")),index))
	elif section == "victory":
		if index == 5:
			lines.append(_line(STORY_TEXT.text("Drzwi. Elara mruży oczy do światła, jak ktoś, kto nie prosił ani o klatkę, ani o wybawcę — tylko o dzień."),index,"Narrator"))
			var elara := _line(STORY_TEXT.text("Najpierw powietrze. Potem pogadamy o tym, czy jesteś ratunkiem, czy następną wieżą."),6)
			lines.append(elara)
		elif index == 6:
			var words: Dictionary = {"wygoda":STORY_TEXT.text("I nie stań za długo. Ogród potrzebuje kogoś, kto umie nic nie robić w sposób, który nie niszczy kwiatów."),"obojetnosc":STORY_TEXT.text("Wygrywaj. Nie będę czekać przy bramie."),"ambicja":STORY_TEXT.text("Patrzę. Na razie.")}
			lines.append(_line(words.get(state.get("elara",""),STORY_TEXT.text("Idź. Będę na galerii.")),index))
		elif index == 10:
			lines.append(_line(bard_song(state),index))
		else:
			lines.append(_line(STORY_TEXT.text("Kości milkną. Droga prowadzi dalej."),index,"Narrator"))
	elif state.get("mercy_" + str(index),false):
		lines.append(_line(STORY_TEXT.text("Idź do błazna i tak. Zmęczyło mnie twoje szczęście.") if index == 3 else STORY_TEXT.text("Idź. Zupa poczeka. Mnich nie."),index))
	sequence.lines = lines
	return sequence

static func bard_song(state: Dictionary) -> String:
	if state.get("piesn_cienia",false):
		return STORY_TEXT.text("Południe. A gdy tłum będzie krzyczał twoje imię — zejdź w aleję. Vespera nie klaszcze. Ona otwiera drzwi.")
	var route := str(state.get("lucjan",""))
	if route.is_empty():
		var points: Dictionary = state.get("ending_points",{})
		route = ROUTES[0]
		for candidate in ROUTES:
			if int(points.get(candidate,0)) > int(points.get(route,0)):
				route = candidate
		if state.get("elara","") == "wygoda":
			route = "princess"
	return {"princess":STORY_TEXT.text("Idź na południe. Aureliusz gra w klasztorze bez dzwonów. Potem wróć, bo ktoś musi doglądać ognia, a Elara nie zdąży wszędzie."),"king":STORY_TEXT.text("Południe. Klasztor. Po nim — wróć podpisywać, nie pozować."),"emperor":STORY_TEXT.text("Południe. Pokonaj mnicha. Świat lubi mieć pana z imieniem."),"world_champion":STORY_TEXT.text("Południe. Tam jest stół, którego chcesz. Reszty nie śpiewam.")}.get(route,"")

static func epilogue(ending: String, state: Dictionary) -> Resource:
	var sequence := SEQUENCE.new()
	sequence.title = STORY_TEXT.text(TITLES.get(ending,STORY_TEXT.text("Kroniki Kostek")))
	var lines: Array[Resource] = []
	match ending:
		"princess":
			lines.append(_line(STORY_TEXT.text("Dobrze. Ja mapy, sądy i listy. Ty ogród, kuchnię i kości z kucharzem. Królestwo Kości będzie syte, ciche i dziwnie łaskawe. Kronikarze napiszą o mądrej królowej. O tobie — mniej. I bardzo ci to odpowiada."),6))
			lines.append(_line(STORY_TEXT.text("[Wybrałeś|Wybrałaś] Elarę i wygodę. Nie [zostałeś bohaterem|zostałaś bohaterką]. [Zostałeś człowiekiem|Zostałaś osobą], której się nie chce — i której wreszcie wolno. Elara rządzi sprawiedliwie. Ty żyjesz. To też jest zwycięstwo, tylko cichsze."),6,"Narrator"))
			if state.get("matka_pogodzona",false):
				lines.append(_line(STORY_TEXT.text("Matylda przychodzi na zupę co pierwszy dzień miesiąca i mówi, że łóżko wprawdzie królewskie, ale wstawanie nadal słabe."),14,"Narrator"))
		"king":
			lines.append(_line(STORY_TEXT.text("Prawo jedno. Cła jedne. Łapówki — do rowu. Zakładów na dworze nie będzie, bo król nie uczy ludu, że korona to kości."),6 if state.get("zaufanie_elary",false) else 7))
			lines.append(_line(STORY_TEXT.text("Nie jesteś [leniwy|leniwa]. Nie jesteś [chciwy|chciwa]. Nie idziesz po trupach. Rządzisz według stołu i ustawy. Elara jest u boku jako równa, nie jako puchar — albo jako sędzia, jeśli nie chciała ręki. Ludzie narzekają, że korona za mało błyszczy. Błyszczą za to sądy."),7,"Narrator"))
			if state.get("aldryk_los","") == "oszczedzony":
				lines.append(_line(STORY_TEXT.text("Były król pisze komentarze do ustaw na marginesie i milczy na ucztach. To też jest litość."),5,"Narrator"))
			if int(state.get("liczba_zakladow",0)) == 0:
				lines.append(_line(STORY_TEXT.text("Ani razu nie [postawiłeś|postawiłaś] srebra o duszę. Kronika to podkreśla."),7,"Narrator"))
		"emperor":
			lines.append(_line(STORY_TEXT.text("[Zjednoczyłeś|Zjednoczyłaś]. Pokój boli po twojemu. Ja przynajmniej wiem, kto trzyma nóż."),9))
			lines.append(_line(STORY_TEXT.text("Nie [bałeś|bałaś] się umoczyć rąk. [Kupiłeś|Kupiłaś], [zagroziłeś|zagroziłaś], [postawiłeś|postawiłaś] srebro, gdy prawo było za wolne. Królestwa są jedne. Twoje imię jest głośne. Śpisz krótko. To cena."),9,"Narrator"))
			lines.append(_line(STORY_TEXT.text("Elara opuszcza galerię. Nie chce być kolejną zdobytą koroną.") if state.get("elara","") in ["obojetnosc","ambicja"] else STORY_TEXT.text("Elara patrzy z galerii. Pamięta każdy stopień tej drogi."),6,"Narrator"))
			if state.get("brudne_rece",false) and state.get("magnus_los","") == "wygnany":
				lines.append(_line(STORY_TEXT.text("W alejach Vespera unosi brew: cesarz, który zna piwnicę, jest groźniejszy niż cesarz, który zna tylko tron."),13,"Narrator"))
		"world_champion":
			lines.append(_line(STORY_TEXT.text("Idź. Kobiet, koron i map nie bierzesz. To ubóstwo. To wolność. To prawie to samo."),11))
			lines.append(_line(STORY_TEXT.text("[Odrzuciłeś|Odrzuciłaś] koronę. Księżniczka, kobiety, cesarstwo — tło. Zakład jest językiem stołu, nie powodem do wstydu. Wędrujesz. Ani razu nie przyjmujesz przegranej do legendy. Lucjan śpiewa o tobie za dużo. Ty nie słuchasz."),11,"Narrator"))
			if state.get("elara","") == "obojetnosc":
				lines.append(_line(STORY_TEXT.text("Elara nie czeka przy bramie. Kazała nie czekać. Dotrzymała."),6,"Narrator"))
			lines.append(_line(STORY_TEXT.text("Przy misce kaszy Aureliusz pokazuje stary bilet. Ten sam staruszek wypisał kiedyś na nim jego imię. Dwie drogi zaczęły się przy jednym garnku."),11,"Narrator"))
		"shadow":
			lines.append(_line(STORY_TEXT.text("Tłum krzyczy imię. My nie potrzebujemy imienia. Ojciec kłania się, raz w życiu, i to ci wystarczy. Zostaniesz [królem|królową] tego, czego dwór nie umie policzyć."),13))
			lines.append(_line(STORY_TEXT.text("Ha, tfu. Witaj w rodzinie. Korona z cienia nie gniecie karku. Gniecie sumienie, jak je masz. Jak nie masz — śpisz lepiej niż cesarz."),1))
			lines.append(_line(STORY_TEXT.text("Znikasz. Kroniki piszą o pielgrzymce mistrza. Pod miastem jest drugi dwór. Ty na nim siedzisz. Czasem leniwie. Czasem ostro. Zawsze poza prawem, które [pisałeś|pisałaś] w dzień."),13,"Narrator"))
			lines.append(_line(STORY_TEXT.text("Elara rozumie i milczy. Pamięta twoje słowa o alei.") if state.get("elara","") == "cienie" else STORY_TEXT.text("Elara patrzy na puste miejsce na galerii. Nie zna całej odpowiedzi."),6,"Narrator"))
			if int(state.get("liczba_zakladow",0)) >= 2:
				lines.append(_line(STORY_TEXT.text("Hazard został twoim językiem. W piwnicy nikt nie udaje, że kości są tylko zabawą."),13,"Narrator"))
			elif state.get("brudne_rece",false):
				lines.append(_line(STORY_TEXT.text("Brudne ręce znają drogę po omacku. Drugi dwór nie musi ci tłumaczyć swoich cen."),13,"Narrator"))
			if state.get("matka_pogodzona",false):
				lines.append(_line(STORY_TEXT.text("Matylda dostaje co miesiąc kosz srebra «od dalekiego kuzyna». Nie pyta. Wie. Kroi pieróg mniejszy, bo złość syta jest lżejsza."),14,"Narrator"))
			lines.append(_line(STORY_TEXT.text("W alei staruszek podaje kaszę Aureliuszowi. Teraz wiesz: to on wyprawił was oboje w drogę. Nie pyta, gdzie kończy się twoja pielgrzymka."),11,"Narrator"))
	if clean_run(state):
		lines.append(_line(STORY_TEXT.text("Od pierwszej miski kaszy do ostatniego stołu — bez kupowania kości i bez ani jednego zakładu. Zwykłe kości wystarczyły. Osiągnięcie: Czyste ręce, zwykłe kości."),0,"Narrator"))
	sequence.lines = lines
	return sequence
