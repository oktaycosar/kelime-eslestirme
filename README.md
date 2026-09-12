# 🎯 Türkçe → İngilizce Memory (Godot 4)

## ▶️ Tarayıcıda Oyna

Kurulum gerekmez, doğrudan oynayabilirsiniz:

**https://oktaycosar.github.io/kelime-eslestirme/**

İlk açılışta ~38 MB indirilir (ilerleme çubuğu görünür), sonra oyun başlar.
Masaüstü `.exe` sürümüyle tek farkı: tarayıcıda konuşma sentezi (TTS)
olmadığı için **Sesli Mod sessiz kalır**. Diğer her şey aynıdır.

> Web sürümü `gh-pages` dalında yayınlanır; `main` dalı yalnızca kaynak kodu içerir.

Klasik memory oyununun biraz farklı bir versiyonu: bu oyunda aynı görsele sahip iki kartı bulmazsınız. Bir **Türkçe** kelimenin **İngilizce** karşılığını bulduğunuzda çift tamamlanır.

```
ELMA  (Türkçe)  +  APPLE (İngilizce)  =  DOĞRU ÇİFT 🎉
ELMA  (Türkçe)  +  BOOK  (İngilizce)  =  YANLIŞ ÇİFT ❌
ELMA  (Türkçe)  +  KİTAP (Türkçe)    =  İKİNCİ KART AÇILMAZ (geçersiz hamle)
APPLE (İngilizce)+ HOUSE (İngilizce) =  İKİNCİ KART AÇILMAZ (geçersiz hamle)
```

---

## 📦 İçindekiler

