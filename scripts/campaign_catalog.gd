class_name CampaignCatalog
extends RefCounted

const CHAPTERS := [
	{"opponent_key": "campaign_opponent_1", "story_key": "campaign_story_1", "dialogue": "res://dialogues/chapter_01.tres", "avatar": "builtin:innkeeper", "profile": "rookie", "difficulty": "easy", "theme": "tavern", "target": 1500},
	{"opponent_key": "campaign_opponent_2", "story_key": "campaign_story_2", "dialogue": "res://dialogues/chapter_02.tres", "avatar": "builtin:thief", "profile": "gambler", "difficulty": "normal", "theme": "forest", "target": 2000},
	{"opponent_key": "campaign_opponent_3", "story_key": "campaign_story_3", "dialogue": "res://dialogues/chapter_03.tres", "avatar": "builtin:knight", "profile": "tactician", "difficulty": "normal", "theme": "tavern", "target": 2500},
	{"opponent_key": "campaign_opponent_4", "story_key": "campaign_story_4", "dialogue": "res://dialogues/chapter_04.tres", "avatar": "builtin:witch", "profile": "tactician", "difficulty": "hard", "theme": "forest", "target": 2800},
	{"opponent_key": "campaign_opponent_5", "story_key": "campaign_story_5", "dialogue": "res://dialogues/chapter_05.tres", "avatar": "builtin:madman", "profile": "gambler", "difficulty": "hard", "theme": "tavern", "target": 3200},
	{"opponent_key": "campaign_opponent_6", "story_key": "campaign_story_6", "dialogue": "res://dialogues/chapter_06.tres", "avatar": "builtin:king", "profile": "champion", "difficulty": "hard", "theme": "royal", "target": 3500},
	{"opponent_key": "campaign_opponent_7", "story_key": "campaign_story_7", "dialogue": "res://dialogues/chapter_07.tres", "avatar": "builtin:princess", "profile": "tactician", "difficulty": "hard", "theme": "royal", "target": 3800},
	{"opponent_key": "campaign_opponent_8", "story_key": "campaign_story_8", "dialogue": "res://dialogues/chapter_08.tres", "avatar": "builtin:knight", "profile": "champion", "difficulty": "expert", "theme": "royal", "target": 4000},
	{"opponent_key": "campaign_opponent_9", "story_key": "campaign_story_9", "dialogue": "res://dialogues/chapter_09.tres", "avatar": "builtin:merchant", "profile": "tactician", "difficulty": "hard", "theme": "forest", "target": 4300},
	{"opponent_key": "campaign_opponent_10", "story_key": "campaign_story_10", "dialogue": "res://dialogues/chapter_10.tres", "avatar": "builtin:king", "profile": "champion", "difficulty": "expert", "theme": "royal", "target": 4500},
	{"opponent_key": "campaign_opponent_11", "story_key": "campaign_story_11", "dialogue": "res://dialogues/chapter_11.tres", "avatar": "builtin:bard", "profile": "champion", "difficulty": "expert", "theme": "tavern", "target": 4800},
	{"opponent_key": "campaign_opponent_12", "story_key": "campaign_story_12", "dialogue": "res://dialogues/chapter_12.tres", "avatar": "builtin:monk", "profile": "champion", "difficulty": "expert", "theme": "royal", "target": 5000}
]

const MILESTONES := [
	{"required": 6, "key": "campaign_goal_princess"},
	{"required": 8, "key": "campaign_goal_king"},
	{"required": 10, "key": "campaign_goal_emperor"},
	{"required": 12, "key": "campaign_goal_world_champion"}
]

# Optional wagers, configured separately for each opponent (zero-based chapter).
# Opponents absent from this table do not accept wagers.
const WAGER_LIMITS := {1: 100, 4: 200, 8: 500, 12: 20, 13: 150}


