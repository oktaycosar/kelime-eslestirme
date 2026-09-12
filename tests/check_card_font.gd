extends SceneTree
##
## Kart fontu doğrulaması (regresyon).
##
## Neden gerekli: kartlarda kullanılan variable fontun ağırlık ekseni
## (variation_opentype wght) Godot tarafından UYGULANMIYOR - 300 ile 900
## arası metin genişliği birebir aynı çıkıyor. Bu yüzden "bold" ayarı
## sessizce Regular olarak render ediliyordu ve kimse fark etmiyordu.
##
## Çözüm: eksene bağımlı olmayan statik Poppins-Bold / Poppins-SemiBold.
## Bu test, uygulanan fontun gerçekten o dosya ve o ağırlık olduğunu
## font metadata'sından doğrular (piksele gerek yok).
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/check_card_font.gd

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    await process_frame
    var scene: PackedScene = load("res://scenes/Card.tscn")
    if scene == null:
        print("FAIL: Card.tscn yüklenemedi")
        quit(1)
        return
    var card = scene.instantiate()
    root.add_child(card)
    for i in range(3):
        await process_frame

    _check_font("WordLabel", card.get_node_or_null("FrontPanel/WordLabel"), "Poppins-Bold", 700)
    # BackLabel artik bir TextureRect (BackQuestion) - asagida ayrica dogrulaniyor
    _check_font("BackPanel/LanguageBadge", card.get_node_or_null("BackPanel/LanguageBadge"), "Poppins-SemiBold", 600)
    _check_font("FrontPanel/LanguageBadge", card.get_node_or_null("FrontPanel/LanguageBadge"), "Poppins-SemiBold", 600)

    # Kelime metni karta sığıyor mu? (Poppins geniş bir font)
    var word: Label = card.get_node_or_null("FrontPanel/WordLabel")
    if word != null:
        for sample in ["KELİME", "ÖĞRETMEN", "BİLGİSAYAR", "ELEPHANT", "SCOOTER"]:
            var sz: Vector2 = word.get_theme_font("font").get_string_size(
                sample, HORIZONTAL_ALIGNMENT_LEFT, -1, word.get_theme_font_size("font_size"))
            var fits: bool = sz.x <= word.size.x
            print("    %-12s genişlik %.1f / yer %.1f  %s" % [sample, sz.x, word.size.x, "sığıyor" if fits else "TAŞIYOR"])
            if not fits:
                _failures.append("%s karta sığmıyor (%.1f > %.1f)" % [sample, sz.x, word.size.x])

    # --- Kart arkasindaki "?" gorseli (assets/card_question.png) ---
    var q = card.get_node_or_null("BackPanel/BackQuestion")
    _check("BackQuestion dugumu mevcut", q != null)
    if q != null:
        _check("TextureRect tipinde", q is TextureRect)
        var tex = q.texture
        _check("gorsel yuklendi", tex != null)
        if tex != null:
            print("    gorsel: %s  %dx%d" % [tex.resource_path.get_file(), tex.get_width(), tex.get_height()])
            _check("dogru dosya (card_question.png)", tex.resource_path.ends_with("card_question.png"))
            _check("kare (1:1) gorsel", tex.get_width() == tex.get_height())
        # Kart olcegi zorlukla degisiyor (269x110 -> 177x64); "?" orantili kalmali.
        print("    kart olcegi degisince:")
        for boyut in [Vector2(269, 110), Vector2(177, 64)]:
            card.size = boyut
            for i in range(3):
                await process_frame
            var r: Rect2 = q.get_global_rect()
            var cr: Rect2 = card.get_global_rect()
            var icerde: bool = r.position.x >= cr.position.x - 0.5 and r.position.y >= cr.position.y - 0.5 and r.end.x <= cr.end.x + 0.5 and r.end.y <= cr.end.y + 0.5
            var oran_w: float = r.size.x / cr.size.x   # GERCEK boyut (Godot min boyuta kilitler)
            var oran_h: float = r.size.y / cr.size.y
            var cizilen: float = minf(r.size.x, r.size.y)
            print("      kart %.0fx%.0f -> kutu %.1fx%.1f  cizilen kare ~%.0fpx  oran %.2f/%.2f  icerde=%s" % [
                cr.size.x, cr.size.y, r.size.x, r.size.y, cizilen, oran_w, oran_h, str(icerde)])
            _check("kart %.0fx%.0f: '?' karti asmiyor" % [boyut.x, boyut.y], icerde)
            _check("kart %.0fx%.0f: oransal (%%40 x %%68)" % [boyut.x, boyut.y], absf(oran_w - 0.40) < 0.02 and absf(oran_h - 0.68) < 0.02)
            _check("kart %.0fx%.0f: makul boyut (30-90px)" % [boyut.x, boyut.y], cizilen >= 30.0 and cizilen <= 90.0)

    print("---------------------------------------------")
    if _failures.is_empty():
        print("KART FONTU: TAMAM ✅")
        quit(0)
    else:
        print("KART FONTU: %d SORUN ❌" % _failures.size())
        for f in _failures:
            print("  - " + f)
        quit(1)


func _check_font(label_name: String, label: Label, expect_file: String, expect_weight: int) -> void:
    if label == null:
        print("  FAIL: %s bulunamadı" % label_name)
        _failures.append(label_name + " yok")
        return
    var f = label.get_theme_font("font")
    if f == null:
        print("  FAIL: %s font override yok (tema varsayılanına düşüyor)" % label_name)
        _failures.append(label_name + " font override yok")
        return
    var path: String = ""
    var weight: int = -1
    if f is FontVariation:
        path = f.base_font.resource_path if f.base_font != null else "?"
        print("  NOT: %s hâlâ FontVariation kullanıyor (kırık eksen riski)" % label_name)
    elif f is FontFile:
        path = f.resource_path
        if f.has_method("get_font_weight"):
            weight = f.get_font_weight()
    var file_ok: bool = path.get_file().begins_with(expect_file)
    var weight_ok: bool = weight == expect_weight
    print("  %s: %s  ağırlık=%d (beklenen %d)  dosya doğru=%s  ağırlık doğru=%s" % [
        label_name, path.get_file(), weight, expect_weight, str(file_ok), str(weight_ok)])
    if not file_ok:
        _failures.append("%s yanlış dosya: %s (beklenen %s*)" % [label_name, path.get_file(), expect_file])
    if not weight_ok:
        _failures.append("%s ağırlık %d, beklenen %d (bold uygulanmıyor!)" % [label_name, weight, expect_weight])

func _check(label: String, ok: bool) -> void:
    if ok:
        print("  PASS: " + label)
    else:
        print("  FAIL: " + label)
        _failures.append(label)