# ============================================================
# Main.gd
# Oyun akışını yönetir:
#   - Kartları dile göre iki sütuna ayır (Türkçe sol, İngilizce sağ)
#   - Her sütun bağımsız karıştırılır
#   - Kart tıklamalarını GameManager'a yönlendir
#   - İpucu / Duraklat / Sesi Kapat butonları
#   - Kategori butonları (multi-select, toggle)
#   - Oyun modu butonları (4 mod: Klasik / TR→EN / EN→TR / Sesli)
#   - Klavye kısayolları (R / H / P / M / ESC)
#   - Eşleşme → ConnectionRibbon'a kart pozisyonları geçir
#   - Oyun sonu panelini göster (SaveManager ile rekor kontrolü)
#   - TEKRAR OYNA işlevi
# ============================================================
extends Control

const CARD_SCENE: PackedScene = preload("res://scenes/Card.tscn")

# Kategori cubugu: 15 buton tek satira sigmadigi icin dengeli 2 satira (8+7) sarar.
# Bu degerler CategoryFlow'un ~1005px'lik alanina gore secildi; buyutursen 3. satir olusur.
const CATEGORY_BUTTON_SIZE := Vector2(108, 32)
const CATEGORY_CLEAR_BUTTON_SIZE := Vector2(132, 32)
const CATEGORY_FONT_SIZE := 13
# Oyun modu cubugu (Mod: Klasik / TR-EN / ...) - kategori cubugundan bagimsiz
const MODE_BUTTON_SIZE := Vector2(170, 38)
const MODE_FONT_SIZE := 15
# Zorluk cubugu (Zorluk: Kolay / Orta / Zor / Uzman)
const DIFFICULTY_BUTTON_SIZE := Vector2(118, 34)
const DIFFICULTY_FONT_SIZE := 14

@onready var title_label: Label = $RootVBox/TitleLabel
@onready var subtitle_label: Label = $RootVBox/SubtitleLabel
@onready var turkish_cards_container: GridContainer = $RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards
@onready var english_cards_container: GridContainer = $RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards
@onready var connection_ribbon: Control = $RootVBox/GameArea/ConnectionRibbon
@onready var game_area: Control = $RootVBox/GameArea
@onready var difficulty_flow: HFlowContainer = $RootVBox/DifficultyBar/DifficultyFlow
@onready var game_over_panel = $GameOverPanel
@onready var hint_button: Button = $RootVBox/ControlBar/HintButton
@onready var pause_button: Button = $RootVBox/ControlBar/PauseButton
@onready var mute_button: Button = $RootVBox/ControlBar/MuteButton
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/CenterContainer/DialogPanel/VBox/ResumeButton
@onready var quit_button: Button = $PauseOverlay/CenterContainer/DialogPanel/VBox/QuitButton
@onready var category_flow: HFlowContainer = $RootVBox/CategoryBar/CategoryFlow
# Oyun modu butonları için container (Web Task 12 paritesi)
@onready var game_mode_flow: HFlowContainer = $RootVBox/GameModeBar/GameModeFlow
# Yanlış yön mesajı label'ı (geçici toast benzeri)
@onready var wrong_side_message: Label = $RootVBox/WrongSideMessage
# Task 22: Kelime öğrenme kartı paneli (matched kart tıklanınca açılır)
@onready var word_card_panel = $WordCardPanel

# Aktif kartlar
var cards: Array = []

# Kategori butonu referansları: { category_id -> Button }
var category_buttons: Dictionary = {}

# "Tümünü göster" temizleme butonu
var clear_categories_button: Button = null

# Kategori butonu görsel durumları (StyleBoxFlat)
var _cat_style_normal: StyleBoxFlat = null
var _cat_style_hover: StyleBoxFlat = null
var _cat_style_pressed: StyleBoxFlat = null
var _cat_style_disabled: StyleBoxFlat = null

# Oyun modu butonu görsel durumları (StyleBoxFlat)
# Aktif mod -> amber gradient (dolu), diğerleri -> outline (ince border, şeffaf zemin)
var _mode_style_normal: StyleBoxFlat = null
var _mode_style_hover: StyleBoxFlat = null
var _mode_style_active: StyleBoxFlat = null
var _mode_style_disabled: StyleBoxFlat = null

# Oyun modu butonu referansları: { GameMode (int) -> Button }
var mode_buttons: Dictionary = {}

# Zorluk butonu referanslari: { Difficulty (int) -> Button }
var difficulty_buttons: Dictionary = {}

# Yeni oyun başlatılırken kategori değişikliği kaynaklı mı?
# (avoid infinite recursion: category change -> new_game -> ... )
var _suppress_category_restart: bool = false

# Yeni oyun başlatılırken mod değişikliği kaynaklı mı?
# (avoid infinite recursion: mode change -> new_game -> ... )
var _suppress_mode_restart: bool = false

# Wrong-side mesajı için aktif tween (yeni mesaj gelince eskiyi öldür)
var _wrong_side_tween: Tween = null


