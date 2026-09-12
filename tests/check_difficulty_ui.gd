extends SceneTree
##
## Arayuz regresyon testi: zorluk secici + duraklatma penceresi cikis butonu.
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

	# --- Duraklatma penceresi: Devam et + Cikis ---
	var overlay = main.get_node_or_null("PauseOverlay")
	var vbox = main.get_node_or_null("PauseOverlay/CenterContainer/DialogPanel/VBox")
	_check(overlay != null, "PauseOverlay dugumu mevcut")
	_check(vbox != null, "PauseOverlay VBox mevcut")
	if vbox != null:
		var resume_btn = vbox.get_node_or_null("ResumeButton")
		var quit_btn = vbox.get_node_or_null("QuitButton")
		_check(resume_btn != null, "ResumeButton mevcut")
		_check(quit_btn != null, "QuitButton mevcut")
		# Buton var ama bagli degilse sessizce calismaz -- tam da bu test edilmeli
		if quit_btn != null:
			_check(quit_btn.pressed.get_connections().size() > 0,
				"QuitButton pressed sinyaline bagli")
			_check(quit_btn.text.length() > 0, "QuitButton etiketi bos degil")
		var restart_btn = vbox.get_node_or_null("RestartButton")
		_check(restart_btn != null, "RestartButton mevcut (mobil standardi)")
		if restart_btn != null:
			_check(restart_btn.pressed.get_connections().size() > 0,
					"RestartButton pressed sinyaline bagli")
			_check(restart_btn.text.length() > 0, "RestartButton etiketi bos degil")

	# --- Duraklatma paneli: icerik paneli asiyor mu? (3 buton olunca risk) ---
	if overlay != null and vbox != null:
		overlay.visible = true
		for i in range(3):
			await process_frame
		var panel = main.get_node_or_null("PauseOverlay/CenterContainer/DialogPanel")
		if panel != null:
			var pr: Rect2 = panel.get_global_rect()
			var vb: Rect2 = vbox.get_global_rect()
			print("    panel=%s  vbox=%s  vbox_min=%s" % [str(pr.size), str(vb.size), str(vbox.get_combined_minimum_size())])
			_check(vb.position.y >= pr.position.y - 0.5, "Panel icerigi yukaridan tasmiyor")
			_check(vb.end.y <= pr.end.y + 0.5, "Panel icerigi asagidan tasmiyor")
		overlay.visible = false
	
	# --- RestartButton gercekten calisiyor mu? ---
	if overlay != null and vbox != null:
		var rb = vbox.get_node_or_null("RestartButton")
		var gmgr = root.get_node_or_null("/root/GameManager")
		if rb != null and gmgr != null:
			gmgr.toggle_pause()
			for i in range(2):
				await process_frame
			_check(gmgr.is_paused, "on kosul: oyun duraklatildi")
			gmgr.moves = 5
			rb.pressed.emit()
			for i in range(4):
				await process_frame
			_check(not gmgr.is_paused, "RestartButton duraklatmayi kaldirdi")
			_check(gmgr.moves == 0, "RestartButton hamle sayacini sifirladi")
			_check(not overlay.visible, "RestartButton sonrasi PauseOverlay kapandi")
	
	# --- Kazanma paneli: TEKRAR OYNA + Cikis ---
	var gop_vbox = main.get_node_or_null("GameOverPanel/CenterContainer/DialogPanel/VBox")
	_check(gop_vbox != null, "GameOverPanel VBox mevcut")
	if gop_vbox != null:
		var replay_btn = gop_vbox.get_node_or_null("ReplayButton")
		var gquit_btn = gop_vbox.get_node_or_null("QuitButton")
		_check(replay_btn != null, "Kazanma panelinde ReplayButton mevcut")
		_check(gquit_btn != null, "Kazanma panelinde QuitButton mevcut")
		if gquit_btn != null:
			_check(gquit_btn.text.length() > 0, "Kazanma QuitButton etiketi bos degil")
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
		print("ARAYUZ: TUM TESTLER GECTI ✅")
		quit(0)
	else:
		print("ARAYUZ: %d SORUN ❌" % _failures.size())
		quit(1)