- [Oyun Kuralları](#-oyun-kuralları)
- [Nasıl Açılır / Çalıştırılır](#-nasıl-açılır--çalıştırılır)
- [Klasör Yapısı](#-klasör-yapısı)
- [Kod Mimarisi](#-kod-mimarisi)
- [Yeni Özellikler](#-yeni-özellikler)
- [🏷️ Kategori Sistemi](#%EF%B8%8F-kategori-sistemi)
- [🎮 Oyun Modları](#-oyun-modları)
- [Klavye Kısayolları](#-klavye-kısayolları)
- [SaveManager (En İyi Skor & İstatistik)](#-savemanager-en-iyi-skor--istatistik)
- [Yeni Kelime Ekleme](#-yeni-kelime-ekleme)
- [Ses Dosyası Ekleme](#-ses-dosyası-ekleme)
- [Zorluk Sistemi](#-zorluk-sistemi)
- [Kart Görselini Değiştirme](#-kart-görselini-değiştirme)
- [Hızlı Sorun Giderme](#-hızlı-sorun-giderme)
- [Windows Path Eşleştirme](#-windows-path-eşleştirme)
- [Testler (headless)](#-testler-headless)
- [Windows .exe derleme](#-windows-exe-derleme)
- [Test Senaryoları](#-test-senaryoları)

---

## 🎮 Oyun Kuralları

1. Oyun başında seçili zorluğa göre **6/8/10/15 çift** rastgele karıştırılır ve iki sütuna (sol TR, sağ EN) dizilir. Yerleşim sabit değildir: sütun sayısı ve kart boyutu, kart sayısına ve ekranda kalan alana göre `Main._apply_board_layout()` tarafından hesaplanır — böylece hiçbir kart ekran dışına taşmaz. Seçili kategori varsa yalnızca o kategorilerden seçilir.
2. Tıkla → kart açılır, kelime görünür.
3. İlk karttan sonra:
   - **Aynı dilde** bir kart seçersen (örn. ELMA → KİTAP): ikinci kart **AÇILMAZ**, hamle geçersiz sayılır. Skor azalmaz.
   - **Farklı dilde** bir kart seçersen (örn. ELMA → APPLE veya ELMA → BOOK): ikinci kart açılır ve eşleşme kontrol edilir.
4. Eşleşme kontrolü **`pair_id`**'ye göre yapılır (kart konumuna göre DEĞİL):
   - `pair_id` eşit + diller farklı → **DOĞRU**
     - Skor +100 + combo_bonus (`combo × 25`)
     - `combo += 1` (üst üste doğru eşleşmeler)
     - Kartlar yeşile döner, kalıcı açık
   - `pair_id` farklı + diller farklı → **YANLIŞ**
     - Skor -20 (min 0)
     - `combo = 0` (combo kırılır)
     - Hata +1, kartlar shake, 1 sn açık kalıp kapanır
5. Kontrol sırasında diğer kartlara **tıklama engellenir** (`GameManager.busy`).
6. **İpucu**: Mor renkte eşleşmemiş bir çift 1.5 sn gösterilir. Puan kesilir (zorluğa göre -50/-75/-100). Hak sayısı: EASY=3, MEDIUM=2, HARD=1.
7. **Duraklat**: Süre durur, kart tıklamaları engellenir, overlay gösterilir.
8. 6 çiftin tamamı bulununca **TEBRİKLER 🎉** paneli açılır; skor, süre, hata, hamle, en iyi combo gösterilir; yeni rekor varsa rozet görünür.
9. **TEKRAR OYNA** → kelimeler yeniden karıştırılır, kartlar kapatılır, tüm sayaçlar sıfırlanır.

---

## 🚀 Nasıl Açılır / Çalıştırılır

### Gereksinimler
- **Godot 4.x** (4.2 veya daha yeni önerilir) → https://godotengine.org/download

### Adımlar
1. Godot 4 Editor'ü aç.
2. **Import** butonuna tıkla → `godot-memory-game/` klasörünü seç.
3. `project.godot` dosyasını seç ve **Import & Edit**'e bas.
4. Godot projeyi yükler. Sağ panelde (FileSystem) klasör yapısını görürsün.
5. Üst menüden **Play** (▶) ya da `F5` → oyun açılır.

> İlk açılışta Godot .import dosyalarını oluşturur. İnternet gerektirmez.

### Export (opsiyonel)
- **Project → Export** → platform ekle (Windows Desktop / Linux / macOS / Web).
- Windows için: `Export PCK/Zip` → `.exe` çıkar.

---

## 📁 Klasör Yapısı

```
godot-memory-game/
├── project.godot                  # Godot 4 proje ayarları (7 autoload, window, renderer)
├── README.md                      # Bu dosya
├── .gitignore                     # Git ignore kuralları
│
├── assets/
│   ├── icon.svg                   # Godot project icon (basit SVG)
│   ├── sounds/
│   │   ├── README.txt             # Ses ekleme talimatları
│   │   ├── flip.txt               # PLACEHOLDER -> flip.wav
│   │   ├── match.txt              # PLACEHOLDER -> match.wav
│   │   ├── wrong.txt              # PLACEHOLDER -> wrong.wav
│   │   ├── win.txt                # PLACEHOLDER -> win.wav
│   │   ├── hint.txt               # PLACEHOLDER -> hint.wav (opsiyonel)
│   │   ├── pause.txt              # PLACEHOLDER -> pause.wav (opsiyonel)
│   │   ├── resume.txt             # PLACEHOLDER -> resume.wav (opsiyonel)
│   │   └── words/                 # Kelime ses dosyaları (Sesli Mod + WordCardPanel Dinle butonları)
│   │       └── README.txt         # Kelime sesi ekleme talimatları (slug kuralı)
│   └── theme/
│       └── default_theme.tres     # Opsiyonel boş tema (varsayılan Godot teması kullanılır)
│
├── scenes/
│   ├── Main.tscn                  # Ana sahne (header 6 stat, control bar, category bar, mode bar, columns, pause overlay, word card panel)
│   ├── Card.tscn                  # Kart prefab (TextureButton + 2 Panel)
│   ├── GameOverPanel.tscn         # Kazanma paneli (TEBRİKLER + combo + best score + record badge)
│   └── WordCardPanel.tscn         # Task 22: kelime öğrenme kartı paneli (TR/EN büyük, telaffuz, örnek cümleler, Dinle butonları)
│
└── scripts/
    ├── Main.gd                    # Oyun akışı (kart oluşturma, hint/pause/mute, kategori + mod butonları, klavye, matched_card_clicked -> WordCardPanel)
    ├── GameManager.gd             # Autoload - skor/eşleşme/hata/süre/combo/moves/hints/pause/selected_categories/wrong_side/matched_card_clicked
    ├── Card.gd                    # Kart davranışı (flip, hover, bounce, shake, hint, wrong_side mor flash, matched_card_clicked sinyali)
    ├── UIManager.gd               # Üst bilgi panel etiketleri (6 stat)
    ├── WordData.gd                # Autoload - kelime havuzu (210 çift, 14 kategori × 15 çift, kategori filtreli seçim)
    ├── WordExamples.gd            # Task 22+24 Autoload - 210 çift örnek cümle + telaffuz (pair_id 1-210)
    ├── WordCardPanel.gd           # Task 22 - kelime kartı paneli davranışı (show_pair / hide_panel / Dinle butonları)
    ├── DifficultyManager.gd      # Autoload - zorluk enum + grid boyutu + hints + hint_penalty
    ├── GameModeManager.gd         # Autoload - 4 oyun modu (CLASSIC/TR_TO_EN/EN_TO_TR/AUDIO), mode_changed sinyali
    ├── AudioManager.gd            # Autoload - güvenli ses yükleme/çalma + toggle_mute + play_word (Sesli mod + WordCardPanel Dinle)
    └── SaveManager.gd             # Autoload - en iyi skor & istatistik kaydı (FileAccess + JSON)
```

---

## 🏗️ Kod Mimarisi

### Autoload'lar (`project.godot` içinde)
| Singleton | Görev |
|-----------|------|
| `GameManager`  | Oyun durumu: skor, eşleşme, hata, süre, combo, best_combo, moves, hints, is_paused, **selected_categories**, **wrong_side** sinyali, **matched_card_clicked** sinyali (Task 22). `select_card()` (mod kontrolü dahil), `use_hint()`, `toggle_pause()`, `start_game()`, `reset_game()`, `set_categories()`, `clear_categories()`. |
| `WordData`     | Kelime havuzu (`WORD_PAIRS` dizisi, 210 çift, 14 kategori × 15 çift). Kategori sabitleri + `CATEGORIES` meta. `get_random_pairs(count, categories=[])`, `build_cards(pairs)`, `get_category_pair_count(cat)`, `get_pool_pair_count(cats)`, `has_enough_pairs(count, cats)`. |
| `WordExamples` | **Task 22 + Task 24** — Kelime kartı için örnek cümle + telaffuz verisi. **210 çift** (pair_id 1-210) tümü elle yazılmış (web `src/lib/word-examples.ts` ile birebir parite). `get_example(pair_id)` → `{tr_sentence, en_sentence, pronunciation}`, `has_example(pair_id)`, `get_example_count()` → 210. pair_id > 210 veya geçersizde boş string (crash yok). |
| `DifficultyManager` | `Difficulty` enum (EASY/MEDIUM/HARD/EXPERT). `get_pair_count()`, `get_grid_columns()`, `get_hint_count()`, `get_hint_penalty()`. |
| `AudioManager` | Ses yükleme/çalma (7 ses: flip/match/wrong/win/hint/pause/resume). `toggle_mute()`. **Sesli mod** için `play_word(word)` + `set_audio_mode(enabled)` (kelime ses dosyaları `assets/sounds/words/`'ten yüklenir, yoksa sessizce atlar). WordCardPanel'in "Dinle TR" / "Listen EN" butonları da `play_word` kullanır. Dosya yoksa sessizce atlar (crash yok). |
| `SaveManager`  | En iyi skor + istatistik kaydı (`user://memory_best_save.json`). `save_best_record()`, `is_new_record()`, `load_best_record()`, `record_game_result()`, `load_game_stats()`. |
| `GameModeManager` | **4 oyun modu** (CLASSIC/TR_TO_EN/EN_TO_TR/AUDIO). `current_mode`, `set_mode()`, `get_first_card_language()`, `get_mode_label()`, `get_mode_emoji()`, `is_audio_mode()`. `mode_changed(mode)` sinyali. |

### Sinyal Akışı
```
Karta tıkla (Card._on_pressed)
    -> Eğer matched kart (Task 22):
        -> Card sinyali: matched_card_clicked(card)
        -> Main._on_matched_card_clicked(card)
            -> GameManager.matched_card_clicked.emit(card.pair_id)  # relay
            -> WordData.WORD_PAIRS'dan TR/EN/category bul
            -> WordCardPanel.show_pair(pair_id, tr, en, category)
                -> WordExamples.get_example(pair_id) -> tr/en/pronunciation
                -> Label'lar güncellenir, panel görünür
        -> Card sinyali: card_clicked(card) (her zaman, no-op for matched)
    -> Eğer matched değil:
        -> Card sinyali: card_clicked(card)
        -> Main._on_card_clicked(card)
        -> GameManager.select_card(card)
            -> Eğer geçerli: card.flip_open(), AudioManager.play_flip()
            -> İkinci kart + farklı dil: moves++, _check_match()
                -> Doğru: combo++, score += 100 + combo*25, card.set_matched(),
                         AudioManager.play_match(), match_count++ -> UIManager günceller
                         -> match_count == total_pairs -> game_won()
                -> Yanlış: combo=0, score -= 20, card.shake(), AudioManager.play_wrong(),
                         await 1 sn -> card.flip_close(), busy = false
            -> game_won() -> Main._on_game_won()
                -> SaveManager.is_new_record() -> save_best_record() (eğer yeni rekor)
                -> SaveManager.record_game_result() (istatistik)
                -> GameOverPanel.show_panel(score, time, errors, pairs, best_combo, moves, is_new)
            -> TEKRAR OYNA -> Main._on_replay() -> _new_game()

İpucu:
    -> Main._on_hint_button_pressed() veya klavye H
    -> GameManager.use_hint()
        -> Eşleşmemiş bir çift bul (matched ve open kartları ele)
        -> score -= hint_penalty (50/75/100), hints_left--
        -> busy = true, AudioManager.play_hint()
        -> c1.show_hint(), c2.show_hint() (mor renkte açılır)
        -> await 1.5 sn
        -> c1.hide_hint(), c2.hide_hint() (kapanır)
        -> busy = false

Duraklat:
    -> Main._on_pause_button_pressed() veya klavye P
    -> GameManager.toggle_pause()
        -> is_paused = !is_paused
        -> AudioManager.play_pause() / play_resume()
        -> emit pause_changed -> Main._on_pause_changed (overlay visible toggle)
        -> _process: süre durur (is_paused kontrolü)
        -> select_card: tıklama engellenir (is_paused kontrolü)

Kelime öğrenme kartı (Task 22):
    -> Matched karta tıkla (Card._on_pressed)
    -> Card.matched_card_clicked(card) sinyali
    -> Main._on_matched_card_clicked(card)
        -> GameManager.matched_card_clicked.emit(pair_id)  # GameManager'a relay
        -> WordData'dan çiftin tam bilgisi (TR + EN + kategori) al
        -> WordCardPanel.show_pair(pair_id, turkish, english, category)
            -> WordExamples.get_example(pair_id)
                -> pair_id 1-210: elle yazılmış örnek cümle + IPA (Task 22: 1-90, Task 24: 91-210)
                -> pair_id > 210 veya geçersiz: boş string (crash yok)
            -> TitleLabel: "📖 Kelime Detayı"
            -> CategoryLabel: "{emoji} {label}" (WordData.get_category_info)
            -> TurkishLabel: büyük amber TR kelime
            -> EnglishLabel: büyük emerald EN kelime
            -> PronunciationLabel: italic IPA benzeri gösterim
            -> TRSentenceLabel: "🇹🇷 {tr_sentence}"
            -> ENSentenceLabel: "🇬🇧 {en_sentence}"
            -> ListenTRButton / ListenENButton / CloseButton
        -> "Dinle (TR)" -> AudioManager.play_word(turkish)
        -> "Listen (EN)" -> AudioManager.play_word(english)
        -> "Kapat" veya ESC -> WordCardPanel.hide_panel()
```

### Sinyaller (GameManager)
- `score_changed(score: int)`
- `match_count_changed(count: int, total: int)`
- `error_count_changed(count: int)`
- `time_changed(time_str: String)`  — `"MM:SS"`
- `combo_changed(combo: int, best_combo: int)`
- `moves_changed(moves: int)`
- `hints_changed(hints_left: int, total_hints: int)`
- `hint_used(pair_id: int)`
- `pause_changed(is_paused: bool)`
- `categories_changed(selected_categories: Array)`
- `pair_matched_ribbon(pair_id: int, turkish_card, english_card)`
- `wrong_side(card, expected_language: String)` — oyun modu kuralı ihlali (TR_TO_EN/EN_TO_TR/AUDIO)
- `matched_card_clicked(pair_id: int)` — **Task 22**: eşleşmiş karta tıklandı (kelime kartı için)
- `game_won()`

### Sinyaller (GameModeManager)
- `mode_changed(mode: int)` — mod değiştiğinde Main._on_mode_changed tetiklenir, oyun yeniden başlar

### Sinyaller (Card)
- `card_clicked(card)`  — tıklama anı (matched kartlar da dahil)
- `card_flipped(card)`  — flip tamamlandı
- `matched_card_clicked(card)`  — **Task 22**: eşleşmiş karta tıklandı → WordCardPanel açılır

---

## ✨ Yeni Özellikler

### 1. Combo Sistemi
- Üst üste doğru eşleşmelerde `combo` artar.
- Her doğru eşleşmede bonus puan: `combo × 25` (1. doğru = +25, 2. = +50, 3. = +75, ...).
- Yanlış eşleşmede combo sıfırlanır.
- `best_combo` her doğru eşleşmede güncellenir.
- UIManager'da combo label'ı, `combo >= 2` ise mor renkle vurgulanır.
- GameOverPanel'de "En İyi Combo" gösterilir.

### 2. Hamle Sayacı (Moves)
- İkinci kart her açıldığında (geçerli bir kart açma) `moves += 1`.
- UIManager'da Hamle stat'ı gösterilir.
- GameOverPanel'de gösterilir.
- En iyi skor kaydında kullanılır (tie-breaker: eşit skor+süre+hata'da az hamle kazanır).

### 3. İpucu Sistemi (Hint)
- DifficultyManager'dan hints al: EASY=3, MEDIUM=2, HARD=1.
- `hint_penalty`: EASY=50, MEDIUM=75, HARD=100.
- `use_hint()` fonksiyonu:
  - `hints_left <= 0` veya `busy` veya `is_paused` ise yoksay.
  - Eşleşmemiş ve kapalı bir çift bul (matched_pair_ids'te olmayan).
  - İki kartı `is_hinted = true` yap, mor renkte 1.5 sn göster, sonra kapat.
  - `score = max(0, score - hint_penalty)`
  - `hints_left -= 1`
  - `busy = true` (ipucu süresince tıklama engellend!)
  - `hint_used(pair_id)` sinyali yayılır.
- Card.gd: `is_hinted: bool`, `show_hint()` / `hide_hint()`, mor modülasyon (`COLOR_HINTED`).
- Main.tscn'de "💡 İpucu" butonu (hak sayısı buton metninde).
- Klavye kısayolu: **H**.

### 4. Duraklatma (Pause)
- `is_paused: bool` değişkeni.
- `toggle_pause()` fonksiyonu (yalnızca `is_running && !is_game_won`):
  - `is_paused = !is_paused`
  - `is_paused` true ise `_process`'te süre saymayı durdur.
  - `is_paused` true ise `select_card` return (tıklama engellend).
  - `pause_changed(is_paused)` sinyali.
- Main.tscn'de "Duraklat" butonu.
- PauseOverlay: ColorRect (siyah 70%) + CenterContainer + DialogPanel + "⏸ OYUN DURAKLATILDI" Label + "Devam et ▶" Button.
- Klavye kısayolu: **P** veya **ESC** (duraklatılmışken).

### 5. En İyi Skor Kaydı (Best Score)
- SaveManager autoload (yeni).
- Her zorluk için ayrı: `{score, time, errors, moves, date}`.
- `save_best_record(difficulty, score, time, errors, moves)` — yalnızca daha iyiyse kaydeder.
- `is_new_record(difficulty, score, time, errors, moves)` — tie-breaker: skor → süre → hata → hamle.
- `load_best_record(difficulty)` → Dictionary (yoksa boş).
- Kayıt dosyası: `user://memory_best_save.json` (Godot `FileAccess` ile).
- GameOverPanel'de:
  - "🏆 YENİ REKOR!" rozeti (is_new_record true ise).
  - "En İyi: <score>" satırı (önceki rekor ya da yeni rekor mesajı).

### 6. Oyun İstatistikleri
- SaveManager'a istatistik kaydı:
  - Her zorluk için: `games_played`, `games_won`, `total_score`, `best_score`, `best_time`, `total_errors`, `total_moves`, `total_time`, `best_combo`.
- `record_game_result(difficulty, won, score, time, errors, moves, best_combo)` — her oyun sonunda çağrılır.
- `load_game_stats()` → Dictionary.
- `load_difficulty_stats(difficulty)` → Dictionary.
- (İstatistik paneli şimdilik kayıt tutuyor; ileride bir UI paneli eklenebilir.)

### 7. Klavye Kısayolları
- `Main.gd`'de `_unhandled_input(event)` ile (input map'e ekleme YOK, direkt keycode):
  - **R** → `_new_game()` (yeniden başlat)
  - **H** → `GameManager.use_hint()`
  - **P** → `GameManager.toggle_pause()`
  - **M** → `AudioManager.toggle_mute()`
  - **ESC** → pause ise resume
- Modifiyer tuşlar (Ctrl/Cmd/Alt) ile birlikte basıldığında yoksayılır.

### 8. UI Güncellemeleri
- Header panel'de 6 stat yan yana: Skor, Eşleşme, Hata, Süre, Hamle, Combo.
- ControlBar: İpucu butonu + Duraklat butonu + Sesi Kapat butonu.
- CategoryBar: "Kategoriler:" etiketi + HFlowContainer içinde 1 "🎲 Tümünü Göster" + 14 kategori butonu (toggle).
- **GameModeBar**: "Mod:" etiketi + iki sade seçenek (🎲 Klasik, 🔊 Sesli). Yönlü modlar gereksiz arayüz kalabalığını önlemek için gösterilmez.
- **WrongSideMessage** (Task 13): Geçici bilgilendirme label'ı (yanlış sütun seçilince 2 sn görünür).
- Combo `>= 2` ise mor renkle vurgulanır.
- GameOverPanel: combo göster, en iyi skor göster, "YENİ REKOR!" rozeti.
- PauseOverlay: dialog paneli + "Devam et" butonu.

### 9. Oyun Modu Sistemi (Task 13, Web paritesi)
- **4 mod**: CLASSIC (rastgele), TR_TO_EN (Türkçe → İngilizce), EN_TO_TR (İngilizce → Türkçe), AUDIO (Sesli Mod).
- **GameModeManager** autoload (6. autoload): `current_mode`, `set_mode()`, `get_first_card_language()`, `mode_changed` sinyali.
- **Yanlış sütun kontrolü**: TR_TO_EN/EN_TO_TR/AUDIO modlarında ilk kart yanlış sütundansa açılmaz, mor flash + yanlış sesi + `wrong_side` sinyali.
- **Bilgilendirme mesajı**: Yanlış sütun seçilince `WrongSideMessage` label'ı 2 sn fade in/out ile "Bu modda önce [Türkçe/İngilizce] kart seçmelisin" gösterir.
- **Sesli mod (AUDIO)**: İngilizce kart açılınca `AudioManager.play_word(card.word)` çağrılır. `assets/sounds/words/` klasöründe slug'la eşleşen `word.wav/.ogg/.mp3` çalar. Yoksa sessizce atlanır (cache'lenir, oyun çökmez).
- **Mod değişince yeniden başlatma**: `GameModeManager.set_mode()` → `mode_changed` sinyali → `Main._on_mode_changed` → `_new_game()`. Aynı mod seçilirse no-op (oyun devam eder).
- **Buton görselleri**: Aktif mod → amber zemin (dolu), diğerleri → outline (şeffaf + ince border).
- Web versiyonu (Task 12) ile **birebir parite** — aynı 4 mod, aynı davranış.

### 10. Kelime Havuzu Genişletme (Task 16 + Task 18, Web paritesi)
- **90 → 126 çift** (Task 16, 36 yeni çift) → **210 çift** (Task 18, 84 yeni çift). **10 → 14 kategori** (Task 16). Her kategori 9 → 15 çift (Task 18).
- **Task 16: 4 yeni kategori** (web `src/lib/word-data.ts` Task 15 paritesi):
  - 👨‍⚕️ **Meslekler** (`professions`): DOKTOR, HEMŞİRE, POLİS, İTFAİYE, AŞÇI, ŞOFÖR, BERBER, MÜHENDİS, RESSAM (pair_id 91-99)
  - 😊 **Duygular** (`emotions`): MUTLU, ÜZGÜN, KIZGIN, KORKMUŞ, ŞAŞKIN, YORGUN, SİKİNTİLİ, HEYECANLI, RAHAT (pair_id 100-108)
  - ⛅ **Hava Durumu** (`weather`): GÜNEŞLİ, YAĞMURLU, BULUTLU, KARLI, RÜZGARLI, SICAK, SOĞUK, FIRTINALI, SİSLİ (pair_id 109-117)
  - 🚗 **Ulaşım** (`transport`): ARABA, OTOBÜS, TREN, UÇAK, GEMİ, BİSİKLET, MOTOR, KAMİYON, METRO (pair_id 118-126)
- **Task 18: 84 yeni çift** (web `src/lib/word-data.ts` Task 17 paritesi, pair_id 127-210). Her kategoriye +6 çift eklendi → her kategori **15 çift**:
  - 🐶 **Hayvanlar** (127-132): ASLAN, KAPLAN, AYI, FİL, MAYMUN, YILAN
  - 🍎 **Yiyecekler** (133-138): ÇİKOLATA, BAL, ÇAY, KAHVE, ŞEKER, TUZ
  - 🌳 **Doğa** (139-144): DAĞ, DENİZ, GÖL, NEHİR, ORMAN, KUM
  - 🏠 **Ev & Eşya** (145-150): HALI, DOLAP, ÇEKMECE, ÇÖP, ANAHTAR, KİLİT
  - 👁️ **Vücut** (151-156): BOYUN, OMUZ, KOL, BACAK, PARMAK, TIRNAK
  - 📚 **Okul** (157-162): SİLMEK, YAZMAK, OKUMAK, ÖĞRENMEK, BİLGİ, DERS
  - 👕 **Giyim** (163-168): ETEK, TŞÖRT, BOT, ŞORT, KRAVAT, KEMER
  - 🎨 **Renkler** (169-174): GRİ, KAHVERENGİ, ALTIN, GÜMÜŞ, BEJ, LACİVERT
  - 🔢 **Sayılar** (175-180): ON, YİRMİ, OTUZ, KIRK, ELLİ, YÜZ
  - 👪 **Aile** (181-186): OĞUL, KIZ EVLAT, TORUN, DAMAT, GELİN, KAYINVALİDE
  - 👨‍⚕️ **Meslekler** (187-192): ÖĞRETMEN, AVUKAT, TÜCCAR, ÇİFTÇİ, ASKER, POSTACI
  - 😊 **Duygular** (193-198): GURURLU, KÜSKÜN, SABIRLI, CESARETLİ, UTANGAN, NEŞELİ
  - ⛅ **Hava Durumu** (199-204): İLKBAHAR, YAZ, SONBAHAR, KIŞ, NEM, ESİNTİ
  - 🚗 **Ulaşım** (205-210): TAKSİ, TRAMVAY, VAPUR, HELİKOPTER, ROKET, SKUTER
- **Yeni kategori sabitleri** (Task 16): `CATEGORY_PROFESSIONS`, `CATEGORY_EMOTIONS`, `CATEGORY_WEATHER`, `CATEGORY_TRANSPORT`.
- **UI otomatik güncelleme**: `Main._build_category_buttons()` `WordData.CATEGORIES` üzerinden döngüyle buton üretir — yeni kategori eklemek için yalnızca `WordData.gd` güncellenir (Main.gd'ye dokunmaya gerek yok). Toplam buton sayısı: 1 "Tümünü Göster" + 14 kategori = **15 buton**.
- **Uzman (15 çift) tek kategori ile oynanabilir** (Task 18 sonrası her kategori 15 çift) — önceki sürümde her kategori 9 çift olduğu için Uzman tek kategori ile oynanamıyordu; artık tam 15 çift kullanılarak Uzman zorluk doldurulur.
- Web versiyonu (Task 15 + Task 17) ile **birebir parite** — aynı 14 kategori, aynı 210 çift, aynı pair_id'ler.

### 11. Kelime Öğrenme Kartı (Task 22 + Task 24, Web paritesi)
- **Matched kart tıklanınca detay kartı açılır**: eşleşmiş bir karta (yeşil renkli) tıklayınca `WordCardPanel` görünür hale gelir.
- **Yeni sinyal**: `Card.matched_card_clicked(card)` — Card._on_pressed içinde `is_matched` true ise yayılır. `GameManager.matched_card_clicked(pair_id)` ile de GameManager seviyesinde duyurulur (relay).
- **Matched kartlar tıklanabilir**: `Card.set_matched()` artık `disabled = true` YERİNE `disabled = false` bırakır. Böylece kullanıcı eşleşmiş bir karta tıklayıp detay kartını açabilir. `GameManager.select_card` matched kartlarda no-op olduğundan ek tıklama oyunu bozmaz.
- **WordCardPanel** (`scenes/WordCardPanel.tscn` + `scripts/WordCardPanel.gd`):
  - Başlık: "📖 Kelime Detayı"
  - Kategori etiketi: "{emoji} {label}" (örn. "🐶 Hayvanlar")
  - Türkçe kelime: 42pt amber renk (`Color(0.98, 0.82, 0.45, 1)`)
  - İngilizce kelime: 42pt emerald renk (`Color(0.45, 0.92, 0.55, 1)`)
  - Telaffuz: italic IPA benzeri gösterim (örn. "dog /dɒɡ/")
  - TR örnek cümle: "🇹🇷 {tr_sentence}"
  - EN örnek cümle: "🇬🇧 {en_sentence}"
  - "🔊 Dinle (TR)" butonu → `AudioManager.play_word(turkish)`
  - "🔊 Listen (EN)" butonu → `AudioManager.play_word(english)`
  - "✖ Kapat" butonu → `WordCardPanel.hide_panel()`
  - ESC tuşu da paneli kapatır (`_unhandled_input` içinde)
- **WordExamples** autoload (`scripts/WordExamples.gd`):
  - **210 çift elle yazılmış** (pair_id 1-210): her çift için `{tr_sentence, en_sentence, pronunciation}` — doğal Türkçe ve İngilizce cümleler + IPA benzeri telaffuz.
    - **Task 22 (1-90)**: animals / food / nature / house / body / school / clothing / colors / numbers / family — orijinal 9 kategori.
    - **Task 24 (91-210)**: professions / emotions / weather / transport yeni kategorileri (91-126) + her kategoriye 6 ek çift (127-210) — web `src/lib/word-examples.ts` ile **birebir parite**.
  - Pronunciation formatı: `"{word_lower} /{IPA}/"` (örn. `"dog /dɒɡ/"`, `"doctor /ˈdɒktər/"`).
  - API: `get_example(pair_id)` → Dictionary, `has_example(pair_id)` → bool, `get_example_count()` → 210.
  - Geçersiz pair_id (0, negatif, > 210 / havuz dışı) → boş string değerleri (crash yok).
  - `_generate_fallback` defensive olarak korunur (gelecekte WordData havuzu > 210 olursa yeni çiftler için geçici çözüm).
- **Main.gd akışı**: `_new_game` her kart için `card.matched_card_clicked.connect(_on_matched_card_clicked)` kurar. Handler, WordData'dan çiftin tam bilgilerini (TR + EN + kategori) alır ve `word_card_panel.show_pair(pair_id, tr, en, category)` çağırır.
- **Test kapsamı**: 7 yeni test fonksiyonu (Task 22) + 2 güncellenen test fonksiyonu (Task 24: WordExamples 90 → 210 örnek, fallback 91-210 → havuz dışı). Toplam ~95 + ~13 yeni assertion ≈ 428 PASS.
- Web versiyonu (Task 21 + Task 23) ile **birebir parite** — aynı 210 örnek cümle yapısı, aynı Dinle butonları, aynı kategori gösterimi.

---

## 🏷️ Kategori Sistemi

Oyun, kelimeleri **14 kategoriye** ayırır. Kullanıcılar tek bir kategoriye odaklanabilir, birden fazla kategoriyi karışık seçebilir ya da "🎲 Tümünü Göster" ile tüm havuzdan oynayabilir.

### Kategori Listesi (14 kategori, her biri 15 çift — Task 18 sonrası)

| Kategori id     | Etiket      | Emoji | Açıklama |
|-----------------|-------------|-------|----------|
| `animals`       | Hayvanlar    | 🐶    | Köpek, kedi, kuş, balık, at, tavşan, tavuk, inek, arılar + Task 18: aslan, kaplan, ayı, fil, maymun, yılan |
| `food`          | Yiyecekler  | 🍎    | Elma, ekmek, süt, su, peynir, yumurta, muz, portakal, domates + Task 18: çikolata, bal, çay, kahve, şeker, tuz |
| `nature`        | Doğa        | 🌳    | Ağaç, güneş, ay, yıldız, çiçek, bulut, yağmur, kar, rüzgar + Task 18: dağ, deniz, göl, nehir, orman, kum |
| `house`         | Ev & Eşya   | 🏠    | Ev, masa, sandalye, kapı, pencere, saat, yatak, lamba, ayna + Task 18: halı, dolap, çekmece, çöp, anahtar, kilit |
| `body`          | Vücut       | 👁️    | Göz, burun, ağız, kulak, el, ayak, baş, diş, saç + Task 18: boyun, omuz, kol, bacak, parmak, tırnak |
| `school`        | Okul        | 📚    | Kitap, kalem, okul, öğretmen, öğrenci, defter, silgi, cetvel, tahta + Task 18: silmek, yazmak, okumak, öğrenmek, bilgi, ders |
| `clothing`      | Giyim       | 👕    | Ayakkabı, şapka, çanta, gömlek, pantolon, ceket, çorap, eldiven, atkı + Task 18: etek, tişört, bot, şort, kravat, kemer |
| `colors`        | Renkler     | 🎨    | Kırmızı, mavi, yeşil, sarı, siyah, beyaz, mor, turuncu, pembe + Task 18: gri, kahverengi, altın, gümüş, bej, lacivert |
| `numbers`       | Sayılar     | 🔢    | Bir, iki, üç, dört, beş, altı, yedi, sekiz, dokuz + Task 18: on, yirmi, otuz, kırk, elli, yüz |
| `family`        | Aile        | 👪    | Anne, baba, kardeş, abla, ağabey, dede, babaanne, teyze, amca + Task 18: oğul, kız evlat, torun, damat, gelin, kayınvalide |
| `professions` * | Meslekler   | 👨‍⚕️ | Task 16: doktor, hemşire, polis, itfaiye, aşçı, şoför, berber, mühendis, ressam + Task 18: öğretmen, avukat, tüccar, çiftçi, asker, postacı |
| `emotions` *    | Duygular    | 😊    | Task 16: mutlu, üzgün, kızgın, korkmuş, şaşkın, yorgun, sıkıntılı, heyecanlı, rahat + Task 18: gururlu, küskün, sabırlı, cesaretli, utangan, neşeli |
| `weather` *     | Hava Durumu | ⛅    | Task 16: güneşli, yağmurlu, bulutlu, karlı, rüzgarlı, sıcak, soğuk, fırtinalı, sisli + Task 18: ilkbahar, yaz, sonbahar, kış, nem, esinti |
| `transport` *   | Ulaşım      | 🚗    | Task 16: araba, otobüs, tren, uçak, gemi, bisiklet, motor, kamyon, metro + Task 18: taksi, tramvay, vapur, helikopter, roket, skuter |

*Task 16: 4 yeni kategori. Task 18: her kategori +6 çift (pair_id 127-210).*

Toplam: **210 çift** (web versiyonu ile birebir aynı).

### Kullanım

- **Boş seçim (Karışık)**: Tüm 210 çiftin içinden rastgele seçilir. Bu varsayılan moddur.
- **Tek kategori**: Örn. yalnızca Hayvanlar → 15 çiftten seçim.
- **Çoklu kategori**: Birden fazla kategori seçilebilir (Ctrl+tık gerekmez, her buton toggle). Örn. Hayvanlar + Yiyecekler → 30 çiftlik havuzdan seçim.
- **Tümünü Göster butonu**: Tüm seçili kategorileri temizler, Karışık moduna döner.

### Kategori Yetersiz Durumu

Kategori havuzu, zorluğun istediği çift sayısından azsa otomatik uyum sağlanır. **Task 18 sonrası her kategori 15 çift olduğundan**, çoğu zorluk artık tek kategori ile tamamlanabilir:

| Zorluk   | İstenen çift | Kategori    | Kategorideki çift | Gerçek çift sayısı |
|----------|-------------|-------------|--------------------|---------------------|
| Kolay    | 6           | Hayvanlar   | 15                 | 6 (yeterli)         |
| Orta     | 8           | Hayvanlar   | 15                 | 8 (yeterli)         |
| Zor      | 10          | Hayvanlar   | 15                 | 10 (yeterli)        |
| Uzman    | 15          | Hayvanlar   | 15                 | 15 (yeterli — Task 18 öncesi 9 çift, yetersizdi) |

> **Task 18 öncesi** (her kategori 9 çift): Zor + tek kategori = 9 çift (10 yerine), Uzman + tek kategori = 9 çift (15 yerine), "Eşleşme 0/9" gösterilirdi. **Task 18 sonrası** (her kategori 15 çift): tüm zorluklar tek kategori ile tamamlanabilir. "Eşleşme 0/N" (N=istenen) doğru gösterilir. Web ile aynı davranış.

### Kategori Butonları UI

- **Yer**: `Main.tscn` → `RootVBox/CategoryBar/HFlowContainer` (HFlowContainer, sığmazsa alt satıra kayar)
- **İçerik** (Main.gd `_build_category_buttons()` ile kodda oluşturulur):
  - 1 adet "🎲 Tümünü Göster" butonu (toggle_mode=false, tüm seçimi temizler)
  - 14 adet kategori butonu (toggle_mode=true, çoklu seçim) — `WordData.CATEGORIES` üzerinden otomatik üretilir
- **Stil** (kod ile `StyleBoxFlat`):
  - Normal: yarı saydam koyu zemin (0.18,0.22,0.32) + ince gri-mavi border
  - Hover: hafif amber tint + 2px amber border
  - Pressed (seçili): **amber zemin** (0.95,0.78,0.45) + koyu amber border + koyu font rengi
  - Disabled (oyun sırasında): soluk gri
- **Disabled durumu**: Oyun aktifken (`is_running && !is_game_won`) tüm butonlar disabled. Kazanma ekranı görünürse veya oyun başlamadan değiştirilebilir.

### API

#### `WordData.gd`

```gdscript
const CATEGORIES: Array  # 14 Dictionary { id, label, label_en, emoji, description }
# WORD_PAIRS: Array — 210 Dictionary { pair_id, turkish, english, category } (14 kategori × 15 çift)

func get_categories() -> Array  # tüm kategori meta listesi
func get_category_info(category_id: String) -> Dictionary  # tek kategori meta
func get_category_pair_count(category_id: String) -> int  # tek kategoride kaç çift
func get_pool_pair_count(categories: Array = []) -> int  # seçili kategorilerde toplam
func get_random_pairs(count: int, categories: Array = []) -> Array  # filtreli rastgele seçim
func has_enough_pairs(count: int, categories: Array = []) -> bool
func build_cards(pairs: Array) -> Array  # her kart 'category' alanını taşır
```

#### `GameManager.gd`

```gdscript
var selected_categories: Array  # boş = tümü (Karışık)
signal categories_changed(selected_categories: Array)

func set_categories(cats: Array) -> void  # validate + emit signal
func clear_categories() -> void  # temizle + emit signal
func get_pool_pair_count() -> int  # WordData.get_pool_pair_count(selected_categories)
func has_enough_pairs_for_difficulty() -> bool
```

#### `Main.gd` (sinyal akışı)

```
Kullanıcı kategori butonuna tıklar
  -> Button.toggled sinyali
  -> Main._on_category_toggled(is_pressed, category_id)
  -> Yeni selected listesini kur (toggle butonlarının button_pressed durumundan)
  -> GameManager.set_categories(new_cats)
      -> Doğrula (bilinmeyen id'leri süz, duplikatları tekilleştir)
      -> selected_categories = valid
      -> emit categories_changed(selected_categories)
  -> Main._on_categories_changed(selected_cats)
      -> _apply_category_button_states() (görsel durumu senkronize et)
      -> _new_game() (yeni seçimle oyunu yeniden başlat)
```

---

## 🎮 Oyun Modları

Oyun, **4 farklı mod** sunar (Web versiyonu Task 12 ile birebir parite). Her mod, kart seçim sırasını farklı şekilde kısıtlar.

### Mod Listesi

| Mod | Etiket | Emoji | İlk Kart Zorunlu | Açıklama |
|-----|--------|-------|------------------|---------|
| `CLASSIC`   | Klasik                | 🎲  | — (herhangi)    | Rastgele yön - herhangi sütundan başla (varsayılan) |
| `TR_TO_EN`  | Türkçe → İngilizce    | 🇹🇷 | Türkçe          | Önce Türkçe kart seç, sonra İngilizce karşılığını bul |
| `EN_TO_TR`  | İngilizce → Türkçe    | 🇬🇧 | İngilizce       | Önce İngilizce kart seç, sonra Türkçe karşılığını bul |
| `AUDIO`     | Sesli Mod             | 🔊 | İngilizce       | İngilizce kart seçilince ses dosyası çalar, Türkçe karşılığı bul |

> Mod seçilirse oyun **otomatik olarak yeniden başlar** (kartlar yeni mod kurallarıyla yeniden karıştırılır). Aynı mod tekrar seçilirse yeniden başlatma yapılmaz (no-op).

### Yanlış Sütun Davranışı

TR_TO_EN, EN_TO_TR ve AUDIO modlarında **ilk kart yanlış sütundan** seçilirse:
- Kart **açılmaz** (geçersiz hamle).
- `Card.play_wrong_side()` animasyonu çalar: **mor flash** + hafif sarsılma.
- `GameManager.wrong_side(card, expected_language)` sinyali yayılır.
- `AudioManager.play_wrong()` çalınır (yanlış sesi).
- Main.gd, `WrongSideMessage` label'ında 2 sn bilgilendirici mesaj gösterir:
  - TR_TO_EN modunda EN karta tıklarsan: `⚠ Bu modda önce Türkçe kart seçmelisin`
  - EN_TO_TR / AUDIO modunda TR karta tıklarsan: `⚠ Bu modda önce İngilizce kart seçmelisin`

### Sesli Mod (AUDIO)

- İlk kart **İngilizce** olmalı (sıradan EN_TO_TR gibi davranır).
- İngilizce kart açıldığında `AudioManager.play_word(card.word)` çağrılır.
- `assets/sounds/words/` klasöründe kelimenin slug'ına uyan `word.wav`/`.ogg`/`.mp3` dosyası varsa çalar.
- Dosya yoksa sessizce atlanır (oyun çökmez).
- Slug kuralı (dosya adları için):
  - Küçük harf: `ELMA` → `elma`
  - Türkçe karakterler ASCII'ye: `Ç`→`c`, `Ğ`→`g`, `I`→`i`, `Ö`→`o`, `Ş`→`s`, `Ü`→`u`
  - Boşluk → `_`
  - Örnekler: `ELMA.wav`→`elma.wav`, `KÖPEK.wav`→`kopek.wav`, `KİTAP.wav`→`kitap.wav`
- Ses dosyası ekleme talimatları: `assets/sounds/words/README.txt`

> Ayrıntılı talimat: [🔊 Kelime Ses Dosyası Ekleme (Sesli Mod)](#kelime-ses-dosyası-ekleme-sesli-mod)

### Oyun Modu Butonları UI

- **Yer**: `Main.tscn` → `RootVBox/GameModeBar/GameModeFlow` (HFlowContainer, sığmazsa alt satıra kayar)
- **Sıra**: CategoryBar'ın altında, ColumnHeaders'ın üstünde.
- **İçerik** (Main.gd `_build_mode_buttons()` ile kodda oluşturulur):
  - 4 buton (toggle_mode=false, normal button): 🎲 Klasik, 🇹🇷 Türkçe → İngilizce, 🇬🇧 İngilizce → Türkçe, 🔊 Sesli Mod
  - Her butonun `tooltip_text`'i mod açıklamasını taşır (fareyle üstüne gelince görünür).
- **Stil** (kod ile `StyleBoxFlat`):
  - Pasif: outline (şeffaf koyu zemin + ince amber border)
  - Hover: hafif amber tint + 2px amber border
  - **Aktif**: amber zemin (0.95, 0.78, 0.45) + koyu amber border + koyu font rengi
- **Disabled**: Mod butonları her zaman etkindir (web paritesi); mod değişince oyun otomatik yeniden başlar.

### API

#### `GameModeManager.gd`

```gdscript
enum GameMode { CLASSIC, TR_TO_EN, EN_TO_TR, AUDIO }  # 0, 1, 2, 3

var current_mode: int  # varsayılan: CLASSIC

signal mode_changed(mode: int)

func set_mode(mode: int) -> void  # geçerliyse güncelle + sinyal yay
func get_first_card_language() -> String  # "" | "turkish" | "english"
func get_first_card_language_for(mode: int) -> String  # parametreyle
func get_mode_label(mode: int) -> String  # "Klasik" | "Türkçe → İngilizce" | ...
func get_mode_emoji(mode: int) -> String  # "🎲" | "🇹🇷" | "🇬🇧" | "🔊"
func get_mode_description(mode: int) -> String
func get_mode_button_text(mode: int) -> String  # "emoji + label"
func get_all_modes() -> Array  # [CLASSIC, TR_TO_EN, EN_TO_TR, AUDIO]
func is_audio_mode() -> bool  # current_mode == AUDIO
func get_current_mode_label() -> String
func get_current_mode_emoji() -> String
```

#### `AudioManager.gd` (Sesli mod ek fonksiyonları)

```gdscript
var audio_mode_enabled: bool  # varsayılan: false

func set_audio_mode(enabled: bool) -> void  # bayrak aç/kapat
func play_word(word: String) -> void  # assets/sounds/words/{slug}.wav/.ogg/.mp3 çal
func is_word_loaded(word: String) -> bool  # cache kontrolü
func clear_word_cache() -> void  # cache temizle
```

#### `GameManager.gd` (yeni sinyal)

```gdscript
signal wrong_side(card, expected_language: String)
# select_card() içinde: ilk kart yanlış sütundansa, kart açma + sinyal yay + blocked animasyonu
```

#### `Card.gd` (yeni animasyon)

```gdscript
func play_wrong_side() -> void  # mor flash (0.18 sn) + hafif sarsılma (0.15 sn)
```

#### `Main.gd` (sinyal akışı)

```
Kullanıcı mod butonuna tıklar
  -> Button.pressed sinyali
  -> Main._on_mode_button_pressed(mode)
  -> GameModeManager.set_mode(mode)
      -> Eğer mode == current_mode: no-op (sinyal yayılmaz)
      -> Eğer farklı: current_mode = mode, emit mode_changed(mode)
  -> Main._on_mode_changed(mode)
      -> AudioManager.set_audio_mode(mode == AUDIO)
      -> _apply_mode_button_states() (aktif butonu vurgula)
      -> _new_game() (yeni mod kurallarıyla oyunu yeniden başlat)

Kullanıcı yanlış sütundan kart tıklar (örn. TR_TO_EN modunda EN kart)
  -> Card._on_pressed -> card_clicked(card) sinyali
  -> Main._on_card_clicked(card)
  -> GameManager.select_card(card)
      -> selected_cards boş + GameModeManager.get_first_card_language() != ""
      -> card.language != expected_lang:
          -> card.play_wrong_side() (mor flash)
          -> AudioManager.play_wrong()
          -> emit wrong_side(card, expected_lang)
          -> return false (kart açılmadı)
  -> Main._on_wrong_side(card, expected_lang)
      -> WrongSideMessage label: "⚠ Bu modda önce [Türkçe/İngilizce] kart seçmelisin"
      -> 2 sn fade in/out tween
```

---

## ⌨️ Klavye Kısayolları

| Tuş | İşlev |
|-----|------|
| **R** | Yeni oyun (yeniden başlat) |
| **H** | İpucu kullan (varsa) |
| **P** | Duraklat / Devam et |
| **M** | Sesi aç / kapat |
| **ESC** | Duraklatılmışsa devam et; **Task 22**: WordCardPanel açıksa kapat |

> Kısayollar input map'e eklenmedi, direkt `event.keycode` ile kontrol edilir. Modifiyer tuşlar (Ctrl/Cmd/Alt) ile birlikte basıldığında yoksayılır. Task 22: ESC tuşu, Main.gd'nin _unhandled_input'undan önce WordCardPanel._unhandled_input'unda yakalanır (panel açıksa kapatır).

---

## 💾 SaveManager (En İyi Skor & İstatistik)

### Kayıt Dosyası
- Yol: `user://memory_best_save.json`
- Godot 4 `FileAccess` sınıfı ile okunur/yazılır (cross-platform: Windows/Linux/macOS).
- Hata durumunda (dosya yok, bozuk JSON, yazma izni yok) sessizce sıfırlanır, **crash ETMEZ**.

### Veri Yapısı
```json
{
  "best_records": {
    "EASY":   {"score": 1425, "time": 48.2, "errors": 0, "moves": 6, "date": "2024-08-31 17:13"},
    "MEDIUM": {},
    "HARD":   {}
  },
  "game_stats": {
    "EASY": {
      "games_played": 5, "games_won": 4, "total_score": 5200,
      "best_score": 1425, "best_time": 48.2,
      "total_errors": 3, "total_moves": 32, "total_time": 240.5,
      "best_combo": 6
    },
    "MEDIUM": { ... },
    "HARD":   { ... }
  }
}
```

### API
- `save_best_record(difficulty, score, time, errors, moves) -> bool` — yalnızca daha iyiyse kaydeder, true/false döner.
- `is_new_record(difficulty, score, time, errors, moves) -> bool` — tie-breaker: skor → süre → hata → hamle.
- `load_best_record(difficulty) -> Dictionary` — boş dict dönebilir.
- `record_game_result(difficulty, won, score, time, errors, moves, best_combo) -> void` — istatistik günceller.
- `load_game_stats() -> Dictionary` — tüm istatistikler.
- `load_difficulty_stats(difficulty) -> Dictionary` — tek zorluk istatistikleri.
- `clear_all() -> void` — tüm kayıtları sıfırlar (debug / ayarlar için).

### Godot user:// Yolu
- **Windows**: `%APPDATA%\Godot\app_userdata\Türkçe-İngilizce Memory\memory_best_save.json`
- **Linux**: `~/.local/share/godot/app_userdata/Türkçe-İngilizce Memory/memory_best_save.json`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Türkçe-İngilizce Memory/memory_best_save.json`

---

## ➕ Yeni Kelime Ekleme

Aç: `scripts/WordData.gd`

`WORD_PAIRS` dizisine yeni satır ekle. **`category` alanı zorunludur**:

```gdscript
{"pair_id": 211, "turkish": "KAĞIT", "english": "PAPER", "category": "school"},
```

Kurallar:
- `pair_id` **benzersiz** olmalıdır (en büyük pair_id'den büyük seç; Task 18 sonrası en büyük pair_id = 210).
- `category`, `CATEGORIES` içindeki bir `id` ile eşleşmelidir (`animals`, `food`, `nature`, `house`, `body`, `school`, `clothing`, `colors`, `numbers`, `family`, `professions`, `emotions`, `weather`, `transport`). Bilinmeyen kategori kullanırsanız çift kategori filtresinde görünmez (crash olmaz, sessizce süzülür).
- Türkçe karakterler (Ç, Ğ, İ, ı, Ö, Ş, Ü) doğrudan yazılabilir.
- Türkçe/İngilizce alanlar kısa tutulursa (≤ 8 karakter) kart üzerinde daha rahat okunur.

### Yeni Kategori Eklemek

1. `WordData.gd`'de `CATEGORIES` dizisine yeni Dictionary ekle:
   ```gdscript
   { "id": "jobs", "label": "Meslekler", "label_en": "Jobs", "emoji": "👷", "description": "Doktor, öğretmen, polis..." },
   ```
2. Aynı isimle bir sabit ekle (opsiyonel, kod okunurluğu için):
   ```gdscript
   const CATEGORY_JOBS: String = "jobs"
   ```
3. Yeni çiftleri bu kategoriyle ekle (yukarıdaki örnekteki gibi `"category": "jobs"`).
4. `Main.gd`'de değişiklik YOK — butonlar `WordData.CATEGORIES` üzerinden otomatik üretilir.

Otomatik kullanım: oyun her açılışta `get_random_pairs(total_pairs, selected_categories)` ile seçili kategorilerden rastgele çift seçer. Yeni eklediğin kelimeler havuza dahil edilir, sonraki oyunlarda görünebilir.

---

## 🔊 Ses Dosyası Ekleme

1. `assets/sounds/` klasörüne gerçek ses dosyalarını koy:
   - `flip.wav`  (kart açma — kısa tık efekti)
   - `match.wav` (doğru eşleşme — olumlu "ding")
   - `wrong.wav` (yanlış eşleşme — kısa "buzz")
   - `win.wav`   (kazanma — uzun triumfan melodiesi)
   - `hint.wav`  (ipucu gösterimi — opsiyonel, yoksa sessiz)
   - `pause.wav` (duraklatma — opsiyonel)
   - `resume.wav` (devam et — opsiyonel)
2. Placeholder `.txt` dosyalarını silebilirsin.
3. `scripts/AudioManager.gd` içindeki yolları kontrol et (zaten varsayılan yollar `.wav` uzantılı).
4. Eğer `.ogg` kullanıyorsan: `AudioManager.gd` içindeki `*_PATH` sabitlerini güncelle.

> **Ses yoksa oyun yine de çalışır** — `ResourceLoader.exists()` ile kontrol edilir, yoksa `push_warning` ile uyarı verilir, oyun çökmez. Ayrıntılı talimat: `assets/sounds/README.txt`.

---

## 🔊 Kelime Ses Dosyası Ekleme (Sesli Mod)

**Sesli Mod** (AUDIO) aktifken, kullanıcı İngilizce bir kart seçtiğinde o kelimenin ses dosyası çalar. Türkçe karşılığını bulur.

### Adımlar

1. `assets/sounds/words/` klasörüne İngilizce kelimeler için ses dosyaları koyun:
   - `apple.wav`, `book.wav`, `house.wav`, `dog.wav`, `water.wav`, `car.wav`, ...
2. Dosya adları **slug kuralına** uymalı (AudioManager._slugify_word ile aynı):
   - Küçük harf: `APPLE` → `apple`
   - Türkçe karakterler ASCII'ye: `Ç`→`c`, `Ğ`→`g`, `I`→`i`, `Ö`→`o`, `Ş`→`s`, `Ü`→`u`
   - Boşluk → `_` (alt çizgi)
   - Sadece `a-z`, `0-9`, `_` tutar
3. Öncelik sırasıyla denenecek uzantılar: `.wav` → `.ogg` → `.mp3` (ilk bulunan çalınır).
4. Godot Editor'da **Project > Reload Current Project** (dosyalar otomatik .import edilir).
5. "🔊 Sesli Mod" butonuna tıkla, İngilizce karta tıkla → ses çalar.

### Cache

- AudioManager, her kelimenin ses dosyasını ilk aramada yükler ve cache'ler (null da cache'lenir, tekrar arama yapılmaz).
- Yeni ses dosyası ekledikten sonra cache temizlemek için: `AudioManager.clear_word_cache()`.
- Veya Godot Editor'de **Project > Reload Current Project** → AudioManager yeniden yüklenir.

### Hata Durumu

- Dosya yoksa oyun çökmez: sessizce atlanır (sadece bir kez `ResourceLoader.exists()` ile kontrol edilir, sonra cache).
- Mute (M tuşu) aktifse kelime sesleri de çalmaz.
- `AudioManager.is_word_loaded(word)` ile bir kelimenin ses dosyasının yüklenip yüklenmediğini kontrol edebilirsiniz (debug/test).

> Ayrıntılı talimat: `assets/sounds/words/README.txt`

### Ücretsiz Ses Kaynakları (İngilizce telaffuz)

- https://ttsmp3.com (Text-to-Speech MP3 üretici)
- https://www.naturalreaders.com (online TTS)
- Python + gTTS: `pip install gTTS` → `gtts-cli "apple" -o apple.mp3`

---

## 🎚️ Zorluk Sistemi

Aç: `scripts/DifficultyManager.gd`

```gdscript
enum Difficulty { EASY, MEDIUM, HARD, EXPERT }

# Kolay : 6 çift = 12 kart, 3 ipucu, -50 penalty (varsayılan)
# Orta  : 8 çift = 16 kart, 2 ipucu, -75 penalty
# Zor   : 10 çift = 20 kart, 1 ipucu, -100 penalty
# Uzman : 15 çift = 30 kart, 1 ipucu, -150 penalty
```

### Zorluk seçimi (arayüzde)
Zorluk, `Main.tscn` → `RootVBox/DifficultyBar/DifficultyFlow` içindeki butonlarla seçilir:
**Kolay (6) / Orta (8) / Zor (10) / Uzman (15)**. Butonlar `DifficultyManager.Difficulty`
üzerinden **otomatik** üretilir — yeni zorluk eklemek için yalnızca `DifficultyManager.gd`
güncellenir, `Main.gd`'ye dokunulmaz. Aktif zorluk amber dolgulu görünür.

Butona basıldığında `Main._on_difficulty_button_pressed()` → `DifficultyManager.set_difficulty()`
→ `_new_game()`. `GameManager.start_game()` çift sayısını ve ipucu hakkını
`DifficultyManager.current_difficulty`'den alır.

### Kart yerleşimi
Sütun sayısı ve kart yüksekliği sabit değildir; `Main._apply_board_layout()` hesaplar:
- Sütun sayısı: kartların okunabilir en küçük yüksekliğe (52px) sığdığı **en az** sütun sayısı
  (`_pick_board_columns()`), yani kartlar mümkün olduğunca geniş kalır.
- Kart yüksekliği: kalan alanın satır sayısına bölümü; 52px alt sınır, 112px üst sınır.
- `GameArea.resized` sinyali bağlıdır: pencere yeniden boyutlandırılınca yerleşim tazelenir.

Ölçülen sonuç (1152×720): Kolay 2 sütun 269×99 · Orta 2 sütun 269×73 · Zor 2 sütun 269×57 ·
Uzman 3 sütun 177×57. Dördü de pencere içinde kalır; bu `tests/check_layout.gd` ile korunur.

---

## 🎨 Kart Görselini Değiştirme

Aç: `scenes/Card.tscn`

### Kapalı kart rengi (BackPanel)
- `BackPanel` node'una tıkla → Inspector → `theme_override_styles/panel` → `StyleBoxFlat`
- `bg_color`, `border_color`, `corner_radius` değiştir.

### Açık kart renkleri (FrontPanel)
- Dil renkleri `scripts/Card.gd` içindeki sabitlerdedir:
  ```gdscript
  const COLOR_TURKISH: Color = Color(0.98, 0.82, 0.55, 1.0)  # sıcak amber
  const COLOR_ENGLISH: Color = Color(0.62, 0.85, 0.98, 1.0)  # soğuk mavi
  const COLOR_MATCHED: Color = Color(0.62, 0.96, 0.66, 1.0)  # yeşil
  const COLOR_HINTED: Color = Color(0.78, 0.55, 0.95, 1.0)   # mor (ipucu)
  ```
- `FrontPanel` stylebox base color beyaz → modulate çarpar; renkleri değiştirmek için `COLOR_*` sabitlerini güncelle.

### Kapalı kart deseni / ikon
- `BackLabel` node'unda `?` yerine farklı bir karakter (örn `🃏`, `🂠`, `📖`) veya gerçek bir Texture kullan.

### Kart boyutu
- `Card (TextureButton)` varsayılan `custom_minimum_size = Vector2(180, 70)`. DİKKAT: çalışma anında `Main._apply_board_layout()` kart yüksekliğini ezer. Kalıcı değişiklik için `Main.gd` içindeki `BOARD_CELL_MIN_H` / `BOARD_CELL_MAX_H` / `BOARD_CELL_MIN_W` sabitlerini ayarla.
- Grid ile aralıklar: `scenes/Main.tscn` → `GridContainer` → `theme_override_constants/h_separation`, `v_separation`.

### Gerçek resim kullanmak istersen
- `BackPanel` ve `FrontPanel` yerine `TextureRect` kullan.
- `scripts/Card.gd` içinde `@onready var back_panel` referanslarını güncelle.

---

## 🛠️ Hızlı Sorun Giderme

| Sorun | Çözüm |
|------|------|
| **Kartlar tıklanmıyor** | `Card.tscn`'de TextureButton'ın `mouse_filter = 0` (STOP) olduğundan emin ol. BackPanel/FrontPanel/Label `mouse_filter = 2` (IGNORE) olmalı. |
| **Ses çalmıyor** | `assets/sounds/`'a gerçek `.wav`/`.ogg` ekle. AudioManager logu `push_warning` ile gösterilir. |
| **İpucu çalışmıyor** | `hints_left > 0` olmalı, `busy = false` olmalı, `is_paused = false` olmalı. Buton metnindeki hak sayısını kontrol et. |
| **Pause overlay görünmüyor** | `Main.tscn`'de `PauseOverlay`'in `visible = false` başlangıçta. `Main._on_pause_changed` tetiklenince görünür olur. |
| **En iyi skor kaydedilmiyor** | `SaveManager` autoload `project.godot`'da kayıtlı olmalı. Kayıt dosyası `user://memory_best_save.json`'da. Hata varsa `push_warning` ile loglanır. |
| **Türkçe karakterler görünmüyor** | Godot 4 varsayılan fontu Türkçe'yi destekler. Eğer özel font kullanırsan, Türkçe karakter içeren bir font seç. |
| **Oyun paneli görünmüyor** | `Main.tscn`'de `GameOverPanel`'in `visible = false` başlangıçta olmalı. `Main.gd` `_new_game()` `hide_panel()` çağırır. |
| **Kartlar ekrana sığmıyor** | Yerleşim `Main._apply_board_layout()` ile hesaplanır; elle boyut verme. `BOARD_CELL_MIN_H` düşür ya da `tests/check_layout.gd` çıktısına bak — hangi zorlukta taşıyor gösterir. |
| **Otomatik içe aktarım sırasında hata** | `.godot/` klasörünü silip Godot Editor'de projeyi yeniden import et. |
| **Klavye kısayolları çalışmıyor** | `Main.gd`'nin `_unhandled_input` metodunu kontrol et. Butona focus varken Tab/Enter gibi tuşlar buton tarafından yakalanır; R/H/P/M yine de çalışır. |
| **Kategori butonları yanıt vermiyor** | Oyun aktifken (is_running && !is_game_won) butonlar disabled. Oyunu kazanınca veya başlatmadan önce kategori değiştirilebilir. |
| **Kategori seçince oyun başlamıyor** | `Main._on_categories_changed` → `_new_game()` çağrısı yapmalı. Test: tek kategori seç, kartlar yeni seçimle gelmeli. |
| **Zor + tek kategori → 9 çift gösteriliyor** | (Eski Task 16 davranışı, Task 18 sonrası geçersiz.) Artık her kategori 15 çift olduğundan tek kategori ile tüm zorluklar tamamlanabilir. |

---

## 🖥️ Windows Path Eşleştirme

Bu proje, Windows'taki şu klasörle **birebir aynı yapıda** oluşturulmuştur:

```
C:\Users\OktayC\Desktop\Harness_Genel_26\Godot_Ana\kelime-memory
```

Dosyaları indirip bu klasöre çıkardığınızda Godot 4 doğrudan açar.
Aynı içeriği kullanır: aynı `project.godot`, aynı `scenes/`, aynı `scripts/`,
aynı `assets/`. Klasör adını (`godot-memory-game` → `kelime-memory`) değiştirmeniz
gerekmez — Windows pathinde klasör adını istediğiniz gibi ayarlayabilirsiniz.

### Taşıma
1. `godot-memory-game/` klasörünün tüm içeriğini ZIP'le ya da doğrudan kopyala.
2. Windows'ta `C:\Users\OktayC\Desktop\Harness_Genel_26\Godot_Ana\` altına `kelime-memory` adlı klasör oluştur.
3. İçeriği yapıştır.
4. Godot 4 → **Import** → `kelime-memory/project.godot` seç → **Import & Edit**.

### Kayıt Dosyası Konumu (Windows)
- `C:\Users\<Kullanıcı>\AppData\Roaming\Godot\app_userdata\Türkçe-İngilizce Memory\memory_best_save.json`

---

## 🧪 Test Senaryoları

Aşağıdaki senaryoları manuel test edebilirsin:

| # | Senaryo | Beklenen |
|---|--------|----------|
| 1 | Açık karta tekrar tıkla | Yoksay |
| 2 | İlk kart TR, ikinci kart TR | İkinci kart AÇILMAZ, küçük "blocked" animasyonu |
| 3 | İlk kart EN, ikinci kart EN | İkinci kart AÇILMAZ |
| 4 | İlk kart TR (ELMA), ikinci kart EN (APPLE) | DOĞRU — yeşil, bounce, kalıcı açık, skor +100 + combo_bonus |
| 5 | İlk kart TR (ELMA), ikinci kart EN (BOOK) | YANLIŞ — shake, 1 sn açık, kapanır, hata +1, skor -20, combo=0 |
| 6 | Üst üste 2 doğru eşleşme | Combo 1 → 2, ikinci doğru +50 bonus, combo label mor |
| 7 | İpucu butonuna bas | Eşleşmemiş bir çift 1.5 sn mor renkte açılır, kapanır, hak 1 azalır, skor -penalty |
| 8 | İpucu hakkı bitince buton | Disabled, metin "💡 İpucu (0/N)" |
| 9 | Duraklat butonuna bas | Overlay görünür, süre durur, kart tıklamaları engellend |
| 10 | Devam et butonuna bas | Overlay gizlenir, süre devam eder, kart tıklamaları aktif |
| 11 | Klavye R | Yeni oyun başlar |
| 12 | Klavye H | İpucu kullanılır |
| 13 | Klavye P / ESC | Duraklat / Devam et |
| 14 | Klavye M | Sesi aç/kapat, buton metni güncellenir |
| 15 | 6 çifti tamamla | TEBRİKLER paneli, skor/süre/hata/hamle/combo, yeni rekor rozeti (ilk oyun) |
| 16 | TEKRAR OYNA | Yeni kelimelerle yeni grid, tüm sayaçlar sıfır |
| 17 | Bir çift kontrol edilirken 3. karta tıkla | Yoksay (busy) |
| 18 | Aynı oyunu iki kez oyna, ikincide daha düşük skor | "En İyi: <önceki_skor>" görünür, YENİ REKOR rozeti YOK |
| 19 | Kategori butonu "🐶 Hayvanlar" seç (oyun öncesi) | Buton amber zemin + koyu border; kartlar yalnızca Hayvanlar kategorisinden gelir |
| 20 | İki kategori seç (Hayvanlar + Yiyecekler) | İki buton da amber; kartlar her iki kategoriden gelir |
| 21 | "🎲 Tümünü Göster" butonuna bas | Tüm kategori butonları seçimsiz; oyun Karışık modda yeniden başlar |
| 22 | Oyun sırasında kategori butonuna tıkla | Disabled (tıklanmaz); oyun bitince tekrar aktif |
| 23 | Zor + Hayvanlar kategorisi | 10 çift (Task 18 sonrası, öncesi 9 gösterilirdi); "Eşleşme 0/10"; oyun kazanılınca 10/10 |
| 24 | Oyunu kazan, kategori değiştir, yeni oyun | Yeni kategoriyle oyun başlar, skor 0, rekor önceki kategorideki gibi kayıtlı kalır |
| 25 | "🎲 Klasik" mod butonuna tıkla (başlangıçta) | Buton amber zemin + koyu border (aktif); diğer mod butonları outline (pasif) |
| 26 | "🇹🇷 Türkçe → İngilizce" mod butonuna tıkla | Oyun yeniden başlar; buton amber (aktif); TR karta tıklayınca açılır, EN karta tıklarsan açılmaz |
| 27 | TR_TO_EN modunda ilk kart olarak İngilizce kart tıkla | Kart AÇILMAZ; mor flash animasyonu; "⚠ Bu modda önce Türkçe kart seçmelisin" mesajı 2 sn görünür |
| 28 | TR_TO_EN modunda Türkçe kart tıkla → İngilizce eşini tıkla | DOĞRU eşleşme; skor +100 + combo_bonus; ConnectionRibbon çizilir |
| 29 | "🇬🇧 İngilizce → Türkçe" mod butonuna tıkla | Oyun yeniden başlar; buton amber (aktif); EN karta tıklayınca açılır, TR karta tıklarsan açılmaz |
| 30 | EN_TO_TR modunda ilk kart Türkçe tıkla | Kart AÇILMAZ; mor flash; "⚠ Bu modda önce İngilizce kart seçmelisin" mesajı 2 sn |
| 31 | "🔊 Sesli Mod" butonuna tıkla | Oyun yeniden başlar; buton amber (aktif); AudioManager.set_audio_mode(true) çağrılır |
| 32 | Sesli modda İngilizce kart tıkla, ses dosyası YOKSA | Kart açılır; kelime sesi sessizce atlanır; oyun çökmez (cache'lenir) |
| 33 | Sesli modda İngilizce kart tıkla, ses dosyası VARSA | Kart açılır; `assets/sounds/words/{slug}.wav` çalar |
| 34 | "🎲 Klasik" mod'a geri dön | Oyun yeniden başlar; herhangi sütundan kart seçilebilir (yanlış yön mesajı YOK) |
| 35 | Aynı mod butona tekrar tıkla | Yeniden başlatma YAPILMAZ (no-op); oyun devam eder |
| 36 | "👨‍⚕️ Meslekler" kategori butonu seç (oyun öncesi) | Buton amber zemin; 15 çiftten rastgele 6 kart gelir (Task 18 sonrası, öncesi 9'dan gelirdi): DOKTOR, HEMŞİRE, POLİS, İTFAİYE, AŞÇI, ŞOFÖR, BERBER, MÜHENDİS, RESSAM + Task 18: ÖĞRETMEN, AVUKAT, TÜCCAR, ÇİFTÇİ, ASKER, POSTACI |
| 37 | "😊 Duygular" kategori butonu seç | 15 çiftten rastgele kartlar (Task 18 sonrası): MUTLU, ÜZGÜN, KIZGIN, KORKMUŞ, ŞAŞKIN, YORGUN, SİKİNTİLİ, HEYECANLI, RAHAT + GURURLU, KÜSKÜN, SABIRLI, CESARETLİ, UTANGAN, NEŞELİ |
| 38 | "⛅ Hava Durumu" kategori butonu seç | 15 çiftten rastgele kartlar: GÜNEŞLİ, YAĞMURLU, BULUTLU, KARLI, RÜZGARLI, SICAK, SOĞUK, FIRTINALI, SİSLİ + İLKBAHAR, YAZ, SONBAHAR, KIŞ, NEM, ESİNTİ |
| 39 | "🚗 Ulaşım" kategori butonu seç | 15 çiftten rastgele kartlar: ARABA, OTOBÜS, TREN, UÇAK, GEMİ, BİSİKLET, MOTOR, KAMİYON, METRO + TAKSİ, TRAMVAY, VAPUR, HELİKOPTER, ROKET, SKUTER |
| 40 | 4 yeni kategori çoklu seç (Meslekler + Duygular + Hava Durumu + Ulaşım) | 4 buton da amber; 60 çiftlik havuzdan (Task 18 sonrası, öncesi 36) rastgele 6 çift (Kolay) gelir |
| 41 | Uzman zorluk + Meslekler kategorisi (Task 18 sonrası) | 15 çift gösterilir (Task 18 öncesi 9 gösterilirdi); "Eşleşme 0/15"; oyun bitince 15/15 |
| 42 | 14 kategori butonu + "Tümünü Göster" say | Toplam 15 buton görüntülenir (Main.gd `WordData.CATEGORIES` üzerinden otomatik üretir) |
| 43 | Yeni çift 91-126 (örn. DOKTOR↔DOCTOR) eşleştir | DOĞRU; skor +100 + combo; ConnectionRibbon çizilir |
| 44 | Task 18: Yeni çift 127-210 (örn. ASLAN↔LION) eşleştir | DOĞRU; skor +100 + combo; ConnectionRibbon çizilir |
| 45 | Task 18: Uzman zorluk + tek kategori (örn. Renkler) | 15 çift (15/15) — her kategori 15 çift olduğundan tam doldurulur |
| 46 | Task 18: Karışık mod havuz sayısı | Toplam 210 çiftin tamamından rastgele 15 (Uzman) gelir |
| 47 | Task 18: Yeni kategori "Renkler" + GRİ/KAHVERENGİ/ALTIN/GÜMÜŞ/BEJ/LACİVERT çiftleri | 6 yeni çift (pair_id 169-174) Tek kategoriyle gelir; Uzman için 15 çiftten 6'sı bunlardır |
| 48 | Task 18: Yeni kelime "KIZ EVLAT" (boşluklu Türkçe) | Çiftin ingilizcesi "DAUGHTER"; eşleşme doğru; iki kelimelik Türkçe kart üzerinde uygun şekilde render olur |
| 49 | Task 22: Eşleşmiş (yeşil) karta tıkla | Kelime kartı paneli açılır; TR/EN büyük font, telaffuz, örnek cümleler, Dinle butonları görünür |
| 50 | Task 22: WordCardPanel "✖ Kapat" butonu | Panel gizlenir, oyuna dönülür |
| 51 | Task 22: WordCardPanel açıkken ESC tuşu | Panel gizlenir (_unhandled_input ile) |
| 52 | Task 22: WordCardPanel "🔊 Dinle (TR)" butonu | `AudioManager.play_word(turkish)` çağrılır; ses dosyası yoksa sessizce atlanır (crash yok) |
| 53 | Task 22: WordCardPanel "🔊 Listen (EN)" butonu | `AudioManager.play_word(english)` çağrılır; ses dosyası varsa çalar |
| 54 | Task 22: pair_id 1 (KÖPEK/DOG) kartı aç | TR cümle "Köpek çok sadık bir hayvandır."; EN cümle "A dog is a very loyal animal."; pronunciation "dog /dɒɡ/" |
| 55 | Task 22: pair_id 90 (AMCA/UNCLE) kartı aç | TR cümle "Amca tarlada çalışır."; EN cümle "Uncle works in the field."; pronunciation "uncle /ˈʌŋkl/" |
| 56 | Task 24: pair_id 91 (DOKTOR/DOCTOR, professions) kartı aç | TR cümle "Doktor hastaya bakar."; EN cümle "The doctor sees the patient."; pronunciation "doctor /ˈdɒktər/" (Task 24: elle yazılmış, fallback DEĞİL) |
| 57 | Task 24: pair_id 127 (ASLAN/LION, animals ek) kartı aç | TR cümle "Aslan kraldır."; EN cümle "The lion is the king."; pronunciation "lion /ˈlaɪən/" (Task 24: elle yazılmış) |
| 58 | Task 24: pair_id 202 (KIŞ/WINTER, weather ek) kartı aç | TR cümle "Kış soğuk."; EN cümle "Winter is cold."; pronunciation "winter /ˈwɪntər/" (Task 24: elle yazılmış) |
| 59 | Task 24: pair_id 210 (SKUTER/SCOOTER, transport ek) kartı aç | TR cümle "Skuter hızlı."; EN cümle "The scooter is fast."; pronunciation "scooter /ˈskuːtər/" (Task 24: son çift) |
| 60 | Task 24: pair_id 211 (havuz dışı) kartı aç | get_example(211) boş string döner; WordCardPanel yine de açılır, örnek cümleler boş görüntülenir (crash yok) |
| 61 | Task 22: WordCardPanel başlık ve kategori gösterimi | Başlık "📖 Kelime Detayı"; kategori etiketi "{emoji} {label}" (örn. "🐶 Hayvanlar") |
| 62 | Task 22: Eşleşmemiş (açık/kapalı) karta tıkla | WordCardPanel açılmaz (sadece matched kartlar tetikler) |
| 63 | Task 22: Kelime kartı açıkken oyun süresi | Süre devam eder (panel pause yapmaz; opsiyonel geliştirme) |
| 64 | Task 22: GameManager.matched_card_clicked sinyali | Matched kart tıklanınca GameManager'a pair_id relay edilir; Main dinleyip WordCardPanel.show_pair çağırır |
| 65 | Task 22 + Task 24: WordExamples.get_example(0) veya negatif | Boş string değerleri döner (crash yok) |
| 66 | Task 24: WordExamples.get_example_count() | 210 döner (elle yazılmış örnek sayısı — Task 22: 90, Task 24: +120) |
| 67 | Task 24: WordExamples.EXAMPLES.size() | 210 döner (pair_id 1-210 tümü dolu) |
| 68 | Task 24: WordExamples.has_example(91/127/210) | true döner (Task 24 ile elle yazılmış örnekler) |
| 69 | Task 24: WordExamples.has_example(211) | false döner (havuz dışı) |
| 70 | Task 22: Geçersiz pair_id (9999) ile WordCardPanel.show_pair | Panel yine de açılır (crash yok); TR/EN kelime label'da gösterilir; örnek cümleler boş olabilir |

---

## 🧪 Testler (headless)

Üç test betiği var; üçü de Godot'u headless çalıştırır ve **exit code** döndürür (0 = geçti):

```bash
GODOT=/path/to/godot            # örn. C:\Godot\Godot_v4.7.1-stable_win64.exe
P="res://"                      # proje kökü

# 1) Ana test paketi (426 iddia): oyun mantığı, veri, sinyaller, paneller
"$GODOT" --headless --path . --script res://tests/run_tests.gd

# 2) Yerleşim testi: 4 zorlukta TÜM kartların pencere içinde kaldığını ÖLÇER
"$GODOT" --headless --path . --script res://tests/check_layout.gd

# 3) Zorluk seçici testi: butonlar var mı, basınca oyun güncelleniyor mu
"$GODOT" --headless --path . --script res://tests/check_difficulty_ui.gd
```

Neden ayrı betikler: `TestRunner.gd` autoload olarak tasarlanmıştır, bu yüzden
`run_tests.gd` onu root'a ekleyen bir sarmalayıcıdır; diğer ikisi bağımsız
`SceneTree` betikleridir.

> **Ders:** Bu projede tüm testler yeşilken oyun kazanılamıyordu (kartlar ekran
> dışındaydı) — çünkü hiçbir test "kartlar gerçekten görünüyor mu" diye
> bakmıyordu. Yeni özellik eklerken yalnızca mantığı değil, **kullanıcının
> göreceğini** de doğrulayan bir iddia ekle.

## 📦 Windows .exe derleme

```bash
"$GODOT" --headless --path . --export-release "Windows" build/KelimeEslestirme.exe
```

- Preset: `export_presets.cfg` → **Windows** (x86_64, release,
  `binary_format/embed_pck=true` → tek dosya çıktı, ayrı `.pck` yok).
- `exclude_filter="tests/*,autoload/*,tools/*"` → testler, ses üretici ve Godot AI köprüsü oyuna girmez.
- `build/` klasörünü önce oluştur (Godot oluşturmaz, yoksa
  "The given export path doesn't exist" hatası verir).
- Çıktı ~104 MB'tır; Windows export şablonlarının kurulu olması gerekir
  (Editor → Manage Export Templates).

---
## 📜 Lisans

Bu projenin kaynak kodu **MIT lisansı** altındadır — bkz. [LICENSE](LICENSE).
Kısaca: kullanabilir, değiştirebilir, ticari olarak da kullanabilirsiniz;
tek şart telif satırını korumak.

Projede kullanılan üçüncü taraf varlıklar (Poppins yazı tipi, Godot Engine) için
bkz. [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

Ses efektleri bu projede üretilmiştir (`tools/generate_sfx.gd`), dışarıdan
indirilmiş ses örneği yoktur.

İyi oyunlar! 🎉