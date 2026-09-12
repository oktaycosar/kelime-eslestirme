# ============================================================
# WordCardPanel.gd
# Kelime öğrenme kartı paneli (Web Task 21 paritesi).
# ------------------------------------------------------------
# Matched kart tıklanınca açılır. İçerik:
#   - Başlık: "Kelime Detayı" + kategori emoji + label
#   - Türkçe kelime (büyük font, amber renk)
#   - İngilizce kelime (büyük font, emerald renk)
#   - Telaffuz (italic, slate)
#   - TR örnek cümle
#   - EN örnek cümle
#   - "Dinle TR" butonu (AudioManager.play_word(turkish))
#   - "Dinle EN" butonu (AudioManager.play_word(english))
#   - "Kapat" butonu
# ------------------------------------------------------------
# API:
#   show_pair(pair_id: int, turkish: String, english: String, category: String)
#     Verileri panele yazar ve görünür yapar.
#   hide_panel()
#     Paneli gizler.
# ------------------------------------------------------------
# Node yapısı (scenes/WordCardPanel.tscn ile eşleşir):
#   WordCardPanel (Control) ← bu script
#     OverlayColor (ColorRect, siyah 70%)
#     CenterContainer
#       DialogPanel (Panel)
#         VBox
#           TitleLabel        : "📖 Kelime Detayı"
#           CategoryLabel     : "{emoji} {label}"
#           DividerH          : HSeparator
#           TurkishLabel      : büyük amber TR kelime
#           EnglishLabel      : büyük emerald EN kelime
#           PronunciationLabel: italic telaffuz
#           ExampleTitleLabel : "Örnek Cümleler"
#           TRSentenceLabel   : TR örnek cümle
#           ENSentenceLabel   : EN örnek cümle
#           ButtonRow (HBox)
#             ListenTRButton  : "🔊 Dinle (TR)"
#             ListenENButton  : "🔊 Listen (EN)"
#             CloseButton     : "✖ Kapat"
# ============================================================
extends Control

# Şu anki gösterilen çiftin verileri
var _current_pair_id: int = 0
var _current_turkish: String = ""
var _current_english: String = ""
var _current_category: String = ""

# --- Alt node referansları (@onready) ---
@onready var overlay_color: ColorRect = $OverlayColor
@onready var center_container: CenterContainer = $CenterContainer
@onready var dialog_panel: Panel = $CenterContainer/DialogPanel
@onready var title_label: Label = $CenterContainer/DialogPanel/VBox/TitleLabel
@onready var category_label: Label = $CenterContainer/DialogPanel/VBox/CategoryLabel
@onready var turkish_label: Label = $CenterContainer/DialogPanel/VBox/TurkishLabel
@onready var english_label: Label = $CenterContainer/DialogPanel/VBox/EnglishLabel
@onready var pronunciation_label: Label = $CenterContainer/DialogPanel/VBox/PronunciationLabel
@onready var example_title_label: Label = $CenterContainer/DialogPanel/VBox/ExampleTitleLabel
@onready var tr_sentence_label: Label = $CenterContainer/DialogPanel/VBox/TRSentenceLabel
@onready var en_sentence_label: Label = $CenterContainer/DialogPanel/VBox/ENSentenceLabel
@onready var listen_tr_button: Button = $CenterContainer/DialogPanel/VBox/ButtonRow/ListenTRButton
@onready var listen_en_button: Button = $CenterContainer/DialogPanel/VBox/ButtonRow/ListenENButton
@onready var close_button: Button = $CenterContainer/DialogPanel/VBox/ButtonRow/CloseButton


func _ready() -> void:
        # Buton sinyallerini bağla
        if listen_tr_button != null and not listen_tr_button.pressed.is_connected(_on_listen_tr_pressed):
                listen_tr_button.pressed.connect(_on_listen_tr_pressed)
        if listen_en_button != null and not listen_en_button.pressed.is_connected(_on_listen_en_pressed):
                listen_en_button.pressed.connect(_on_listen_en_pressed)
        if close_button != null and not close_button.pressed.is_connected(_on_close_pressed):
                close_button.pressed.connect(_on_close_pressed)
        # Başlangıçta gizli
        visible = false


# Verilen çifti panelde göster. WordExamples'tan örnek alır.
# pair_id <= 0 veya boş kelimeler → boş panel gösterilir (crash yok).
func show_pair(pair_id: int, turkish: String, english: String, category: String) -> void:
        _current_pair_id = pair_id
        _current_turkish = turkish
        _current_english = english
        _current_category = category

        # Başlık
        if title_label != null:
                title_label.text = "📖 Kelime Detayı"

        # Kategori etiketi (emoji + label)
        if category_label != null:
                var cat_info: Dictionary = {}
                if WordData != null:
                        cat_info = WordData.get_category_info(category)
                var cat_emoji: String = String(cat_info.get("emoji", "🏷️"))
                var cat_label: String = String(cat_info.get("label", category))
                category_label.text = "%s %s" % [cat_emoji, cat_label]

        # Kelimeler
        if turkish_label != null:
                turkish_label.text = turkish
        if english_label != null:
                english_label.text = english

        # Örnek cümle ve telaffuz (WordExamples autoload)
        var example: Dictionary = {}
        if WordExamples != null:
                example = WordExamples.get_example(pair_id)
        var tr_sentence: String = String(example.get("tr_sentence", ""))
        var en_sentence: String = String(example.get("en_sentence", ""))
        var pronunciation: String = String(example.get("pronunciation", ""))

        if pronunciation_label != null:
                pronunciation_label.text = pronunciation if pronunciation != "" else ""
        if example_title_label != null:
                example_title_label.text = "📝 Örnek Cümleler"
        if tr_sentence_label != null:
                tr_sentence_label.text = "🇹🇷 " + tr_sentence
        if en_sentence_label != null:
                en_sentence_label.text = "🇬🇧 " + en_sentence

        # Görünür yap
        visible = true


# Paneli gizle.
func hide_panel() -> void:
        visible = false


# Panel açık mı?
func is_panel_visible() -> bool:
        return visible


# "Dinle (TR)" butonuna basıldı. Türkçe kelimenin ses dosyasını çal.
# Türkçe kelime için ses dosyası genelde yok; AudioManager sessizce atlar.
func _on_listen_tr_pressed() -> void:
        if AudioManager == null:
                return
        AudioManager.play_word(_current_turkish)


# "Listen (EN)" butonuna basıldı. İngilizce kelimenin ses dosyasını çal.
func _on_listen_en_pressed() -> void:
        if AudioManager == null:
                return
        AudioManager.play_word(_current_english)


# "Kapat" butonuna basıldı. Paneli gizle.
func _on_close_pressed() -> void:
        hide_panel()


# ESC ile kapatma (Main.gd tarafından _unhandled_input'ta yakalanır,
# ama biz de bir önlem olarak burada yakalayalım).
func _unhandled_input(event: InputEvent) -> void:
        if not visible:
                return
        if event is InputEventKey:
                var key_event: InputEventKey = event
                if key_event.pressed and not key_event.echo:
                        if key_event.keycode == KEY_ESCAPE:
                                hide_panel()
                                get_viewport().set_input_as_handled()