func _ready() -> void:
																# GameOverPanel'in replay sinyalini dinle
																if game_over_panel and not game_over_panel.replay_pressed.is_connected(_on_replay):
																																game_over_panel.replay_pressed.connect(_on_replay)

																# game_won sinyalini dinle
																if not GameManager.game_won.is_connected(_on_game_won):
																																GameManager.game_won.connect(_on_game_won)

																# ConnectionRibbon sinyali: eşleşme anında ribbon çizimi için
																if connection_ribbon and not GameManager.pair_matched_ribbon.is_connected(_on_pair_matched_ribbon):
																																GameManager.pair_matched_ribbon.connect(_on_pair_matched_ribbon)

																# İpucu / Duraklat / Sesi Kapat butonları
																if hint_button and not hint_button.pressed.is_connected(_on_hint_button_pressed):
																																hint_button.pressed.connect(_on_hint_button_pressed)
																if pause_button and not pause_button.pressed.is_connected(_on_pause_button_pressed):
																																pause_button.pressed.connect(_on_pause_button_pressed)
																if mute_button and not mute_button.pressed.is_connected(_on_mute_button_pressed):
																																mute_button.pressed.connect(_on_mute_button_pressed)
																if resume_button and not resume_button.pressed.is_connected(_on_resume_button_pressed):
																																resume_button.pressed.connect(_on_resume_button_pressed)
																if quit_button and not quit_button.pressed.is_connected(_on_quit_button_pressed):
																																quit_button.pressed.connect(_on_quit_button_pressed)

																# GameManager sinyallerini dinle
																if not GameManager.hints_changed.is_connected(_on_hints_changed):
																																GameManager.hints_changed.connect(_on_hints_changed)
																if not GameManager.pause_changed.is_connected(_on_pause_changed):
																																GameManager.pause_changed.connect(_on_pause_changed)
																if not GameManager.categories_changed.is_connected(_on_categories_changed):
																																GameManager.categories_changed.connect(_on_categories_changed)
																# Wrong-side sinyali: oyun modu kuralı ihlalinde mesaj göster
																if not GameManager.wrong_side.is_connected(_on_wrong_side):
																																GameManager.wrong_side.connect(_on_wrong_side)

																# GameModeManager.mode_changed sinyalini dinle (mod değişince yeni oyun)
																if GameModeManager != null and not GameModeManager.mode_changed.is_connected(_on_mode_changed):
																																GameModeManager.mode_changed.connect(_on_mode_changed)

																# Pause overlay başlangıçta gizli
																if pause_overlay:
																																pause_overlay.visible = false

																# Wrong-side mesajı başlangıçta gizli
																if wrong_side_message:
																																wrong_side_message.visible = false
																																wrong_side_message.text = ""

																# İlk oyunu hazırla: kategori butonları + mod butonları + yeni oyun.
																# call_deferred, ağacın tam hazırlanması ve "Parent busy" hatasını
																# önler (geçici instantiate durumlarında, TestRunner gibi).
																call_deferred("_initialize_first_game")


# İlk oyunu hazırla: kategori butonları + mod butonları + yeni oyun.
# Testler doğrudan çağırabilir (geçici instantiate senaryoları için).
func _initialize_first_game() -> void:
																if not is_inside_tree() or is_queued_for_deletion():
																																print("DEBUG aborted (not in tree), name=", name, " id=", get_instance_id())
																																return
																print("DEBUG running, name=", name, " id=", get_instance_id(), " trc=", turkish_cards_container, " enc=", english_cards_container)
																_build_category_buttons()
																_apply_category_button_states()
																_build_mode_buttons()
																_apply_mode_button_states()
																_build_difficulty_buttons()
																_apply_difficulty_button_states()
																_new_game()
																print("DEBUG done, name=", name, " id=", get_instance_id(), " cards=", cards.size())


# Kategori butonlarını kod ile oluştur (Main.tscn'deki CategoryFlow içine).
# 1 "Tümünü Göster" butonu + 14 kategori butonu (10 orijinal + 4 yeni Task 16).
# Not: butonlar WordData.CATEGORIES üzerinden OTOMATİK üretilir;
# yeni kategori eklemek için yalnızca WordData.gd güncellenir (Main.gd'ye dokunmaya gerek yok).
func _build_category_buttons() -> void:
																if category_flow == null:
																																push_warning("Main.gd: CategoryFlow node bulunamadı - kategori butonları oluşturulamadı.")
																																return

																# Daha önce oluşturulmuşsa tekrar oluşturma (TestRunner ikinci çağrı güvenliği)
																# _ready -> call_deferred("_initialize_first_game") + testin doğrudan çağrısı
																# çakışmasını önler (Task 16: 30 buton → 15 buton idempotent guard).
																if category_buttons.size() > 0 or clear_categories_button != null:
																																return

																# StyleBoxFlat'ları bir kez hazırla
																_prepare_category_styles()

																# "Tümünü Göster" temizleme butonu
																clear_categories_button = Button.new()
																clear_categories_button.name = "ClearCategoriesButton"
																clear_categories_button.text = "🎲 Tümünü Göster"
																clear_categories_button.toggle_mode = false
																clear_categories_button.custom_minimum_size = CATEGORY_CLEAR_BUTTON_SIZE
																clear_categories_button.add_theme_font_size_override("font_size", CATEGORY_FONT_SIZE)
																clear_categories_button.mouse_filter = Control.MOUSE_FILTER_STOP
																_apply_button_style(clear_categories_button, false)
																clear_categories_button.pressed.connect(_on_clear_categories_pressed)
																category_flow.add_child(clear_categories_button)

																# 14 kategori butonu (toggle_mode = true) — WordData.CATEGORIES üzerinden otomatik
																for cat in WordData.CATEGORIES:
																																var btn: Button = Button.new()
																																btn.name = "Cat_" + cat["id"]
																																btn.text = "%s %s" % [cat["emoji"], cat["label"]]
																																btn.toggle_mode = true
																																btn.custom_minimum_size = CATEGORY_BUTTON_SIZE
																																btn.add_theme_font_size_override("font_size", CATEGORY_FONT_SIZE)
																																btn.mouse_filter = Control.MOUSE_FILTER_STOP
																																btn.set_meta("category_id", cat["id"])
																																_apply_button_style(btn, false)
																																btn.toggled.connect(_on_category_toggled.bind(cat["id"]))
																																category_flow.add_child(btn)
																																category_buttons[cat["id"]] = btn


