# ============================================================
# DifficultyManager.gd  (Autoload singleton)
# Zorluk seviyelerini yönetir.
# ------------------------------------------------------------
# EASY   : 6  çift = 12 kart , 4 sütun x 3 satır, 3 ipucu,  -50  penalty
# MEDIUM : 8  çift = 16 kart , 4 sütun x 4 satır, 2 ipucu,  -75  penalty
# HARD   : 10 çift = 20 kart , 5 sütun x 4 satır, 1 ipucu,  -100 penalty
# EXPERT : 15 çift = 30 kart , 5 sütun x 6 satır, 1 ipucu,  -150 penalty
#   (iki sütunlu layout'ta grid sütun sayısı kullanılmaz ama geri
#    uyumluluk için tutulur; UI'da "Uzman" etiketi gösterilir.)
# ============================================================
extends Node

enum Difficulty { EASY, MEDIUM, HARD, EXPERT }

# Şu anki zorluk. EASY varsayılan.
var current_difficulty: int = Difficulty.EASY


# Zorluğa göre çift sayısı
func get_pair_count(difficulty: int) -> int:
        match difficulty:
                Difficulty.EASY:
                        return 6
                Difficulty.MEDIUM:
                        return 8
                Difficulty.HARD:
                        return 10
                Difficulty.EXPERT:
                        return 15
                _:
                        return 6


# Zorluğa göre grid sütun sayısı (satır = kart_sayisi / sutun).
# İki sütunlu layout'ta kullanılmaz; geri uyumluluk için tutulur.
func get_grid_columns(difficulty: int) -> int:
        match difficulty:
                Difficulty.EASY:
                        return 4
                Difficulty.MEDIUM:
                        return 4
                Difficulty.HARD:
                        return 5
                Difficulty.EXPERT:
                        return 5
                _:
                        return 4


# Zorluğa göre kart sayısı (2 * çift)
func get_card_count(difficulty: int) -> int:
        return get_pair_count(difficulty) * 2


# Zorluğa göre ipucu hakkı sayısı
func get_hint_count(difficulty: int) -> int:
        match difficulty:
                Difficulty.EASY:
                        return 3
                Difficulty.MEDIUM:
                        return 2
                Difficulty.HARD:
                        return 1
                Difficulty.EXPERT:
                        return 1
                _:
                        return 3


# Zorluğa göre ipucu kullanınca kesilen puan
func get_hint_penalty(difficulty: int) -> int:
        match difficulty:
                Difficulty.EASY:
                        return 50
                Difficulty.MEDIUM:
                        return 75
                Difficulty.HARD:
                        return 100
                Difficulty.EXPERT:
                        return 150
                _:
                        return 50


# Zorluk seviyesi numarası (1..4). UI'da "Seviye X" gösterimi için.
func get_difficulty_level(difficulty: int) -> int:
        match difficulty:
                Difficulty.EASY:
                        return 1
                Difficulty.MEDIUM:
                        return 2
                Difficulty.HARD:
                        return 3
                Difficulty.EXPERT:
                        return 4
                _:
                        return 1


# Aktif zorluğu ayarla
func set_difficulty(difficulty: int) -> void:
        current_difficulty = difficulty


# Zorluk etiketi (UI'da göstermek için)
func get_difficulty_label(difficulty: int) -> String:
        match difficulty:
                Difficulty.EASY:
                        return "KOLAY"
                Difficulty.MEDIUM:
                        return "ORTA"
                Difficulty.HARD:
                        return "ZOR"
                Difficulty.EXPERT:
                        return "UZMAN"
                _:
                        return "KOLAY"


# Zorluk etiketinin Türkçe karşılığı (UI header için, daha okunaklı)
func get_difficulty_label_pretty(difficulty: int) -> String:
        match difficulty:
                Difficulty.EASY:
                        return "Kolay"
                Difficulty.MEDIUM:
                        return "Orta"
                Difficulty.HARD:
                        return "Zor"
                Difficulty.EXPERT:
                        return "Uzman"
                _:
                        return "Kolay"
