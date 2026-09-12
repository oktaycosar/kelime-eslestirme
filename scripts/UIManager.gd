# ============================================================
# UIManager.gd
# Oyun üst bilgi panelini (6 stat) yönetir:
#   Skor, Eşleşme, Hata, Süre, Hamle, Combo
# GameManager sinyallerini dinler ve etiketleri günceller.
# Main.tscn içinde bir Node olarak yer alır.
# ============================================================
extends Node

# --- Etiket referansları (Main.tscn ağacına göre) ---
@onready var score_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/ScoreLabel"
@onready var match_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/MatchLabel"
@onready var error_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/ErrorLabel"
@onready var time_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/TimeLabel"
@onready var moves_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/MovesLabel"
@onready var combo_label: Label = $"../RootVBox/HeaderPanel/HeaderHBox/ComboLabel"

# Combo highlight renkleri
const COLOR_COMBO_DEFAULT: Color = Color(1, 1, 1, 1)
const COLOR_COMBO_HOT: Color = Color(0.85, 0.65, 1.0, 1.0)  # mor (combo >= 2)


func _ready() -> void:
	# GameManager sinyallerini dinle
	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.match_count_changed.is_connected(_on_match_count_changed):
		GameManager.match_count_changed.connect(_on_match_count_changed)
	if not GameManager.error_count_changed.is_connected(_on_error_count_changed):
		GameManager.error_count_changed.connect(_on_error_count_changed)
	if not GameManager.time_changed.is_connected(_on_time_changed):
		GameManager.time_changed.connect(_on_time_changed)
	if not GameManager.moves_changed.is_connected(_on_moves_changed):
		GameManager.moves_changed.connect(_on_moves_changed)
	if not GameManager.combo_changed.is_connected(_on_combo_changed):
		GameManager.combo_changed.connect(_on_combo_changed)

	# İlk değerler
	_on_score_changed(0)
	_on_match_count_changed(0, GameManager.total_pairs)
	_on_error_count_changed(0)
	_on_time_changed("00:00")
	_on_moves_changed(0)
	_on_combo_changed(0, 0)


# --- Sinyal işleyiciler ---
func _on_score_changed(s: int) -> void:
	if score_label:
		score_label.text = "Skor: %d" % s


func _on_match_count_changed(c: int, t: int) -> void:
	if match_label:
		match_label.text = "Eşleşme: %d/%d" % [c, t]


func _on_error_count_changed(c: int) -> void:
	if error_label:
		error_label.text = "Hata: %d" % c


func _on_time_changed(t: String) -> void:
	if time_label:
		time_label.text = "Süre: %s" % t


func _on_moves_changed(m: int) -> void:
	if moves_label:
		moves_label.text = "Hamle: %d" % m


func _on_combo_changed(c: int, best: int) -> void:
	if combo_label:
		if best > 0:
			combo_label.text = "Combo: %dx (En iyi: %dx)" % [c, best]
		else:
			combo_label.text = "Combo: %dx" % c
		# Combo >= 2 ise mor vurgu
		if c >= 2:
			combo_label.add_theme_color_override("font_color", COLOR_COMBO_HOT)
		else:
			combo_label.add_theme_color_override("font_color", COLOR_COMBO_DEFAULT)
