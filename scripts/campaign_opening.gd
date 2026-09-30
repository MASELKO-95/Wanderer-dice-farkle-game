extends RefCounted

const STORY_TEXT := preload("res://scripts/story_text.gd")

const LINE = preload("res://scripts/dialogue_line.gd")
const CHOICE = preload("res://scripts/dialogue_choice.gd")
const SEQUENCE = preload("res://scripts/dialogue_sequence.gd")

static func line(text: String, speaker: String = "Narrator", jump: int = -1) -> Resource:
	var result := LINE.new()
	result.text = STORY_TEXT.text(text)
	result.speaker = STORY_TEXT.text(speaker)
	result.next_line_index = jump
	result.portrait_side = "narrator"
	return result

static func choice(id: String, text: String, jump: int = -1) -> Resource:
	var result := CHOICE.new()
	result.id = id
	result.text = STORY_TEXT.text(text)
	result.next_line_index = jump
	return result

static func build(section: String) -> Resource:
	var result := SEQUENCE.new()
	result.title = STORY_TEXT.text("Prolog — o kościach i pustym brzuchu") if section.begins_with("prologue") or section.begins_with("tutorial") else STORY_TEXT.text("Rozdział 1 — pierwszy turniej")
	var lines: Array[Resource] = []
	match section:
		"prologue":
			lines.append(line(STORY_TEXT.text("Witaj w świecie, w którym problemy i konflikty rozwiązuje się grą w kości. W twoim kraju gra się w Farkle. A ty? Jesteś zwykłym chłopem… albo chłopką.")))
			lines[0].choices.assign([choice("male", STORY_TEXT.text("Chłop")), choice("female", STORY_TEXT.text("Chłopka"))])
			lines.append(line(STORY_TEXT.text("Zaczynasz jako [chłop|chłopka], bez grosza przy duszy. Matka wyrzuciła cię z domu. Za co?")))
			for reason in [["theft", STORY_TEXT.text("Kradzież")], ["violence", STORY_TEXT.text("Pobicie")], ["laziness", STORY_TEXT.text("Lenistwo")], ["gluttony", STORY_TEXT.text("Obżarstwo")], ["greed", STORY_TEXT.text("Chciwość")]]:
				lines[1].choices.append(choice(reason[0], reason[1]))
			lines.append(line(STORY_TEXT.text("Od kilku godzin wędrujesz z pustym brzuchem — matka wyrzuciła cię jeszcze przed śniadaniem. Przy drodze dostrzegasz tablicę ogłoszeń.")))
			lines.append(line(STORY_TEXT.text("TURNIEJ FARKLE — JUŻ DZISIAJ! Do wygrania ręka księżniczki Elary i pokaźna suma pieniędzy. Postanawiasz spróbować szczęścia.")))
			# The original illustration contains Polish lettering; the translated
			# notice remains fully readable in the dialogue itself.
			if STORY_TEXT.locale == "pl":
				lines[3].illustration = load("res://assets/campaign/tournament_notice.png")
			lines.append(line(STORY_TEXT.text("W drodze na turniej spotykasz staruszka z miską rozwodnionej kaszy i garścią kości.")))
			lines.append(line(STORY_TEXT.text("Hej, kośćmi ziejący. Zagrasz o miskę kaszy? Wygrasz — kasza. Przegrasz — też kasza, bo wyglądasz, jakby ci się brzuch do kręgosłupa kleił. Zasady opowiem, zanim umrzesz z dumy."), STORY_TEXT.text("Staruszek")))
			lines.append(line(STORY_TEXT.text("Rzucasz sześcioma kośćmi. Wybierz punktujące kości: jedynka daje 100, piątka 50. Trzy jednakowe dają wartość oczka razy 100, a trzy jedynki — 1000."), STORY_TEXT.text("Staruszek")))
			lines.append(line(STORY_TEXT.text("Możesz odłożyć wybrane kości i rzucić pozostałymi albo zakończyć turę, bankując punkty. Gdy rzut nie daje punktów, to Farkle — tracisz punkty tej tury!"), STORY_TEXT.text("Staruszek")))
			lines.append(line(STORY_TEXT.text("Jeżeli wszystkie kości zapunktują, możesz rzucać znów sześcioma. Spróbujmy krótkiej gry do 500 punktów. Podpowiedzi znajdziesz przy stole."), STORY_TEXT.text("Staruszek")))
		"tutorial_victory", "tutorial_defeat":
			lines.append(line(STORY_TEXT.text("No. Ręka nie całkiem drewniana. Jedz. I bilet na turniej — bo jak cię tu zostawię, to ci wilki zjedzą resztę kaszy.") if section == "tutorial_victory" else STORY_TEXT.text("Widzisz? Kości lubią głodnych, ale nie aż tak. Jedz i tak. Bilet masz. Przegrana przy kaszy nie liczy się do legendy."), STORY_TEXT.text("Staruszek")))
			lines.append(line(STORY_TEXT.text("Masz miskę kaszy. Weź też bilet na turniej — mnie stare kości już tam nie poniosą. Powodzenia!"), STORY_TEXT.text("Staruszek")))
			lines.append(line(STORY_TEXT.text("Po posiłku ruszasz na arenę z biletem w kieszeni.")))
	result.lines = lines
	return result
