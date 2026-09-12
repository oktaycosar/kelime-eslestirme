# ============================================================
# Card.gd
# Bir kart: Türkçe veya İngilizce kelime + dil + pair_id
# ------------------------------------------------------------
# Görsel durum:
#   Kapalı    : BackPanel (soru işareti)
#   Açık      : FrontPanel (kelime, dil rengi)
#   Eşleşmiş  : FrontPanel (kelime, yeşil ton)
#   İpucu     : FrontPanel (kelime, mor ton) - 1.5sn gösterim
# Animasyonlar: flip (scale.x 0->1), hover, bounce, shake, blocked, wrong_side (mor flash)
# Sinyaller:
#   card_clicked(card) - tıklama (Main.gd -> GameManager.select_card)
#   card_flipped(card) - flip animasyonu tamamlandı (geçerli)
#   matched_card_clicked(card) - eşleşmiş kart tıklama (Main.gd -> WordCardPanel.show_pair)
# ============================================================
extends TextureButton

signal card_clicked(card)
signal card_flipped(card)
signal matched_card_clicked(card)

# --- Veri ---
@export var word: String = ""
@export var language: String = ""  # "turkish" | "english"
@export var pair_id: int = 0
@export var is_open: bool = false
@export var is_matched: bool = false
@export var is_hinted: bool = false

# --- Görsel renkler (subtle) ---
const COLOR_TURKISH: Color = Color(1.0, 0.88, 0.62, 1.0)    # sıcak amber
const COLOR_ENGLISH: Color = Color(0.68, 0.9, 0.78, 1.0)    # ferah yeşil
const COLOR_MATCHED: Color = Color(0.62, 0.96, 0.66, 1.0)   # yeşil
const COLOR_HINTED: Color = Color(0.82, 0.67, 0.98, 1.0)    # mor (ipucu)
const BORDER_TURKISH: Color = Color(0.86, 0.62, 0.18, 1.0)
const BORDER_ENGLISH: Color = Color(0.2, 0.66, 0.42, 1.0)
const BORDER_MATCHED: Color = Color(0.18, 0.72, 0.34, 1.0)
const BORDER_HINTED: Color = Color(0.57, 0.34, 0.82, 1.0)
const BACK_BORDER: Color = Color(0.38, 0.57, 0.82, 1.0)
const BACK_BORDER_HOVER: Color = Color(0.62, 0.8, 1.0, 1.0)
const BANNER_TURKISH: Color = Color(0.78, 0.12, 0.17, 1.0)
const BANNER_TURKISH_EDGE: Color = Color(1.0, 0.62, 0.65, 0.95)
const BANNER_ENGLISH: Color = Color(0.08, 0.27, 0.58, 1.0)
const BANNER_ENGLISH_EDGE: Color = Color(0.48, 0.72, 1.0, 0.95)

# --- Alt node referansları ---
@onready var back_panel: Panel = $BackPanel
@onready var back_graphic: TextureRect = $BackPanel/BackGraphic
@onready var front_panel: Panel = $FrontPanel
@onready var word_label: Label = $FrontPanel/WordLabel
@onready var back_question: TextureRect = $BackPanel/BackQuestion
@onready var back_language_badge: Label = $BackPanel/LanguageBadge
@onready var front_language_badge: Label = $FrontPanel/LanguageBadge

# Pivot (flip animasyonu için merkez)
var _base_scale: Vector2 = Vector2.ONE
var _hovered: bool = false


func _ready() -> void:
        # TextureButton sinyallerini bağla
        if not pressed.is_connected(_on_pressed):
                pressed.connect(_on_pressed)
        if not mouse_entered.is_connected(_on_mouse_entered):
                mouse_entered.connect(_on_mouse_entered)
        if not mouse_exited.is_connected(_on_mouse_exited):
                mouse_exited.connect(_on_mouse_exited)

        # Resize sinyali -> pivot merkeze al
        if not resized.is_connected(_on_resized):
                resized.connect(_on_resized)

        # Pivot merkeze al (flip animasyonu için)
        pivot_offset = size / 2.0
        _base_scale = scale

        # Görseli güncelle
        _update_visual()


# Boyut değiştiğinde pivot'u merkeze al ve fontları yeniden uygula
func _on_resized() -> void:
        pivot_offset = size / 2.0
        # Adaptif fontlar için görseli de güncelle
        if is_inside_tree():
                _update_visual()


# Kurulum fonksiyonu (Main.gd tarafından çağrılır)
func setup(p_word: String, p_language: String, p_pair_id: int) -> void:
        word = p_word
        language = p_language
        pair_id = p_pair_id
        is_open = false
        is_matched = false
        is_hinted = false
        if is_inside_tree():
                _update_visual()


