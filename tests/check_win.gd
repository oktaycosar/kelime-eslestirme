extends SceneTree
##
## Uçtan uca kazanma testi (regresyon).
##
## Hedefin asıl kabul kriteri: kartlar ekran dışına taşmıyor VE oyun
## kazanılabiliyor. check_layout.gd sığmayı ölçer; bu test oyunun gerçekten
## bitirilebildiğini ve GameOverPanel'in açıldığını kanıtlar.
##
## Dört zorluk da denenir: Kolay 6, Orta 8, Zor 10, Uzman 15 çift.
## Sabit bekleme yerine GameManager.busy üzerinde beklenir -> deterministik.
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/check_win.gd
##
## Exit code 0 = tüm zorluklar kazanıldı, 1 = kazanılamayan zorluk var.

const DIFFICULTY_NAMES := ["Kolay", "Orta", "Zor", "Uzman"]
const PAIR_COUNTS := [6, 8, 10, 15]

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    await process_frame
    var scene: PackedScene = load("res://scenes/Main.tscn")
    if scene == null:
        print("FAIL: Main.tscn yüklenemedi")
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
        print("FAIL: autoload eksik (DifficultyManager/GameManager)")
        quit(1)
        return

    for d in range(4):
        await _play_difficulty(main, dm, gm, d)

    # Test, kaynaklar hala tutulurken sureci kapatinca Godot kapanista
    # "resources still in use at exit" uyarisi verir. Deneyle dogrulandi:
    # sesi durdurmak yetmiyor, stream referansini birakmak gerekiyor.
    var am = root.get_node_or_null("/root/AudioManager")
    if am != null:
        for child in am.get_children():
            if child is AudioStreamPlayer:
                child.stop()
                child.stream = null   # referansi birak (kapanista uyari cikmasin)
    await _settle(2)

    print("---------------------------------------------")
    if _failures.is_empty():
        print("KAZANMA: TÜM ZORLUKLAR BİTİRİLEBİLİR ✅")
        quit(0)
    else:
        print("KAZANMA: %d SORUN ❌" % _failures.size())
        for f in _failures:
            print("  - " + f)
        quit(1)


func _play_difficulty(main, dm: Node, gm: Node, d: int) -> void:
    dm.current_difficulty = d
    main._new_game()
    await _settle(8)

    var trc: GridContainer = main.get_node("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
    var enc: GridContainer = main.get_node("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")

    var tr_by_id := {}
    var en_by_id := {}
    for c in trc.get_children():
        tr_by_id[int(c.pair_id)] = c
    for c in enc.get_children():
        en_by_id[int(c.pair_id)] = c

    var expected: int = PAIR_COUNTS[d]
    print("--- %s (zorluk %d): TR=%d EN=%d kart, beklenen %d çift" % [
        DIFFICULTY_NAMES[d], d, trc.get_child_count(), enc.get_child_count(), expected])

    if trc.get_child_count() != expected or enc.get_child_count() != expected:
        _failures.append("%s: kart sayısı beklenmedik (TR=%d EN=%d, beklenen %d)" % [
            DIFFICULTY_NAMES[d], trc.get_child_count(), enc.get_child_count(), expected])

    var ids: Array = tr_by_id.keys()
    ids.sort()

    var stuck: Array = []
    for id in ids:
        var tr = tr_by_id[id]
        var en = en_by_id.get(id)
        if en == null:
            stuck.append(id)
            continue
        if not await _match_pair(gm, tr, en):
            stuck.append(id)

    var won: bool = gm.is_game_won
    var panel = main.get_node_or_null("GameOverPanel")
    var panel_visible: bool = panel != null and panel.visible

    print("    eşleşmeyen=%d  is_game_won=%s  panel=%s  hamle=%d  skor=%d" % [
        stuck.size(), str(won), str(panel_visible), gm.moves, gm.score])
    if not stuck.is_empty():
        _failures.append("%s: %d çift eşleşmedi -> %s" % [DIFFICULTY_NAMES[d], stuck.size(), str(stuck)])
    if not won:
        _failures.append("%s: tüm çiftler eşleşti ama is_game_won false" % DIFFICULTY_NAMES[d])
    if not panel_visible:
        _failures.append("%s: kazanınca GameOverPanel açılmadı" % DIFFICULTY_NAMES[d])
    if stuck.is_empty() and won and panel_visible:
        print("    SONUÇ: kazanıldı, GameOverPanel açıldı ✅")
    print("")


func _match_pair(gm: Node, tr, en) -> bool:
    for attempt in range(4):
        if tr.is_matched and en.is_matched:
            return true
        await _wait_idle(gm)
        if not tr.is_matched and not tr.is_open:
            gm.select_card(tr)
            await _settle(2)
        await _wait_idle(gm)
        if not en.is_matched and not en.is_open:
            gm.select_card(en)
        await _wait_idle(gm)
        await _settle(3)
    return tr.is_matched and en.is_matched


func _wait_idle(gm: Node, max_frames: int = 900) -> void:
    var f := 0
    while gm.busy and f < max_frames:
        await process_frame
        f += 1
    await process_frame


func _settle(frames: int) -> void:
    for i in range(frames):
        await process_frame