# StyleBoxFlat kaynaklarını hazırla (kategori butonları için).
# - normal: yarı saydam koyu zemin + ince amber border
# - hover: hafif amber tint + amber border
# - pressed (seçili): amber zemin + koyu border (seçili durum)
# - disabled: soluk
func _prepare_category_styles() -> void:
																_cat_style_normal = StyleBoxFlat.new()
																_cat_style_normal.bg_color = Color(0.18, 0.22, 0.32, 1.0)
																_cat_style_normal.border_color = Color(0.4, 0.5, 0.7, 0.6)
																_cat_style_normal.set_border_width_all(1)
																_cat_style_normal.set_corner_radius_all(8)
																_cat_style_normal.content_margin_left = 10
																_cat_style_normal.content_margin_right = 10
																_cat_style_normal.content_margin_top = 5
																_cat_style_normal.content_margin_bottom = 5

																_cat_style_hover = StyleBoxFlat.new()
																_cat_style_hover.bg_color = Color(0.28, 0.32, 0.42, 1.0)
																_cat_style_hover.border_color = Color(0.85, 0.7, 0.4, 0.9)
																_cat_style_hover.set_border_width_all(2)
																_cat_style_hover.set_corner_radius_all(8)
																_cat_style_hover.content_margin_left = 10
																_cat_style_hover.content_margin_right = 10
																_cat_style_hover.content_margin_top = 5
																_cat_style_hover.content_margin_bottom = 5

																_cat_style_pressed = StyleBoxFlat.new()
																_cat_style_pressed.bg_color = Color(0.95, 0.78, 0.45, 1.0)  # amber zemin
																_cat_style_pressed.border_color = Color(0.6, 0.45, 0.2, 1.0)  # koyu amber border
																_cat_style_pressed.set_border_width_all(2)
																_cat_style_pressed.set_corner_radius_all(8)
																_cat_style_pressed.content_margin_left = 10
																_cat_style_pressed.content_margin_right = 10
																_cat_style_pressed.content_margin_top = 5
																_cat_style_pressed.content_margin_bottom = 5

																_cat_style_disabled = StyleBoxFlat.new()
																_cat_style_disabled.bg_color = Color(0.15, 0.18, 0.25, 0.5)
																_cat_style_disabled.border_color = Color(0.3, 0.35, 0.45, 0.4)
																_cat_style_disabled.set_border_width_all(1)
																_cat_style_disabled.set_corner_radius_all(8)
																_cat_style_disabled.content_margin_left = 10
																_cat_style_disabled.content_margin_right = 10
																_cat_style_disabled.content_margin_top = 5
																_cat_style_disabled.content_margin_bottom = 5


# Tek bir butona, seçili/seçili değil durumuna göre stil uygula.
# Ayrıca font rengini de günceller (seçili -> koyu, değil -> beyaz).
func _apply_button_style(btn: Button, selected: bool) -> void:
																if btn == null:
																																return
																if _cat_style_normal == null:
																																_prepare_category_styles()
																btn.add_theme_stylebox_override("normal", _cat_style_normal)
																btn.add_theme_stylebox_override("hover", _cat_style_hover if not btn.disabled else _cat_style_disabled)
																btn.add_theme_stylebox_override("pressed", _cat_style_pressed)
																btn.add_theme_stylebox_override("focus", _cat_style_normal)
																if selected:
																																btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_hover_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.25, 0.6))
																else:
																																btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
																																btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
																																btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.55, 0.6))


# GameManager.selected_categories'e göre buton durumlarını (button_pressed) senkronize et.
# Butona tıklamadan yalnızca görsel durumu günceller.
func _apply_category_button_states() -> void:
																for cat_id in category_buttons.keys():
																																var btn: Button = category_buttons[cat_id]
																																if btn == null:
																																																continue
																																var was_pressed: bool = btn.button_pressed
																																var should_be_pressed: bool = GameManager.selected_categories.has(cat_id)
																																if was_pressed != should_be_pressed:
																																																# Toggled sinyali tetiklemeden güncelle
																																																btn.set_pressed_no_signal(should_be_pressed)
																																_apply_button_style(btn, should_be_pressed)


# Kategori butonlarının disabled durumunu güncelle.
# Oyun aktifken (is_running && !is_game_won) ve busy/pause iken disabled.
func _update_category_buttons_disabled() -> void:
																var disabled: bool = GameManager.is_running and not GameManager.is_game_won
																for cat_id in category_buttons.keys():
																																var btn: Button = category_buttons[cat_id]
																																if btn != null:
																																																btn.disabled = disabled
																if clear_categories_button != null:
																																# "Tümünü Göster" butonu da oyun sırasında disabled
																																clear_categories_button.disabled = disabled


# ============================================================
# OYUN MODU BUTONLARI (Web Task 12 paritesi)
# 4 buton: 🎲 Klasik, 🇹🇷 Türkçe→İngilizce, 🇬🇧 İngilizce→Türkçe, 🔊 Sesli
# Aktif mod -> amber gradient (dolu), diğerleri -> outline (şeffaf + ince border)
# Mod butonları her zaman etkindir (web paritesi); mod değişince
# _on_mode_changed -> _new_game çağrılır (oyun yeniden başlar).
# ============================================================

