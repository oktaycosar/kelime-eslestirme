# ============================================================
# TestRunner.gd (Geçici autoload)
# Godot 4 headless modda otomatik testler çalıştırır.
# Testler tamamlandığında uygulama otomatik kapanır.
# Temiz teslimat için project.godot'tan kaldırılmalıdır.
# ============================================================
extends Node

var _passed: int = 0
var _failed: int = 0
var _current_test: String = ""

# Test helper state (Task 13): lambda capture by-reference GDScript'te
# güvenilmediği için sinyal sayacıları member değişkenlerde tutulur.
var _test_mode_changed_received: bool = false
var _test_mode_changed_mode: int = -1
var _test_ws_count: int = 0
# Task 22: matched_card_clicked sinyal sayacı (GameManager seviyesi)
var _test_mcc_count: int = 0
var _test_mcc_pair_id: int = -1


# Test sinyal işleyicileri (Task 13)
func _on_test_mode_changed(mode: int) -> void:
        _test_mode_changed_received = true
        _test_mode_changed_mode = mode


func _on_test_wrong_side(_card, _lang: String) -> void:
        _test_ws_count += 1


# Task 22: GameManager.matched_card_clicked sinyali geldiğinde çağrılır
func _on_test_matched_card_clicked(pair_id: int) -> void:
        _test_mcc_count += 1
        _test_mcc_pair_id = pair_id


# Task 22: Card.matched_card_clicked sinyali geldiğinde çağrılır (Card nesnesi alır)
var _test_card_mcc_count: int = 0
var _test_card_mcc_pair_id: int = -1
func _on_test_card_matched_card_clicked(card) -> void:
        _test_card_mcc_count += 1
        if card != null:
                _test_card_mcc_pair_id = card.pair_id


func _ready() -> void:
        print("=== TestRunner başlıyor ===")
        await _run_all_tests()
        print("=== SONUÇ: %d PASS, %d FAIL ===" % [_passed, _failed])
        get_tree().quit(0 if _failed == 0 else 1)


func _assert_eq(actual, expected, label: String) -> void:
        if actual == expected:
                _passed += 1
                print("  PASS: %s" % label)
        else:
                _failed += 1
                print("  FAIL: %s (beklenen=%s, gerçek=%s)" % [label, str(expected), str(actual)])


func _assert_true(value: bool, label: String) -> void:
        if value:
                _passed += 1
                print("  PASS: %s" % label)
        else:
                _failed += 1
                print("  FAIL: %s (false bekleniyordu true)" % label)


func _assert_false(value: bool, label: String) -> void:
        if not value:
                _passed += 1
                print("  PASS: %s" % label)
        else:
                _failed += 1
                print("  FAIL: %s (true bekleniyordu false)" % label)


func _begin_test(name: String) -> void:
        _current_test = name
        print("")
        print(">>> %s" % name)


func _run_all_tests() -> void:
        await _test_difficulty_manager_expert()
        await _test_save_manager_expert()
        await _test_word_data_categories()
        await _test_main_scene_structure()
        await _test_connection_ribbon_class()
        await _test_game_manager_pair_matched_ribbon_signal()
        await _test_main_card_split()
        await _test_difficulty_manager_regression()
        await _test_save_manager_regression()
        await _test_difficulty_labels()
        await _test_game_mode_manager_autoload()
        await _test_game_mode_manager_default_and_language()
        await _test_game_mode_manager_set_mode()
        await _test_game_mode_manager_labels_emojis()
        await _test_game_mode_manager_signal()
        await _test_game_manager_wrong_side_signal()
        await _test_main_scene_game_mode_bar()
        await _test_main_wrong_side_behavior()
        await _test_game_manager_new_categories()
        await _test_word_data_new_pairs_task18()
        await _test_word_examples_autoload()
        await _test_word_examples_fallback()
        await _test_card_matched_card_clicked_signal()
        await _test_game_manager_matched_card_clicked_signal()
        await _test_word_card_panel_scene()
        await _test_main_word_card_panel_node()
        await _test_main_matched_card_opens_word_card()


# --- DifficultyManager EXPERT testleri ---
func _test_difficulty_manager_expert() -> void:
        _begin_test("DifficultyManager EXPERT desteği")
        var DM = DifficultyManager
        _assert_eq(DM.Difficulty.EXPERT, 3, "Difficulty.EXPERT enum = 3")
        _assert_eq(DM.get_pair_count(DM.Difficulty.EXPERT), 15, "EXPERT pair_count = 15")
        _assert_eq(DM.get_card_count(DM.Difficulty.EXPERT), 30, "EXPERT card_count = 30")
        _assert_eq(DM.get_hint_count(DM.Difficulty.EXPERT), 1, "EXPERT hint_count = 1")
        _assert_eq(DM.get_hint_penalty(DM.Difficulty.EXPERT), 150, "EXPERT hint_penalty = 150")
        _assert_eq(DM.get_difficulty_level(DM.Difficulty.EXPERT), 4, "EXPERT level = 4")
        _assert_eq(DM.get_difficulty_label(DM.Difficulty.EXPERT), "UZMAN", "EXPERT label = UZMAN")
        _assert_eq(DM.get_difficulty_label_pretty(DM.Difficulty.EXPERT), "Uzman", "EXPERT pretty label = Uzman")
        _assert_eq(DM.get_grid_columns(DM.Difficulty.EXPERT), 5, "EXPERT grid_columns = 5 (geri uyumluluk)")


# --- SaveManager EXPERT desteği ---
func _test_save_manager_expert() -> void:
        _beginTestHack()
        # Boş kayıttan başla
        SaveManager.clear_all()
        _assert_true(SaveManager.load_best_record(DifficultyManager.Difficulty.EXPERT).is_empty(), "EXPERT boş kayıt")
        # Yeni rekor kaydet
        var is_new: bool = SaveManager.is_new_record(DifficultyManager.Difficulty.EXPERT, 1000, 30.0, 0, 15)
        _assert_true(is_new, "EXPERT ilk kayıt yeni rekor")
        var saved: bool = SaveManager.save_best_record(DifficultyManager.Difficulty.EXPERT, 1000, 30.0, 0, 15)
        _assert_true(saved, "EXPERT save_best_record true")
        # Tekrar oku
        var rec: Dictionary = SaveManager.load_best_record(DifficultyManager.Difficulty.EXPERT)
        _assert_eq(int(rec.get("score", 0)), 1000, "EXPERT kayıttan skor oku")
        # İstatistik kaydı
        SaveManager.record_game_result(DifficultyManager.Difficulty.EXPERT, true, 1000, 30.0, 0, 15, 5)
        var stats: Dictionary = SaveManager.load_difficulty_stats(DifficultyManager.Difficulty.EXPERT)
        _assert_eq(int(stats.get("games_played", 0)), 1, "EXPERT stats games_played = 1")
        _assert_eq(int(stats.get("games_won", 0)), 1, "EXPERT stats games_won = 1")
        _assert_eq(int(stats.get("best_score", 0)), 1000, "EXPERT stats best_score = 1000")
        _assert_eq(int(stats.get("best_combo", 0)), 5, "EXPERT stats best_combo = 5")
        # Tüm stats dict'inde EXPERT key var mı?
        var all_stats: Dictionary = SaveManager.load_game_stats()
        _assert_true(all_stats.has("EXPERT"), "all_stats has EXPERT key")
        # Temizlik
        SaveManager.clear_all()


# ---
func _beginTestHack() -> void:
        _current_test = "SaveManager EXPERT desteği"
        print("")
        print(">>> %s" % _current_test)


