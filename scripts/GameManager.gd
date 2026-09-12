# ============================================================
# GameManager.gd  (Autoload singleton)
# Oyun durumunu yönetir: skor, eşleşme, hata, süre, seçili kartlar,
# combo, hamle, ipucu, duraklatma.
# ------------------------------------------------------------
# Mantık:
# 1. İlk kart her zaman açılır (zaten açık karta tıklanmaz).
#    Oyun modu kontrolü (TR_TO_EN / EN_TO_TR / AUDIO): ilk kart
#    beklenen dilde değilse açılmaz, "wrong_side" sinyali yayılır,
#    kart play_wrong_side() animasyonu çalar.
# 2. İkinci kart:
#    - Aynı dil ise -> ikinci kart AÇILMAZ (geçersiz hamle)
#    - Farklı dil + aynı pair_id -> DOĞRU (bounce + yeşil + kalıcı açık)
#      * combo += 1, bonus puan = combo * 25
#    - Farklı dil + farklı pair_id -> YANLIŞ (shake + kısa açık + kapat)
#      * combo = 0
# 3. busy=true iken tıklamalar yoksayılır.
# 4. is_paused=true iken tıklamalar yoksayılır, süre durur.
# 5. use_hint(): 1.5sn eşleşmemiş bir çifti mor renkte gösterir.
# 6. Tüm çiftler bulununca game_won sinyali yayılır.
# 7. Sesli modda (AUDIO): ilk kart İngilizce ise AudioManager.play_word
#    çağrılır (kelimenin ses dosyası varsa çalar, yoksa sessizce atlanır).
# ============================================================
extends Node

# --- Sinyaller ---
signal score_changed(score: int)
signal match_count_changed(count: int, total: int)
signal error_count_changed(count: int)
signal time_changed(time_str: String)
signal game_won()
signal combo_changed(combo: int, best_combo: int)
signal moves_changed(moves: int)
signal hints_changed(hints_left: int, total_hints: int)
signal hint_used(pair_id: int)
signal pause_changed(is_paused: bool)
signal categories_changed(selected_categories: Array)
# Eşleşme anında ConnectionRibbon için: pair_id + Türkçe kart + İngilizce kart.
# Main.gd dinler ve connection_ribbon.show_connection(...) çağırır.
signal pair_matched_ribbon(pair_id: int, turkish_card, english_card)
# Oyun modu kuralı: ilk kart yanlış sütundan seçildi (TR_TO_EN, EN_TO_TR, AUDIO).
# Main.gd dinler ve kullanıcıya bilgilendirici mesaj gösterir.
# card: engellenen kart, expected_language: "turkish" | "english"
signal wrong_side(card, expected_language: String)
# Task 22: eşleşmiş bir karta tıklandı (kelime öğrenme kartı için).
# Main.gd, Card.matched_card_clicked sinyalini dinleyip bu sinyali yayarak
# GameManager seviyesinde de duyurur (ileride başka sistemler dinleyebilir).
# pair_id: tıklanan çiftin pair_id'si.
signal matched_card_clicked(pair_id: int)

# --- Sabitler ---
const POINTS_PER_MATCH: int = 100
const POINTS_PER_ERROR: int = -20
const POINTS_PER_COMBO: int = 25
const WRONG_CARD_HOLD_SECONDS: float = 1.0
const HINT_HOLD_SECONDS: float = 1.5

# --- Temel oyun durumu ---
var score: int = 0
var match_count: int = 0
var total_pairs: int = 6
var error_count: int = 0
var elapsed_time: float = 0.0
var is_running: bool = false
var busy: bool = false

# --- Combo sistemi ---
var combo: int = 0
var best_combo: int = 0

# --- Hamle sayacı ---
var moves: int = 0

# --- İpucu sistemi ---
var hints_left: int = 0
var total_hints: int = 0

# --- Duraklatma ---
var is_paused: bool = false
var is_game_won: bool = false