# Görsel durumu güncelle
func _update_visual() -> void:
        if back_panel == null or front_panel == null:
                return

        var show_back: bool = not is_open and not is_matched
        back_panel.visible = show_back
        front_panel.visible = not show_back

        # Köşe banner'ı sütunları bir bakışta ayırt etmeyi kolaylaştırır.
        var language_code: String = "TR" if language == "turkish" else "EN"
        if back_language_badge:
                back_language_badge.text = language_code
                _style_language_banner(back_language_badge)
        if front_language_badge:
                front_language_badge.text = language_code
                _style_language_banner(front_language_badge)

        # FrontPanel rengi öncelik sırasıyla: ipucu > eşleşme > dil.
        # Modulate yerine StyleBox güncellenir; metin rengi temiz ve okunaklı kalır.
        var face_color: Color
        var border_color: Color
        if is_hinted:
                face_color = COLOR_HINTED
                border_color = BORDER_HINTED
        elif is_matched:
                face_color = COLOR_MATCHED
                border_color = BORDER_MATCHED
        elif language == "turkish":
                face_color = COLOR_TURKISH
                border_color = BORDER_TURKISH
        else:
                face_color = COLOR_ENGLISH
                border_color = BORDER_ENGLISH
        _set_panel_colors(front_panel, face_color, border_color)
        _set_back_hover(_hovered)

        if word_label:
                word_label.text = word
                # Font boyutu kartın yüksekliğine göre adaptif (iki sütunlu layout
                # her zorlukta farklı yükseklikte kartlar veriyor; uzun kelimeler
                # için ek küçültme uygulanır).
                var h: float = float(size.y)
                var base_font: int = 14
                if h >= 120:
                        base_font = 30
                elif h >= 80:
                        base_font = 24
                elif h >= 60:
                        base_font = 18
                elif h >= 40:
                        base_font = 14
                else:
                        base_font = 11
                # Uzun kelime uyarlaması
                if word.length() > 10 and base_font > 14:
                        base_font -= 4
                elif word.length() > 8 and base_font > 18:
                        base_font -= 4
                elif word.length() > 6 and base_font > 22:
                        base_font -= 4
                word_label.add_theme_font_size_override("font_size", base_font)
		# "?" artik TextureRect: boyutu anchor oraniyla otomatik olceklenir,
		# bu yuzden burada ayrica font boyutu ayarlanmiyor.


func _set_panel_colors(panel: Panel, background: Color, border: Color) -> void:
        var source: StyleBox = panel.get_theme_stylebox("panel")
        if source is StyleBoxFlat:
                var styled: StyleBoxFlat = source.duplicate()
                styled.bg_color = background
                styled.border_color = border
                panel.add_theme_stylebox_override("panel", styled)


func _style_language_banner(banner: Label) -> void:
        var source: StyleBox = banner.get_theme_stylebox("normal")
        if source is StyleBoxFlat:
                var styled: StyleBoxFlat = source.duplicate()
                if language == "turkish":
                        styled.bg_color = BANNER_TURKISH
                        styled.border_color = BANNER_TURKISH_EDGE
                else:
                        styled.bg_color = BANNER_ENGLISH
                        styled.border_color = BANNER_ENGLISH_EDGE
                banner.add_theme_stylebox_override("normal", styled)


func _set_back_hover(active: bool) -> void:
        if back_graphic == null:
                return
        back_graphic.modulate = Color(1.12, 1.16, 1.22, 1.0) if active else Color.WHITE