# --- WordData kategori regresyon (Task 9 + Task 16 + Task 18) ---
func _test_word_data_categories() -> void:
        _begin_test("WordData kategori regresyon (Task 9 + Task 16 + Task 18)")
        # Task 16: 10 → 14 kategori, 90 → 126 çift. Task 18: her kategori +6 → 15 çift, 126 → 210 çift.
        _assert_eq(WordData.CATEGORIES.size(), 14, "CATEGORIES size = 14")
        _assert_eq(WordData.WORD_PAIRS.size(), 210, "WORD_PAIRS size = 210 (Task 18)")
        _assert_eq(WordData.get_total_pair_count(), 210, "get_total_pair_count = 210 (Task 18)")
        # Kategori 15 çift (Task 18 sonrası her kategori 9 → 15)
        _assert_eq(WordData.get_category_pair_count("animals"), 15, "animals 15 çift (Task 18)")
        _assert_eq(WordData.get_category_pair_count("family"), 15, "family 15 çift (Task 18)")
        # Task 16: 4 yeni kategori - her biri 15 çift (Task 18 sonrası)
        _assert_eq(WordData.get_category_pair_count("professions"), 15, "professions 15 çift (Task 18)")
        _assert_eq(WordData.get_category_pair_count("emotions"), 15, "emotions 15 çift (Task 18)")
        _assert_eq(WordData.get_category_pair_count("weather"), 15, "weather 15 çift (Task 18)")
        _assert_eq(WordData.get_category_pair_count("transport"), 15, "transport 15 çift (Task 18)")
        # Yeni kategori sabitleri
        _assert_eq(WordData.CATEGORY_PROFESSIONS, "professions", "CATEGORY_PROFESSIONS = professions")
        _assert_eq(WordData.CATEGORY_EMOTIONS, "emotions", "CATEGORY_EMOTIONS = emotions")
        _assert_eq(WordData.CATEGORY_WEATHER, "weather", "CATEGORY_WEATHER = weather")
        _assert_eq(WordData.CATEGORY_TRANSPORT, "transport", "CATEGORY_TRANSPORT = transport")
        # Havuz sayısı
        _assert_eq(WordData.get_pool_pair_count([]), 210, "boş havuz 210 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["animals"]), 15, "animals havuz 15 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["animals", "food"]), 30, "animals+food havuz 30 (Task 18)")
        # Task 16: 4 yeni kategori havuz sayilari (Task 18 sonrası 15)
        _assert_eq(WordData.get_pool_pair_count(["professions"]), 15, "professions havuz 15 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["emotions"]), 15, "emotions havuz 15 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["weather"]), 15, "weather havuz 15 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["transport"]), 15, "transport havuz 15 (Task 18)")
        # 4 yeni kategori toplam (60 çift — Task 18: 4 × 15)
        _assert_eq(WordData.get_pool_pair_count(["professions", "emotions", "weather", "transport"]), 60, "4 yeni kategori toplam 60 (Task 18)")
        # Random pairs
        _assert_eq(WordData.get_random_pairs(6).size(), 6, "6 rastgele çift")
        _assert_eq(WordData.get_random_pairs(0).size(), 0, "0 rastgele çift boş array")
        var many: Array = WordData.get_random_pairs(300)
        _assert_eq(many.size(), 210, "300 istek → 210 döner (Task 18 havuz üst sınırı)")
        # Kategori filtreli
        _assert_eq(WordData.get_random_pairs(6, ["animals"]).size(), 6, "animals 6 çift")
        _assert_eq(WordData.get_random_pairs(10, ["animals"]).size(), 10, "animals 10 iste → 10 döner (Task 18 sonrası 15 havuz)")
        _assert_eq(WordData.get_random_pairs(15, ["animals"]).size(), 15, "animals 15 iste → 15 döner (Task 18 tam havuz)")
        _assert_eq(WordData.get_random_pairs(20, ["animals"]).size(), 15, "animals 20 iste → 15 döner (havuz üst sınırı)")
        # Task 16: yeni kategori filtreli (Task 18 sonrası 15)
        _assert_eq(WordData.get_random_pairs(6, ["professions"]).size(), 6, "professions 6 çift")
        _assert_eq(WordData.get_random_pairs(15, ["professions"]).size(), 15, "professions 15 iste → 15 döner (Task 18 tam havuz)")
        # build_cards
        var cards3: Array = WordData.build_cards(WordData.get_random_pairs(3))
        _assert_eq(cards3.size(), 6, "3 çift → 6 kart")
        var tr_count: int = 0
        var en_count: int = 0
        for c in cards3:
                if c["language"] == "turkish":
                        tr_count += 1
                else:
                        en_count += 1
        _assert_eq(tr_count, 3, "3 Türkçe kart")
        _assert_eq(en_count, 3, "3 İngilizce kart")
        # Task 16: Yeni çiftlerin pair_id'leri 91-126 aralığında ve benzersiz
        var t16_pair_ids: Array = []
        for p in WordData.WORD_PAIRS:
                if p.get("category", "") in ["professions", "emotions", "weather", "transport"] and p["pair_id"] <= 126:
                        t16_pair_ids.append(p["pair_id"])
        _assert_eq(t16_pair_ids.size(), 36, "Task 16 yeni kategori toplam 36 çift")
        # 91-126 aralığında, benzersiz
        var t16_expected: Array = []
        for i in range(91, 127):
                t16_expected.append(i)
        t16_pair_ids.sort()
        _assert_eq(t16_pair_ids, t16_expected, "Task 16 çift pair_id'leri 91-126 aralığında")
        # Task 18: Yeni çiftlerin pair_id'leri 127-210 aralığında ve benzersiz (84 çift)
        var t18_pair_ids: Array = []
        for p in WordData.WORD_PAIRS:
                if p["pair_id"] >= 127:
                        t18_pair_ids.append(p["pair_id"])
        _assert_eq(t18_pair_ids.size(), 84, "Task 18 toplam 84 yeni çift")
        var t18_expected: Array = []
        for i in range(127, 211):
                t18_expected.append(i)
        t18_pair_ids.sort()
        _assert_eq(t18_pair_ids, t18_expected, "Task 18 çift pair_id'leri 127-210 aralığında")
        # Duplicate pair_id kontrolü: tüm 210 pair_id benzersiz olmalı
        var all_ids: Array = []
        for p in WordData.WORD_PAIRS:
                all_ids.append(p["pair_id"])
        _assert_eq(all_ids.size(), 210, "Toplam 210 pair_id")
        var unique_ids: Array = []
        for pid in all_ids:
                if not unique_ids.has(pid):
                        unique_ids.append(pid)
        _assert_eq(unique_ids.size(), 210, "210 benzersiz pair_id (duplicate yok)")
        # Her kategori tam 15 çift (Task 18 sonrası)
        var cat_counts: Dictionary = {}
        for p in WordData.WORD_PAIRS:
                var ck: String = p.get("category", "")
                cat_counts[ck] = cat_counts.get(ck, 0) + 1
        for cat_key in cat_counts.keys():
                _assert_eq(int(cat_counts[cat_key]), 15, "Kategori " + str(cat_key) + " 15 çift (Task 18)")
        # Task 16: CATEGORIES 4 yeni kategori içeriyor
        var cat_ids: Array = []
        for c in WordData.CATEGORIES:
                cat_ids.append(c["id"])
        for new_id in ["professions", "emotions", "weather", "transport"]:
                _assert_true(cat_ids.has(new_id), "CATEGORIES contains " + new_id)
        # Task 18: Örnek yeni çift içerik kontrolü (pair_id 127, 210)
        var p127: Dictionary = {}
        var p210: Dictionary = {}
        for p in WordData.WORD_PAIRS:
                if p["pair_id"] == 127:
                        p127 = p
                if p["pair_id"] == 210:
                        p210 = p
        _assert_eq(p127.get("turkish", ""), "ASLAN", "pair_id 127 turkish = ASLAN")
        _assert_eq(p127.get("english", ""), "LION", "pair_id 127 english = LION")
        _assert_eq(p127.get("category", ""), "animals", "pair_id 127 category = animals")
        _assert_eq(p210.get("turkish", ""), "SKUTER", "pair_id 210 turkish = SKUTER")
        _assert_eq(p210.get("english", ""), "SCOOTER", "pair_id 210 english = SCOOTER")
        _assert_eq(p210.get("category", ""), "transport", "pair_id 210 category = transport")


