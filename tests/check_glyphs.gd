extends SceneTree
##
## Font kapsama testi (regresyon).
##
## NEDEN: oyunun kullandigi hicbir gomulu fontta emoji/sembol/IPA karakteri
## yoktu. Masaustunde isletim sistemi kendi fontunu devreye sokuyordu, ama
## TARAYICIDA sistem fontu olmadigi icin butun ikonlar tofu (▯) kutusu
## olarak gorunuyordu. Bu hata ekran goruntulerinde gorunmez, cunku
## goruntuler masaustunde alinir.
##
## Bu test, arayuzde KULLANILAN her ozel karakterin font zincirinde
## bulundugunu dogrular -> tofu bir daha sessizce geri gelemez.
##
## Kullanim:
##   godot --headless --path <proje> --script res://tests/check_glyphs.gd

# Arayuzde gercekten gosterilen ozel karakterler:
#   Turkce harfler + IPA (telaffuz) + semboller + emoji
const KULLANILAN := "çÇğĞıİöÖşŞüÜˈɪːəʊæʃʌɒɡɔɑɜʒŋθðˌ▼◆⏸↔⚠×✕▶✖✓⚕⛅💡🔊🎲🎉🏆🔥🔁"

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    await process_frame

    var ff = root.get_node_or_null("/root/FontFallback")
    _check("FontFallback autoload yuklu", ff != null)

    var taban: Font = ThemeDB.fallback_font
    _check("ThemeDB.fallback_font mevcut", taban != null)
    if taban == null:
        _finish()
        return

    var yedekler: Array = taban.fallbacks
    print("    yedek font sayisi: %d" % yedekler.size())
    for f in yedekler:
        var ad := String(f.resource_path).get_file() if f is FontFile else "(gomulu)"
        print("      - %s" % ad)
    _check("en az 3 yedek font kurulu", yedekler.size() >= 3)

    var zincir: Array = [taban]
    for f in yedekler:
        zincir.append(f)

    var eksik := ""
    for ch in KULLANILAN:
        var bulundu := false
        for f in zincir:
            if f.has_char(ord(ch)):
                bulundu = true
                break
        if not bulundu:
            eksik += ch

    print("    test edilen karakter sayisi: %d" % KULLANILAN.length())
    _check("tum karakterler kapsaniyor (eksik: '%s')" % eksik, eksik == "")

    _finish()


func _check(label: String, ok: bool) -> void:
    if ok:
        print("  PASS: " + label)
    else:
        print("  FAIL: " + label)
        _failures.append(label)


func _finish() -> void:
    print("---------------------------------------------")
    if _failures.is_empty():
        print("FONT KAPSAMA: TAMAM ✅")
        quit(0)
    else:
        print("FONT KAPSAMA: %d SORUN ❌" % _failures.size())
        for f in _failures:
            print("  - " + f)
        quit(1)