# 4 oyun modu butonunu kod ile oluştur (Main.tscn'deki GameModeFlow içine).
# toggle_mode=false: basınca "pressed" sinyali yayılır, görsel durumu
# _apply_mode_button_states() ile senkronize edilir (aktif mod).
func _build_mode_buttons() -> void:
																if game_mode_flow == null:
																																push_warning("Main.gd: GameModeFlow node bulunamadı - mod butonları oluşturulamadı.")
																																return
																if GameModeManager == null:
																																push_warning("Main.gd: GameModeManager autoload yok - mod butonları atlanıyor.")
																																return

																# StyleBoxFlat'ları bir kez hazırla
																_prepare_mode_styles()

																# Daha önce oluşturulmuşsa tekrar oluşturma (TestRunner ikinci çağrı güvenliği)
																if mode_buttons.size() > 0:
																																return

																for mode in GameModeManager.get_all_modes():
																																var btn: Button = Button.new()
																																btn.name = "Mode_%d" % mode
																																btn.text = GameModeManager.get_mode_button_text(mode)
																																btn.toggle_mode = false
																																btn.custom_minimum_size = MODE_BUTTON_SIZE
																																btn.add_theme_font_size_override("font_size", MODE_FONT_SIZE)
																																btn.mouse_filter = Control.MOUSE_FILTER_STOP
																																btn.tooltip_text = GameModeManager.get_mode_description(mode)
																																btn.set_meta("mode", mode)
																																_apply_mode_button_style(btn, false)
																																btn.pressed.connect(_on_mode_button_pressed.bind(mode))
																																game_mode_flow.add_child(btn)
																																mode_buttons[mode] = btn


# StyleBoxFlat kaynaklarını hazırla (oyun modu butonları için).
# - normal: outline (şeffaf zemin + ince amber border)
# - hover: hafif amber tint + brighter border
# - active: amber zemin (dolu) + koyu border (aktif mod)
# - disabled: soluk (mod butonları genelde etkin ama yine de tanımlı)
func _prepare_mode_styles() -> void:
																_mode_style_normal = StyleBoxFlat.new()
																_mode_style_normal.bg_color = Color(0.15, 0.18, 0.25, 0.7)
																_mode_style_normal.border_color = Color(0.6, 0.45, 0.2, 0.6)
																_mode_style_normal.set_border_width_all(1)
																_mode_style_normal.set_corner_radius_all(8)
																_mode_style_normal.content_margin_left = 10
																_mode_style_normal.content_margin_right = 10
																_mode_style_normal.content_margin_top = 6
																_mode_style_normal.content_margin_bottom = 6

																_mode_style_hover = StyleBoxFlat.new()
																_mode_style_hover.bg_color = Color(0.22, 0.24, 0.32, 1.0)
																_mode_style_hover.border_color = Color(0.85, 0.7, 0.4, 0.9)
																_mode_style_hover.set_border_width_all(2)
																_mode_style_hover.set_corner_radius_all(8)
																_mode_style_hover.content_margin_left = 10
																_mode_style_hover.content_margin_right = 10
																_mode_style_hover.content_margin_top = 6
																_mode_style_hover.content_margin_bottom = 6

																_mode_style_active = StyleBoxFlat.new()
																_mode_style_active.bg_color = Color(0.95, 0.78, 0.45, 1.0)  # amber zemin
																_mode_style_active.border_color = Color(0.6, 0.45, 0.2, 1.0)  # koyu amber border
																_mode_style_active.set_border_width_all(2)
																_mode_style_active.set_corner_radius_all(8)
																_mode_style_active.content_margin_left = 10
																_mode_style_active.content_margin_right = 10
																_mode_style_active.content_margin_top = 6
																_mode_style_active.content_margin_bottom = 6

																_mode_style_disabled = StyleBoxFlat.new()
																_mode_style_disabled.bg_color = Color(0.15, 0.18, 0.25, 0.5)
																_mode_style_disabled.border_color = Color(0.3, 0.35, 0.45, 0.4)
																_mode_style_disabled.set_border_width_all(1)
																_mode_style_disabled.set_corner_radius_all(8)
																_mode_style_disabled.content_margin_left = 10
																_mode_style_disabled.content_margin_right = 10
																_mode_style_disabled.content_margin_top = 6
																_mode_style_disabled.content_margin_bottom = 6


# Tek bir mod butonuna, aktif/pasif durumuna göre stil uygula.
# active=true -> _mode_style_active (amber dolu, koyu font rengi)
# active=false -> _mode_style_normal (outline, beyaz font)
func _apply_mode_button_style(btn: Button, active: bool) -> void:
																if btn == null:
																																return
																if _mode_style_normal == null:
																																_prepare_mode_styles()
																btn.add_theme_stylebox_override("normal", _mode_style_normal)
																btn.add_theme_stylebox_override("hover", _mode_style_hover if not btn.disabled else _mode_style_disabled)
																btn.add_theme_stylebox_override("pressed", _mode_style_active if active else _mode_style_normal)
																btn.add_theme_stylebox_override("focus", _mode_style_normal)
																# Aktif buton için "pressed" durumu kalıcı görsel olarak kullanılır
																# (button_pressed yok çünkü toggle_mode=false). Aktif olunca
																# normal stiline de active'yi veriyoruz ki buton basılı görünümde kalsın.
																if active:
																																btn.add_theme_stylebox_override("normal", _mode_style_active)
																																btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_hover_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.25, 0.6))
																else:
																																btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
																																btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
																																btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.05, 1.0))
																																btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.55, 0.6))