# --- Task 18: 84 yeni çift detaylı test ---
func _test_word_data_new_pairs_task18() -> void:
        _begin_test("Task 18: 84 yeni çift (pair_id 127-210)")
        # Her kategori için 6 yeni çiftin doğru category alanına sahip olduğunu doğrula
        # Task 18 yeni çift kategori bazında dağılımı (pair_id -> category)
        var expected_t18: Dictionary = {
                "animals": [127, 128, 129, 130, 131, 132],
                "food": [133, 134, 135, 136, 137, 138],
                "nature": [139, 140, 141, 142, 143, 144],
                "house": [145, 146, 147, 148, 149, 150],
                "body": [151, 152, 153, 154, 155, 156],
                "school": [157, 158, 159, 160, 161, 162],
                "clothing": [163, 164, 165, 166, 167, 168],
                "colors": [169, 170, 171, 172, 173, 174],
                "numbers": [175, 176, 177, 178, 179, 180],
                "family": [181, 182, 183, 184, 185, 186],
                "professions": [187, 188, 189, 190, 191, 192],
                "emotions": [193, 194, 195, 196, 197, 198],
                "weather": [199, 200, 201, 202, 203, 204],
                "transport": [205, 206, 207, 208, 209, 210],
        }
        # Her kategori için: o kategoriye ait tüm pair_id'leri topla ve Task 18 yeni 6 çifti içerdiğini kontrol et
        for cat_key in expected_t18.keys():
                var cat_pair_ids: Array = []
                for p in WordData.WORD_PAIRS:
                        if p.get("category", "") == cat_key:
                                cat_pair_ids.append(p["pair_id"])
                _assert_eq(cat_pair_ids.size(), 15, "Kategori " + str(cat_key) + " toplam 15 çift (Task 18)")
                for new_pid in expected_t18[cat_key]:
                        _assert_true(cat_pair_ids.has(new_pid), "Kategori " + str(cat_key) + " Task 18 çifti içeriyor: pair_id=" + str(new_pid))
        # Toplam 84 yeni çift (127-210)
        var total_new: int = 0
        for cat_key in expected_t18.keys():
                total_new += expected_t18[cat_key].size()
        _assert_eq(total_new, 84, "14 kategori × 6 yeni çift = 84 (Task 18)")
        # Yeni çiftlerin Türkçe ve İngilizce alanları boş değil
        var empty_count: int = 0
        for p in WordData.WORD_PAIRS:
                if p["pair_id"] >= 127:
                        if p.get("turkish", "") == "" or p.get("english", "") == "":
                                empty_count += 1
        _assert_eq(empty_count, 0, "Task 18 çiftlerinin tüm Türkçe/İngilizce alanları dolu")
        # Yeni çiftlerin Türkçe alanları benzersiz mi (aynı kelimeden iki kez yok mu)
        var t18_tr_words: Array = []
        var t18_en_words: Array = []
        for p in WordData.WORD_PAIRS:
                if p["pair_id"] >= 127:
                        t18_tr_words.append(p.get("turkish", ""))
                        t18_en_words.append(p.get("english", ""))
        var unique_tr: int = 0
        var unique_en: int = 0
        for w in t18_tr_words:
                if t18_tr_words.count(w) == 1:
                        unique_tr += 1
        for w in t18_en_words:
                if t18_en_words.count(w) == 1:
                        unique_en += 1
        _assert_eq(unique_tr, 84, "Task 18 Türkçe kelimelerinin tümü benzersiz")
        _assert_eq(unique_en, 84, "Task 18 İngilizce kelimelerinin tümü benzersiz")
        # pool_pair_count testleri
        _assert_eq(WordData.get_pool_pair_count(["animals", "nature", "body", "school", "clothing", "colors"]), 90, "6 kategori × 15 = 90 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["numbers", "family"]), 30, "numbers + family = 30 (Task 18)")
        _assert_eq(WordData.get_pool_pair_count(["professions", "emotions"]), 30, "professions + emotions = 30 (Task 18)")
        # has_enough_pairs - Uzman (15) tek kategori ile artık yeterli
        _assert_true(WordData.has_enough_pairs(15, ["animals"]), "Uzman (15) animals yeterli (Task 18 sonrası)")
        _assert_true(WordData.has_enough_pairs(15, ["professions"]), "Uzman (15) professions yeterli (Task 18 sonrası)")
        _assert_true(WordData.has_enough_pairs(15, ["transport"]), "Uzman (15) transport yeterli (Task 18 sonrası)")
        _assert_false(WordData.has_enough_pairs(20, ["animals"]), "20 çift tek kategori yetersiz (15 < 20)")
        # build_cards 15 çift ile 30 kart üretir
        var cards_full: Array = WordData.build_cards(WordData.get_random_pairs(15, ["animals"]))
        _assert_eq(cards_full.size(), 30, "15 çift → 30 kart (Task 18 tam havuz)")


# --- Main.tscn yeni yapı (iki sütunlu + ConnectionRibbon) ---
func _test_main_scene_structure() -> void:
        _begin_test("Main.tscn iki sütunlu yapı")
        # Project startup (autoload + main scene) tamamlanmasını bekle.
        # Aksi takdirde test'in add_child'i "Parent node is busy" hatası alabilir.
        await get_tree().process_frame
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        # Main.gd call_deferred("_initialize_first_game") ile ilk oyunu başlatır.
        # Test senaryosunda bu doğrudan çağrılır (geçici instantiate senaryosu).
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        # Bir frame bekle, kartlar tam yerleşsin.
        await get_tree().process_frame

        # TitleLabel metni
        var title: Label = inst.get_node_or_null("RootVBox/TitleLabel")
        _assert_true(title != null, "TitleLabel mevcut")
        if title != null:
                _assert_eq(title.text, "KELİME EŞLEŞTİRME", "Title metni 'KELİME EŞLEŞTİRME'")
        var title_logo: HBoxContainer = inst.get_node_or_null("RootVBox/TitleLogo")
        _assert_true(title_logo != null, "Grafik TitleLogo mevcut")
        if title_logo != null:
                _assert_eq(title_logo.get_child_count(), 17, "TitleLogo 16 harf + bağlantı simgesi")

        # SubtitleLabel
        var subtitle: Label = inst.get_node_or_null("RootVBox/SubtitleLabel")
        _assert_true(subtitle != null, "SubtitleLabel mevcut")
        if subtitle != null:
                _assert_true(subtitle.text.find("Türkçe") >= 0, "Subtitle 'Türkçe' içeriyor")
                _assert_true(subtitle.text.find("İngilizce") >= 0, "Subtitle 'İngilizce' içeriyor")
                _assert_true(subtitle.text.find("TR") >= 0 and subtitle.text.find("EN") >= 0, "Subtitle TR/EN içeriyor")

        # TurkishCards container
        var trc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
        _assert_true(trc != null, "TurkishCards container mevcut")

        # EnglishCards container
        var enc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
        _assert_true(enc != null, "EnglishCards container mevcut")

        # TurkishHeaderPanel
        var trh: Panel = inst.get_node_or_null("RootVBox/ColumnHeaders/TurkishHeaderPanel")
        _assert_true(trh != null, "TurkishHeaderPanel mevcut")
        var trhl: Label = inst.get_node_or_null("RootVBox/ColumnHeaders/TurkishHeaderPanel/TurkishHeaderLabel")
        if trhl != null:
                _assert_true(trhl.text.find("TÜRKÇE") >= 0, "Türkçe başlık metni 'TÜRKÇE' içeriyor")

        # EnglishHeaderPanel
        var enh: Panel = inst.get_node_or_null("RootVBox/ColumnHeaders/EnglishHeaderPanel")
        _assert_true(enh != null, "EnglishHeaderPanel mevcut")
        var enhl: Label = inst.get_node_or_null("RootVBox/ColumnHeaders/EnglishHeaderPanel/EnglishHeaderLabel")
        if enhl != null:
                _assert_true(enhl.text.find("İNGİLİZCE") >= 0, "İngilizce başlık metni 'İNGİLİZCE' içeriyor")

        # ConnectionRibbon
        var ribbon: Control = inst.get_node_or_null("RootVBox/GameArea/ConnectionRibbon")
        _assert_true(ribbon != null, "ConnectionRibbon mevcut")
        if ribbon != null:
                _assert_true(ribbon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Ribbon mouse_filter=IGNORE")
                _assert_eq(ribbon.get_connection_count(), 0, "Ribbon başlangıçta 0 bağlantı")

        # GameArea mevcut
        var game_area: Control = inst.get_node_or_null("RootVBox/GameArea")
        _assert_true(game_area != null, "GameArea mevcut")

        # Eski GridContainer YOK
        _assert_true(inst.get_node_or_null("RootVBox/GridContainer") == null, "Eski GridContainer YOK")

        # 6 çift (EASY) → 6 Türkçe + 6 İngilizce kart
        if trc != null:
                _assert_eq(trc.get_child_count(), 6, "Türkçe sütunda 6 kart (EASY)")
        if enc != null:
                _assert_eq(enc.get_child_count(), 6, "İngilizce sütunda 6 kart (EASY)")

        # Task 16: Kategori butonları — 1 "Tümünü Göster" + 14 kategori = 15 buton
        var cat_flow: HFlowContainer = inst.get_node_or_null("RootVBox/CategoryBar/CategoryFlow")
        _assert_true(cat_flow != null, "CategoryFlow mevcut")
        if cat_flow != null:
                _assert_eq(cat_flow.get_child_count(), 15, "CategoryFlow 15 buton (1 + 14 kategori, Task 16)")
                # 4 yeni kategori butonu mevcut mu kontrol et
                for new_id in ["professions", "emotions", "weather", "transport"]:
                        _assert_true(inst.get_node_or_null("RootVBox/CategoryBar/CategoryFlow/Cat_" + new_id) != null, "Cat_" + new_id + " butonu mevcut")

        inst.queue_free()
        await get_tree().process_frame


# --- ConnectionRibbon class testi ---
func _test_connection_ribbon_class() -> void:
        _begin_test("ConnectionRibbon sınıfı API")
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame

        var ribbon: Control = inst.get_node_or_null("RootVBox/GameArea/ConnectionRibbon")
        _assert_true(ribbon != null, "ConnectionRibbon mevcut")
        if ribbon != null:
                # clear_all çağrılabilir
                ribbon.clear_all()
                _assert_eq(ribbon.get_connection_count(), 0, "clear_all sonrası 0 bağlantı")
                # show_connection: dummy parametrelerle (kartlar null → noop)
                ribbon.show_connection(null, null, 999)
                _assert_eq(ribbon.get_connection_count(), 0, "null kartlarla bağlantı eklenmedi")
                # Geçerli kartlarla: en az bir Türkçe ve bir İngilizce kart bul
                var tr_card = null
                var en_card = null
                var trc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
                var enc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
                if trc != null and trc.get_child_count() > 0:
                        tr_card = trc.get_child(0)
                if enc != null and enc.get_child_count() > 0:
                        en_card = enc.get_child(0)
                if tr_card != null and en_card != null:
                        # Aynı pair_id'li iki kart bulmak ideal, ama sadece API testi için fark etmez
                        ribbon.show_connection(tr_card, en_card, 1)
                        _assert_eq(ribbon.get_connection_count(), 1, "1 bağlantı eklendi")
                        ribbon.show_connection(tr_card, en_card, 1)
                        _assert_eq(ribbon.get_connection_count(), 1, "Aynı pair_id → üzerine yazıldı (hala 1)")
                        # hide_connection
                        ribbon.hide_connection(1)
                        _assert_eq(ribbon.get_connection_count(), 0, "hide_connection sonrası 0")
                        # Yeniden ekle
                        ribbon.show_connection(tr_card, en_card, 2)
                        ribbon.show_connection(tr_card, en_card, 3)
                        _assert_eq(ribbon.get_connection_count(), 2, "2 farklı pair_id → 2 bağlantı")
                        ribbon.clear_all()
                        _assert_eq(ribbon.get_connection_count(), 0, "clear_all → 0")

        inst.queue_free()
        await get_tree().process_frame


# --- GameManager pair_matched_ribbon sinyali ---
func _test_game_manager_pair_matched_ribbon_signal() -> void:
        _begin_test("GameManager.pair_matched_ribbon sinyali")
        # Sinyalin varlığını kontrol et
        var sig_list: Array = GameManager.get_signal_list()
        var found: bool = false
        for s in sig_list:
                if s["name"] == "pair_matched_ribbon":
                        found = true
                        break
        _assert_true(found, "GameManager.pair_matched_ribbon sinyali mevcut")


# --- Main.gd kartları dile göre ayırır ---
func _test_main_card_split() -> void:
        _begin_test("Main.gd kartları dile göre ayırır")
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame

        var trc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
        var enc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
        _assert_true(trc != null and enc != null, "İki sütun konteyner mevcut")
        if trc != null and enc != null:
                # Tüm Türkçe kartlar Türkçe dilinde
                var all_tr: bool = true
                for c in trc.get_children():
                        if c.get("language") != "turkish":
                                all_tr = false
                                break
                _assert_true(all_tr, "Türkçe sütundaki tüm kartlar 'turkish' dilinde")
                # Tüm İngilizce kartlar İngilizce dilinde
                var all_en: bool = true
                for c in enc.get_children():
                        if c.get("language") != "english":
                                all_en = false
                                break
                _assert_true(all_en, "İngilizce sütundaki tüm kartlar 'english' dilinde")
                # Toplam kart sayısı EASY'de 12
                _assert_eq(trc.get_child_count() + enc.get_child_count(), 12, "Toplam 12 kart (EASY)")

        inst.queue_free()
        await get_tree().process_frame


# --- DifficultyManager regresyon ---
func _test_difficulty_manager_regression() -> void:
        _begin_test("DifficultyManager regresyon (EASY/MEDIUM/HARD)")
        var DM = DifficultyManager
        _assert_eq(DM.get_pair_count(DM.Difficulty.EASY), 6, "EASY 6 çift")
        _assert_eq(DM.get_pair_count(DM.Difficulty.MEDIUM), 8, "MEDIUM 8 çift")
        _assert_eq(DM.get_pair_count(DM.Difficulty.HARD), 10, "HARD 10 çift")
        _assert_eq(DM.get_hint_count(DM.Difficulty.EASY), 3, "EASY 3 ipucu")
        _assert_eq(DM.get_hint_count(DM.Difficulty.MEDIUM), 2, "MEDIUM 2 ipucu")
        _assert_eq(DM.get_hint_count(DM.Difficulty.HARD), 1, "HARD 1 ipucu")
        _assert_eq(DM.get_hint_penalty(DM.Difficulty.EASY), 50, "EASY -50 penalty")
        _assert_eq(DM.get_hint_penalty(DM.Difficulty.MEDIUM), 75, "MEDIUM -75 penalty")
        _assert_eq(DM.get_hint_penalty(DM.Difficulty.HARD), 100, "HARD -100 penalty")
        _assert_eq(DM.get_difficulty_label(DM.Difficulty.EASY), "KOLAY", "EASY label KOLAY")
        _assert_eq(DM.get_difficulty_label(DM.Difficulty.MEDIUM), "ORTA", "MEDIUM label ORTA")
        _assert_eq(DM.get_difficulty_label(DM.Difficulty.HARD), "ZOR", "HARD label ZOR")
        _assert_eq(DM.get_difficulty_level(DM.Difficulty.EASY), 1, "EASY level 1")
        _assert_eq(DM.get_difficulty_level(DM.Difficulty.MEDIUM), 2, "MEDIUM level 2")
        _assert_eq(DM.get_difficulty_level(DM.Difficulty.HARD), 3, "HARD level 3")


# --- SaveManager regresyon ---
func _test_save_manager_regression() -> void:
        _begin_test("SaveManager regresyon (EASY/MEDIUM/HARD)")
        SaveManager.clear_all()
        # EASY kayıt
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.EASY, 500, 60.0, 0, 6), "EASY ilk rekor")
        SaveManager.save_best_record(DifficultyManager.Difficulty.EASY, 500, 60.0, 0, 6)
        # Daha düşük skor yeni rekor değil
        _assert_false(SaveManager.is_new_record(DifficultyManager.Difficulty.EASY, 400, 60.0, 0, 6), "EASY daha düşük rekor değil")
        # Daha yüksek skor yeni rekor
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.EASY, 600, 60.0, 0, 6), "EASY daha yüksek yeni rekor")
        # Tie-breaker: süre kısa olan kazanır
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.EASY, 600, 50.0, 0, 6), "EASY aynı skor daha kısa süre yeni rekor")
        # MEDIUM bağımsız
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.MEDIUM, 500, 60.0, 0, 8), "MEDIUM bağımsız ilk rekor")
        SaveManager.save_best_record(DifficultyManager.Difficulty.MEDIUM, 500, 60.0, 0, 8)
        # HARD bağımsız
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.HARD, 500, 60.0, 0, 10), "HARD bağımsız ilk rekor")
        # EXPERT bağımsız
        _assert_true(SaveManager.is_new_record(DifficultyManager.Difficulty.EXPERT, 500, 60.0, 0, 15), "EXPERT bağımsız ilk rekor")
        SaveManager.clear_all()


