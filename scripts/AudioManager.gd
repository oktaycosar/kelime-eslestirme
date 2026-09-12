# ============================================================
# AudioManager.gd  (Autoload singleton)
# Ses efektlerini güvenli yükler ve çalar.
# ------------------------------------------------------------
# Ses dosyaları assets/sounds/ altında:
#   flip.wav   -> kart açma
#   match.wav  -> doğru eşleşme
#   wrong.wav  -> yanlış eşleşme
#   win.wav    -> oyun kazanıldı
#   hint.wav   -> ipucu gösterimi (opsiyonel)
#   pause.wav  -> duraklatma (opsiyonel)
#   resume.wav -> devam et (opsiyonel)
# Dosya YOKSA oyun hata vermez, sessizce devam eder.
# (ResourceLoader.exists() ile kontrol edilir.)
# Mute toggle: toggle_mute() -> bool (yeni muted durumu)
#
# Sesli mod (AUDIO game mode):
#   set_audio_mode(enabled: bool) -> sesli mod açık/kapalı
#   play_word(word: String)       -> assets/sounds/words/{word}.wav/.ogg
#     çal (varsa), yoksa sessizce atla (kelime havuzunda ses dosyası olmayabilir).
#   Kelime ses dosyaları cache'lenir (ilk çalmada yüklenir, sonra yeniden kullanılır).
# ============================================================
extends Node

# Ses dosya yolları
const FLIP_PATH: String = "res://assets/sounds/flip.wav"
const MATCH_PATH: String = "res://assets/sounds/match.wav"
const WRONG_PATH: String = "res://assets/sounds/wrong.wav"
const WIN_PATH: String = "res://assets/sounds/win.wav"
const HINT_PATH: String = "res://assets/sounds/hint.wav"
const PAUSE_PATH: String = "res://assets/sounds/pause.wav"
const RESUME_PATH: String = "res://assets/sounds/resume.wav"

# Kelime ses dosyaları klasörü (Sesli mod için)
const WORDS_DIR: String = "res://assets/sounds/words/"
# Kelime ses dosyası için denenecek uzantılar (öncelik sırasıyla)
const WORD_EXTS: Array = [".wav", ".ogg", ".mp3"]

# Yüklenen AudioStream'ler (yoksa null)
var flip_stream: AudioStream = null
var match_stream: AudioStream = null
var wrong_stream: AudioStream = null
var win_stream: AudioStream = null
var hint_stream: AudioStream = null
var pause_stream: AudioStream = null
var resume_stream: AudioStream = null

# AudioStreamPlayer'lar
var _flip_player: AudioStreamPlayer = null
var _match_player: AudioStreamPlayer = null
var _wrong_player: AudioStreamPlayer = null
var _win_player: AudioStreamPlayer = null
var _hint_player: AudioStreamPlayer = null
var _pause_player: AudioStreamPlayer = null
var _resume_player: AudioStreamPlayer = null
# Kelime sesleri için ayrı player (flip/match ile çakışmasın)
var _word_player: AudioStreamPlayer = null

# Kelime ses cache: { word (String) -> AudioStream (or null) }
# Bir kelime için ilk arama null (yok) dönmüşse, null cache'lenir
# (her aramada tekrar disk kontrolü yapmamak için).
var _word_stream_cache: Dictionary = {}

# Genel ses düzeyi (0..1)
var master_volume: float = 0.6
# Sessize alındı mı (M tuşu / buton ile)
var is_muted: bool = false

# Sesli mod (AUDIO game mode) açık mı?
# true ise GameManager.select_card ilk kart İngilizce seçildiğinde
# AudioManager.play_word(card.word) çağrılır.
var audio_mode_enabled: bool = false


