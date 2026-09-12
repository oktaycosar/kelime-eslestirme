# ============================================================
# ConnectionRibbon.gd  (Control, custom _draw)
# Eşleşen Türkçe ↔ İngilizce kart çiftleri arasında animasyonlu
# "origami" bağlantı şeridi çizer.
# ------------------------------------------------------------
# API:
#   show_connection(turkish_card, english_card, pair_id) -> void
#       Eşleşme anında Main.gd tarafından çağrılır.
#       Kart merkezleri arası quadratic bezier (eğri) çizilir.
#       0 → 1 progress tween ile "çizim" animasyonu (0.6 sn).
#       Başlangıç (amber) ve bitiş (emerald) noktalarında daireler.
#   hide_connection(pair_id) -> void
#   clear_all() -> void
# Çizim:
#   - Bezier 32 segment, gradient: amber → rose → emerald
#   - Glow arka plan (kalın, düşük opaklık) + ana çizgi (ince)
#   - Başlangıç dairesi (amber, progress > 0.05'te)
#   - Bitiş dairesi (emerald, progress = 1'de)
#   - Orta sparkle (amber, animasyon sırasında 0.3..1)
# Koordinat:
#   Kartların global_position + size/2 → to_local() ile ConnectionRibbon
#   lokal uzayına çevrilir (Control, full-rect, parent'a anchored).
# Güvenlik:
#   Kart queue_free() edilmişse is_instance_valid() false → çizim atlanır.
# ============================================================
extends Control

# --- Renkler (web ile parite: amber → rose → emerald) ---
const COLOR_AMBER: Color = Color(0.96, 0.62, 0.04, 0.9)
const COLOR_ROSE: Color = Color(0.96, 0.25, 0.37, 0.95)
const COLOR_EMERALD: Color = Color(0.06, 0.73, 0.51, 0.9)
const COLOR_SPARKLE: Color = Color(0.98, 0.74, 0.05, 0.9)

# Animasyon süresi (saniye)
const DRAW_DURATION: float = 0.6

# Bezier segment sayısı (yüksek = daha pürüzsüz)
const SEGMENT_COUNT: int = 32

# Aktif bağlantılar: { pair_id (int) -> Dictionary }
# Dictionary yapısı:
#   "turkish": Card (zayıf değil, doğrudan ref; is_instance_valid ile kontrol)
#   "english": Card
#   "progress": float (0..1)
#   "tween": Tween (animasyon referansı)
var _connections: Dictionary = {}


func _ready() -> void:
        # Tıklama olaylarını kartlara iletmek için kendi üzerinize çizim yapar
        # ama tıklamayı engelleme.
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        # Üstte çizim garantisi.
        z_index = 5


