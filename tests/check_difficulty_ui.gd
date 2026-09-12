extends SceneTree
##
## Zorluk secici regresyon testi.
##
## DifficultyManager dort zorlugu destekliyordu ama arayuzde secici yoktu;
## artik DifficultyBar var. Bu test hem dugumun varligini hem de butona
## basildiginda oyunun gercekten guncellendigini dogrular.
##
## Kullanim: godot --headless --path <proje> --script res://tests/check_difficulty_ui.gd

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		print("FAIL: Main.tscn yuklenemedi")
		quit(1)
		return
	var main = scene.instantiate()
	root.add_child(main)
	current_scene = main
	for i in range(4):
		await process_frame

	var dm: Node = root.get_node_or_null("/root/DifficultyManager")
	var gm: Node = root.get_node_or_null("/root/GameManager")
	if dm == null or gm == null:
		print("FAIL: autoload bulunamadi")
		quit(1)
		return

	var bar = main.get_node_or_null("RootVBox/DifficultyBar")
	var flow = main.get_node_or_null("RootVBox/DifficultyBar/DifficultyFlow")
	var trc = main.get_node("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
	var enc = main.get_node("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")

	_check(bar != null, "DifficultyBar dugumu mevcut")
	_check(flow != null, "DifficultyFlow dugumu mevcut")
	if flow == null:
		_finish()
		return

	var expected_count: int = dm.Difficulty.size()
	_check(flow.get_child_count() == expected_count,
		"%d zorluk butonu (gercek %d)" % [expected_count, flow.get_child_count()])

	# Her butona sirayla bas: secim + kart sayisi + ipucu hakki guncellenmeli
	for d in range(expected_count):
		if d >= flow.get_child_count():
			break
		var btn: Button = flow.get_child(d)
		_check(btn.name == "Diff_%d" % d, "buton adi Diff_%d (gercek %s)" % [d, btn.name])
		_check(btn.text.contains(dm.get_difficulty_label_pretty(d)),
			"Diff_%d etiketi '%s' iceriyor (gercek '%s')" % [d, dm.get_difficulty_label_pretty(d), btn.text])

		btn.pressed.emit()
		for i in range(4):
			await process_frame
		await create_timer(0.25).timeout
		for i in range(3):
			await process_frame

		var pairs: int = dm.get_pair_count(d)
		_check(dm.current_difficulty == d, "zorluk %d secildi (gercek %d)" % [d, dm.current_difficulty])
		_check(gm.total_pairs == pairs, "zorluk %d -> total_pairs %d (gercek %d)" % [d, pairs, gm.total_pairs])
		_check(gm.total_hints == dm.get_hint_count(d),
			"zorluk %d -> ipucu %d (gercek %d)" % [d, dm.get_hint_count(d), gm.total_hints])
		_check(trc.get_child_count() == pairs,
			"zorluk %d -> TR sutununda %d kart (gercek %d)" % [d, pairs, trc.get_child_count()])
		_check(enc.get_child_count() == pairs,
			"zorluk %d -> EN sutununda %d kart (gercek %d)" % [d, pairs, enc.get_child_count()])

	_finish()


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  OK  : " + label)
	else:
		print("  FAIL: " + label)
		_failures.append(label)


func _finish() -> void:
	print("---------------------------------------------")
	if _failures.is_empty():
		print("ZORLUK SECICI: TUM TESTLER GECTI ✅")
		quit(0)
	else:
		print("ZORLUK SECICI: %d SORUN ❌" % _failures.size())
		quit(1)