func _ready() -> void:
        # 7 ayrı player oluştur (üst üste binen sesler için)
        _flip_player = AudioStreamPlayer.new()
        _flip_player.name = "FlipPlayer"
        _match_player = AudioStreamPlayer.new()
        _match_player.name = "MatchPlayer"
        _wrong_player = AudioStreamPlayer.new()
        _wrong_player.name = "WrongPlayer"
        _win_player = AudioStreamPlayer.new()
        _win_player.name = "WinPlayer"
        _hint_player = AudioStreamPlayer.new()
        _hint_player.name = "HintPlayer"
        _pause_player = AudioStreamPlayer.new()
        _pause_player.name = "PausePlayer"
        _resume_player = AudioStreamPlayer.new()
        _resume_player.name = "ResumePlayer"
        # Kelime sesleri için ayrı player
        _word_player = AudioStreamPlayer.new()
        _word_player.name = "WordPlayer"

        add_child(_flip_player)
        add_child(_match_player)
        add_child(_wrong_player)
        add_child(_win_player)
        add_child(_hint_player)
        add_child(_pause_player)
        add_child(_resume_player)
        add_child(_word_player)

        _load_all_streams()


# Tüm ses akışlarını güvenli şekilde yükler
func _load_all_streams() -> void:
        flip_stream = _safe_load_stream(FLIP_PATH)
        match_stream = _safe_load_stream(MATCH_PATH)
        wrong_stream = _safe_load_stream(WRONG_PATH)
        win_stream = _safe_load_stream(WIN_PATH)
        hint_stream = _safe_load_stream(HINT_PATH)
        pause_stream = _safe_load_stream(PAUSE_PATH)
        resume_stream = _safe_load_stream(RESUME_PATH)

        if flip_stream:
                _flip_player.stream = flip_stream
        if match_stream:
                _match_player.stream = match_stream
        if wrong_stream:
                _wrong_player.stream = wrong_stream
        if win_stream:
                _win_player.stream = win_stream
        if hint_stream:
                _hint_player.stream = hint_stream
        if pause_stream:
                _pause_player.stream = pause_stream
        if resume_stream:
                _resume_player.stream = resume_stream


# Bir yolu güvenli yükler; AudioStream değilse veya yoksa null döner.
func _safe_load_stream(path: String) -> AudioStream:
        if not ResourceLoader.exists(path):
                push_warning("AudioManager: Ses dosyası bulunamadı (sessizce atlandı): %s" % path)
                return null
        var res = load(path)
        if res == null:
                push_warning("AudioManager: Yükleme başarısız: %s" % path)
                return null
        if not (res is AudioStream):
                push_warning("AudioManager: Kaynak AudioStream değil: %s" % path)
                return null
        return res


# --- Genel ses kontrolü ---
func set_master_volume(value: float) -> void:
        master_volume = clampf(value, 0.0, 1.0)
        _apply_volume()


# Sessize al / aç. Yeni is_muted durumunu döndürür.
func toggle_mute() -> bool:
        is_muted = not is_muted
        _apply_volume()
        return is_muted


func _apply_volume() -> void:
        for p in [_flip_player, _match_player, _wrong_player, _win_player,
                          _hint_player, _pause_player, _resume_player, _word_player]:
                if p == null:
                        continue
                if is_muted:
                        p.volume_db = -80.0
                else:
                        p.volume_db = linear_to_db(master_volume) if master_volume > 0.0 else -80.0


# --- Çalma fonksiyonları ---
func play_flip() -> void:
        _play_on(_flip_player)

func play_match() -> void:
        _play_on(_match_player)

func play_wrong() -> void:
        _play_on(_wrong_player)

func play_win() -> void:
        _play_on(_win_player)

func play_hint() -> void:
        _play_on(_hint_player)

func play_pause() -> void:
        _play_on(_pause_player)

func play_resume() -> void:
        _play_on(_resume_player)


# --- Sesli mod (AUDIO game mode) fonksiyonları ---

# Sesli modu aç/kapat. GameModeManager.set_mode tarafından dolaylı
# (Main.gd _on_mode_changed içinde) çağrılır. Sesli mod açıkken:
# - GameManager.select_card ilk kart İngilizce ise play_word(card.word) çağrılır
# - Bu fonksiyon yalnızca bayrak tutar, gerçek ses çalma play_word içindedir.
func set_audio_mode(enabled: bool) -> void:
        audio_mode_enabled = enabled
        print("AudioManager: sesli mod ", "AÇIK" if enabled else "KAPALI")