# --- Difficulty labels (pretty) ---
func _test_difficulty_labels() -> void:
        _begin_test("Difficulty labels (pretty + raw)")
        var DM = DifficultyManager
        _assert_eq(DM.get_difficulty_label_pretty(DM.Difficulty.EASY), "Kolay", "pretty EASY = Kolay")
        _assert_eq(DM.get_difficulty_label_pretty(DM.Difficulty.MEDIUM), "Orta", "pretty MEDIUM = Orta")
        _assert_eq(DM.get_difficulty_label_pretty(DM.Difficulty.HARD), "Zor", "pretty HARD = Zor")
        _assert_eq(DM.get_difficulty_label_pretty(DM.Difficulty.EXPERT), "Uzman", "pretty EXPERT = Uzman")


# --- GameModeManager autoload mevcut (Task 13) ---
func _test_game_mode_manager_autoload() -> void:
        _begin_test("GameModeManager autoload mevcut")
        _assert_true(GameModeManager != null, "GameModeManager singleton yuklu")
        if GameModeManager != null:
                # Enum degerleri
                _assert_eq(GameModeManager.GameMode.CLASSIC, 0, "GameMode.CLASSIC = 0")
                _assert_eq(GameModeManager.GameMode.TR_TO_EN, 1, "GameMode.TR_TO_EN = 1")
                _assert_eq(GameModeManager.GameMode.EN_TO_TR, 2, "GameMode.EN_TO_TR = 2")
                _assert_eq(GameModeManager.GameMode.AUDIO, 3, "GameMode.AUDIO = 3")
                # Tum modlar listesi 4 elemanli
                _assert_eq(GameModeManager.get_all_modes().size(), 4, "get_all_modes 4 mod")


# --- GameModeManager default + get_first_card_language (Task 13) ---
func _test_game_mode_manager_default_and_language() -> void:
        _begin_test("GameModeManager default mode + get_first_card_language")
        if GameModeManager == null:
                _assert_true(false, "GameModeManager yuklu olmali")
                return
        # Test basi: CLASSIC'a sifirla (singleton state kalinti olabilir)
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.CLASSIC, "default current_mode = CLASSIC")
        # get_first_card_language (mevcut mode'a gore)
        _assert_eq(GameModeManager.get_first_card_language(), "", "CLASSIC get_first_card_language = ''")
        # get_first_card_language_for (parametreyle)
        _assert_eq(GameModeManager.get_first_card_language_for(GameModeManager.GameMode.CLASSIC), "", "CLASSIC (for) = ''")
        _assert_eq(GameModeManager.get_first_card_language_for(GameModeManager.GameMode.TR_TO_EN), "turkish", "TR_TO_EN (for) = 'turkish'")
        _assert_eq(GameModeManager.get_first_card_language_for(GameModeManager.GameMode.EN_TO_TR), "english", "EN_TO_TR (for) = 'english'")
        _assert_eq(GameModeManager.get_first_card_language_for(GameModeManager.GameMode.AUDIO), "english", "AUDIO (for) = 'english'")


# --- GameModeManager set_mode (Task 13) ---
func _test_game_mode_manager_set_mode() -> void:
        _begin_test("GameModeManager.set_mode")
        if GameModeManager == null:
                _assert_true(false, "GameModeManager yuklu olmali")
                return
        # Sifirla
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC
        # set_mode + current_mode dogrula
        GameModeManager.set_mode(GameModeManager.GameMode.TR_TO_EN)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.TR_TO_EN, "set_mode(TR_TO_EN) -> current_mode = TR_TO_EN")
        _assert_eq(GameModeManager.get_first_card_language(), "turkish", "TR_TO_EN aktifken get_first_card_language = 'turkish'")
        GameModeManager.set_mode(GameModeManager.GameMode.EN_TO_TR)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.EN_TO_TR, "set_mode(EN_TO_TR) -> current_mode = EN_TO_TR")
        _assert_eq(GameModeManager.get_first_card_language(), "english", "EN_TO_TR aktifken get_first_card_language = 'english'")
        GameModeManager.set_mode(GameModeManager.GameMode.AUDIO)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.AUDIO, "set_mode(AUDIO) -> current_mode = AUDIO")
        _assert_eq(GameModeManager.get_first_card_language(), "english", "AUDIO aktifken get_first_card_language = 'english'")
        _assert_true(GameModeManager.is_audio_mode(), "AUDIO aktifken is_audio_mode() = true")
        GameModeManager.set_mode(GameModeManager.GameMode.CLASSIC)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.CLASSIC, "set_mode(CLASSIC) -> current_mode = CLASSIC")
        _assert_eq(GameModeManager.get_first_card_language(), "", "CLASSIC aktifken get_first_card_language = ''")
        _assert_false(GameModeManager.is_audio_mode(), "CLASSIC aktifken is_audio_mode() = false")
        # Gecersiz deger no-op
        GameModeManager.set_mode(-1)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.CLASSIC, "set_mode(-1) gecersiz -> current_mode degismez")
        GameModeManager.set_mode(99)
        _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.CLASSIC, "set_mode(99) gecersiz -> current_mode degismez")


