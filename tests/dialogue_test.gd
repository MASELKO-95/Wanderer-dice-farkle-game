extends SceneTree

const DIALOGUE_SCENE := preload("res://scenes/visual_novel_dialogue.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var rules := preload("res://scripts/campaign_chronicles.gd")
	var state := {}
	rules.initialize(state,0)
	for index in CampaignCatalog.ROUTE:
		for section in ["intro","victory","defeat"]:
			assert(not rules.build(index,section,state).lines.is_empty())
	var final_sequence := DialogueSequence.new()
	var final_line := DialogueLine.new()
	final_line.text = "Wybierz zakończenie."
	for ending in rules.endings(state):
		var choice := DialogueChoice.new()
		choice.id = ending
		choice.ending_id = ending
		choice.text = rules.TITLES[ending]
		final_line.choices.append(choice)
	final_sequence.lines.append(final_line)
	var ending_choices: Array = final_line.choices
	assert(ending_choices.size() == 4)
	var dialogue := DIALOGUE_SCENE.instantiate()
	root.add_child(dialogue)
	dialogue.call("play", rules.build(0,"intro",state), "intro")
	await process_frame
	if str(dialogue._speaker_label.text).is_empty() or str(dialogue._text_label.text).is_empty():
		_fail("scena visual novel nie wyświetla mówiącego lub tekstu")
		return
	dialogue.call("finish_dialogue")
	dialogue.queue_free()
	await process_frame
	var ending_dialogue := DIALOGUE_SCENE.instantiate()
	root.add_child(ending_dialogue)
	ending_dialogue.call("play", final_sequence, "victory")
	ending_dialogue.call("_select_choice", ending_choices[2])
	if str(ending_dialogue.get("result_id")) != "emperor":
		_fail("wybór finałowy nie zwrócił zakończenia cesarskiego")
		return
	ending_dialogue.queue_free()
	await process_frame
	print("PASS: scena visual novel, 15 dialogów, gałęzie zwycięstwa/porażki i wybór zakończenia")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