# --- Kategori sistemi ---
# Boş array -> tüm kategoriler kullanılır (Karışık mod).
# 1+ kategori -> yalnızca seçili kategorilerden çift seçilir.
var selected_categories: Array = []

# --- Kart referansları ---
# Tüm aktif kartlar (ipucu için). Main.gd register_card() ile ekler.
var all_cards: Array = []
# Eşleşmiş çift id'leri (debug / ipucu filtreleme için).
var matched_pair_ids: Array = []

# Seçili kartlar (en fazla 2)
var selected_cards: Array = []


func _ready() -> void:
        # Başlangıçta total_pairs ve total_hints EASY'e ayarla
        total_pairs = DifficultyManager.get_pair_count(DifficultyManager.current_difficulty)
        total_hints = DifficultyManager.get_hint_count(DifficultyManager.current_difficulty)
        hints_left = total_hints


func _process(delta: float) -> void:
        # Süre yalnızca çalışırken ve duraklatılmamışken ve kazanılmamışken ilerler
        if is_running and not is_paused and not is_game_won:
                elapsed_time += delta
                emit_signal("time_changed", _format_time(elapsed_time))


# Süreyi "MM:SS" biçiminde biçimlendir
func _format_time(time_sec: float) -> String:
        var total: int = int(time_sec)
        var m: int = total / 60
        var s: int = total % 60
        return "%02d:%02d" % [m, s]


# Yeni oyun başlat. Main.gd tarafından çağrılır.
# Not: selected_categories KORUNUR (oyunlar arası kalıcı).
# Main.gd, get_random_pairs(total_pairs, selected_categories) ile filtre uygular.
func start_game() -> void:
        total_pairs = DifficultyManager.get_pair_count(DifficultyManager.current_difficulty)
        total_hints = DifficultyManager.get_hint_count(DifficultyManager.current_difficulty)
        score = 0
        match_count = 0
        error_count = 0
        elapsed_time = 0.0
        combo = 0
        best_combo = 0
        moves = 0
        hints_left = total_hints
        is_paused = false
        is_game_won = false
        matched_pair_ids.clear()
        selected_cards.clear()
        busy = false
        is_running = true
        emit_signal("score_changed", score)
        emit_signal("match_count_changed", match_count, total_pairs)
        emit_signal("error_count_changed", error_count)
        emit_signal("time_changed", _format_time(elapsed_time))
        emit_signal("combo_changed", combo, best_combo)
        emit_signal("moves_changed", moves)
        emit_signal("hints_changed", hints_left, total_hints)
        emit_signal("pause_changed", is_paused)


# Main.gd kartları kaydeder (ipucu sisteminin tüm kartları görebilmesi için).
func register_card(card) -> void:
        if card == null:
                return
        if not all_cards.has(card):
                all_cards.append(card)


# Main.gd yeni oyun başlatırken listeyi temizler.
func clear_cards() -> void:
        all_cards.clear()


