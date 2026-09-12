# Üçüncü Taraf Bildirimleri

Bu projenin kendi kaynak kodu **MIT** lisansı altındadır — bkz. [LICENSE](LICENSE).

Projede kullanılan üçüncü taraf varlıklar aşağıdadır ve kendi lisanslarına tabidir.
Bunların bildirimleri, ilgili lisansların şartı olduğu için dağıtıma dahil edilmelidir.

---

## Poppins (yazı tipi) — SIL Open Font License 1.1

| | |
|---|---|
| Dosyalar | `assets/fonts/Poppins-Bold.ttf`, `assets/fonts/Poppins-SemiBold.ttf` |
| Telif | Copyright 2020 The Poppins Project Authors (https://github.com/itfoundry/Poppins) |
| Lisans metni | [`assets/fonts/OFL-Poppins.txt`](assets/fonts/OFL-Poppins.txt) |

OFL 1.1 şartları:

- Lisans metni ve telif bildirimi dağıtıma dahil edilmelidir (bu depoda mevcuttur).
- Yazı tipi **tek başına satılamaz**.
- Değiştirilmiş sürümler "Poppins" adını kullanamaz (Reserved Font Name).

## Godot Engine — MIT License

- Bu oyun Godot Engine 4 ile geliştirilmiştir; dışa aktarılan `.exe` Godot
  motorunu gömülü olarak içerir.
- Copyright (c) 2014-present Godot Engine contributors
- Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur
- Lisans: https://godotengine.org/license

Godot'un MIT lisansı telif bildiriminin dağıtıma dahil edilmesini gerektirir.
Dışa aktarılan sürümlerde bu dosya (veya Godot lisans metni) oyunla birlikte verilmelidir.

---

## Bu projede üretilen varlıklar (üçüncü taraf değil)

- **Ses efektleri** (`assets/sounds/*.wav`) — [`tools/generate_sfx.gd`](tools/generate_sfx.gd)
  ile sinüs dalgalarından sentezlenerek üretilmiştir. Dışarıdan indirilmiş hiçbir
  ses örneği yoktur; üçüncü taraf telif hakkı veya atıf yükümlülüğü doğurmaz.
- **Kelime verisi ve örnek cümleler** (`scripts/WordData.gd`, `scripts/WordExamples.gd`)
  — bu proje için yazılmıştır.