# --- GameModeManager etiketler + emojiler (Task 13) ---
func _test_game_mode_manager_labels_emojis() -> void:
        _begin_test("GameModeManager labels + emojis")
        if GameModeManager == null:
                _assert_true(false, "GameModeManager yuklu olmali")
                return
        _assert_eq(GameModeManager.get_mode_label(GameModeManager.GameMode.CLASSIC), "Klasik", "label CLASSIC = Klasik")
        _assert_eq(GameModeManager.get_mode_label(GameModeManager.GameMode.TR_TO_EN), "Türkçe → İngilizce", "label TR_TO_EN = 'Türkçe → İngilizce'")
        _assert_eq(GameModeManager.get_mode_label(GameModeManager.GameMode.EN_TO_TR), "İngilizce → Türkçe", "label EN_TO_TR = 'İngilizce → Türkçe'")
        _assert_eq(GameModeManager.get_mode_label(GameModeManager.GameMode.AUDIO), "Sesli Mod", "label AUDIO = Sesli Mod")
        _assert_eq(GameModeManager.get_mode_emoji(GameModeManager.GameMode.CLASSIC), "🎲", "emoji CLASSIC = 🎲")
        _assert_eq(GameModeManager.get_mode_emoji(GameModeManager.GameMode.TR_TO_EN), "🇹🇷", "emoji TR_TO_EN = 🇹🇷")
        _assert_eq(GameModeManager.get_mode_emoji(GameModeManager.GameMode.EN_TO_TR), "🇬🇧", "emoji EN_TO_TR = 🇬🇧")
        _assert_eq(GameModeManager.get_mode_emoji(GameModeManager.GameMode.AUDIO), "🔊", "emoji AUDIO = 🔊")
        # Buton metni "emoji + label"
        _assert_eq(GameModeManager.get_mode_button_text(GameModeManager.GameMode.CLASSIC), "🎲 Klasik", "button_text CLASSIC")
        # Mevcut mod etiketleri
        GameModeManager.current_mode = GameModeManager.GameMode.AUDIO
        _assert_eq(GameModeManager.get_current_mode_label(), "Sesli Mod", "current label AUDIO = Sesli Mod")
        _assert_eq(GameModeManager.get_current_mode_emoji(), "🔊", "current emoji AUDIO = 🔊")
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC


# --- GameModeManager.mode_changed sinyali (Task 13) ---
func _test_game_mode_manager_signal() -> void:
        _begin_test("GameModeManager.mode_changed sinyali")
        if GameModeManager == null:
                _assert_true(false, "GameModeManager yuklu olmali")
                return
        # Sifirla
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC
        # Sinyalin varligini kontrol et
        var sig_list: Array = GameModeManager.get_signal_list()
        var found: bool = false
        for s in sig_list:
                if s["name"] == "mode_changed":
                        found = true
                        break
        _assert_true(found, "GameModeManager.mode_changed sinyali mevcut")
        # Sinyalin gercekten yayilip yayilmadigini test et (member method kullan)
        _test_mode_changed_received = false
        _test_mode_changed_mode = -1
        if not GameModeManager.mode_changed.is_connected(_on_test_mode_changed):
                GameModeManager.mode_changed.connect(_on_test_mode_changed)
        GameModeManager.set_mode(GameModeManager.GameMode.TR_TO_EN)
        _assert_true(_test_mode_changed_received, "set_mode(TR_TO_EN) -> mode_changed yayildi")
        _assert_eq(_test_mode_changed_mode, GameModeManager.GameMode.TR_TO_EN, "alinan mode = TR_TO_EN")
        # Ayni mode -> sinyal tekrar yayilmaz
        _test_mode_changed_received = false
        GameModeManager.set_mode(GameModeManager.GameMode.TR_TO_EN)
        _assert_false(_test_mode_changed_received, "ayni mode -> sinyal yayilmadi (no-op)")
        # Geri al, sifirla
        if GameModeManager.mode_changed.is_connected(_on_test_mode_changed):
                GameModeManager.mode_changed.disconnect(_on_test_mode_changed)
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC


# --- GameManager.wrong_side sinyali (Task 13) ---
func _test_game_manager_wrong_side_signal() -> void:
        _begin_test("GameManager.wrong_side sinyali")
        var sig_list: Array = GameManager.get_signal_list()
        var found: bool = false
        for s in sig_list:
                if s["name"] == "wrong_side":
                        found = true
                        break
        _assert_true(found, "GameManager.wrong_side sinyali mevcut")


# --- Main.tscn GameModeBar + WrongSideMessage (Task 13) ---
func _test_main_scene_game_mode_bar() -> void:
        _begin_test("Main.tscn GameModeBar + WrongSideMessage")
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame

        # GameModeBar mevcut
        var bar: HBoxContainer = inst.get_node_or_null("RootVBox/GameModeBar")
        _assert_true(bar != null, "GameModeBar mevcut")

        # GameModeFlow mevcut (sadeleştirilmiş 2 buton: Klasik + Sesli)
        var flow: HFlowContainer = inst.get_node_or_null("RootVBox/GameModeBar/GameModeFlow")
        _assert_true(flow != null, "GameModeFlow mevcut")
        if flow != null:
                _assert_eq(flow.get_child_count(), 2, "GameModeFlow'ta 2 mod butonu")
                _assert_true(flow.get_node_or_null("Mode_0") != null, "Klasik mod butonu mevcut")
                _assert_true(flow.get_node_or_null("Mode_3") != null, "Sesli mod butonu mevcut")
                _assert_true(flow.get_node_or_null("Mode_1") == null, "TR→EN butonu arayüzden kaldırıldı")
                _assert_true(flow.get_node_or_null("Mode_2") == null, "EN→TR butonu arayüzden kaldırıldı")

        # WrongSideMessage label mevcut
        var msg: Label = inst.get_node_or_null("RootVBox/WrongSideMessage")
        _assert_true(msg != null, "WrongSideMessage label mevcut")
        if msg != null:
                _assert_false(msg.visible, "WrongSideMessage baslangicta gizli")
                _assert_eq(msg.text, "", "WrongSideMessage baslangicta bos")

        inst.queue_free()
        await get_tree().process_frame


# --- Main.gd wrong_side davranisi (Task 13) ---
func _test_main_wrong_side_behavior() -> void:
        _begin_test("Main.gd wrong_side davranisi (TR_TO_EN)")
        if GameModeManager == null:
                _assert_true(false, "GameModeManager yuklu olmali")
                return

        # Test oncesi sifirla
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC

        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame

        var trc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
        var enc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
        _assert_true(trc != null and enc != null, "Sutunlar mevcut")

        if trc != null and enc != null and trc.get_child_count() > 0 and enc.get_child_count() > 0:
                # TR_TO_EN moduna gec -> mode_changed sinyali Main._on_mode_changed'i cagirir,
                # _new_game() kartlari yeniden olusturur. Bir frame bekle.
                GameModeManager.set_mode(GameModeManager.GameMode.TR_TO_EN)
                await get_tree().process_frame
                _assert_eq(GameModeManager.current_mode, GameModeManager.GameMode.TR_TO_EN, "current_mode TR_TO_EN")

                # Yeni kartlari al (yeniden karistirildi)
                var tr_card = trc.get_child(0)
                var en_card = enc.get_child(0)
                _assert_true(tr_card != null and en_card != null, "Yeni kartlar olustu")

                if tr_card != null and en_card != null:
                        # wrong_side sinyali sayaci (member degisken, lambda capture onerme)
                        _test_ws_count = 0
                        if not GameManager.wrong_side.is_connected(_on_test_wrong_side):
                                GameManager.wrong_side.connect(_on_test_wrong_side)

                        # 1) Ingilizce karti tikla -> yanlis sutun, açilmamali, wrong_side yayilmali
                        inst._on_card_clicked(en_card)
                        await get_tree().process_frame
                        _assert_eq(_test_ws_count, 1, "EN kart -> wrong_side sinyali 1 kez")
                        _assert_false(en_card.is_open, "EN kart TR_TO_EN modunda ACILMADI")

                        # 2) Turkce karti tikla -> dogru sutun, acilmali.
                        # flip_open animasyonu 0.12s + 0.12s; is_open=true 0.12s'de set edilir.
                        inst._on_card_clicked(tr_card)
                        await get_tree().create_timer(0.20).timeout
                        _assert_eq(_test_ws_count, 1, "TR kart -> wrong_side sinyali YAYILMADI (count hala 1)")
                        # (Kart acildi mi? flip_open tween yarida is_open=true yapar)
                        _assert_true(tr_card.is_open, "TR kart TR_TO_EN modunda ACILDI")

                        # 3) Ayni pair_id'li EN karti bul ve tikla -> eslesme
                        var tr_pid: int = tr_card.pair_id
                        var matched_en = null
                        for c in enc.get_children():
                                if c.pair_id == tr_pid and not c.is_matched:
                                        matched_en = c
                                        break
                        if matched_en != null:
                                inst._on_card_clicked(matched_en)
                                await get_tree().process_frame
                                _assert_true(matched_en.is_matched, "Esen EN kart eslesti (is_matched=true)")
                                _assert_true(tr_card.is_matched, "TR kart eslesti (is_matched=true)")

                        # Cleanup
                        if GameManager.wrong_side.is_connected(_on_test_wrong_side):
                                GameManager.wrong_side.disconnect(_on_test_wrong_side)
                        _test_ws_count = 0

        # Test sonrasi: CLASSIC'a geri don (singleton state)
        GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC

        inst.queue_free()
        await get_tree().process_frame