# --- Flip animasyonu ---
# Kartı aç (kapalı -> açık)
func flip_open() -> void:
        if is_open or is_matched:
                return
        # Ses GameManager.select_card tarafından çalınır
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        tween.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
        tween.tween_callback(Callable(self, "_on_flip_half_open"))
        tween.tween_property(self, "scale:x", _base_scale.x, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        emit_signal("card_flipped", self)


# Flip yarıya gelince görseli güncelle
func _on_flip_half_open() -> void:
        is_open = true
        _update_visual()


# Kartı kapat (açık -> kapalı)
func flip_close() -> void:
        if not is_open:
                return
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        tween.tween_property(self, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
        tween.tween_callback(Callable(self, "_on_flip_half_close"))
        tween.tween_property(self, "scale:x", _base_scale.x, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# Flip yarıya gelince (kapanış) görseli güncelle
func _on_flip_half_close() -> void:
        is_open = false
        _update_visual()


# --- İpucu gösterimi ---
# Kartı mor renkte aç (GameManager.use_hint tarafından çağrılır)
func show_hint() -> void:
        is_hinted = true
        # flip_open zaten is_open=true yapacak; _on_flip_half_open -> _update_visual mor gösterir
        flip_open()


# İpucu kapat (mor açıktan -> kapalı)
func hide_hint() -> void:
        is_hinted = false
        # flip_close kapanışın yarısında _update_visual çağırır ama back_panel görünür olacak
        flip_close()


# --- Eşleşme animasyonu (bounce + kalıcı açık) ---
func set_matched() -> void:
        is_matched = true
        is_open = false
        is_hinted = false  # Eşleşince ipucu durumu temizlenir
        _update_visual()
        # Bounce
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        tween.tween_property(self, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        # Tıklamayı AÇIK bırakırız (Task 22: kelime öğrenme kartı için
        # matched kart tıklanınca matched_card_clicked sinyali yayılır).
        # GameManager.select_card matched kartlarda no-op olduğundan
        # ek tıklama kartı tekrar açmaz; yalnızca word card panel tetiklenir.
        disabled = false


# --- Shake animasyonu (yanlış eşleşme) ---
func shake() -> void:
        var orig_pos: Vector2 = position
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        tween.tween_property(self, "position", orig_pos + Vector2(8, 0), 0.05).set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos + Vector2(-8, 0), 0.05).set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos + Vector2(6, 0), 0.05).set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos + Vector2(-6, 0), 0.05).set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos, 0.05).set_trans(Tween.TRANS_SINE)


# --- Engellendi animasyonu (aynı dil ikinci kart) ---
func play_blocked() -> void:
        # Hafif aşağı-yukarı titreme (sarsılma değil, "engellendi" hissi)
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        tween.tween_property(self, "position:y", position.y + 4, 0.06).set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position:y", position.y - 0, 0.06).set_trans(Tween.TRANS_SINE)


# --- Yanlış yön animasyonu (oyun modu kuralı: yanlış sütun) ---
# Klasik "blocked" animasyonuna ek olarak kart mor renk flash yapar.
# (Web Task 12 paritesi: yanlış sütun seçildiğinde kullanıcıya görsel feedback)
func play_wrong_side() -> void:
        var orig_mod: Color = modulate
        var tween: Tween = create_tween()
        tween.set_parallel(false)
        # Mor flash (0.18 sn)
        tween.tween_property(self, "modulate", Color(0.78, 0.55, 0.95, 1.0), 0.09) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        tween.tween_property(self, "modulate", orig_mod, 0.09) \
                .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
        # Hafif sarsılma (shake benzeri ama daha kısa)
        var orig_pos: Vector2 = position
        tween.tween_property(self, "position", orig_pos + Vector2(5, 0), 0.05) \
                .set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos + Vector2(-5, 0), 0.05) \
                .set_trans(Tween.TRANS_SINE)
        tween.tween_property(self, "position", orig_pos, 0.05) \
                .set_trans(Tween.TRANS_SINE)


# --- Hover efekti ---
func _on_mouse_entered() -> void:
        if is_open or is_matched:
                return
        if disabled:
                return
        _hovered = true
        _set_back_hover(true)
        var tween: Tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(self, "modulate", Color(1.06, 1.06, 1.08, 1.0), 0.1)


func _on_mouse_exited() -> void:
        _hovered = false
        _set_back_hover(false)
        if is_open or is_matched:
                # Açık/eşleşmiş kartlar olduğu gibi kalsın
                var tween: Tween = create_tween()
                tween.set_parallel(true)
                tween.tween_property(self, "scale", _base_scale, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
                tween.tween_property(self, "modulate", Color.WHITE, 0.08)
                return
        var tween: Tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(self, "scale", _base_scale, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(self, "modulate", Color.WHITE, 0.1)


# --- Tıklama ---
func _on_pressed() -> void:
        # Eşleşmiş kart tıklanınca matched_card_clicked sinyali yayılır
        # (Task 22: kelime öğrenme kartı için). Main.gd dinler ve
        # WordCardPanel.show_pair çağırır. card_clicked da yayılır
        # (GameManager.select_card matched kartlarda no-op olduğundan
        # ek tıklama kartı tekrar açmaz).
        if is_matched:
                emit_signal("matched_card_clicked", self)
        emit_signal("card_clicked", self)


# --- Reset (yeniden kullanım için) ---
func reset_card() -> void:
        is_open = false
        is_matched = false
        is_hinted = false
        disabled = false
        _hovered = false
        modulate = Color.WHITE
        scale = _base_scale
        _update_visual()