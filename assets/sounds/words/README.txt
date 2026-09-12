================================================================
 KELİME SES DOSYALARI (Sesli Mod - AUDIO game mode)
================================================================

Bu klasöre kelime ses dosyalarını bırakarak **Sesli Mod**'u
aktif hale getirebilirsiniz. Sesli modda, kullanıcı İngilizce
bir kart seçtiğinde o kelimenin ses dosyası otomatik olarak
çalar. Türkçe karşılığını bularak eşleştirir.

----------------------------------------------------------------
1) DOSYA ADLANDIRMA KURALI
----------------------------------------------------------------
AudioManager._slugify_word() her kelimeyi güvenli bir slug'a
çevirir:
  - Küçük harfe çevirir
  - Türkçe karakterleri ASCII'ye: ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u
  - Boşluk → alt çizgi (_)
  - Sadece a-z, 0-9 ve _ tutar

Örnekler:
  ELMA     -> elma.wav
  KÖPEK    -> kopek.wav
  KİTAP    -> kitap.wav
  ARABA    -> araba.wav
  EKMEK    -> ekmek.wav
  SU       -> su.wav
  AIRPLANE -> airplane.wav
  BROTHER  -> brother.wav

----------------------------------------------------------------
2) DESTEKLENEN FORMATLAR
----------------------------------------------------------------
Öncelik sırasıyla (ilk bulunan çalınır):
  1. .wav  (önerilen, sıkıştırılmamış)
  2. .ogg  (Ogg Vorbis, küçük boyut)
  3. .mp3  (Godot 4'te desteklenir)

Bir kelime için hem .wav hem .ogg varsa .wav çalınır.

----------------------------------------------------------------
3) EKLEME ADIMLARI
----------------------------------------------------------------
  a) İngilizce kelimeler için ses dosyalarını bu klasöre koyun
     (örn. apple.wav, book.wav, house.wav, ...).
  b) Dosya adları slug kuralına uymalı (bkz. yukarıdaki örnekler).
  c) Godot Editor'da Project > Reload Current Project yapın.
     Dosyalar otomatik .import edilir.
  d) "🔊 Sesli Mod" butonuna tıklayın, İngilizce karta tıklayın.
  e) Ses dosyası yoksa oyun sessizce devam eder (hata vermez,
     AudioManager.play_word içinde ResourceLoader.exists ile
     kontrol edilir).

----------------------------------------------------------------
4) ÜCRETSİZ SES KAYNAKLARI (İngilizce telaffuz)
----------------------------------------------------------------
  - https://ttsmp3.com (Text-to-Speech MP3 üretici)
  - https://www.naturalreaders.com (online TTS)
  - https://commons.wikimedia.org (Wiktionary telaffuzları)
  - https://freesound.org (kelime kayıtları)
  - Python + gTTS: pip install gTTS → "gtts-cli 'apple' -o apple.mp3"

----------------------------------------------------------------
5) SES DÜZEYİ
----------------------------------------------------------------
AudioManager.master_volume (0..1) varsayılan 0.6
Kelime sesleri aynı master_volume ile çalınır (flip/match ile
aynı ses seviyesi). Sessize alındıysa (M tuşu) kelime sesleri de
çalmaz.

----------------------------------------------------------------
6) TEST / DEBUG
----------------------------------------------------------------
AudioManager.is_word_loaded(word) -> bool
  Bir kelimenin ses dosyası yüklenmiş mi? (cache kontrolü)
AudioManager.clear_word_cache()
  Tüm kelime cache'ini temizle (yeni dosyalar ekledikten sonra)
================================================================
