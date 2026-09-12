extends SceneTree
##
## itch.io kapak gorseli uretir: 630x500 (istenen 315:250 orani).
## Kaynak ekran goruntusu 1152x720 (16:10) oldugu icin orana uymuyor;
## hicbir seyi KESMEDEN, oyunun kendi arka plan rengiyle cerceveliyoruz.

const SRC := "F:/Projelerim_26/_kart_soru_isareti_yeni.png"
const OUT := "F:/Projelerim_26/itch-kapak-630x500.png"
const W := 630
const H := 500


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var img := Image.load_from_file(SRC)
    if img == null:
        print("HATA: kaynak yuklenemedi: ", SRC)
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    print("kaynak: %dx%d" % [img.get_width(), img.get_height()])

    # Oyunun arka plan rengini sol ust koseden al (cerceve bu renkle dolsun)
    var bg := img.get_pixel(2, 2)
    print("arka plan rengi: (%.3f, %.3f, %.3f)" % [bg.r, bg.g, bg.b])

    # Kaynagi genislige gore olcekle -> 630 x 394
    var oran := float(W) / float(img.get_width())
    var sh := int(round(img.get_height() * oran))
    img.resize(W, sh, Image.INTERPOLATE_LANCZOS)
    print("olceklenmis: %dx%d" % [img.get_width(), img.get_height()])

    # 630x500 tuval, arka plan rengiyle dolu, ortalanmis
    var kapak := Image.create(W, H, false, Image.FORMAT_RGBA8)
    kapak.fill(bg)
    var y := int((H - sh) / 2.0)
    kapak.blit_rect(img, Rect2i(0, 0, W, sh), Vector2i(0, y))
    print("yapistirildi: y=%d (ust/alt cerceve %d px)" % [y, y])

    var err := kapak.save_png(OUT)
    if err != OK:
        print("HATA: kaydedilemedi err=%d" % err)
        quit(1)
        return
    print("yazildi: %s  (%dx%d)" % [OUT, W, H])

    # Kendi ciktisini dogrula
    var chk := Image.load_from_file(OUT)
    if chk == null:
        print("DOGRULAMA: cikti geri yuklenemedi")
        quit(1)
        return
    print("DOGRULAMA: %dx%d  oran=%.3f (hedef 1.260)" % [chk.get_width(), chk.get_height(), float(chk.get_width()) / float(chk.get_height())])
    quit(0)