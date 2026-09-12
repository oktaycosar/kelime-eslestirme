================================================================
 SES DOSYALARI NASIL EKLENİR
================================================================

Bu klasöre gerçek ses dosyalarını bırakarak oyunu sesli
hale getirebilirsiniz. Mevcut .txt dosyaları PLACEHOLDER
(yer tutucu) olarak bırakılmıştır. Çalışma anında
AudioManager.gd bu dosyaları güvenli şekilde yüklemeye
çalışır; dosya yoksa oyun sessizce devam eder, hata vermez.

----------------------------------------------------------------
1) GEREKLİ DOSYALAR
----------------------------------------------------------------
  flip.wav   -> Kart açma sesi (kısa tık/kart dönme efekti)
  match.wav  -> Doğru eşleşme sesi (olumlu "ding" efekti)
  wrong.wav  -> Yanlış eşleşme sesi (kısa "buzz" efekti)
  win.wav    -> Oyun kazanma sesi (uzun triumfan melodiesi)

----------------------------------------------------------------
2) DESTEKLENEN FORMATLAR
----------------------------------------------------------------
  - .wav   (önerilen, sıkıştırılmamış)
  - .ogg   (Ogg Vorbis, küçük boyut)
  - .mp3   (Godot 4'te desteklenir)

----------------------------------------------------------------
3) EKLEME ADIMLARI
----------------------------------------------------------------
  a) Yukarıdaki 4 dosyayı .txt yerine .wav/.ogg olarak
     bu klasöre koyun. (placeholder .txt'leri silebilirsiniz)
  b) AudioManager.gd içindeki *_PATH sabitlerini güncelleyin:

        const FLIP_PATH  = "res://assets/sounds/flip.wav"
        const MATCH_PATH = "res://assets/sounds/match.wav"
        const WRONG_PATH = "res://assets/sounds/wrong.wav"
        const WIN_PATH   = "res://assets/sounds/win.wav"

     Dosya uzantısı .ogg ise yolu buna göre değiştirin:
        const FLIP_PATH  = "res://assets/sounds/flip.ogg"

  c) Godot Editor'da Project > Reload Current Project yapın.
     Dosyalar otomatik .import edilir.
  d) AudioManager, ResourceLoader.exists() ile her dosyanın
     varlığını kontrol eder; bulunamazsa push_warning ile
     uyarı verir ama oyun çökmez.

----------------------------------------------------------------
4) SES DÜZEYİ
----------------------------------------------------------------
  AudioManager.master_volume (0..1) varsayılan 0.6
  Degistirmek için:
        AudioManager.set_master_volume(0.8)

----------------------------------------------------------------
5) ÜCRETSİZ SES KAYNAKLARI
----------------------------------------------------------------
  - https://opengameart.org
  - https://freesound.org
  - https://mixkit.co/free-sound-effects/
  - https://www.zapsplat.com

----------------------------------------------------------------
NOT: Türkçe karakter destekleri dosya adında DEĞİL, sadece
içeriğin ses formatındadır. Dosya adlarında Türkçe karakter
KULLANMAYIN: örn "yanlış.wav" yerine "wrong.wav".
================================================================
