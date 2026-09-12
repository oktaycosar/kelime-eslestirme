extends SceneTree
##
## Ses efektlerini SENTEZLEYEREK üretir -> telif/lisans sorunu yoktur.
##
## Neden: assets/sounds/ boştu, AudioManager.play_flip/match/wrong/win/hint
## çağrılıyordu ama çalacak dosya yoktu; oyun tamamen sessizdi.
## Dışarıdan ses indirmek yerine burada sinüs dalgalarıyla üretiyoruz:
## dosyalar tamamen özgün, hiçbir lisans/atıf gerektirmez.
##
## Kullanım (bir kez):
##   godot --headless --path <proje> --script res://tools/generate_sfx.gd
##
## Sonra Godot dosyaları içe aktarır; OYUNU BİR KEZ çalıştırıp tekrar dene.

const RATE := 44100
const OUT_DIR := "res://assets/sounds"

var _made := 0


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    DirAccess.make_dir_recursive_absolute(OUT_DIR)

    # --- Kart açılma: kısa, yumuşak "tık" (hızlı ardışık açmada rahatsız etmesin) ---
    var flip := _buf(0.09)
    _tone(flip, 0.0, 0.09, 760.0, 1180.0, 0.34, 7.0)

    # --- Eşleşme: yükselen iki notalı parlak çıngırak (E5 -> B5) ---
    var match := _buf(0.42)
    _tone(match, 0.00, 0.22, 659.0, 659.0, 0.40, 4.0)
    _tone(match, 0.09, 0.33, 988.0, 988.0, 0.42, 3.2)

    # --- Yanlış: alçalan yumuşak vınlama (çocuk için sert değil) ---
    var wrong := _buf(0.30)
    _tone(wrong, 0.0, 0.28, 330.0, 205.0, 0.34, 2.6)

    # --- Kazanma: C-E-G-C yükselen arpej ---
    var win := _buf(0.95)
    _tone(win, 0.00, 0.30, 523.0, 523.0, 0.34, 3.0)
    _tone(win, 0.11, 0.32, 659.0, 659.0, 0.36, 2.8)
    _tone(win, 0.22, 0.34, 784.0, 784.0, 0.38, 2.6)
    _tone(win, 0.34, 0.58, 1047.0, 1047.0, 0.42, 2.2)

    # --- İpucu: kısa ışıltı (yükselen tiz) ---
    var hint := _buf(0.26)
    _tone(hint, 0.00, 0.12, 1350.0, 1750.0, 0.26, 5.0)
    _tone(hint, 0.07, 0.19, 1900.0, 2350.0, 0.22, 5.0)

    # --- Duraklat: kısa alçalan ikili / Devam: kısa yükselen ikili ---
    var pause := _buf(0.15)
    _tone(pause, 0.0, 0.13, 540.0, 370.0, 0.30, 4.5)
    var resume := _buf(0.15)
    _tone(resume, 0.0, 0.13, 370.0, 540.0, 0.30, 4.5)

    _save("flip.wav", flip)
    _save("match.wav", match)
    _save("wrong.wav", wrong)
    _save("win.wav", win)
    _save("hint.wav", hint)
    _save("pause.wav", pause)
    _save("resume.wav", resume)

    print("--- %d ses dosyası üretildi: %s" % [_made, OUT_DIR])
    quit(0 if _made == 7 else 1)


# --- Sentez yardımcıları ---

func _buf(dur: float) -> PackedFloat32Array:
    var a := PackedFloat32Array()
    a.resize(int(dur * RATE))
    a.fill(0.0)
    return a


# Yumuşak girişli + üstel sönümlü, fazı doğru hesaplanmış sinüs tonu.
# f0 -> f1 arası kayar (glissando). buffer'a TOPLAYARAK ekler (üst üste binme).
func _tone(buffer: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, amp: float, decay: float) -> void:
    var s := int(start * RATE)
    var n := int(dur * RATE)
    var phase := 0.0
    for i in range(n):
        var idx := s + i
        if idx >= buffer.size():
            break
        var p := float(i) / float(n)
        var f: float = lerpf(f0, f1, p)
        phase += TAU * f / float(RATE)
        var env: float = exp(-decay * p) * (1.0 - p)
        var atk: float = minf(1.0, (float(i) / float(RATE)) / 0.006)
        buffer[idx] += sin(phase) * amp * env * atk


func _save(name: String, buffer: PackedFloat32Array) -> void:
    # Tepe noktasına göre normalize et (kırpma olmasın)
    var peak := 0.0
    for v in buffer:
        peak = maxf(peak, absf(v))
    var gain: float = (0.72 / peak) if peak > 0.0001 else 1.0

    var data := PackedByteArray()
    data.resize(buffer.size() * 2)
    for i in range(buffer.size()):
        var v := int(clampf(buffer[i] * gain, -1.0, 1.0) * 32767.0)
        if v < 0:
            v += 65536
        data[i * 2] = v & 0xFF
        data[i * 2 + 1] = (v >> 8) & 0xFF

    var st := AudioStreamWAV.new()
    st.format = AudioStreamWAV.FORMAT_16_BITS
    st.mix_rate = RATE
    st.stereo = false
    st.data = data

    var path := OUT_DIR + "/" + name
    var err := st.save_to_wav(path)
    if err == OK:
        _made += 1
        print("  OK   %-12s %5.2f sn  %6d örnek" % [name, float(buffer.size()) / RATE, buffer.size()])
    else:
        print("  HATA %-12s err=%d" % [name, err])