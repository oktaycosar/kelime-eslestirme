# ============================================================
# GameOverPanel.gd
# Tüm çiftler bulununca gösterilen panel.
# ------------------------------------------------------------
# Gösterim:
#   "TEBRİKLER! 🎉"
#   "<N> çiftin tamamını buldun!"
#   [YENİ REKOR! 🏆 rozeti - sadece is_new_record ise]
#   Skor: <s>
#   Süre: MM:SS
#   Hata: <e>
#   Hamle: <m>
#   En İyi Combo: <bc>x 🔥
#   [En İyi: <best_score> - önceki rekor ya da yeni rekor mesajı]
#   [ TEKRAR OYNA ]
# Sinyal:
#   replay_pressed - Main.gd tarafından dinlenir.
# ============================================================
extends Control

signal replay_pressed
signal quit_requested

@onready var title_label: Label = $CenterContainer/DialogPanel/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/DialogPanel/VBox/SubtitleLabel
@onready var stats_label: Label = $CenterContainer/DialogPanel/VBox/StatsLabel
@onready var replay_button: Button = $CenterContainer/DialogPanel/VBox/ReplayButton
@onready var quit_button: Button = $CenterContainer/DialogPanel/VBox/QuitButton
@onready var record_badge: Label = $CenterContainer/DialogPanel/VBox/RecordBadge
@onready var best_score_label: Label = $CenterContainer/DialogPanel/VBox/BestScoreLabel
@onready var difficulty_label: Label = $CenterContainer/DialogPanel/VBox/DifficultyLabel


func _ready() -> void:
        # Başlangıçta gizle
        visible = false
        if not replay_button.pressed.is_connected(_on_replay_pressed):
                replay_button.pressed.connect(_on_replay_pressed)
        if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
                quit_button.pressed.connect(_on_quit_pressed)
        # Rozet başlangıçta gizli
        if record_badge:
                record_badge.visible = false
        if best_score_label:
                best_score_label.visible = false
        if difficulty_label:
                difficulty_label.visible = false


# Paneli göster. Skor / süre / hata / combo / moves / rekor bilgisi ile doldur.
func show_panel(score: int, time_sec: float, errors: int, total_pairs: int,
                                best_combo: int = 0, moves: int = 0, is_new_record: bool = false) -> void:
        if subtitle_label:
                subtitle_label.text = "%d çiftin tamamını buldun!" % total_pairs

        # Zorluk etiketi (Kolay/Orta/Zor/Uzman + seviye numarası)
        if difficulty_label:
                var diff: int = DifficultyManager.current_difficulty
                var level: int = DifficultyManager.get_difficulty_level(diff)
                var pretty: String = DifficultyManager.get_difficulty_label_pretty(diff)
                difficulty_label.text = "Seviye %d • %s" % [level, pretty]
                difficulty_label.visible = true

        # Süre biçimlendir
        var total: int = int(time_sec)
        var m: int = total / 60
        var s: int = total % 60

        # İstatistik metni (combo ve hamle eklendi)
        if stats_label:
                var lines: Array = ["Skor: %d" % score,
                                                        "Süre: %02d:%02d" % [m, s],
                                                        "Hata: %d" % errors]
                if moves > 0:
                        lines.append("Hamle: %d" % moves)
                if best_combo > 0:
                        lines.append("En İyi Combo: %dx 🔥" % best_combo)
                stats_label.text = "\n".join(lines)

        # Yeni rekor rozeti
        if record_badge:
                record_badge.visible = is_new_record

        # En iyi skor satırı
        if best_score_label:
                if is_new_record:
                        best_score_label.text = "🏆 YENİ REKOR!"
                        best_score_label.visible = true
                else:
                        var diff: int = DifficultyManager.current_difficulty
                        var best: Dictionary = SaveManager.load_best_record(diff)
                        if best.has("score"):
                                best_score_label.text = "En İyi: %d" % int(best.get("score", 0))
                                best_score_label.visible = true
                        else:
                                best_score_label.visible = false

        visible = true
        # İlk açılışta butona hafif bounce animasyonu
        if replay_button:
                var tween: Tween = create_tween()
                tween.tween_property(replay_button, "scale", Vector2(1.08, 1.08), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
                tween.tween_property(replay_button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# Paneli gizle
func hide_panel() -> void:
        visible = false


# TEKRAR OYNA butonuna basıldı
func _on_replay_pressed() -> void:
        emit_signal("replay_pressed")

# Kazanma panelindeki Cikis butonu: Main.gd dinler ve oyunu kapatir.
func _on_quit_pressed() -> void:
        emit_signal("quit_requested")
