extends SceneTree
##
## Yerleşim doğrulaması (regresyon testi).
##
## Her zorlukta (Kolay/Orta/Zor/Uzman) TÜM kartların pencere içinde kaldığını
## ölçer. Bu kontrol daha önce yoktu: 426 test geçiyordu ama kartlar ekran
## dışına taşıyordu ve oyun kazanılamıyordu.
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/check_layout.gd
##
## Exit code 0 = tüm zorluklar sığıyor, 1 = taşma var.

const DIFFICULTY_NAMES := ["Kolay", "Orta", "Zor", "Uzman"]

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		print("FAIL: main.tscn yüklenemedi")
		quit(1)
		return
	var main = scene.instantiate()
	root.add_child(main)
	current_scene = main
	for i in range(4):
		await process_frame

	var vp: Vector2 = root.get_visible_rect().size

	var difficulty_manager: Node = root.get_node_or_null("/root/DifficultyManager")
	if difficulty_manager == null:
		print("FAIL: DifficultyManager autoload bulunamadi")
		quit(1)
		return
	print("viewport: %s" % str(vp))
	print("")

	for d in range(4):
		difficulty_manager.current_difficulty = d
		main._new_game()
		for i in range(6):
			await process_frame
		await create_timer(0.2).timeout
		for i in range(4):
			await process_frame
		_check_difficulty(main, d, vp)

	print("---------------------------------------------")
	if _failures.is_empty():
		print("YERLEŞİM: TÜM ZORLUKLAR SIĞIYOR ✅")
		quit(0)
	else:
		print("YERLEŞİM: %d SORUN ❌" % _failures.size())
		for f in _failures:
			print("  - " + f)
		quit(1)


func _check_difficulty(main, d: int, vp: Vector2) -> void:
	var trc: GridContainer = main.get_node("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
	var enc: GridContainer = main.get_node("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
	var game_area: Control = main.get_node("RootVBox/GameArea")
	var area: Rect2 = game_area.get_global_rect()
	var n: int = trc.get_child_count()
	print("--- %s (zorluk %d): %d kart/sütun, columns=%d" % [DIFFICULTY_NAMES[d], d, n, trc.columns])
	print("    GameArea rect=%s" % str(area))

	var worst_bottom := -1e9
	var worst_right := -1e9
	var min_h := 1e9
	var min_w := 1e9
	var outside := 0
	var above_area := 0

	for pair in [["TR", trc], ["EN", enc]]:
		var tag: String = pair[0]
		var box: GridContainer = pair[1]
		var idx := 0
		for card in box.get_children():
			var r: Rect2 = card.get_global_rect()
			worst_bottom = maxf(worst_bottom, r.end.y)
			worst_right = maxf(worst_right, r.end.x)
			min_h = minf(min_h, r.size.y)
			min_w = minf(min_w, r.size.x)
			if r.position.x < -0.5 or r.position.y < -0.5 or r.end.x > vp.x + 0.5 or r.end.y > vp.y + 0.5:
				outside += 1
				_failures.append("%s/%s kart #%d pencere dışında: %s (vp %s)" % [DIFFICULTY_NAMES[d], tag, idx, str(r), str(vp)])
			if r.position.y < area.position.y - 0.5:
				above_area += 1
			idx += 1

	print("    en alt kart kenarı=%.1f (vp=%.1f)  en sağ=%.1f (vp=%.1f)" % [worst_bottom, vp.y, worst_right, vp.x])
	print("    kart boyutu min: %.1f x %.1f" % [min_w, min_h])
	print("    pencere dışı kart=%d  GameArea üstünü aşan kart=%d" % [outside, above_area])
	if outside == 0 and above_area == 0:
		print("    SONUÇ: sığıyor ✅")
	else:
		print("    SONUÇ: TAŞMA ❌")
		if above_area > 0:
			_failures.append("%s: %d kart GameArea üst sınırını aşıyor (chrome ile çakışıyor)" % [DIFFICULTY_NAMES[d], above_area])
	print("")