# Stable indices 0–11 keep old saves intact. Insertions have separate IDs.
const ROUTE := [0, 12, 1, 13, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 11]
const INSERTIONS := {
	12: {"number": "1B", "name": "Gromek, karczmarz", "avatar": "builtin:innkeeper", "profile": "rookie", "difficulty": "normal", "theme": "tavern", "target": 1800},
	13: {"number": "2B", "name": "Vespera, Córka Cienia", "avatar": "builtin:witch", "profile": "gambler", "difficulty": "hard", "theme": "forest", "target": 2400},
	14: {"number": "11B", "name": "Matylda, twoja matka", "avatar": "builtin:witch", "profile": "tactician", "difficulty": "hard", "theme": "tavern", "target": 3000}
}
const SIDE_TABLES := [
	{"name": "Ada, piekarka", "target": 1000, "reward": 30, "requires": [], "intro": "Przy bocznym stole Ada otrzepuje fartuch z mąki. «Chleb rośnie sam. W tym czasie zdążymy zagrać.»", "victory": "«Dobra ręka. Weź srebro, a bułkę dorzucę od siebie.»"},
	{"name": "Witek, stajenny", "target": 1200, "reward": 40, "requires": [0], "intro": "Witek kończy poić konie. «Zwierzęta odpoczywają. Teraz moja kolej — stół czeka.»", "victory": "«Kości posłuchały cię lepiej niż mój siwek. Srebro twoje.»"},
	{"name": "Hanka, tkaczka", "target": 1200, "reward": 40, "requires": [0], "intro": "Hanka odkłada wrzeciono i rozkłada kości na skrawku płótna. «Tu nic się nie plącze. Najwyżej szczęście.»", "victory": "«Ładny splot. Ani jednego węzła, którego nie dało się rozwiązać.»"},
	{"name": "Olek, bednarz", "target": 1400, "reward": 50, "requires": [1], "intro": "Olek odwraca pustą beczkę. «Stół pierwsza klasa. Jak przegram, przynajmniej nic nie wycieknie.»", "victory": "«Solidna robota. Gdybym tak składał beczki, miałbym kolejkę pod warsztatem.»"},
	{"name": "Zosia, zielarka", "target": 1400, "reward": 50, "requires": [2], "intro": "Zosia stawia kubek mięty obok kości. «Na nerwy pomaga. Na brak szczęścia — już mniej.»", "victory": "«Srebro na drogę. A miętę wypij, zanim wystygnie.»"},
	{"name": "Feliks, stary woźnica", "target": 1600, "reward": 70, "requires": [3, 4], "intro": "Przy wyjściu z areny Feliks poprawia kapelusz. «Cały dziedziniec już z tobą grał. Zostałem ja. Siadaj, nim ruszą wozy.»", "victory": "«Sześć stołów za tobą. Teraz masz i na drogę, i o czym opowiadać.»"}
]


static func wager_limit(index: int) -> int:
	return int(WAGER_LIMITS.get(index, 0))


static func chapter(index: int) -> Dictionary:
	if INSERTIONS.has(index):
		return INSERTIONS[index].duplicate(true)
	if index >= 100 and index < 100 + SIDE_TABLES.size():
		var result: Dictionary = SIDE_TABLES[index - 100].duplicate(true)
		result.merge({"avatar": "builtin:innkeeper", "profile": "rookie", "difficulty": "easy" if index < 103 else "normal", "theme": "tavern"})
		return result
	if index < 0 or index >= CHAPTERS.size():
		return {}
	return (CHAPTERS[index] as Dictionary).duplicate(true)


static func clamped_progress(progress: int) -> int:
	return clampi(progress, 0, CHAPTERS.size())


static func can_play(index: int, progress: int) -> bool:
	return index >= 0 and index < CHAPTERS.size() and index <= clamped_progress(progress)


static func completed(index: int, progress: int) -> bool:
	return index >= 0 and index < clamped_progress(progress)


static func next_index(progress: int) -> int:
	return mini(clamped_progress(progress), CHAPTERS.size() - 1)


static func advance(progress: int, won_index: int) -> int:
	var safe_progress := clamped_progress(progress)
	if won_index == safe_progress and safe_progress < CHAPTERS.size():
		return safe_progress + 1
	return safe_progress


static func milestone_key_for_progress(progress: int) -> String:
	for milestone: Dictionary in MILESTONES:
		if int(milestone.required) == progress:
			return str(milestone.key)
	return ""