# GameModeManager.current_mode'e göre buton görsel durumlarını senkronize et.
# Butona tıklamadan yalnızca görsel durumu günceller.
func _apply_mode_button_states() -> void:
																if GameModeManager == null:
																																return
																var active_mode: int = GameModeManager.current_mode
																for mode in mode_buttons.keys():
																																var btn: Button = mode_buttons[mode]
																																if btn == null:
																																																continue
																																_apply_mode_button_style(btn, mode == active_mode)


# Yeni oyun kur (ilk açılış ve TEKRAR OYNA, kategori değişimi)
# Kartlar dile göre iki sütuna ayrılır:
#   Türkçe kartlar -> sol (turkish_cards_container)
#   İngilizce kartlar -> sağ (english_cards_container)
# Her sütun bağımsız karıştırılır.
func _new_game() -> void:
																# Mevcut kartları temizle
																for c in cards:
																																if is_instance_valid(c):
																																																if c.get_parent() != null:
																																																																c.get_parent().remove_child(c)
																																																c.queue_free()
																cards.clear()
																GameManager.clear_cards()

																# ConnectionRibbon'daki tüm bağlantıları temizle
																if connection_ribbon and connection_ribbon.has_method("clear_all"):
																																connection_ribbon.clear_all()

																# Wrong-side mesajını gizle (yeni oyunda eski mesaj kalmasın)
																if wrong_side_message:
																																if _wrong_side_tween != null and _wrong_side_tween.is_valid():
																																																_wrong_side_tween.kill()
																																																_wrong_side_tween = null
																																wrong_side_message.visible = false
																																wrong_side_message.modulate.a = 1.0
																																wrong_side_message.text = ""

																# GameManager'ı başlat (skor/süre/hata/combo/moves/hints sıfırla)
																GameManager.start_game()

																# Rastgele çift seç (kategori filtresi ile) ve kart listesi oluştur
																var pairs: Array = WordData.get_random_pairs(
																																GameManager.total_pairs,
																																GameManager.selected_categories
																)
																# Kategori yetersizse total_pairs'i gerçek havuz boyutuna indir
																if pairs.size() < GameManager.total_pairs:
																																GameManager.total_pairs = pairs.size()
																																GameManager.emit_signal("match_count_changed", GameManager.match_count, GameManager.total_pairs)

																var card_data: Array = WordData.build_cards(pairs)

																# Dile göre ikiye ayır
																var turkish_data: Array = []
																var english_data: Array = []
																for data in card_data:
																																if data["language"] == "turkish":
																																																turkish_data.append(data)
																																else:
																																																english_data.append(data)

																# Her sütunu bağımsız karıştır (Web ile parite)
																turkish_data.shuffle()
																english_data.shuffle()

																# Türkçe kartları sol sütuna ekle
																for data in turkish_data:
																																var card = CARD_SCENE.instantiate()
																																turkish_cards_container.add_child(card)
																																card.setup(data["word"], data["language"], data["pair_id"])
																																if not card.card_clicked.is_connected(_on_card_clicked):
																																																card.card_clicked.connect(_on_card_clicked)
																																# Task 22: matched kart tıklama -> kelime kartı paneli
																																if card.has_signal("matched_card_clicked") and not card.matched_card_clicked.is_connected(_on_matched_card_clicked):
																																																card.matched_card_clicked.connect(_on_matched_card_clicked)
																																cards.append(card)
																																GameManager.register_card(card)

																# İngilizce kartları sağ sütuna ekle
																for data in english_data:
																																var card = CARD_SCENE.instantiate()
																																english_cards_container.add_child(card)
																																card.setup(data["word"], data["language"], data["pair_id"])
																																if not card.card_clicked.is_connected(_on_card_clicked):
																																																card.card_clicked.connect(_on_card_clicked)
																																# Task 22: matched kart tıklama -> kelime kartı paneli
																																if card.has_signal("matched_card_clicked") and not card.matched_card_clicked.is_connected(_on_matched_card_clicked):
																																																card.matched_card_clicked.connect(_on_matched_card_clicked)
																																cards.append(card)
																																GameManager.register_card(card)

																# Oyun sonu panelini gizle
																if game_over_panel:
																																game_over_panel.hide_panel()

																# Duraklatma overlay'ini gizle
																if pause_overlay:
																																pause_overlay.visible = false

																# Buton metinlerini sıfırla
																_on_hints_changed(GameManager.hints_left, GameManager.total_hints)
																if pause_button:
																																pause_button.text = "Duraklat ⏸"
																if mute_button:
																																mute_button.text = "🔇 Sesi Aç" if AudioManager.is_muted else "🔊 Sesi Kapat"

																# Kategori butonlarını güncelle (oyun başladı -> disabled)
																_update_category_buttons_disabled()
																_apply_board_layout()


# Karta tıklama
func _on_card_clicked(card) -> void:
																GameManager.select_card(card)


