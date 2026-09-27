extends SceneTree

const DIALOGUE_SCENE := preload("res://scenes/visual_novel_dialogue.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for chapter_number in range(1, 13):
		var path := "res://dialogues/chapter_%02d.tres" % chapter_number
		var sequence := load(path) as Resource
		if sequence == null:
			_fail("nie można załadować %s" % path)
			return
		for section in ["intro_lines", "victory_lines", "defeat_lines"]:
			var lines: Array = sequence.get(section)
			if lines.is_empty():
				_fail("%s nie ma sekcji %s" % [path, section])
				return
	var final_sequence := load("res://dialogues/chapter_12.tres") as Resource
	var final_lines: Array = final_sequence.get("victory_lines")
	var ending_choices: Array = (final_lines[0] as Resource).get("choices")
	if ending_choices.size() != 3:
		_fail("finał nie oferuje trzech zakończeń")
		return
	var dialogue := DIALOGUE_SCENE.instantiate()
	root.add_child(dialogue)
	dialogue.call("play", load("res://dialogues/chapter_01.tres"), "intro")
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
	ending_dialogue.call("_select_choice", ending_choices[1])
	if str(ending_dialogue.get("result_id")) != "emperor":
		_fail("wybór finałowy nie zwrócił zakończenia cesarskiego")
		return
	ending_dialogue.queue_free()
	await process_frame
	print("PASS: scena visual novel, 12 dialogów, gałęzie zwycięstwa/porażki i 3 zakończenia")
	quit(0)


func _fail(message: String) -> void:
	printerr("FAIL: %s" % message)
	quit(1)