# --- Task 16: GameManager.set_categories yeni kategori kabul testi (Task 18 güncellendi) ---
func _test_game_manager_new_categories() -> void:
        _begin_test("GameManager.set_categories yeni kategori (Task 16 + Task 18)")
        # 4 yeni kategori tek tek set edilebilir (Task 18 sonrası her biri 15 çift)
        var prev_cats: Array = GameManager.selected_categories.duplicate()
        GameManager.set_categories(["professions"])
        _assert_eq(GameManager.selected_categories.size(), 1, "professions set edildi (1 kategori)")
        if GameManager.selected_categories.size() == 1:
                _assert_eq(GameManager.selected_categories[0], "professions", "selected[0] = professions")
        # Havuz sayisi (Task 18: professions 15 çift)
        _assert_eq(GameManager.get_pool_pair_count(), 15, "professions havuz 15 (Task 18)")
        _assert_true(GameManager.has_enough_pairs_for_difficulty() == (15 >= GameManager.total_pairs), "has_enough_pairs_for_difficulty (professions, Task 18: 15)")

        # 4 yeni kategori hepsini birden set et (Task 18 sonrası 4 × 15 = 60)
        GameManager.set_categories(["professions", "emotions", "weather", "transport"])
        _assert_eq(GameManager.selected_categories.size(), 4, "4 yeni kategori set edildi")
        _assert_eq(GameManager.get_pool_pair_count(), 60, "4 yeni kategori havuz 60 (Task 18)")

        # Yeni kategori + mevcut kategori karisik (Task 18: 15 + 15 = 30)
        GameManager.set_categories(["animals", "professions"])
        _assert_eq(GameManager.selected_categories.size(), 2, "animals + professions karisik")
        _assert_eq(GameManager.get_pool_pair_count(), 30, "animals + professions havuz 30 (Task 18)")

        # clear_categories -> Karisik mod (Task 18: 210 çift)
        GameManager.clear_categories()
        _assert_eq(GameManager.selected_categories.size(), 0, "clear_categories sonrasi 0")
        _assert_eq(GameManager.get_pool_pair_count(), 210, "Karisik mod havuz 210 (Task 18)")

        # Bilinmeyen kategori sessizce süzülür
        GameManager.set_categories(["professions", "bilinmeyen_x", "emotions"])
        _assert_eq(GameManager.selected_categories.size(), 2, "bilinmeyen kategori süzüldü (2 kaldi)")

        # Cleanup: onceki duruma geri don
        GameManager.set_categories(prev_cats)

# --- Task 22 + Task 24: WordExamples autoload + 210 örnek ---
func _test_word_examples_autoload() -> void:
        _begin_test("WordExamples autoload + 210 örnek (Task 22 + Task 24)")
        _assert_true(WordExamples != null, "WordExamples singleton yüklü")
        if WordExamples == null:
                return
        # Task 24: 90 → 210 elle yazılmış örnek
        _assert_eq(WordExamples.EXAMPLES.size(), 210, "EXAMPLES size = 210 (Task 24)")
        _assert_eq(WordExamples.get_example_count(), 210, "get_example_count = 210 (Task 24)")
        # has_example: 1-210 true, 0/211/-1 false
        _assert_true(WordExamples.has_example(1), "has_example(1) = true")
        _assert_true(WordExamples.has_example(45), "has_example(45) = true")
        _assert_true(WordExamples.has_example(90), "has_example(90) = true")
        _assert_true(WordExamples.has_example(91), "has_example(91) = true (Task 24)")
        _assert_true(WordExamples.has_example(127), "has_example(127) = true (Task 24)")
        _assert_true(WordExamples.has_example(210), "has_example(210) = true (Task 24)")
        _assert_false(WordExamples.has_example(0), "has_example(0) = false")
        _assert_false(WordExamples.has_example(211), "has_example(211) = false (Task 24, havuz dışı)")
        _assert_false(WordExamples.has_example(-1), "has_example(-1) = false")
        # get_example(1): yapı kontrolü
        var ex1: Dictionary = WordExamples.get_example(1)
        _assert_true(ex1.has("tr_sentence"), "get_example(1) has tr_sentence")
        _assert_true(ex1.has("en_sentence"), "get_example(1) has en_sentence")
        _assert_true(ex1.has("pronunciation"), "get_example(1) has pronunciation")
        _assert_true(String(ex1.get("tr_sentence", "")).length() > 0, "get_example(1) tr_sentence boş değil")
        _assert_true(String(ex1.get("en_sentence", "")).length() > 0, "get_example(1) en_sentence boş değil")
        _assert_true(String(ex1.get("pronunciation", "")).length() > 0, "get_example(1) pronunciation boş değil")
        # İçerik kontrolü: pair_id 1 = KÖPEK/DOG
        _assert_true(String(ex1.get("tr_sentence", "")).find("Köpek") >= 0 or String(ex1.get("tr_sentence", "")).find("köpek") >= 0, "get_example(1) tr_sentence 'Köpek' içeriyor")
        _assert_true(String(ex1.get("en_sentence", "")).find("dog") >= 0 or String(ex1.get("en_sentence", "")).find("Dog") >= 0, "get_example(1) en_sentence 'dog' içeriyor")
        _assert_true(String(ex1.get("pronunciation", "")).find("dog") >= 0 or String(ex1.get("pronunciation", "")).find("dɒɡ") >= 0, "get_example(1) pronunciation 'dog' içeriyor")
        # get_example(90): pair_id 90 = AMCA/UNCLE
        var ex90: Dictionary = WordExamples.get_example(90)
        _assert_true(String(ex90.get("tr_sentence", "")).find("Amca") >= 0 or String(ex90.get("tr_sentence", "")).find("amca") >= 0, "get_example(90) tr_sentence 'Amca' içeriyor")
        _assert_true(String(ex90.get("en_sentence", "")).find("Uncle") >= 0 or String(ex90.get("en_sentence", "")).find("uncle") >= 0, "get_example(90) en_sentence 'Uncle' içeriyor")
        # Task 24: get_example(91) = DOKTOR/DOCTOR (artık elle yazılmış, fallback DEĞİL)
        var ex91: Dictionary = WordExamples.get_example(91)
        _assert_true(String(ex91.get("tr_sentence", "")).find("Doktor") >= 0 or String(ex91.get("tr_sentence", "")).find("doktor") >= 0, "get_example(91) tr_sentence 'Doktor' içeriyor (Task 24)")
        _assert_true(String(ex91.get("en_sentence", "")).find("doctor") >= 0 or String(ex91.get("en_sentence", "")).find("Doctor") >= 0, "get_example(91) en_sentence 'doctor' içeriyor (Task 24)")
        _assert_true(String(ex91.get("pronunciation", "")).find("doctor") >= 0 or String(ex91.get("pronunciation", "")).find("dɒktər") >= 0, "get_example(91) pronunciation 'doctor' içeriyor (Task 24)")
        # Task 24: get_example(100) = MUTLU/HAPPY (emotions kategorisi, yeni)
        var ex100: Dictionary = WordExamples.get_example(100)
        _assert_true(String(ex100.get("tr_sentence", "")).find("Mutlu") >= 0 or String(ex100.get("tr_sentence", "")).find("mutlu") >= 0, "get_example(100) tr_sentence 'Mutlu' içeriyor (Task 24)")
        _assert_true(String(ex100.get("en_sentence", "")).find("happy") >= 0 or String(ex100.get("en_sentence", "")).find("Happy") >= 0, "get_example(100) en_sentence 'happy' içeriyor (Task 24)")
        # Task 24: get_example(127) = ASLAN/LION (artık elle yazılmış)
        var ex127: Dictionary = WordExamples.get_example(127)
        _assert_true(String(ex127.get("tr_sentence", "")).find("Aslan") >= 0 or String(ex127.get("tr_sentence", "")).find("aslan") >= 0, "get_example(127) tr_sentence 'Aslan' içeriyor (Task 24)")
        _assert_true(String(ex127.get("en_sentence", "")).find("lion") >= 0 or String(ex127.get("en_sentence", "")).find("Lion") >= 0, "get_example(127) en_sentence 'lion' içeriyor (Task 24)")
        _assert_true(String(ex127.get("pronunciation", "")).find("laɪən") >= 0 or String(ex127.get("pronunciation", "")).find("lion") >= 0, "get_example(127) pronunciation 'lion' içeriyor (Task 24)")
        # Task 24: get_example(202) = KIŞ/WINTER (weather kategorisi ek çift)
        var ex202: Dictionary = WordExamples.get_example(202)
        _assert_true(String(ex202.get("tr_sentence", "")).find("Kış") >= 0 or String(ex202.get("tr_sentence", "")).find("kış") >= 0, "get_example(202) tr_sentence 'Kış' içeriyor (Task 24)")
        _assert_true(String(ex202.get("en_sentence", "")).find("winter") >= 0 or String(ex202.get("en_sentence", "")).find("Winter") >= 0, "get_example(202) en_sentence 'winter' içeriyor (Task 24)")
        _assert_true(String(ex202.get("pronunciation", "")).find("wɪntər") >= 0 or String(ex202.get("pronunciation", "")).find("winter") >= 0, "get_example(202) pronunciation 'winter' içeriyor (Task 24)")
        # Task 24: get_example(210) = SKUTER/SCOOTER (son çift, artık elle yazılmış)
        var ex210: Dictionary = WordExamples.get_example(210)
        _assert_true(String(ex210.get("tr_sentence", "")).find("Skuter") >= 0 or String(ex210.get("tr_sentence", "")).find("skuter") >= 0, "get_example(210) tr_sentence 'Skuter' içeriyor (Task 24)")
        _assert_true(String(ex210.get("en_sentence", "")).find("scooter") >= 0 or String(ex210.get("en_sentence", "")).find("Scooter") >= 0, "get_example(210) en_sentence 'scooter' içeriyor (Task 24)")
        _assert_true(String(ex210.get("pronunciation", "")).find("skuːtər") >= 0 or String(ex210.get("pronunciation", "")).find("scooter") >= 0, "get_example(210) pronunciation 'scooter' içeriyor (Task 24)")
        # Task 24: 1-210 arasındaki tüm örnekler dolu (was 1-90)
        var empty_count: int = 0
        for pid in range(1, 211):
                var ex: Dictionary = WordExamples.get_example(pid)
                if String(ex.get("tr_sentence", "")).length() == 0:
                        empty_count += 1
                if String(ex.get("en_sentence", "")).length() == 0:
                        empty_count += 1
                if String(ex.get("pronunciation", "")).length() == 0:
                        empty_count += 1
        _assert_eq(empty_count, 0, "1-210 arası tüm örneklerde tüm alanlar dolu (Task 24)")


