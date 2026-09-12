# ============================================================
# SaveManager.gd  (Autoload singleton)
# En iyi skor + oyun istatistiklerini kalıcı olarak kaydeder.
# ------------------------------------------------------------
# Kayıt dosyası: user://memory_best_save.json (Godot user dir)
# Format:
# {
#   "best_records": {
#     "EASY":   {"score": int, "time": float, "errors": int, "moves": int, "date": String},
#     "MEDIUM": {...},
#     "HARD":   {...},
#     "EXPERT": {...}
#   },
#   "game_stats": {
#     "EASY":   {"games_played", "games_won", "total_score", "best_score",
#                "best_time", "total_errors", "total_moves", "total_time", "best_combo"},
#     "MEDIUM": {...},
#     "HARD":   {...},
#     "EXPERT": {...}
#   }
# }
# Hata durumunda (dosya yok / bozuk JSON) sessizce sıfırlar, crash ETMEZ.
# ============================================================
extends Node

const SAVE_PATH: String = "user://memory_best_save.json"

# Bellek içi veri
var _data: Dictionary = {}


func _ready() -> void:
        _load_data()


# --- İç yükleme / kaydetme ---

func _load_data() -> void:
        if not FileAccess.file_exists(SAVE_PATH):
                _data = _empty_data()
                return
        var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
        if f == null:
                push_warning("SaveManager: Kayıt dosyası açılamadı: %s" % SAVE_PATH)
                _data = _empty_data()
                return
        var text: String = f.get_as_text()
        f.close()
        var parsed: Variant = JSON.parse_string(text)
        if typeof(parsed) != TYPE_DICTIONARY:
                push_warning("SaveManager: Kayıt dosyası geçersiz JSON, sıfırlanıyor.")
                _data = _empty_data()
                return
        _data = parsed
        # Eksik alanları tamamla
        if not _data.has("best_records") or typeof(_data["best_records"]) != TYPE_DICTIONARY:
                _data["best_records"] = {}
        if not _data.has("game_stats") or typeof(_data["game_stats"]) != TYPE_DICTIONARY:
                _data["game_stats"] = {}
        for diff in ["EASY", "MEDIUM", "HARD", "EXPERT"]:
                if not _data["best_records"].has(diff):
                        _data["best_records"][diff] = {}
                if not _data["game_stats"].has(diff):
                        _data["game_stats"][diff] = _empty_stats()


func _save_data() -> void:
        var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        if f == null:
                push_warning("SaveManager: Kayıt dosyası yazılamadı: %s" % SAVE_PATH)
                return
        f.store_string(JSON.stringify(_data, "  "))
        f.close()


func _empty_data() -> Dictionary:
        return {
                "best_records": {
                        "EASY": {},
                        "MEDIUM": {},
                        "HARD": {},
                        "EXPERT": {}
                },
                "game_stats": {
                        "EASY": _empty_stats(),
                        "MEDIUM": _empty_stats(),
                        "HARD": _empty_stats(),
                        "EXPERT": _empty_stats()
                }
        }


func _empty_stats() -> Dictionary:
        return {
                "games_played": 0,
                "games_won": 0,
                "total_score": 0,
                "best_score": 0,
                "best_time": 0.0,
                "total_errors": 0,
                "total_moves": 0,
                "total_time": 0.0,
                "best_combo": 0
        }


func _difficulty_key(difficulty: int) -> String:
        match difficulty:
                DifficultyManager.Difficulty.EASY:
                        return "EASY"
                DifficultyManager.Difficulty.MEDIUM:
                        return "MEDIUM"
                DifficultyManager.Difficulty.HARD:
                        return "HARD"
                DifficultyManager.Difficulty.EXPERT:
                        return "EXPERT"
                _:
                        return "EASY"


# --- En iyi skor API ---

# Verilen zorluk için en iyi kaydı döndürür (yoksa boş Dictionary).
func load_best_record(difficulty: int) -> Dictionary:
        var key: String = _difficulty_key(difficulty)
        var records: Dictionary = _data.get("best_records", {})
        return records.get(key, {})


# Yeni rekor mu? (skor > mevcut; eşitse süre <, eşitse hata <, eşitse hamle <)
func is_new_record(difficulty: int, score: int, time: float, errors: int, moves: int) -> bool:
        var best: Dictionary = load_best_record(difficulty)
        if not best.has("score"):
                return true  # İlk kayıt
        var b_score: int = int(best.get("score", 0))
        if score > b_score:
                return true
        if score < b_score:
                return false
        # Skor eşitse süre kısa olan kazanır
        var b_time: float = float(best.get("time", 9e9))
        if time < b_time:
                return true
        if time > b_time:
                return false
        # Süre eşitse az hataya bak
        var b_err: int = int(best.get("errors", 0))
        if errors < b_err:
                return true
        if errors > b_err:
                return false
        # Hata eşitse az hamleye bak
        var b_moves: int = int(best.get("moves", 0))
        if moves < b_moves:
                return true
        return false


# Sadece daha iyiyse kaydeder. True dönerse kaydedildi.
func save_best_record(difficulty: int, score: int, time: float, errors: int, moves: int) -> bool:
        if not is_new_record(difficulty, score, time, errors, moves):
                return false
        var key: String = _difficulty_key(difficulty)
        _data["best_records"][key] = {
                "score": score,
                "time": time,
                "errors": errors,
                "moves": moves,
                "date": Time.get_datetime_string_from_system(false, true)
        }
        _save_data()
        return true


# --- Oyun istatistikleri API ---

# Bir oyunun sonucunu istatistiklere yansıtır (won=false desteği ile).
func record_game_result(difficulty: int, won: bool, score: int, time_sec: float, errors: int, moves: int, best_combo: int) -> void:
        var key: String = _difficulty_key(difficulty)
        if not _data["game_stats"].has(key):
                _data["game_stats"][key] = _empty_stats()
        var s: Dictionary = _data["game_stats"][key]
        s["games_played"] = int(s.get("games_played", 0)) + 1
        if won:
                s["games_won"] = int(s.get("games_won", 0)) + 1
        s["total_score"] = int(s.get("total_score", 0)) + score
        s["total_errors"] = int(s.get("total_errors", 0)) + errors
        s["total_moves"] = int(s.get("total_moves", 0)) + moves
        s["total_time"] = float(s.get("total_time", 0.0)) + time_sec
        if score > int(s.get("best_score", 0)):
                s["best_score"] = score
        if won:
                var bt: float = float(s.get("best_time", 0.0))
                if bt == 0.0 or time_sec < bt:
                        s["best_time"] = time_sec
        if best_combo > int(s.get("best_combo", 0)):
                s["best_combo"] = best_combo
        _data["game_stats"][key] = s
        _save_data()


# Tüm istatistik verisini döndürür.
func load_game_stats() -> Dictionary:
        return _data.get("game_stats", {})


# Belirli bir zorluğun istatistiklerini döndürür.
func load_difficulty_stats(difficulty: int) -> Dictionary:
        var key: String = _difficulty_key(difficulty)
        return _data.get("game_stats", {}).get(key, _empty_stats())


# Tüm kayıtları ve istatistikleri sıfırlar (debug / ayarlar için).
func clear_all() -> void:
        _data = _empty_data()
        _save_data()
