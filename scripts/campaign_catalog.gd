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
const WAGER_LIMITS := { 1: 100, 4: 200, 8: 500}


static func wager_limit(index: int) -> int:
	return int(WAGER_LIMITS.get(index, 0))


static func chapter(index: int) -> Dictionary:
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
