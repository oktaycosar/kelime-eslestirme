# ============================================================
# GameModeManager.gd  (Autoload singleton)
# Oyun modu sistemini yönetir (Web Task 12 ile parite).
# ------------------------------------------------------------
# 4 oyun modu:
#   CLASSIC  : Rastgele yön - herhangi sütundan başla
#   TR_TO_EN: Türkçe → İngilizce - ilk kart Türkçe olmalı
#   EN_TO_TR: İngilizce → Türkçe - ilk kart İngilizce olmalı
#   AUDIO    : Sesli mod - ilk kart İngilizce (ses çalar,
#              kullanıcı Türkçe karşılığı bulur)
#
# API:
#   set_mode(mode)              -> current_mode güncelle, sinyal yay
#   get_first_card_language()   -> "" | "turkish" | "english"
#   get_mode_label(mode)        -> "Klasik" | "Türkçe → İngilizce" | ...
#   get_mode_emoji(mode)        -> "🎲" | "🇹🇷" | "🇬🇧" | "🔊"
#   get_mode_description(mode)   -> kısa açıklama metni
#
# Sinyal:
#   mode_changed(mode: GameMode) -> Main.gd dinler, oyunu yeniden başlatır
# ============================================================
extends Node

# --- Oyun modu enum ---
# Değerler: CLASSIC=0, TR_TO_EN=1, EN_TO_TR=2, AUDIO=3
enum GameMode { CLASSIC, TR_TO_EN, EN_TO_TR, AUDIO }

# --- Mevcut mod (varsayılan: CLASSIC) ---
var current_mode: int = GameMode.CLASSIC

# --- Mod etiketleri (Türkçe) ---
const MODE_LABELS: Dictionary = {
        GameMode.CLASSIC: "Klasik",
        GameMode.TR_TO_EN: "Türkçe → İngilizce",
        GameMode.EN_TO_TR: "İngilizce → Türkçe",
        GameMode.AUDIO: "Sesli Mod",
}

# --- Mod emojileri ---
const MODE_EMOJIS: Dictionary = {
        GameMode.CLASSIC: "🎲",
        GameMode.TR_TO_EN: "🇹🇷",
        GameMode.EN_TO_TR: "🇬🇧",
        GameMode.AUDIO: "🔊",
}

# --- Mod açıklamaları (UI tooltip / bilgi için) ---
const MODE_DESCRIPTIONS: Dictionary = {
        GameMode.CLASSIC: "Herhangi bir sütundan başla - rastgele yön",
        GameMode.TR_TO_EN: "Önce Türkçe kart seç, sonra İngilizce karşılığını bul",
        GameMode.EN_TO_TR: "Önce İngilizce kart seç, sonra Türkçe karşılığını bul",
        GameMode.AUDIO: "İngilizce kelime duyulur, Türkçe karşılığını bul",
}

# --- Sinyaller ---
# Mod değiştiğinde yayılır. Main.gd dinler ve oyunu yeniden başlatır.
signal mode_changed(mode: int)


# Mevcut modu ayarla. Aynı mod tekrar seçilirse sinyal yayılmaz (no-op).
# Main.gd bu fonksiyonu çağırır; mode_changed sinyali Main._new_game'i tetikler.
func set_mode(mode: int) -> void:
        # Geçerlilik kontrolü: 0..3 aralığı dışıysa no-op
        if mode < 0 or mode > 3:
                push_warning("GameModeManager: Geçersiz mod değeri: %d" % mode)
                return
        if mode == current_mode:
                return
        current_mode = mode
        emit_signal("mode_changed", current_mode)


# Bu modda ilk kart hangi dilde olmalı?
#   CLASSIC   -> ""  (herhangi dil)
#   TR_TO_EN  -> "turkish"
#   EN_TO_TR  -> "english"
#   AUDIO     -> "english" (önce İngilizce kart seçilir, ses çalar)
# Boş string dönerse GameManager ilk kart kontrolü yapmaz (klasik davranış).
func get_first_card_language() -> String:
        match current_mode:
                GameMode.TR_TO_EN:
                        return "turkish"
                GameMode.EN_TO_TR:
                        return "english"
                GameMode.AUDIO:
                        return "english"
                GameMode.CLASSIC:
                        return ""
                _:
                        return ""


# Belirli bir mod için ilk kart dilini döndür (parametre olarak mod alır).
# Testler ve Main.gd mod buton kurulumu için kullanır.
func get_first_card_language_for(mode: int) -> String:
        match mode:
                GameMode.TR_TO_EN:
                        return "turkish"
                GameMode.EN_TO_TR:
                        return "english"
                GameMode.AUDIO:
                        return "english"
                GameMode.CLASSIC:
                        return ""
                _:
                        return ""


# Mod etiketini (Türkçe) döndür.
func get_mode_label(mode: int) -> String:
        if MODE_LABELS.has(mode):
                return MODE_LABELS[mode]
        return "Bilinmeyen"


# Mod emoji'sini döndür.
func get_mode_emoji(mode: int) -> String:
        if MODE_EMOJIS.has(mode):
                return MODE_EMOJIS[mode]
        return ""


# Mod açıklamasını döndür.
func get_mode_description(mode: int) -> String:
        if MODE_DESCRIPTIONS.has(mode):
                return MODE_DESCRIPTIONS[mode]
        return ""


# Buton metni için "emoji + label" formatı.
func get_mode_button_text(mode: int) -> String:
        return "%s %s" % [get_mode_emoji(mode), get_mode_label(mode)]


# Sesli mod aktif mi? (AudioManager'a bildirmek için)
func is_audio_mode() -> bool:
        return current_mode == GameMode.AUDIO


# Tüm modların listesi (sıralı) - UI kurulumu için.
func get_all_modes() -> Array:
        return [GameMode.CLASSIC, GameMode.TR_TO_EN, GameMode.EN_TO_TR, GameMode.AUDIO]


# Mevcut modun etiketi (kısa yol).
func get_current_mode_label() -> String:
        return get_mode_label(current_mode)


# Mevcut modun emoji'si (kısa yol).
func get_current_mode_emoji() -> String:
        return get_mode_emoji(current_mode)