# Karta tıklama isteğini işle. true dönerse kart açılmıştır.
func select_card(card) -> bool:
        # Kontrol sırası önemli
        if busy:
                return false
        if is_paused:
                return false
        if is_game_won:
                return false
        if card == null:
                return false
        if card.is_open or card.is_matched:
                return false

        # İlk kart: direkt aç
        if selected_cards.size() == 0:
                # --- Oyun modu kontrolü (Web Task 12 parite) ---
                # Eğer GameModeManager yüklenmişse ve ilk kart için belirli bir
                # dil zorunluysa (TR_TO_EN, EN_TO_TR, AUDIO), kontrol et.
                # Uyuşmuyorsa: kart açma, "wrong_side" sinyali yay, blocked animasyonu.
                if GameModeManager != null:
                        var expected_lang: String = GameModeManager.get_first_card_language()
                        if expected_lang != "" and card.language != expected_lang:
                                # Yanlış sütun: kart açılmasın, kullanıcıya bilgi ver
                                card.play_wrong_side()
                                AudioManager.play_wrong()
                                emit_signal("wrong_side", card, expected_lang)
                                return false
                card.flip_open()
                selected_cards.append(card)
                AudioManager.play_flip()
                # Sesli modda: ilk kart İngilizce ise, o kelimenin ses dosyasını çal
                # (dosya yoksa sessizce atlanır, AudioManager.play_word içinde kontrol).
                if GameModeManager != null and GameModeManager.is_audio_mode() \
                                and card.language == "english":
                        AudioManager.play_word(card.word)
                return true

        # İkinci kart: dil kontrolü
        if selected_cards.size() == 1:
                var first = selected_cards[0]
                # Aynı dil -> ikinci kart açılmaz (geçersiz hamle)
                if first.language == card.language:
                        # Hafif "engellendi" animasyonu
                        card.play_blocked()
                        return false
                # Farklı dil -> aç, kontrol et
                card.flip_open()
                selected_cards.append(card)
                AudioManager.play_flip()
                # İkinci kart açıldı -> bir hamle say
                moves += 1
                emit_signal("moves_changed", moves)
                busy = true
                _check_match()
                return true

        return false


# Seçili iki kartı kontrol et
func _check_match() -> void:
        if selected_cards.size() != 2:
                busy = false
                return

        var c1 = selected_cards[0]
        var c2 = selected_cards[1]

        # Eşleşme: pair_id eşit
        if c1.pair_id == c2.pair_id:
                # DOĞRU
                combo += 1
                best_combo = max(best_combo, combo)
                var combo_bonus: int = combo * POINTS_PER_COMBO
                score += POINTS_PER_MATCH + combo_bonus
                match_count += 1
                emit_signal("score_changed", score)
                emit_signal("match_count_changed", match_count, total_pairs)
                emit_signal("combo_changed", combo, best_combo)
                AudioManager.play_match()
                c1.set_matched()
                c2.set_matched()
                matched_pair_ids.append(c1.pair_id)
                # ConnectionRibbon için: hangi kart Türkçe hangi İngilizce?
                var tr_card = c1 if c1.language == "turkish" else c2
                var en_card = c2 if c1.language == "turkish" else c1
                emit_signal("pair_matched_ribbon", c1.pair_id, tr_card, en_card)
                selected_cards.clear()

                # Kazanma kontrolü
                if match_count >= total_pairs:
                        is_running = false
                        is_game_won = true
                        # Kazanma sesini çalmak için kısa gecikme
                        await get_tree().create_timer(0.35).timeout
                        AudioManager.play_win()
                        emit_signal("game_won")
                # busy artık serbest bırakılabilir
                busy = false
        else:
                # YANLIŞ
                combo = 0
                score = max(0, score + POINTS_PER_ERROR)
                error_count += 1
                emit_signal("score_changed", score)
                emit_signal("error_count_changed", error_count)
                emit_signal("combo_changed", combo, best_combo)
                AudioManager.play_wrong()
                c1.shake()
                c2.shake()
                # Kısa süre açık kalsın, sonra kapat
                await get_tree().create_timer(WRONG_CARD_HOLD_SECONDS).timeout
                c1.flip_close()
                c2.flip_close()
                selected_cards.clear()
                busy = false