# Yeni bir bağlantı ekle ve "çizim" animasyonu başlat.
func show_connection(turkish_card, english_card, pair_id: int) -> void:
        if turkish_card == null or english_card == null:
                return
        # Aynı pair_id için zaten bir bağlantı varsa tween'i durdur ve yeniden başlat.
        if _connections.has(pair_id):
                var old: Dictionary = _connections[pair_id]
                var old_tween: Tween = old.get("tween", null)
                if old_tween != null and old_tween.is_valid():
                        old_tween.kill()
        var entry: Dictionary = {
                "turkish": turkish_card,
                "english": english_card,
                "progress": 0.0,
                "tween": null,
        }
        _connections[pair_id] = entry
        var tween: Tween = create_tween()
        tween.tween_method(Callable(self, "_set_progress").bind(pair_id), 0.0, 1.0, DRAW_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
        entry["tween"] = tween
        queue_redraw()


# Bir pair_id'nin progress değerini güncelle (tween tarafından çağrılır).
func _set_progress(value: float, pair_id: int) -> void:
        if not _connections.has(pair_id):
                return
        _connections[pair_id]["progress"] = value
        queue_redraw()


# Belirli bir pair_id'nin bağlantısını kaldır.
func hide_connection(pair_id: int) -> void:
        if not _connections.has(pair_id):
                return
        var entry: Dictionary = _connections[pair_id]
        var tw: Tween = entry.get("tween", null)
        if tw != null and tw.is_valid():
                tw.kill()
        _connections.erase(pair_id)
        queue_redraw()


# Tüm bağlantıları temizle (yeni oyun başlarken).
func clear_all() -> void:
        for pair_id in _connections.keys():
                var entry: Dictionary = _connections[pair_id]
                var tw: Tween = entry.get("tween", null)
                if tw != null and tw.is_valid():
                        tw.kill()
        _connections.clear()
        queue_redraw()


# Aktif bağlantı sayısı (debug / test için)
func get_connection_count() -> int:
        return _connections.size()


# --- Çizim ---
func _draw() -> void:
        if _connections.is_empty():
                return
        for pair_id in _connections.keys():
                _draw_connection(pair_id)


func _draw_connection(pair_id: int) -> void:
        var entry: Dictionary = _connections.get(pair_id, {})
        if entry.is_empty():
                return
        var tr = entry.get("turkish", null)
        var en = entry.get("english", null)
        if not is_instance_valid(tr) or not is_instance_valid(en):
                return
        # Kart sağ kenar / sol kenar noktaları (global) → lokal uzay.
        # ConnectionRibbon anchored-to-fill GameArea olduğu için basit
        # global_position çıkarmak yeterli (rotation/scale yok).
        var start_global: Vector2 = tr.global_position + Vector2(tr.size.x, tr.size.y * 0.5)
        var end_global: Vector2 = en.global_position + Vector2(0.0, en.size.y * 0.5)
        var start: Vector2 = start_global - global_position
        var end: Vector2 = end_global - global_position
        var progress: float = float(entry.get("progress", 0.0))
        if progress <= 0.0:
                return
        # Bezier kontrol noktası: orta noktadan hafif yukarı (origami hissi)
        var mid: Vector2 = (start + end) * 0.5
        var control: Vector2 = mid + Vector2(0.0, -abs(end.y - start.y) * 0.15 - 10.0)

        # Çizilecek nokta sayısı: progress * SEGMENT_COUNT
        var drawn_segments: int = int(round(SEGMENT_COUNT * progress))
        if drawn_segments < 1:
                return
        var points: PackedVector2Array = PackedVector2Array()
        var colors: PackedColorArray = PackedColorArray()
        for i in range(drawn_segments + 1):
                var t: float = float(i) / float(SEGMENT_COUNT)
                # Quadratic bezier: B(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
                var p: Vector2 = start.lerp(control, t).lerp(control.lerp(end, t), t)
                points.append(p)
                # Renk: 0..0.5 amber→rose, 0.5..1 rose→emerald
                if t < 0.5:
                        colors.append(COLOR_AMBER.lerp(COLOR_ROSE, t * 2.0))
                else:
                        colors.append(COLOR_ROSE.lerp(COLOR_EMERALD, (t - 0.5) * 2.0))

        if points.size() >= 2:
                # Glow arka plan (kalın, düşük opaklık)
                var glow_colors: PackedColorArray = PackedColorArray()
                for c in colors:
                        glow_colors.append(Color(c.r, c.g, c.b, c.a * 0.35))
                draw_polyline_colors(points, glow_colors, 6.0, true)
                # Ana çizgi (ince, tam opaklık)
                draw_polyline_colors(points, colors, 2.5, true)

        # Başlangıç dairesi (amber)
        if progress > 0.05:
                draw_circle(start, 4.5, COLOR_AMBER)
        # Bitiş dairesi (emerald) — sadece çizim tamamlandığında
        if progress >= 1.0:
                draw_circle(end, 4.5, COLOR_EMERALD)
        # Orta sparkle — animasyon sırasında 0.3..1
        if progress > 0.3 and progress < 1.0:
                var sp_t: float = 0.5
                var sp: Vector2 = start.lerp(control, sp_t).lerp(control.lerp(end, sp_t), sp_t)
                # Sparkle'ın boyutu animasyonun ilerlemesine göre artıp azalır
                var sparkle_progress: float = (progress - 0.3) / 0.7  # 0..1
                var sparkle_size: float = 4.0 + 4.0 * (1.0 - abs(sparkle_progress * 2.0 - 1.0))
                draw_circle(sp, sparkle_size, COLOR_SPARKLE)


# Her karede kartlar hareket edebilir (scroll, resize) — bağlantıları yeniden çiz.
# Sadece aktif bağlantı varsa yeniden çizim iste.
func _process(_delta: float) -> void:
        if not _connections.is_empty():
                queue_redraw()