# --- Task 24: WordExamples fallback (pair_id > 210 ve geçersiz) ---
func _test_word_examples_fallback() -> void:
        _begin_test("WordExamples fallback (Task 24, pair_id > 210 ve geçersiz)")
        if WordExamples == null:
                _assert_true(false, "WordExamples yüklü olmalı")
                return
        # Task 24: pair_id 91/127/210 artık elle yazılmış örnek (fallback DEĞİL)
        # WordData 210 çift → pair_id > 210 WordData'da yok → boş string döner
        # (fallback fonksiyonu _generate_fallback, WordData'da var ama EXAMPLES'ta
        # yoksa çağrılır; şu an 1-210 tamamen dolu olduğu için fallback yolu hiç
        # çalışmaz, ama defensive kod olarak korunur).
        # pair_id 211 (WordData havuz dışı)
        var ex211: Dictionary = WordExamples.get_example(211)
        _assert_eq(String(ex211.get("tr_sentence", "X")), "", "get_example(211) tr_sentence boş (Task 24, havuz dışı)")
        _assert_eq(String(ex211.get("en_sentence", "X")), "", "get_example(211) en_sentence boş (Task 24, havuz dışı)")
        _assert_eq(String(ex211.get("pronunciation", "X")), "", "get_example(211) pronunciation boş (Task 24, havuz dışı)")
        # pair_id 9999 (WordData havuz dışı)
        var ex9999: Dictionary = WordExamples.get_example(9999)
        _assert_eq(String(ex9999.get("tr_sentence", "X")), "", "get_example(9999) tr_sentence boş (havuz dışı)")
        _assert_eq(String(ex9999.get("en_sentence", "X")), "", "get_example(9999) en_sentence boş (havuz dışı)")
        _assert_eq(String(ex9999.get("pronunciation", "X")), "", "get_example(9999) pronunciation boş (havuz dışı)")
        # Geçersiz pair_id'ler boş string döner (crash yok)
        var ex0: Dictionary = WordExamples.get_example(0)
        _assert_eq(String(ex0.get("tr_sentence", "X")), "", "get_example(0) tr_sentence boş (geçersiz pair_id)")
        _assert_eq(String(ex0.get("en_sentence", "X")), "", "get_example(0) en_sentence boş (geçersiz pair_id)")
        var exneg: Dictionary = WordExamples.get_example(-5)
        _assert_eq(String(exneg.get("tr_sentence", "X")), "", "get_example(-5) tr_sentence boş (negatif pair_id)")
        _assert_eq(String(exneg.get("pronunciation", "X")), "", "get_example(-5) pronunciation boş (negatif pair_id)")


# --- Task 22: Card.matched_card_clicked sinyali ---
func _test_card_matched_card_clicked_signal() -> void:
        _begin_test("Card.matched_card_clicked sinyali (Task 22)")
        # Card.gd script'ini yükle, sinyal listesinde matched_card_clicked var mı
        var card_script: GDScript = load("res://scripts/Card.gd") as GDScript
        _assert_true(card_script != null, "Card.gd script yüklendi")
        if card_script == null:
                return
        var sig_list: Array = card_script.get_script_signal_list()
        var found_mcc: bool = false
        var found_cc: bool = false
        for s in sig_list:
                if s["name"] == "matched_card_clicked":
                        found_mcc = true
                if s["name"] == "card_clicked":
                        found_cc = true
        _assert_true(found_mcc, "Card.matched_card_clicked sinyali mevcut")
        _assert_true(found_cc, "Card.card_clicked sinyali hala mevcut (regresyon yok)")
        # Card instance oluştur, set_matched sonrası disabled=false olmalı
        var card_scene: PackedScene = load("res://scenes/Card.tscn")
        var card = card_scene.instantiate()
        get_tree().root.add_child(card)
        await get_tree().process_frame
        card.setup("KÖPEK", "turkish", 1)
        _assert_false(card.is_matched, "Kart başlangıçta matched değil")
        _assert_false(card.disabled, "Kart başlangıçta disabled değil")
        # set_matched çağır
        card.set_matched()
        await get_tree().process_frame
        _assert_true(card.is_matched, "set_matched sonrası is_matched = true")
        # Task 22: matched kart disabled=false (kelime kartı için tıklanabilir)
        _assert_false(card.disabled, "set_matched sonrası disabled = false (Task 22)")
        # matched_card_clicked sinyalini dinle (member değişken, lambda capture güvenli değil)
        _test_card_mcc_count = 0
        _test_card_mcc_pair_id = -1
        if not card.matched_card_clicked.is_connected(_on_test_card_matched_card_clicked):
                card.matched_card_clicked.connect(_on_test_card_matched_card_clicked)
        # _on_pressed'i doğrudan çağır (GUI input olmadan)
        card._on_pressed()
        await get_tree().process_frame
        _assert_true(_test_card_mcc_count >= 1, "matched kart _on_pressed -> matched_card_clicked sinyali yayıldı")
        _assert_eq(_test_card_mcc_pair_id, 1, "matched_card_clicked pair_id = 1")
        # Cleanup
        if card.matched_card_clicked.is_connected(_on_test_card_matched_card_clicked):
                card.matched_card_clicked.disconnect(_on_test_card_matched_card_clicked)
        card.queue_free()
        await get_tree().process_frame


# --- Task 22: GameManager.matched_card_clicked sinyali ---
func _test_game_manager_matched_card_clicked_signal() -> void:
        _begin_test("GameManager.matched_card_clicked sinyali (Task 22)")
        var sig_list: Array = GameManager.get_signal_list()
        var found: bool = false
        for s in sig_list:
                if s["name"] == "matched_card_clicked":
                        found = true
                        break
        _assert_true(found, "GameManager.matched_card_clicked sinyali mevcut")