# İpucu kullan: eşleşmemiş bir çifti 1.5sn mor renkte gösterir.
# - hints_left <= 0 ise yoksay
# - busy ise yoksay
# - is_paused / is_game_won ise yoksay
# - hint_penalty kadar puan keser (min 0)
# - ipucu süresince busy=true (tıklama engellenir)
func use_hint() -> void:
        if hints_left <= 0:
                return
        if busy:
                return
        if is_paused:
                return
        if is_game_won:
                return

        # Eğer açık seçili kart varsa önce kapat (ipucu ile çakışmasın)
        if selected_cards.size() > 0:
                for c in selected_cards:
                        if is_instance_valid(c) and not c.is_matched:
                                c.flip_close()
                selected_cards.clear()

        # Eşleşmemiş ve kapalı bir çift bul
        var unmatched_pairs: Dictionary = {}
        for card in all_cards:
                if not is_instance_valid(card):
                        continue
                if card.is_matched:
                        continue
                if card.is_open:
                        continue
                if not unmatched_pairs.has(card.pair_id):
                        unmatched_pairs[card.pair_id] = []
                unmatched_pairs[card.pair_id].append(card)

        var pair_id: int = -1
        for pid in unmatched_pairs.keys():
                if unmatched_pairs[pid].size() >= 2:
                        pair_id = pid
                        break
        if pair_id < 0:
                return  # Gösterilecek çift yok

        var pair_cards: Array = unmatched_pairs[pair_id]
        var c1 = pair_cards[0]
        var c2 = pair_cards[1]

        # Penalty ve sayaç
        var penalty: int = DifficultyManager.get_hint_penalty(DifficultyManager.current_difficulty)
        score = max(0, score - penalty)
        hints_left -= 1
        busy = true
        emit_signal("score_changed", score)
        emit_signal("hints_changed", hints_left, total_hints)
        emit_signal("hint_used", pair_id)
        AudioManager.play_hint()

        # İki kartı mor renkte göster
        c1.show_hint()
        c2.show_hint()

        # 1.5 saniye bekle, sonra kapat
        await get_tree().create_timer(HINT_HOLD_SECONDS).timeout
        if is_instance_valid(c1):
                c1.hide_hint()
        if is_instance_valid(c2):
                c2.hide_hint()
        busy = false


# Duraklatmayı aç/kapat. Yalnızca is_running && !is_game_won ise çalışır.
func toggle_pause() -> void:
        if not is_running or is_game_won:
                return
        is_paused = not is_paused
        emit_signal("pause_changed", is_paused)
        if is_paused:
                AudioManager.play_pause()
        else:
                AudioManager.play_resume()


# Oyunu sıfırla (TEKRAR OYNA)
func reset_game() -> void:
        is_running = false
        busy = false
        score = 0
        match_count = 0
        error_count = 0
        elapsed_time = 0.0
        combo = 0
        best_combo = 0
        moves = 0
        is_paused = false
        is_game_won = false
        matched_pair_ids.clear()
        selected_cards.clear()
        start_game()


# Seçili kategorileri ayarla. Boş array = tüm kategoriler (Karışık).
# Bilinmeyen kategori id'leri sessizce süzülür (crash yok).
# categories_changed sinyali yayılır; Main.gd oyunu yeniden başlatır.
func set_categories(cats: Array) -> void:
        var valid: Array = []
        var known: Array = []
        for c in WordData.CATEGORIES:
                known.append(c["id"])
        for c in cats:
                if c is String and known.has(c) and not valid.has(c):
                        valid.append(c)
        if _array_eq(valid, selected_categories):
                return  # değişiklik yok
        selected_categories = valid
        emit_signal("categories_changed", selected_categories)


# Tüm kategori seçimini temizle (Karışık mod).
func clear_categories() -> void:
        if selected_categories.is_empty():
                return
        selected_categories.clear()
        emit_signal("categories_changed", selected_categories)


# İki String array'inin aynı elemanlara sahip olup olmadığını kontrol et (sıra bağımsız).
func _array_eq(a: Array, b: Array) -> bool:
        if a.size() != b.size():
                return false
        for x in a:
                if not b.has(x):
                        return false
        return true


# Seçili kategorilerde kaç çift var? Boş = tüm havuz.
func get_pool_pair_count() -> int:
        return WordData.get_pool_pair_count(selected_categories)


# Seçili kategorilerde zorluğun istediği çift sayısını karşılayacak kadar çift var mı?
func has_enough_pairs_for_difficulty() -> bool:
        return get_pool_pair_count() >= total_pairs


# Süre ölçer (debug / GameOverPanel için)
func get_elapsed_seconds() -> float:
        return elapsed_time
