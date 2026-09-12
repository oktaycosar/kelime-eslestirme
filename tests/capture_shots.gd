extends Node
##
## itch.io icin ekran goruntuleri uretir. Oyunu kendi icinde calistirir,
## dort ayri durumu yakalar ve kendini kapatir.
##
## Kullanim:
##   godot --path <proje> res://tests/capture_shots.tscn

const OUT := "F:/Projelerim_26/itch-gorseller/"

var _main: Node


func _ready() -> void:
    call_deferred("_run")


func _run() -> void:
    DirAccess.make_dir_recursive_absolute(OUT)

    var scene: PackedScene = load("res://scenes/Main.tscn")
    if scene == null:
        print("HATA: Main.tscn yuklenemedi")
        get_tree().quit(1)
        return
    _main = scene.instantiate()
    get_tree().root.add_child(_main)
    get_tree().current_scene = _main
    for i in range(8):
        await get_tree().process_frame

    var trc: GridContainer = _main.get_node("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
    var enc: GridContainer = _main.get_node("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
    print("kart sayisi: TR=%d EN=%d" % [trc.get_child_count(), enc.get_child_count()])

    # --- 1) Kartlar kapali (oyun basi) ---
    await _shot("1-oyun-basi")

    # --- 2) Kartlar acik (kelimeler gorunur) ---
    _kartlari_cevir(trc, enc, true)
    await _shot("2-kartlar-acik")
    _kartlari_cevir(trc, enc, false)

    # --- 3) Kelime detay paneli ---
    var wcp = _main.get_node_or_null("WordCardPanel")
    if wcp != null:
        wcp.show_pair(1, "KÖPEK", "DOG", "animals")
        await _shot("3-kelime-detayi")
        wcp.hide_panel()
    else:
        print("UYARI: WordCardPanel yok")

    # --- 4) Duraklatma penceresi ---
    var overlay = _main.get_node_or_null("PauseOverlay")
    if overlay != null:
        overlay.visible = true
        await _shot("4-duraklatma")
        overlay.visible = false

    # --- 5) Kazanma paneli ---
    var gop = _main.get_node_or_null("GameOverPanel")
    if gop != null:
        # (skor, sure, hata, toplam_cift, en_iyi_combo, hamle, yeni_rekor)
        gop.show_panel(1125, 47.0, 0, 6, 6, 6, true)
        await _shot("5-kazanma")
    else:
        print("UYARI: GameOverPanel yok")

    print("BITTI")
    get_tree().quit(0)


func _kartlari_cevir(trc: GridContainer, enc: GridContainer, on: bool) -> void:
    for box in [trc, enc]:
        for c in box.get_children():
            var onp = c.get_node_or_null("FrontPanel")
            var arka = c.get_node_or_null("BackPanel")
            if onp != null and arka != null:
                onp.visible = on
                arka.visible = not on


func _shot(ad: String) -> void:
    for i in range(4):
        await get_tree().process_frame
    await RenderingServer.frame_post_draw
    var img: Image = get_viewport().get_texture().get_image()
    var yol := OUT + ad + ".png"
    var err := img.save_png(yol)
    print("  %-20s %dx%d  err=%d" % [ad, img.get_width(), img.get_height(), err])