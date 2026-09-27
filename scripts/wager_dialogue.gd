extends RefCounted

const SEQUENCE := preload("res://scripts/dialogue_sequence.gd")
const LINE := preload("res://scripts/dialogue_line.gd")
const CHOICE := preload("res://scripts/dialogue_choice.gd")
const CAMPAIGN := preload("res://scripts/campaign_catalog.gd")

static func build(index: int, silver: int, translate: Callable) -> Resource:
	var chapter: Dictionary = CAMPAIGN.chapter(index)
	var limit := mini(CAMPAIGN.wager_limit(index), silver)
	var sequence := SEQUENCE.new()
	sequence.title_key = "wager_conversation"
	sequence.allow_skip = false
	var offer := LINE.new()
	offer.speaker_key = str(chapter.opponent_key)
	offer.portrait_id = str(chapter.avatar)
	offer.backdrop = str(chapter.theme)
	offer.text = translate.call("wager_talk_offer", [CAMPAIGN.wager_limit(index), silver])
	sequence.lines.append(offer)
	var amounts: Array[int] = []
	if limit > 0:
		amounts.append(mini(25, limit))
		if limit > amounts[0]:
			amounts.append(limit)
	for amount in amounts:
		var proposal := CHOICE.new()
		proposal.id = "propose_%d" % amount
		proposal.text = translate.call("wager_talk_stake", [amount])
		proposal.next_line_index = sequence.lines.size()
		offer.choices.append(proposal)
		var response := LINE.new()
		response.speaker_key = str(chapter.opponent_key)
		response.portrait_id = str(chapter.avatar)
		response.backdrop = str(chapter.theme)
		response.text = translate.call("wager_talk_accept", [amount, amount * 2])
		var agree := CHOICE.new()
		agree.id = "wager_%d" % amount
		agree.ending_id = agree.id
		agree.text_key = "wager_talk_agree"
		response.choices.append(agree)
		var back := CHOICE.new()
		back.id = "negotiate"
		back.text_key = "wager_talk_back"
		back.next_line_index = 0
		response.choices.append(back)
		sequence.lines.append(response)
	var free := CHOICE.new()
	free.id = "wager_0"
	free.ending_id = free.id
	free.text_key = "wager_talk_free"
	offer.choices.append(free)
	var leave := CHOICE.new()
	leave.id = "leave"
	leave.ending_id = leave.id
	leave.text_key = "wager_talk_leave"
	offer.choices.append(leave)
	return sequence