# Task 22: Eşleşmiş karta tıklama -> kelime öğrenme kartı paneli aç.
# Card.matched_card_clicked sinyalini dinler. GameManager'a da relay eder
# (GameManager.matched_card_clicked). WordData'dan çift bilgisi (TR/EN/kategori)
# alıp WordCardPanel.show_pair çağırır. Panel yoksa veya kart geçersizse no-op.
func _on_matched_card_clicked(card) -> void:
																if card == null:
																								return
																if word_card_panel == null:
																								return
																var pair_id: int = card.pair_id
																# GameManager'a relay et (ileride başka sistemler dinleyebilir)
																if GameManager.has_signal("matched_card_clicked"):
																								GameManager.emit_signal("matched_card_clicked", pair_id)
																# WordData'dan çiftin tam bilgilerini al (TR + EN + kategori)
																var turkish: String = ""
																var english: String = ""
																var category: String = ""
																for p in WordData.WORD_PAIRS:
																								if int(p.get("pair_id", -1)) == pair_id:
																																turkish = String(p.get("turkish", ""))
																																english = String(p.get("english", ""))
																																category = String(p.get("category", ""))
																																break
																# Panel aç (çift bulunamazsa bile minimal bilgi ile aç)
																if turkish == "" and card.language == "turkish":
																								turkish = card.word
																elif english == "" and card.language == "english":
																								english = card.word
																word_card_panel.show_pair(pair_id, turkish, english, category)


# GameManager bir çift eşleştiğinde ribbon için sinyal yayar.
# Main.gd, ConnectionRibbon'a kart pozisyonlarını geçirir.
func _on_pair_matched_ribbon(pair_id: int, turkish_card, english_card) -> void:
																if connection_ribbon == null:
																																return
																if not connection_ribbon.has_method("show_connection"):
																																return
																connection_ribbon.show_connection(turkish_card, english_card, pair_id)


# Oyun kazanıldı
func _on_game_won() -> void:
																# Kategori butonları artık kullanıcı tarafından değiştirilebilir
																_update_category_buttons_disabled()
																if game_over_panel:
																																var diff: int = DifficultyManager.current_difficulty
																																# Yeni rekor kontrolü
																																var is_new: bool = SaveManager.is_new_record(
																																																diff,
																																																GameManager.score,
																																																GameManager.elapsed_time,
																																																GameManager.error_count,
																																																GameManager.moves
																																)
																																# Yeni rekor ise kaydet
																																if is_new:
																																																SaveManager.save_best_record(
																																																																diff,
																																																																GameManager.score,
																																																																GameManager.elapsed_time,
																																																																GameManager.error_count,
																																																																GameManager.moves
																																																)
																																# İstatistik kaydı (kazanıldı)
																																SaveManager.record_game_result(
																																																diff,
																																																true,
																																																GameManager.score,
																																																GameManager.elapsed_time,
																																																GameManager.error_count,
																																																GameManager.moves,
																																																GameManager.best_combo
																																)
																																# Paneli göster
																																game_over_panel.show_panel(
																																																GameManager.score,
																																																GameManager.elapsed_time,
																																																GameManager.error_count,
																																																GameManager.total_pairs,
																																																GameManager.best_combo,
																																																GameManager.moves,
																																																is_new
																																)


# TEKRAR OYNA butonu
func _on_replay() -> void:
																_new_game()


# --- Buton işleyicileri ---

func _on_hint_button_pressed() -> void:
																GameManager.use_hint()


func _on_pause_button_pressed() -> void:
																GameManager.toggle_pause()


func _on_resume_button_pressed() -> void:
																if GameManager.is_paused:
																																GameManager.toggle_pause()


func _on_mute_button_pressed() -> void:
																var muted: bool = AudioManager.toggle_mute()
																if mute_button:
																																mute_button.text = "🔇 Sesi Aç" if muted else "🔊 Sesi Kapat"


# --- Kategori işleyicileri ---

# Bir kategori butonu toggle edildiğinde (toggle_mode = true).
# is_pressed: butonun yeni durumu (true = seçili)
# category_id: butona bağlanan kategori id
func _on_category_toggled(is_pressed: bool, category_id: String) -> void:
																if _suppress_category_restart:
																																return
																# Oyun aktifken tıklamayı engelle (yedek güvenlik; buton disabled olmalı)
																if GameManager.is_running and not GameManager.is_game_won:
																																# Eski duruma geri al
																																var btn: Button = category_buttons.get(category_id)
																																if btn != null:
																																																btn.set_pressed_no_signal(not is_pressed)
																																return
																# Yeni seçili kategoriler listesini kur
																var new_cats: Array = []
																for cat_id in category_buttons.keys():
																																var b: Button = category_buttons[cat_id]
																																if b != null and b.button_pressed:
																																																new_cats.append(cat_id)
																# GameManager'a bildir; bu categories_changed sinyalini yayacak
																GameManager.set_categories(new_cats)


# "Tümünü Göster" / "Karışık" temizleme butonu
func _on_clear_categories_pressed() -> void:
																if _suppress_category_restart:
																																return
																if GameManager.is_running and not GameManager.is_game_won:
																																return
																GameManager.clear_categories()


# GameManager.categories_changed sinyali geldi: buton görsel durumlarını
# senkronize et ve oyunu yeni seçimle yeniden başlat.
func _on_categories_changed(selected_cats: Array) -> void:
																_suppress_category_restart = true
																_apply_category_button_states()
																_suppress_category_restart = false
																# Yeni kategoriyle yeni oyun
																_new_game()


# --- Oyun modu işleyicileri (Web Task 12 paritesi) ---

