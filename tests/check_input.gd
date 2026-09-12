extends SceneTree
##
## Klavye kısayolu doğrulaması (regresyon).
##
## ESC eskiden yalnızca duraklamayı KAPATIYORDU (is_paused ise devam et).
## Duraklatmayı açan tek yol "Duraklat" butonu ve P tuşuydu; bu yüzden
## ESC -> pencere -> Çıkış akışı çalışmıyordu. Artık ESC gerçek bir aç/kapa.
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/check_input.gd

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

    var gm = root.get_node_or_null("/root/GameManager")
    if gm == null:
        print("FAIL: GameManager autoload yok")
        quit(1)
        return

    main._new_game()
    for i in range(4):
        await process_frame

    var overlay = main.get_node_or_null("PauseOverlay")

    _check("oyun çalışıyor", gm.is_running)
    _check("başlangıçta duraklatılmamış", not gm.is_paused)
    if overlay != null:
        _check("başlangıçta PauseOverlay gizli", not overlay.visible)

    # 1. ESC -> duraklat
    _press_esc(main)
    for i in range(2):
        await process_frame
    _check("1. ESC -> duraklatıldı", gm.is_paused)
    if overlay != null:
        _check("1. ESC -> PauseOverlay görünür", overlay.visible)

    # 2. ESC -> devam
    _press_esc(main)
    for i in range(2):
        await process_frame
    _check("2. ESC -> devam ediyor", not gm.is_paused)
    if overlay != null:
        _check("2. ESC -> PauseOverlay gizli", not overlay.visible)

    # 3. P tuşu da çalışıyor mu (regresyon)
    _press_key(main, KEY_P)
    for i in range(2):
        await process_frame
    _check("P -> duraklatıldı", gm.is_paused)
    _press_key(main, KEY_P)
    for i in range(2):
        await process_frame
    _check("P -> devam ediyor", not gm.is_paused)

    print("---------------------------------------------")
    if _failures.is_empty():
        print("KISAYOLLAR: TAMAM ✅")
        quit(0)
    else:
        print("KISAYOLLAR: %d SORUN ❌" % _failures.size())
        for f in _failures:
            print("  - " + f)
        quit(1)


func _press_esc(main) -> void:
    _press_key(main, KEY_ESCAPE)


func _press_key(main, keycode: int) -> void:
    var e := InputEventKey.new()
    e.keycode = keycode
    e.pressed = true
    e.echo = false
    main._unhandled_input(e)


func _check(label: String, ok: bool) -> void:
    if ok:
        print("  PASS: " + label)
    else:
        print("  FAIL: " + label)
        _failures.append(label)