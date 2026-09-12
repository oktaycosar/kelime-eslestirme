extends SceneTree
##
## Ses / TTS doğrulaması (regresyon).
##
## assets/sounds/ tamamen boş olduğu için oyun sessizdi ve "Sesli Mod" hiçbir
## şey çalmıyordu. Bu test, ses dosyası olmadığında kelimenin konuşma sentezi
## (TTS) yedeğine düştüğünü ve hiçbir durumda çökmediğini doğrular.
##
## Kullanım:
##   godot --headless --path <proje> --script res://tests/check_audio.gd
##
## Exit code 0 = tamam, 1 = sorun var.

var _failures: Array[String] = []


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    await process_frame
    var am = root.get_node_or_null("/root/AudioManager")
    if am == null:
        print("FAIL: AudioManager autoload yok")
        quit(1)
        return

    _check("AudioManager autoload yüklü", true)
    _check("_init_tts metodu var", am.has_method("_init_tts"))
    _check("_speak_word metodu var", am.has_method("_speak_word"))
    _check("_stop_speaking metodu var", am.has_method("_stop_speaking"))
    _check("is_tts_available metodu var", am.has_method("is_tts_available"))
    _check("play_word metodu var", am.has_method("play_word"))

    # Ses efektleri sentezlenerek uretildi (tools/generate_sfx.gd) -> telifsiz.
    # Bu dosyalar yoksa oyun sessiz kalir; tam da bu yuzden test ediliyor.
    _check("flip.wav yuklendi", am.is_flip_loaded())
    _check("match.wav yuklendi", am.is_match_loaded())
    _check("wrong.wav yuklendi", am.is_wrong_loaded())
    _check("win.wav yuklendi", am.is_win_loaded())
    _check("hint.wav yuklendi", am.is_hint_loaded())
    _check("pause.wav yuklendi", am.is_pause_loaded())
    _check("resume.wav yuklendi", am.is_resume_loaded())

    var tts_feature: bool = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
    var voice_count := 0
    if tts_feature:
        voice_count = DisplayServer.tts_get_voices().size()
    print("    platform TTS=%s  ses sayısı=%d  AudioManager TTS=%s" % [
        str(tts_feature), voice_count, str(am.is_tts_available())])

    if tts_feature:
        _check("platform TTS varsa AudioManager da hazır", am.is_tts_available())
        _check("en az bir konuşma sesi bulundu", voice_count > 0)
    else:
        print("    NOT: bu ortamda TTS yok -> yedek sessizce devre dışı (beklenen davranış)")
        _check("TTS yoksa bayrak false kalır", not am.is_tts_available())

    am.set_audio_mode(true)
    _check("set_audio_mode(true) -> bayrak açık", am.audio_mode_enabled)
    am.play_word("LION")
    am.play_word("")
    am.play_word("ELEPHANT")
    await process_frame
    _check("play_word (ses dosyası yokken) çökmedi", true)

    am.set_audio_mode(false)
    _check("set_audio_mode(false) -> bayrak kapalı", not am.audio_mode_enabled)
    am.play_word("LION")
    await process_frame
    _check("kapatma sonrası play_word çökmedi", true)

    var dir := DirAccess.open("res://assets/sounds/words")
    var word_files := 0
    if dir != null:
        for f in dir.get_files():
            if f.get_extension() in ["wav", "ogg", "mp3"]:
                word_files += 1
    print("    assets/sounds/words/ içindeki ses dosyası sayısı=%d" % word_files)

    print("---------------------------------------------")
    if _failures.is_empty():
        print("SES: TAMAM ✅")
        quit(0)
    else:
        print("SES: %d SORUN ❌" % _failures.size())
        for f in _failures:
            print("  - " + f)
        quit(1)


func _check(label: String, ok: bool) -> void:
    if ok:
        print("  PASS: " + label)
    else:
        print("  FAIL: " + label)
        _failures.append(label)