# Bir oyun modu butonuna basıldı. GameModeManager.set_mode çağrılır.
# Eğer mod gerçekten değişirse mode_changed sinyali yayılır -> _on_mode_changed.
# Aynı mod seçilirse set_mode no-op'tur (oyun yeniden başlamaz).
func _on_mode_button_pressed(mode: int) -> void:
																if GameModeManager == null:
																																return
																if _suppress_mode_restart:
																																return
																GameModeManager.set_mode(mode)


# GameModeManager.mode_changed sinyali geldi: buton görsel durumlarını
# senkronize et, AudioManager sesli modu güncelle, oyunu yeni modla başlat.
func _on_mode_changed(mode: int) -> void:
																# AudioManager sesli modu güncelle
																if AudioManager != null:
																																AudioManager.set_audio_mode(mode == GameModeManager.GameMode.AUDIO)
																# Buton görsel durumlarını senkronize et
																_suppress_mode_restart = true
																_apply_mode_button_states()
																_suppress_mode_restart = false
																# Yeni modla yeni oyun (kartlar yeniden karıştırılır)
																_new_game()


# GameManager.wrong_side sinyali geldi: kullanıcı yanlış sütundan kart seçti.
# Geçici bilgilendirici mesaj göster (2 sn, fade in/out).
# expected_language: "turkish" | "english"
func _on_wrong_side(card, expected_language: String) -> void:
																if wrong_side_message == null:
																																return
																var msg: String = ""
																match expected_language:
																																"turkish":
																																																msg = "⚠ Bu modda önce Türkçe kart seçmelisin"
																																"english":
																																																msg = "⚠ Bu modda önce İngilizce kart seçmelisin"
																																_:
																																																msg = "⚠ Bu modda yanlış kart seçildi"
																wrong_side_message.text = msg
																wrong_side_message.visible = true
																wrong_side_message.modulate.a = 0.0
																# Eski tween varsa öldür
																if _wrong_side_tween != null and _wrong_side_tween.is_valid():
																																_wrong_side_tween.kill()
																_wrong_side_tween = create_tween()
																_wrong_side_tween.set_parallel(false)
																# Fade in (0.2 sn)
																_wrong_side_tween.tween_property(wrong_side_message, "modulate:a", 1.0, 0.2) \
																																.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
																# 1.6 sn tam opak bekle
																_wrong_side_tween.tween_interval(1.6)
																# Fade out (0.4 sn)
																_wrong_side_tween.tween_property(wrong_side_message, "modulate:a", 0.0, 0.4) \
																																.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
																# Bitince gizle
																_wrong_side_tween.tween_callback(Callable(wrong_side_message, "set").bind("visible", false))


# --- GameManager sinyal işleyicileri ---

func _on_hints_changed(hints_left: int, total_hints: int) -> void:
																if hint_button:
																																hint_button.text = "💡 İpucu (%d/%d)" % [hints_left, total_hints]
																																hint_button.disabled = hints_left <= 0


func _on_pause_changed(is_paused: bool) -> void:
																if pause_overlay:
																																pause_overlay.visible = is_paused
																if pause_button:
																																pause_button.text = "Devam et ▶" if is_paused else "Duraklat ⏸"


# --- Klavye kısayolları ---
# R = yeniden başlat, H = ipucu, P = duraklat, M = sesi aç/kapat
# ESC = duraklatılmışsa devam et (GameOverPanel açıkken bir şey yapma)
func _unhandled_input(event: InputEvent) -> void:
																if not (event is InputEventKey):
																																return
																var key_event: InputEventKey = event
																if not key_event.pressed or key_event.echo:
																																return
																# Modifiyer tuşlar (Ctrl/Cmd/Alt/Shift) ile birlikte basıldığında yoksay
																if key_event.ctrl_pressed or key_event.meta_pressed or key_event.alt_pressed:
																																return

																match key_event.keycode:
																																KEY_R:
																																																_new_game()
																																																get_viewport().set_input_as_handled()
																																KEY_H:
																																																GameManager.use_hint()
																																																get_viewport().set_input_as_handled()
																																KEY_P:
																																																GameManager.toggle_pause()
																																																get_viewport().set_input_as_handled()
																																KEY_M:
																																																_on_mute_button_pressed()
																																																get_viewport().set_input_as_handled()
																																KEY_ESCAPE:
																																																if GameManager.is_paused:
																																																																GameManager.toggle_pause()
																																																																get_viewport().set_input_as_handled()

# Debug print for test verification
func _print_debug_init() -> void:
																print("DEBUG Main._new_game tamamlandı, kart sayisi: ", cards.size())


# ============================================================
# Kart tahtasi yerlesimi (uyarlanabilir grid) - bkz. _apply_board_layout
# ============================================================
# Sorun: kartlar tek sutunda alt alta dizildiginde Kolay'da 6, Uzman'da 15
# satir gerekiyor ve mevcut alana sigmiyordu. Kontrol min boyutuyla buyuyup
# ortadan tasiyor, son satir ekran disinda kaliyordu (oyun kazanilamiyordu).
# Cozum: kart sayisina VE o anki alana gore sutun/satir dagilimini hesapla.
# Boylece hicbir kart ekran disina tasmaz; pencere yeniden boyutlandirilinca
# yerlesim kendini gunceller (GameArea.resized -> _on_game_area_resized).

const BOARD_SEPARATION := 6.0     # kartlar arasi bosluk (px)
const BOARD_CELL_MIN_H := 52.0    # okunabilir en kucuk kart yuksekligi
const BOARD_CELL_MIN_W := 88.0    # en kucuk kart genisligi
const BOARD_CELL_MAX_H := 112.0   # asiri buyumesin (az kartli zorluklarda)
const BOARD_COLUMNS_GAP := 16.0   # TR ve EN sutunlari arasi bosluk (ColumnsHBox)


