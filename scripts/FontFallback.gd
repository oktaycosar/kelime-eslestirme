extends Node
##
## Emoji / sembol / IPA karakterleri icin font yedegi kurar.
##
## SORUN: oyunun kullandigi hicbir gomulu fontta bu karakterler yok
## (Poppins de, Godot'un dahili fontu da). Masaustunde isletim sistemi
## kendi fontunu devreye sokuyor, ama TARAYICIDA boyle bir sistem fontu
## yok -> butun ikonlar tofu (▯) kutusu olarak gorunuyordu.
##
## COZUM: ThemeDB.fallback_font'a yedek font zinciri tanimlamak.
## Zincir sirasi onemli: karakteri ilk bulan font kullanilir.
##   NotoSans          -> IPA (telaffuz metni) + Turkce
##   NotoSansSymbols2  -> geometrik semboller, ok isaretleri
##   NotoEmoji         -> emoji
##
## Uc font da SIL Open Font License 1.1 (bkz. OFL-Noto*.txt).

const YEDEKLER := [
    "res://assets/fonts/NotoSans-Variable.ttf",
    "res://assets/fonts/NotoSansSymbols2-Regular.ttf",
    "res://assets/fonts/NotoEmoji-Variable.ttf",
]


func _ready() -> void:
    _kur()


func _kur() -> void:
    var taban: Font = ThemeDB.fallback_font
    if taban == null:
        push_warning("FontFallback: ThemeDB.fallback_font bulunamadi")
        return
    var yedekler: Array[Font] = []
    for yol in YEDEKLER:
        if not ResourceLoader.exists(yol):
            push_warning("FontFallback: font bulunamadi: %s" % yol)
            continue
        var f = load(yol)
        if f is Font:
            yedekler.append(f)
    taban.fallbacks = yedekler


## Test / teshis icin: zincirdeki tum fontlar (taban + yedekler).
func zincir() -> Array[Font]:
    var liste: Array[Font] = []
    var taban: Font = ThemeDB.fallback_font
    if taban != null:
        liste.append(taban)
        for f in taban.fallbacks:
            liste.append(f)
    return liste


## Verilen metindeki tum karakterler zincirde bulunuyor mu?
## Bulunamayanlari string olarak dondurur (bos = hepsi tamam).
func eksik_karakterler(metin: String) -> String:
    var liste := zincir()
    var eksik := ""
    for ch in metin:
        var bulundu := false
        for f in liste:
            if f.has_char(ord(ch)):
                bulundu = true
                break
        if not bulundu:
            eksik += ch
    return eksik