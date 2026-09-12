extends SceneTree
##
## "?" PNG'sini kart arkasi icin hazirlar:
##   1) Beyaz arka plani seffaf yapar - KENARDAN flood fill ile, boylece
##      glifin ICINDEKI beyaz parlamalar korunur (delik acilmaz).
##   2) 1254x1254 -> 256x256 kucultur: disk 633 KB -> ~15 KB,
##      VRAM 6.3 MB -> 256 KB. Ekranda ~32-60 px gorundugu icin fark yok.
##
## Kullanim:
##   godot --headless --path <proje> --script res://tools/prepare_question_png.gd

const SRC := "C:/Users/OktayC/Downloads/ChatGPT Image 12 Eyl 2026 23_50_40.png"
const OUT := "res://assets/card_question.png"
const OUT_SIZE := 256
const TOL := 42

var _data: PackedByteArray
var _visited: PackedByteArray
var _stack: PackedInt32Array
var _w := 0
var _h := 0
var _br := 0
var _bg := 0
var _bb := 0


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var img := Image.load_from_file(SRC)
    if img == null:
        print("HATA: kaynak PNG yuklenemedi: ", SRC)
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    _w = img.get_width()
    _h = img.get_height()
    print("kaynak: %dx%d" % [_w, _h])

    _data = img.get_data()
    _br = _data[0]
    _bg = _data[1]
    _bb = _data[2]
    print("arka plan rengi: (%d,%d,%d)" % [_br, _bg, _bb])

    _visited = PackedByteArray()
    _visited.resize(_w * _h)
    _stack = PackedInt32Array()

    for x in range(_w):
        _seed(x, 0)
        _seed(x, _h - 1)
    for y in range(_h):
        _seed(0, y)
        _seed(_w - 1, y)

    var filled := 0
    while not _stack.is_empty():
        var i: int = _stack[_stack.size() - 1]
        _stack.remove_at(_stack.size() - 1)
        filled += 1
        _data[i * 4 + 3] = 0
        var x := i % _w
        var y := int(i / _w)
        if x > 0:
            _seed(x - 1, y)
        if x < _w - 1:
            _seed(x + 1, y)
        if y > 0:
            _seed(x, y - 1)
        if y < _h - 1:
            _seed(x, y + 1)

    print("seffaf yapilan piksel: %d (%.1f%%)" % [filled, 100.0 * float(filled) / float(_w * _h)])

    # Kenar temizligi: beyaz kenar halkasi kalmasin (glifin ic parlamalarina dokunmaz,
    # cunku onlarin komsulari seffaf degil).
    var temiz := 0
    for i in range(_w * _h):
        if _data[i * 4 + 3] == 0:
            continue
        var o := i * 4
        if _data[o] > 230 and _data[o + 1] > 230 and _data[o + 2] > 230:
            if _komsuSeffaf(i):
                _data[o + 3] = 0
                temiz += 1
    print("kenar halkasi temizlenen piksel: %d" % temiz)

    var out := Image.create_from_data(_w, _h, false, Image.FORMAT_RGBA8, _data)
    out.resize(OUT_SIZE, OUT_SIZE, Image.INTERPOLATE_LANCZOS)
    var err := out.save_png(OUT)
    if err != OK:
        print("HATA: kaydedilemedi err=%d" % err)
        quit(1)
        return
    print("yazildi: %s  (%dx%d)" % [OUT, OUT_SIZE, OUT_SIZE])

    # --- Kendi ciktisini dogrula: seffaflik gercekten calisti mi? ---
    var chk := Image.load_from_file(ProjectSettings.globalize_path(OUT))
    if chk == null:
        print("DOGRULAMA: cikti geri yuklenemedi")
        quit(1)
        return
    var seffaf := 0
    for y in range(chk.get_height()):
        for x in range(chk.get_width()):
            if chk.get_pixel(x, y).a < 0.05:
                seffaf += 1
    var toplam := chk.get_width() * chk.get_height()
    print("DOGRULAMA: kose alfa=%.2f  merkez alfa=%.2f  seffaf oran=%.1f%%" % [
        chk.get_pixel(0, 0).a,
        chk.get_pixel(chk.get_width() / 2, chk.get_height() / 2).a,
        100.0 * float(seffaf) / float(toplam)])
    quit(0)


func _seed(x: int, y: int) -> void:
    var i := y * _w + x
    if _visited[i] == 1:
        return
    var o := i * 4
    if absi(int(_data[o]) - _br) <= TOL and absi(int(_data[o + 1]) - _bg) <= TOL and absi(int(_data[o + 2]) - _bb) <= TOL:
        _visited[i] = 1
        _stack.append(i)


func _komsuSeffaf(i: int) -> bool:
    var x := i % _w
    var y := int(i / _w)
    if x > 0 and _data[(i - 1) * 4 + 3] == 0:
        return true
    if x < _w - 1 and _data[(i + 1) * 4 + 3] == 0:
        return true
    if y > 0 and _data[(i - _w) * 4 + 3] == 0:
        return true
    if y < _h - 1 and _data[(i + _w) * 4 + 3] == 0:
        return true
    return false