# GameArea yeniden boyutlandiginda yerlesimi tazele.
func _on_game_area_resized() -> void:
	_apply_board_layout()


# TR ve EN sutunlari icin sutun sayisini ve kart hucre boyutunu hesaplayip uygular.
func _apply_board_layout() -> void:
	var pair_count: int = turkish_cards_container.get_child_count()
	if pair_count <= 0:
		return
	var area: Vector2 = game_area.size
	if area.x <= 0.0 or area.y <= 0.0:
		return

	var cols: int = _pick_board_columns(pair_count, area.y)
	var rows: int = int(ceil(float(pair_count) / float(cols)))
	var side_w: float = (area.x - BOARD_COLUMNS_GAP) * 0.5

	# Hucre boyutu: mevcut alani satir/sutun sayisina bol (bosluklari duserek).
	var cell_h: float = (area.y - float(rows - 1) * BOARD_SEPARATION) / float(rows)
	var cell_w: float = (side_w - float(cols - 1) * BOARD_SEPARATION) / float(cols)
	cell_h = clampf(cell_h, BOARD_CELL_MIN_H, BOARD_CELL_MAX_H)
	cell_w = maxf(cell_w, BOARD_CELL_MIN_W)

	for container in [turkish_cards_container, english_cards_container]:
		container.columns = cols
		for card in container.get_children():
			card.custom_minimum_size = Vector2(BOARD_CELL_MIN_W, cell_h)


# `n` kart icin `avail_h` yuksekligine sigan EN AZ sutun sayisini dondurur.
# En az sutun = en genis kartlar; bu yuzden 1'den baslayip sigan ilk degeri seciyoruz.
func _pick_board_columns(n: int, avail_h: float) -> int:
	for cols in range(1, n + 1):
		var rows: int = int(ceil(float(n) / float(cols)))
		var needed: float = float(rows) * BOARD_CELL_MIN_H + float(rows - 1) * BOARD_SEPARATION
		if needed <= avail_h:
			return cols
	return n


# ============================================================
# Zorluk secici (Zorluk: Kolay / Orta / Zor / Uzman)
# ============================================================
# DifficultyManager dort zorluk destekliyordu ve testleri vardi ama arayuzde
# secici yoktu; oyuncu hep Kolay oynuyordu. Butonlar DifficultyManager uzerinden
# OTOMATIK uretilir -- yeni zorluk eklemek icin yalnizca DifficultyManager.gd
# guncellenir, Main.gd'ye dokunulmaz.

func _build_difficulty_buttons() -> void:
	if difficulty_flow == null:
		push_warning("Main.gd: DifficultyFlow node bulunamadi - zorluk butonlari olusturulamadi.")
		return
	# Idempotent guard (TestRunner ikinci cagri guvenligi)
	if difficulty_buttons.size() > 0:
		return
	for d in DifficultyManager.Difficulty.values():
		var btn: Button = Button.new()
		btn.name = "Diff_%d" % d
		btn.text = "%s (%d)" % [
			DifficultyManager.get_difficulty_label_pretty(d),
			DifficultyManager.get_pair_count(d),
		]
		btn.toggle_mode = false
		btn.custom_minimum_size = DIFFICULTY_BUTTON_SIZE
		btn.add_theme_font_size_override("font_size", DIFFICULTY_FONT_SIZE)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.tooltip_text = "%s: %d cift, %d ipucu hakki" % [
			DifficultyManager.get_difficulty_label_pretty(d),
			DifficultyManager.get_pair_count(d),
			DifficultyManager.get_hint_count(d),
		]
		btn.set_meta("difficulty", d)
		# Mod butonlariyla ayni gorsel dil (amber outline / amber dolu)
		_apply_mode_button_style(btn, false)
		btn.pressed.connect(_on_difficulty_button_pressed.bind(d))
		difficulty_flow.add_child(btn)
		difficulty_buttons[d] = btn


# Aktif zorluga gore butonlarin gorsel durumunu senkronize et (tiklama olmadan).
func _apply_difficulty_button_states() -> void:
	var active: int = DifficultyManager.current_difficulty
	for d in difficulty_buttons.keys():
		_apply_mode_button_style(difficulty_buttons[d], d == active)


# Zorluk butonuna basildi: zorlugu degistir, butonlari guncelle, yeni oyun kur.
func _on_difficulty_button_pressed(difficulty: int) -> void:
	if DifficultyManager.current_difficulty == difficulty:
		return
	DifficultyManager.set_difficulty(difficulty)
	_apply_difficulty_button_states()
	_new_game()

# ============================================================
# Cikis butonu
# ============================================================
# Masaustu exe'de oyundan cikmanin tek yolu pencereyi kapatmakti. Buton
# duraklatma penceresine konuldu: oyuncunun once Duraklat'a basmasi gerekir,
# boylece oyun ortasinda kazara cikis olmaz. Ayrica bir onay penceresi
# yazmaya gerek kalmaz -- duraklatma penceresi o onayi saglar.
#
# get_tree().quit() sureci temiz kapatir; kaybedilecek veri yok (rekorlar
# kazaninca senkron yazilir). Web ihracinda bu cagri etkisizdir, ama proje
# Windows exe hedefliyor.

func _on_quit_button_pressed() -> void:
	get_tree().quit()