# --- Task 22: WordCardPanel scene + show_pair ---
func _test_word_card_panel_scene() -> void:
        _begin_test("WordCardPanel scene + show_pair (Task 22)")
        var packed: PackedScene = load("res://scenes/WordCardPanel.tscn")
        _assert_true(packed != null, "WordCardPanel.tscn yüklendi")
        if packed == null:
                return
        var panel = packed.instantiate()
        get_tree().root.add_child(panel)
        await get_tree().process_frame
        # Başlangıçta gizli
        _assert_false(panel.visible, "WordCardPanel başlangıçta gizli")
        # show_pair çağır
        panel.show_pair(1, "KÖPEK", "DOG", "animals")
        await get_tree().process_frame
        _assert_true(panel.visible, "show_pair sonrası panel görünür")
        _assert_true(panel.is_panel_visible(), "is_panel_visible() = true")
        # İçerik kontrolü
        var title_lbl: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/TitleLabel")
        _assert_true(title_lbl != null, "TitleLabel mevcut")
        if title_lbl != null:
                _assert_true(title_lbl.text.find("Kelime Detayı") >= 0, "TitleLabel 'Kelime Detayı' içeriyor")
        var tr_lbl: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/TurkishLabel")
        _assert_true(tr_lbl != null, "TurkishLabel mevcut")
        if tr_lbl != null:
                _assert_eq(tr_lbl.text, "KÖPEK", "TurkishLabel 'KÖPEK'")
        var en_lbl: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/EnglishLabel")
        _assert_true(en_lbl != null, "EnglishLabel mevcut")
        if en_lbl != null:
                _assert_eq(en_lbl.text, "DOG", "EnglishLabel 'DOG'")
        var pron_lbl: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/PronunciationLabel")
        _assert_true(pron_lbl != null, "PronunciationLabel mevcut")
        if pron_lbl != null:
                _assert_true(pron_lbl.text.length() > 0, "PronunciationLabel dolu (WordExamples'tan)")
                _assert_true(pron_lbl.text.find("dog") >= 0 or pron_lbl.text.find("dɒɡ") >= 0, "PronunciationLabel 'dog' içeriyor")
        var cat_lbl: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/CategoryLabel")
        _assert_true(cat_lbl != null, "CategoryLabel mevcut")
        if cat_lbl != null:
                # Kategori emoji + label (animals -> 🐶 Hayvanlar)
                _assert_true(cat_lbl.text.find("Hayvanlar") >= 0, "CategoryLabel 'Hayvanlar' içeriyor (animals kategorisi)")
        var tr_sent: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/TRSentenceLabel")
        _assert_true(tr_sent != null, "TRSentenceLabel mevcut")
        if tr_sent != null:
                _assert_true(tr_sent.text.length() > 0, "TRSentenceLabel dolu")
                _assert_true(tr_sent.text.find("Köpek") >= 0 or tr_sent.text.find("köpek") >= 0, "TRSentenceLabel 'Köpek' içeriyor (WordExamples'tan)")
        var en_sent: Label = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/ENSentenceLabel")
        _assert_true(en_sent != null, "ENSentenceLabel mevcut")
        if en_sent != null:
                _assert_true(en_sent.text.length() > 0, "ENSentenceLabel dolu")
        # Butonlar mevcut
        var listen_tr: Button = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/ButtonRow/ListenTRButton")
        _assert_true(listen_tr != null, "ListenTRButton mevcut")
        var listen_en: Button = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/ButtonRow/ListenENButton")
        _assert_true(listen_en != null, "ListenENButton mevcut")
        var close_btn: Button = panel.get_node_or_null("CenterContainer/DialogPanel/VBox/ButtonRow/CloseButton")
        _assert_true(close_btn != null, "CloseButton mevcut")
        # hide_panel
        panel.hide_panel()
        await get_tree().process_frame
        _assert_false(panel.visible, "hide_panel sonrası panel gizli")
        _assert_false(panel.is_panel_visible(), "is_panel_visible() = false")
        # Bilinmeyen kategori ile show_pair (crash olmamalı)
        panel.show_pair(9999, "BİLİNMEYEN", "UNKNOWN", "yok_kategori")
        await get_tree().process_frame
        _assert_true(panel.visible, "show_pair (geçersiz pair_id) sonrası panel yine de görünür (crash yok)")
        if tr_lbl != null:
                _assert_eq(tr_lbl.text, "BİLİNMEYEN", "TurkishLabel 'BİLİNMEYEN' (geçersiz pair_id)")
        panel.hide_panel()
        panel.queue_free()
        await get_tree().process_frame


# --- Task 22: Main.tscn içinde WordCardPanel node ---
func _test_main_word_card_panel_node() -> void:
        _begin_test("Main.tscn içinde WordCardPanel node (Task 22)")
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame
        # WordCardPanel node mevcut
        var wcp = inst.get_node_or_null("WordCardPanel")
        _assert_true(wcp != null, "Main.tscn içinde WordCardPanel node mevcut")
        if wcp != null:
                # Başlangıçta gizli
                _assert_false(wcp.visible, "WordCardPanel başlangıçta gizli")
                # show_pair metodu var
                _assert_true(wcp.has_method("show_pair"), "WordCardPanel.show_pair metodu mevcut")
                _assert_true(wcp.has_method("hide_panel"), "WordCardPanel.hide_panel metodu mevcut")
                _assert_true(wcp.has_method("is_panel_visible"), "WordCardPanel.is_panel_visible metodu mevcut")
        inst.queue_free()
        await get_tree().process_frame


# --- Task 22: Main matched kart tıklayınca word card açılır ---
func _test_main_matched_card_opens_word_card() -> void:
        _begin_test("Main matched kart tıklayınca word card açılır (Task 22)")
        # Test öncesi CLASSIC'e sıfırla
        if GameModeManager != null:
                GameModeManager.current_mode = GameModeManager.GameMode.CLASSIC
        var packed: PackedScene = load("res://scenes/Main.tscn")
        var inst = packed.instantiate()
        get_tree().root.add_child(inst)
        if inst.has_method("_initialize_first_game"):
                inst._initialize_first_game()
        await get_tree().process_frame

        var wcp = inst.get_node_or_null("WordCardPanel")
        _assert_true(wcp != null, "WordCardPanel mevcut")
        if wcp == null:
                inst.queue_free()
                await get_tree().process_frame
                return
        _assert_false(wcp.visible, "Oyun başında WordCardPanel gizli")

        # GameManager.matched_card_clicked sinyalini dinle
        _test_mcc_count = 0
        _test_mcc_pair_id = -1
        if not GameManager.matched_card_clicked.is_connected(_on_test_matched_card_clicked):
                GameManager.matched_card_clicked.connect(_on_test_matched_card_clicked)

        # Bir Türkçe + bir İngilizce kart eşleştir (pair_id'leri aynı olan)
        var trc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/TurkishColumn/TurkishCards")
        var enc: GridContainer = inst.get_node_or_null("RootVBox/GameArea/ColumnsHBox/EnglishColumn/EnglishCards")
        if trc != null and enc != null and trc.get_child_count() > 0 and enc.get_child_count() > 0:
                var tr_card = trc.get_child(0)
                var tr_pid: int = tr_card.pair_id
                # Aynı pair_id'li EN kartı bul
                var en_card = null
                for c in enc.get_children():
                        if c.pair_id == tr_pid and not c.is_matched:
                                en_card = c
                                break
                _assert_true(en_card != null, "Eşleştirilebilir TR+EN çifti bulundu")
                if en_card != null:
                        # 1) TR kart tıkla -> açılır
                        inst._on_card_clicked(tr_card)
                        await get_tree().create_timer(0.20).timeout
                        _assert_true(tr_card.is_open, "TR kart açıldı")
                        # 2) EN kart tıkla -> eşleşme
                        inst._on_card_clicked(en_card)
                        await get_tree().process_frame
                        _assert_true(tr_card.is_matched, "TR kart matched")
                        _assert_true(en_card.is_matched, "EN kart matched")
                        # WordCardPanel henüz görünmemeli (matched_card_clicked tıklamayla tetiklenir)
                        _assert_false(wcp.visible, "Eşleşme sonrası WordCardPanel hala gizli (tıklama bekleniyor)")
                        # 3) Matched TR kartı tıkla -> WordCardPanel açılmalı
                        # Card._on_pressed() doğrudan çağırılır (GUI input olmadan).
                        # Card, matched_card_clicked sinyalini yayar; Main dinleyip
                        # WordCardPanel.show_pair çağırır.
                        tr_card._on_pressed()
                        await get_tree().process_frame
                        _assert_true(wcp.visible, "Matched TR kart tıklayınca WordCardPanel açıldı")
                        _assert_true(_test_mcc_count >= 1, "GameManager.matched_card_clicked sinyali en az 1 kez yayıldı")
                        _assert_eq(_test_mcc_pair_id, tr_pid, "GameManager.matched_card_clicked pair_id = TR kart pair_id")
                        # İçerik kontrolü
                        var tr_lbl: Label = wcp.get_node_or_null("CenterContainer/DialogPanel/VBox/TurkishLabel")
                        _assert_true(tr_lbl != null, "WordCardPanel TurkishLabel mevcut")
                        if tr_lbl != null:
                                _assert_eq(tr_lbl.text, tr_card.word, "WordCardPanel TurkishLabel = TR kart word")
                        var en_lbl: Label = wcp.get_node_or_null("CenterContainer/DialogPanel/VBox/EnglishLabel")
                        _assert_true(en_lbl != null, "WordCardPanel EnglishLabel mevcut")
                        if en_lbl != null:
                                _assert_eq(en_lbl.text, en_card.word, "WordCardPanel EnglishLabel = EN kart word")
                        # 4) Kapat butonu ile kapat
                        var close_btn: Button = wcp.get_node_or_null("CenterContainer/DialogPanel/VBox/ButtonRow/CloseButton")
                        _assert_true(close_btn != null, "WordCardPanel CloseButton mevcut")
                        if close_btn != null:
                                close_btn.pressed.emit()
                                await get_tree().process_frame
                                _assert_false(wcp.visible, "Kapat butonu sonrası WordCardPanel gizli")

        # Cleanup
        if GameManager.matched_card_clicked.is_connected(_on_test_matched_card_clicked):
                GameManager.matched_card_clicked.disconnect(_on_test_matched_card_clicked)
        _test_mcc_count = 0
        _test_mcc_pair_id = -1

        inst.queue_free()
        await get_tree().process_frame
