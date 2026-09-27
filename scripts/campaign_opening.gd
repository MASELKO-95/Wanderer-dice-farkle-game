extends RefCounted

const LINE = preload("res://scripts/dialogue_line.gd")
const CHOICE = preload("res://scripts/dialogue_choice.gd")
const SEQUENCE = preload("res://scripts/dialogue_sequence.gd")

static func line(text: String, speaker: String = "Narrator", jump: int = -1) -> Resource:
	var result := LINE.new()
	result.text = text
	result.speaker = speaker
	result.next_line_index = jump
	result.portrait_side = "narrator"
	return result

static func choice(id: String, text: String, jump: int = -1) -> Resource:
	var result := CHOICE.new()
	result.id = id
	result.text = text
	result.next_line_index = jump
	return result

static func build(section: String) -> Resource:
	var result := SEQUENCE.new()
	result.title = "Prolog — o kościach i pustym brzuchu" if section.begins_with("prologue") or section.begins_with("tutorial") else "Rozdział 1 — pierwszy turniej"
	var lines: Array[Resource] = []
	match section:
		"prologue":
			lines.append(line("Witaj w świecie, w którym problemy i konflikty rozwiązuje się grą w kości. W twoim kraju gra się w Farkle. A ty? Jesteś zwykłym chłopem… albo chłopką."))
			lines[0].choices.assign([choice("male", "Chłop"), choice("female", "Chłopka")])
			lines.append(line("Zaczynasz jako [chłop|chłopka], bez grosza przy duszy. Matka wyrzuciła cię z domu. Za co?"))
			for reason in [["theft", "Kradzież"], ["violence", "Pobicie"], ["laziness", "Lenistwo"], ["gluttony", "Obżarstwo"], ["greed", "Chciwość"]]:
				lines[1].choices.append(choice(reason[0], reason[1]))
			lines.append(line("Od kilku godzin wędrujesz z pustym brzuchem — matka wyrzuciła cię jeszcze przed śniadaniem. Przy drodze dostrzegasz tablicę ogłoszeń."))
			lines.append(line("TURNIEJ FARKLE — JUŻ DZISIAJ! Do wygrania ręka [księżniczki|księcia] i pokaźna suma pieniędzy. Postanawiasz spróbować szczęścia."))
			lines[3].illustration = load("res://assets/campaign/tournament_notice.png")
			lines.append(line("W drodze na turniej spotykasz staruszka z miską rozwodnionej kaszy i garścią kości."))
			lines.append(line("Burczy ci w brzuchu tak, że słyszę cię z daleka! Wygraj ze mną, a kasza będzie twoja. Nie znasz zasad? Już tłumaczę.", "Staruszek"))
			lines.append(line("Rzucasz sześcioma kośćmi. Wybierz punktujące kości: jedynka daje 100, piątka 50. Trzy jednakowe dają wartość oczka razy 100, a trzy jedynki — 1000.", "Staruszek"))
			lines.append(line("Możesz odłożyć wybrane kości i rzucić pozostałymi albo zakończyć turę, bankując punkty. Gdy rzut nie daje punktów, to Farkle — tracisz punkty tej tury!", "Staruszek"))
			lines.append(line("Jeżeli wszystkie kości zapunktują, możesz rzucać znów sześcioma. Spróbujmy krótkiej gry do 500 punktów. Podpowiedzi znajdziesz przy stole.", "Staruszek"))
		"tutorial_victory", "tutorial_defeat":
			lines.append(line("Ha! Wygrywasz. Kasza jest twoja!" if section == "tutorial_victory" else "Tym razem wygrałem, ale przecież nie puszczę cię dalej z pustym brzuchem!", "Staruszek"))
			lines.append(line("Masz miskę kaszy. Weź też bilet na turniej — mnie stare kości już tam nie poniosą. Powodzenia!", "Staruszek"))
			lines.append(line("Po posiłku ruszasz na arenę z biletem w kieszeni."))
		"intro":
			lines.append(line("Spoglądasz z podziwem na mury areny. Jeszcze dziś rano nie [wiedziałeś|wiedziałaś] o jej istnieniu. Z biletem od staruszka podchodzisz do zapisów, gdzie wita cię [piękna ekspedientka|przystojny ekspedient]."))
			lines.append(line("Dzień dobry, w czym mogę pomóc?", "[Ekspedientka|Ekspedient]"))
			lines[1].choices.assign([choice("register", "Dzień dobry, [chciałbym|chciałabym] zapisać się na turniej.", 2), choice("flirt", "Eee… hej, skarbie. Może umówimy się na randkę?", 3)])
			lines.append(line("Już zapisuję. Oto twoje stanowisko i rozpiska przeciwników. Powodzenia!", "[Ekspedientka|Ekspedient]", 7))
			lines.append(line("Ech, ktoś chyba nie wie, po co tu przyszedł. Ale zgaduję, że chodzi o zapis na turniej, prawda?", "[Ekspedientka|Ekspedient]"))
			lines.append(line("Tak, tak…", "Ty"))
			lines.append(line("Dobra, dobra. Oto twoje stanowisko i rozpiska. Oby szczęście przy kościach dopisywało ci tak, jak sobie tego życzysz w zalotach!", "[Ekspedientka|Ekspedient]"))
			lines.append(line("Odchodzisz [cały czerwony|cała czerwona] ze wstydu do stolika pierwszego przeciwnika."))
			lines.append(line("Hej, [chłopcze|dziewczyno]! Ale z ciebie drobnota. Grajmy, zanim szczęście mi ucieknie!", "Chłop"))
		"victory":
			lines.append(line("Gratulacje! Jesteś [lepszy|lepsza] ode mnie. Trzymaj jeszcze 5 srebra ode mnie — dodatkowo do nagrody za wygraną.", "Chłop"))
		"defeat":
			lines.append(line("Ech, po twoich oczach spodziewałem się więcej. Ale nie załamuj się, możesz jeszcze wygrać cały turniej. Powodzenia!", "Chłop"))
	result.lines = lines
	return result

static func record_first_result(state: Dictionary, won: bool) -> bool:
	if state.has("first_result"):
		return false
	state["first_result"] = "victory" if won else "defeat"
	state["ending_points"] = {"princess": 1, "king": int(won), "emperor": 1, "world_champion": int(won)}
	return true