# Verilen kelimenin ses dosyasını çal (Sesli mod için).
# Önce WORD_EXTS sırasıyla (wav/ogg/mp3) dosya arar; ilk bulunanı çalar.
# Kelime ses dosyası yoksa sessizce atlar (warning log, hata vermez).
# Cache: aynı kelime için ilk aramadan sonra result cache'lenir.
# Boş/null kelime yoksayılır.
func play_word(word: String) -> void:
        if word == null or word == "":
                return
        if _word_player == null:
                return
        if is_muted:
                return

        # Cache kontrolü
        var stream: AudioStream = null
        if _word_stream_cache.has(word):
                stream = _word_stream_cache[word]
        else:
                stream = _load_word_stream(word)
                _word_stream_cache[word] = stream  # null da cache'lenir

        if stream == null:
                # Ses dosyası yok - sessizce atla (placeholder durum)
                # print("AudioManager: kelime ses dosyası yok: ", word)
                return

        # Player'a stream ata ve çal
        if _word_player.stream != stream:
                _word_player.stream = stream
        if _word_player.playing:
                _word_player.stop()
        _word_player.volume_db = linear_to_db(master_volume) if master_volume > 0.0 else -80.0
        _word_player.play()


# Bir kelime için ses dosyasını diskten yükle (cache'e koymadan önce).
# Önce WORDS_DIR/word.wav, sonra .ogg, .mp3 dener. Yoksa null döner.
func _load_word_stream(word: String) -> AudioStream:
        # Güvenlik: kelimeyi yol için güvenli hale getir (sadece alfanumerik).
        # Türkçe karakterler ve boşluklar dosya adlarında sorun olabilir,
        # bu yüzden normalize edilmiş bir slug kullanırız. Gerçek dosyalar
        # bu slug'la eşleşmelidir (örn. "ELMA" -> "elma.wav").
        var slug: String = _slugify_word(word)
        if slug == "":
                return null
        for ext in WORD_EXTS:
                var path: String = WORDS_DIR + slug + ext
                if ResourceLoader.exists(path):
                        var res = load(path)
                        if res != null and res is AudioStream:
                                return res
        return null


# Kelimeyi dosya adı için güvenli slug'a çevir.
# Türkçe karakterler ASCII karşılığına, büyük harfler küçüğe,
# boşluklar "_" alt çizgiye. (örn. "ELMA" -> "elma", "KÖPEK" -> "kopek")
func _slugify_word(word: String) -> String:
        var s: String = word.to_lower()
        # Türkçe karakter eşlemeleri
        var tr_map: Dictionary = {
                "ç": "c", "ğ": "g", "ı": "i", "ö": "o", "ş": "s", "ü": "u",
                "î": "i", "â": "a", "û": "u",
        }
        for k in tr_map.keys():
                s = s.replace(k, tr_map[k])
        # Boşluk -> alt çizgi
        s = s.replace(" ", "_")
        # Yalnızca alfanumerik + alt çizgi tut
        var out: String = ""
        for ch in s:
                if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
                        out += ch
        return out


# Bir kelime için ses dosyası yüklenmiş mi? (test / debug için)
func is_word_loaded(word: String) -> bool:
        if word == null or word == "":
                return false
        if not _word_stream_cache.has(word):
                return false
        return _word_stream_cache[word] != null


# Kelime cache'ini temizle (yeni ses dosyaları eklendikten sonra çağrılabilir).
func clear_word_cache() -> void:
        _word_stream_cache.clear()


# Player'da stream varsa baştan çal
func _play_on(player: AudioStreamPlayer) -> void:
        if player == null:
                return
        if player.stream == null:
                return
        if is_muted:
                return  # Sessize alınmışsa çalma
        if player.playing:
                player.stop()
        player.volume_db = linear_to_db(master_volume) if master_volume > 0.0 else -80.0
        player.play()


# Seslerin yüklü olup olmadığını UI / debug için döndür
func is_flip_loaded() -> bool:
        return flip_stream != null

func is_match_loaded() -> bool:
        return match_stream != null

func is_wrong_loaded() -> bool:
        return wrong_stream != null

func is_win_loaded() -> bool:
        return win_stream != null

func is_hint_loaded() -> bool:
        return hint_stream != null

func is_pause_loaded() -> bool:
        return pause_stream != null

func is_resume_loaded() -> bool:
        return resume_stream != null
