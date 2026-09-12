# ============================================================
# WordExamples.gd  (Autoload singleton)
# Eşleşmiş kart tıklanınca açılan kelime öğrenme kartı için
# örnek cümle ve telaffuz verisi (Web Task 21 + 23 paritesi).
# ------------------------------------------------------------
# 210 çift için elle yazılmış örnek cümleler + telaffuz.
# pair_id 1-90   → Task 22 elle yazılmış (animals / food / nature /
#                  house / body / school / clothing / colors /
#                  numbers / family — orijinal 9 kategori × 9 + 1 = 90).
# pair_id 91-210 → Task 24 elle yazılmış (Task 16 + Task 18 çiftleri:
#                  professions / emotions / weather / transport yeni
#                  kategorileri + her kategoriye 6 ek çift — web ile
#                  birebir parite, src/lib/word-examples.ts).
# pair_id > 210 veya WordData'da yoksa → boş string (crash yok).
#
# API:
#   get_example(pair_id: int) -> Dictionary
#     Dönüş: { "tr_sentence": String, "en_sentence": String, "pronunciation": String }
#     pair_id bulunamazsa (WordData'da yoksa) boş string değerleri döner.
#   has_example(pair_id: int) -> bool
#     Elle yazılmış örnek var mı?
#   get_example_count() -> int
#     Elle yazılmış örnek sayısı (210).
#
# Pronunciation formatı:
#   "{word_lower} /{IPA}/" — örn. "dog /dɒɡ/", "doctor /ˈdɒktər/".
#   Godot'ta gerçek IPA fontu olmadığı için basit phonetic gösterim;
#   UTF-8 IPA sembolleri (ɒ, ɪ, ʃ, ˈ, vb.) default font ile render olur
#   ama bazı semboller eksik görünebilir.
# ============================================================
extends Node

# --- Elle yazılmış örnek cümleler (pair_id 1-210) ---
# Yapı: { pair_id: { "tr_sentence", "en_sentence", "pronunciation" } }
const EXAMPLES: Dictionary = {
	# === ANIMALS (1-9) ===
	1:  { "tr_sentence": "Köpek çok sadık bir hayvandır.", "en_sentence": "A dog is a very loyal animal.", "pronunciation": "dog /dɒɡ/" },
	2:  { "tr_sentence": "Kedim sabahtan akşama kadar uyur.", "en_sentence": "My cat sleeps all day long.", "pronunciation": "kæt /kæt/" },
	3:  { "tr_sentence": "Kuş gökyüzünde özgürce uçar.", "en_sentence": "A bird flies freely in the sky.", "pronunciation": "bɜːd /bɜːd/" },
	4:  { "tr_sentence": "Balık suda çok hızlı yüzer.", "en_sentence": "A fish swims very fast in water.", "pronunciation": "fɪʃ /fɪʃ/" },
	5:  { "tr_sentence": "At koşmayı çok sever.", "en_sentence": "A horse loves to run.", "pronunciation": "hɔːs /hɔːs/" },
	6:  { "tr_sentence": "Tavşan havuç yer.", "en_sentence": "A rabbit eats carrots.", "pronunciation": "ræbɪt /ˈræbɪt/" },
	7:  { "tr_sentence": "Tavuk yumurtlar.", "en_sentence": "A chicken lays eggs.", "pronunciation": "tʃɪkɪn /ˈtʃɪkɪn/" },
	8:  { "tr_sentence": "İnek süt verir.", "en_sentence": "A cow gives milk.", "pronunciation": "kaʊ /kaʊ/" },
	9:  { "tr_sentence": "Arı bal yapar.", "en_sentence": "A bee makes honey.", "pronunciation": "biː /biː/" },
	# === FOOD (10-18) ===
	10: { "tr_sentence": "Elma günde bir tane yenir.", "en_sentence": "An apple a day keeps the doctor away.", "pronunciation": "æpl /ˈæpl/" },
	11: { "tr_sentence": "Ekmek sabah kahvaltısında yenir.", "en_sentence": "Bread is eaten at breakfast.", "pronunciation": "bred /bred/" },
	12: { "tr_sentence": "Süt kemiği güçlendirir.", "en_sentence": "Milk strengthens bones.", "pronunciation": "mɪlk /mɪlk/" },
	13: { "tr_sentence": "Su hayattır.", "en_sentence": "Water is life.", "pronunciation": "wɔːtər /ˈwɔːtər/" },
	14: { "tr_sentence": "Peynir makarna ile güzel gider.", "en_sentence": "Cheese goes well with pasta.", "pronunciation": "tʃiːz /tʃiːz/" },
	15: { "tr_sentence": "Yumurta protein kaynağıdır.", "en_sentence": "An egg is a source of protein.", "pronunciation": "eɡ /eɡ/" },
	16: { "tr_sentence": "Muz sarı bir meyvedir.", "en_sentence": "A banana is a yellow fruit.", "pronunciation": "bənænə /bəˈnænə/" },
	17: { "tr_sentence": "Portakal C vitamini içerir.", "en_sentence": "An orange contains vitamin C.", "pronunciation": "ɒrɪndʒ /ˈɒrɪndʒ/" },
	18: { "tr_sentence": "Domates salatada kullanılır.", "en_sentence": "Tomato is used in salad.", "pronunciation": "təmeɪtoʊ /təˈmeɪtoʊ/" },
	# === NATURE (19-27) ===
	19: { "tr_sentence": "Ağaç doğanın akciğerleridir.", "en_sentence": "Trees are the lungs of nature.", "pronunciation": "triː /triː/" },
	20: { "tr_sentence": "Güneş sıcaklık verir.", "en_sentence": "The sun gives warmth.", "pronunciation": "sʌn /sʌn/" },
	21: { "tr_sentence": "Ay geceleri parlar.", "en_sentence": "The moon shines at night.", "pronunciation": "muːn /muːn/" },
	22: { "tr_sentence": "Yıldız gökyüzünde twinkle eder.", "en_sentence": "A star twinkles in the sky.", "pronunciation": "stɑːr /stɑːr/" },
	23: { "tr_sentence": "Çiçek bahçede açtı.", "en_sentence": "The flower bloomed in the garden.", "pronunciation": "flaʊər /ˈflaʊər/" },
	24: { "tr_sentence": "Bulut gökyüzünü kapladı.", "en_sentence": "A cloud covered the sky.", "pronunciation": "klaʊd /klaʊd/" },
	25: { "tr_sentence": "Yağmur toprağı suladı.", "en_sentence": "Rain watered the soil.", "pronunciation": "reɪn /reɪn/" },
	26: { "tr_sentence": "Kar beyaz ve soğuktur.", "en_sentence": "Snow is white and cold.", "pronunciation": "snoʊ /snoʊ/" },
	27: { "tr_sentence": "Rüzgar yaprakları savurur.", "en_sentence": "Wind scatters the leaves.", "pronunciation": "wɪnd /wɪnd/" },
	# === HOUSE (28-36) ===
	28: { "tr_sentence": "Evimiz çok rahat.", "en_sentence": "Our house is very comfortable.", "pronunciation": "haʊs /haʊs/" },
	29: { "tr_sentence": "Masa odanın ortasında.", "en_sentence": "The table is in the middle of the room.", "pronunciation": "teɪbl /ˈteɪbl/" },
	30: { "tr_sentence": "Sandalye ahşaptan yapılmış.", "en_sentence": "The chair is made of wood.", "pronunciation": "tʃeər /tʃeər/" },
	31: { "tr_sentence": "Kapı çalındı.", "en_sentence": "The door was knocked.", "pronunciation": "dɔːr /dɔːr/" },
	32: { "tr_sentence": "Pencereden deniz görünüyor.", "en_sentence": "The sea is visible from the window.", "pronunciation": "wɪndoʊ /ˈwɪndoʊ/" },
	33: { "tr_sentence": "Saat tam oniki.", "en_sentence": "The clock shows exactly twelve.", "pronunciation": "klɒk /klɒk/" },
	34: { "tr_sentence": "Yatak çok geniş.", "en_sentence": "The bed is very wide.", "pronunciation": "bed /bed/" },
	35: { "tr_sentence": "Lamba gece yanar.", "en_sentence": "The lamp burns at night.", "pronunciation": "læmp /læmp/" },
	36: { "tr_sentence": "Ayna duvarda asılı.", "en_sentence": "The mirror hangs on the wall.", "pronunciation": "mɪrər /ˈmɪrər/" },
	# === BODY (37-45) ===
	37: { "tr_sentence": "Gözümü kırpıştırdım.", "en_sentence": "I blinked my eye.", "pronunciation": "aɪ /aɪ/" },
	38: { "tr_sentence": "Burnum koku alır.", "en_sentence": "My nose smells.", "pronunciation": "noʊz /noʊz/" },
	39: { "tr_sentence": "Ağzını aç ve konuş.", "en_sentence": "Open your mouth and speak.", "pronunciation": "maʊθ /maʊθ/" },
	40: { "tr_sentence": "Kulağım müzik duyuyor.", "en_sentence": "My ear hears music.", "pronunciation": "ɪər /ɪr/" },
	41: { "tr_sentence": "Elimi salladım.", "en_sentence": "I waved my hand.", "pronunciation": "hænd /hænd/" },
	42: { "tr_sentence": "Ayakları yorgun.", "en_sentence": "My feet are tired.", "pronunciation": "fiːt /fiːt/" },
	43: { "tr_sentence": "Başım ağrıyor.", "en_sentence": "My head aches.", "pronunciation": "hed /hed/" },
	44: { "tr_sentence": "Diş fırçalamayı unutma.", "en_sentence": "Don't forget to brush your teeth.", "pronunciation": "tiːθ /tiːθ/" },
	45: { "tr_sentence": "Saçını taramalısın.", "en_sentence": "You should comb your hair.", "pronunciation": "heər /her/" },
	# === SCHOOL (46-54) ===
	46: { "tr_sentence": "Kitap okumayı severim.", "en_sentence": "I like to read a book.", "pronunciation": "bʊk /bʊk/" },
	47: { "tr_sentence": "Kalemle yazı yaz.", "en_sentence": "Write with a pencil.", "pronunciation": "pensl /ˈpensl/" },
	48: { "tr_sentence": "Okula gittim.", "en_sentence": "I went to school.", "pronunciation": "skuːl /skuːl/" },
	49: { "tr_sentence": "Öğretmen derse girdi.", "en_sentence": "The teacher entered the class.", "pronunciation": "tiːtʃər /ˈtiːtʃər/" },
	50: { "tr_sentence": "Öğrenci notlarını çalıştı.", "en_sentence": "The student studied the notes.", "pronunciation": "stuːdənt /ˈstuːdənt/" },
	51: { "tr_sentence": "Deftere yazdım.", "en_sentence": "I wrote in the notebook.", "pronunciation": "noʊtbʊk /ˈnoʊtbʊk/" },
	52: { "tr_sentence": "Silgi ile yanlışı sil.", "en_sentence": "Erase the mistake with an eraser.", "pronunciation": "ɪreɪsər /ɪˈreɪsər/" },
	53: { "tr_sentence": "Cetvel ile çizgi çiz.", "en_sentence": "Draw a line with a ruler.", "pronunciation": "ruːlər /ˈruːlər/" },
	54: { "tr_sentence": "Tahtaya yazı yazıldı.", "en_sentence": "It was written on the board.", "pronunciation": "bɔːrd /bɔːrd/" },
	# === CLOTHING (55-63) ===
	55: { "tr_sentence": "Ayakkabıları bağla.", "en_sentence": "Tie your shoes.", "pronunciation": "ʃuːz /ʃuːz/" },
	56: { "tr_sentence": "Şapka güneşten korur.", "en_sentence": "A hat protects from the sun.", "pronunciation": "hæt /hæt/" },
	57: { "tr_sentence": "Çantam ağır.", "en_sentence": "My bag is heavy.", "pronunciation": "bæɡ /bæɡ/" },
	58: { "tr_sentence": "Gömlek ütülenmeli.", "en_sentence": "The shirt should be ironed.", "pronunciation": "ʃɜːrt /ʃɜːrt/" },
	59: { "tr_sentence": "Pantolon yeni.", "en_sentence": "The pants are new.", "pronunciation": "pænts /pænts/" },
	60: { "tr_sentence": "Ceketini giy.", "en_sentence": "Put on your jacket.", "pronunciation": "dʒækɪt /ˈdʒækɪt/" },
	61: { "tr_sentence": "Çorap eşini bulamadım.", "en_sentence": "I couldn't find the sock's pair.", "pronunciation": "sɒk /sɒk/" },
	62: { "tr_sentence": "Eldiveni unutma.", "en_sentence": "Don't forget the glove.", "pronunciation": "ɡlʌv /ɡlʌv/" },
	63: { "tr_sentence": "Atkı boynuma sarılı.", "en_sentence": "The scarf is wrapped around my neck.", "pronunciation": "skɑːrf /skɑːrf/" },
	# === COLORS (64-72) ===
	64: { "tr_sentence": "Kırmızı ışıkta dur.", "en_sentence": "Stop at the red light.", "pronunciation": "red /red/" },
	65: { "tr_sentence": "Mavi denizin rengidir.", "en_sentence": "Blue is the color of the sea.", "pronunciation": "bluː /bluː/" },
	66: { "tr_sentence": "Yeşil doğanın rengidir.", "en_sentence": "Green is the color of nature.", "pronunciation": "ɡriːn /ɡriːn/" },
	67: { "tr_sentence": "Sarı güneş rengi.", "en_sentence": "Yellow is the color of the sun.", "pronunciation": "jeloʊ /ˈjeloʊ/" },
	68: { "tr_sentence": "Siyah gece gibidir.", "en_sentence": "Black is like the night.", "pronunciation": "blæk /blæk/" },
	69: { "tr_sentence": "Beyaz bulutlar gökyüzünde.", "en_sentence": "White clouds are in the sky.", "pronunciation": "waɪt /waɪt/" },
	70: { "tr_sentence": "Mor en sevdiğim renk.", "en_sentence": "Purple is my favorite color.", "pronunciation": "pɜːrpl /ˈpɜːrpl/" },
	71: { "tr_sentence": "Turuncu mevsim rengi.", "en_sentence": "Orange is a seasonal color.", "pronunciation": "ɒrɪndʒ /ˈɒrɪndʒ/" },
	72: { "tr_sentence": "Pembe çiçekler açtı.", "en_sentence": "Pink flowers bloomed.", "pronunciation": "pɪŋk /pɪŋk/" },
	# === NUMBERS (73-81) ===
	73: { "tr_sentence": "Bir elma yedim.", "en_sentence": "I ate one apple.", "pronunciation": "wʌn /wʌn/" },
	74: { "tr_sentence": "İki gözüm var.", "en_sentence": "I have two eyes.", "pronunciation": "tuː /tuː/" },
	75: { "tr_sentence": "Üç kere denedim.", "en_sentence": "I tried three times.", "pronunciation": "θriː /θriː/" },
	76: { "tr_sentence": "Dört mevsim var.", "en_sentence": "There are four seasons.", "pronunciation": "fɔːr /fɔːr/" },
	77: { "tr_sentence": "Beş parmağım var.", "en_sentence": "I have five fingers.", "pronunciation": "faɪv /faɪv/" },
	78: { "tr_sentence": "Altı saat uyudum.", "en_sentence": "I slept six hours.", "pronunciation": "sɪks /sɪks/" },
	79: { "tr_sentence": "Yedi gün bir hafta.", "en_sentence": "Seven days make a week.", "pronunciation": "sevn /ˈsevn/" },
	80: { "tr_sentence": "Sekiz taş saydım.", "en_sentence": "I counted eight stones.", "pronunciation": "eɪt /eɪt/" },
	81: { "tr_sentence": "Dokuz yaşındayım.", "en_sentence": "I am nine years old.", "pronunciation": "naɪn /naɪn/" },
	# === FAMILY (82-90) ===
	82: { "tr_sentence": "Annem yemek yaptı.", "en_sentence": "My mother cooked a meal.", "pronunciation": "mʌðər /ˈmʌðər/" },
	83: { "tr_sentence": "Babam işe gitti.", "en_sentence": "My father went to work.", "pronunciation": "fɑːðər /ˈfɑːðər/" },
	84: { "tr_sentence": "Kardeşim oyun oynuyor.", "en_sentence": "My sibling is playing.", "pronunciation": "sɪblɪŋ /ˈsɪblɪŋ/" },
	85: { "tr_sentence": "Ablam üniversitede.", "en_sentence": "My older sister is at university.", "pronunciation": "sɪstər /ˈsɪstər/" },
	86: { "tr_sentence": "Ağabey spor yapıyor.", "en_sentence": "My older brother is exercising.", "pronunciation": "brʌðər /ˈbrʌðər/" },
	87: { "tr_sentence": "Dede gazete okur.", "en_sentence": "Grandpa reads the newspaper.", "pronunciation": "ɡrænpɑː /ˈɡrænpɑː/" },
	88: { "tr_sentence": "Babaanne kek pişirdi.", "en_sentence": "Grandma baked a cake.", "pronunciation": "ɡrænmɑː /ˈɡrænmɑː/" },
	89: { "tr_sentence": "Teyzem bize geldi.", "en_sentence": "My aunt came to us.", "pronunciation": "ænt /ænt/" },
	90: { "tr_sentence": "Amca tarlada çalışır.", "en_sentence": "Uncle works in the field.", "pronunciation": "ʌŋkl /ˈʌŋkl/" },
	# === PROFESSIONS (91-99) — Task 16 + Task 24 ===
	91: { "tr_sentence": "Doktor hastaya bakar.", "en_sentence": "The doctor sees the patient.", "pronunciation": "doctor /ˈdɒktər/" },
	92: { "tr_sentence": "Hemşire ilaç verir.", "en_sentence": "The nurse gives medicine.", "pronunciation": "nurse /nɜːrs/" },
	93: { "tr_sentence": "Polis güvenliği sağlar.", "en_sentence": "The police keep safety.", "pronunciation": "police /pəˈliːs/" },
	94: { "tr_sentence": "İtfaiye yangın söndürür.", "en_sentence": "Firefighters put out fires.", "pronunciation": "firefighter /ˈfaɪərfaɪtər/" },
	95: { "tr_sentence": "Aşçı yemek yapar.", "en_sentence": "The chef cooks food.", "pronunciation": "chef /ʃef/" },
	96: { "tr_sentence": "Şoför araba kullanır.", "en_sentence": "The driver drives the car.", "pronunciation": "driver /ˈdraɪvər/" },
	97: { "tr_sentence": "Berber saç keser.", "en_sentence": "The barber cuts hair.", "pronunciation": "barber /ˈbɑːrbər/" },
	98: { "tr_sentence": "Mühendis proje yapar.", "en_sentence": "The engineer designs projects.", "pronunciation": "engineer /ˌendʒɪˈnɪər/" },
	99: { "tr_sentence": "Ressam resim yapar.", "en_sentence": "The painter paints pictures.", "pronunciation": "painter /ˈpeɪntər/" },
	# === EMOTIONS (100-108) — Task 16 + Task 24 ===
	100: { "tr_sentence": "Mutluyum.", "en_sentence": "I am happy.", "pronunciation": "happy /ˈhæpi/" },
	101: { "tr_sentence": "Üzgünüm.", "en_sentence": "I am sad.", "pronunciation": "sad /sæd/" },
	102: { "tr_sentence": "Kızgınım.", "en_sentence": "I am angry.", "pronunciation": "angry /ˈæŋɡri/" },
	103: { "tr_sentence": "Korkmuşum.", "en_sentence": "I am afraid.", "pronunciation": "afraid /əˈfreɪd/" },
	104: { "tr_sentence": "Şaşkınım.", "en_sentence": "I am surprised.", "pronunciation": "surprised /sərˈpraɪzd/" },
	105: { "tr_sentence": "Yorgunum.", "en_sentence": "I am tired.", "pronunciation": "tired /ˈtaɪərd/" },
	106: { "tr_sentence": "Sıkıntılıyım.", "en_sentence": "I am bored.", "pronunciation": "bored /bɔːrd/" },
	107: { "tr_sentence": "Heyecanlıyım.", "en_sentence": "I am excited.", "pronunciation": "excited /ɪkˈsaɪtɪd/" },
	108: { "tr_sentence": "Rahatım.", "en_sentence": "I am calm.", "pronunciation": "calm /kɑːm/" },
	# === WEATHER (109-117) — Task 16 + Task 24 ===
	109: { "tr_sentence": "Bugün güneşli.", "en_sentence": "Today is sunny.", "pronunciation": "sunny /ˈsʌni/" },
	110: { "tr_sentence": "Yağmurlu hava.", "en_sentence": "Rainy weather.", "pronunciation": "rainy /ˈreɪni/" },
	111: { "tr_sentence": "Bulutlu gökyüzü.", "en_sentence": "Cloudy sky.", "pronunciation": "cloudy /ˈklaʊdi/" },
	112: { "tr_sentence": "Karlı kış.", "en_sentence": "Snowy winter.", "pronunciation": "snowy /ˈsnoʊi/" },
	113: { "tr_sentence": "Rüzgarlı gün.", "en_sentence": "Windy day.", "pronunciation": "windy /ˈwɪndi/" },
	114: { "tr_sentence": "Sıcak çorba.", "en_sentence": "Hot soup.", "pronunciation": "hot /hɒt/" },
	115: { "tr_sentence": "Soğuk su.", "en_sentence": "Cold water.", "pronunciation": "cold /koʊld/" },
	116: { "tr_sentence": "Fırtınalı gece.", "en_sentence": "Stormy night.", "pronunciation": "stormy /ˈstɔːrmi/" },
	117: { "tr_sentence": "Sisli sabah.", "en_sentence": "Foggy morning.", "pronunciation": "foggy /ˈfɒɡi/" },
	# === TRANSPORT (118-126) — Task 16 + Task 24 ===
	118: { "tr_sentence": "Araba hızlı.", "en_sentence": "The car is fast.", "pronunciation": "car /kɑːr/" },
	119: { "tr_sentence": "Otobüs kalabalık.", "en_sentence": "The bus is crowded.", "pronunciation": "bus /bʌs/" },
	120: { "tr_sentence": "Tren geç geldi.", "en_sentence": "The train arrived late.", "pronunciation": "train /treɪn/" },
	121: { "tr_sentence": "Uçak uçuyor.", "en_sentence": "The plane is flying.", "pronunciation": "plane /pleɪn/" },
	122: { "tr_sentence": "Gemi denizde.", "en_sentence": "The ship is at sea.", "pronunciation": "ship /ʃɪp/" },
	123: { "tr_sentence": "Bisiklet sürüyorum.", "en_sentence": "I ride a bicycle.", "pronunciation": "bicycle /ˈbaɪsɪkəl/" },
	124: { "tr_sentence": "Motor hızlı.", "en_sentence": "The motorcycle is fast.", "pronunciation": "motorcycle /ˈmoʊtərsaɪkəl/" },
	125: { "tr_sentence": "Kamyon büyük.", "en_sentence": "The truck is big.", "pronunciation": "truck /trʌk/" },
	126: { "tr_sentence": "Metro hızlı.", "en_sentence": "The subway is fast.", "pronunciation": "subway /ˈsʌbweɪ/" },
	# === GENİŞLETME (127-210) — her kategoriye 6 ek çift, Task 18 + Task 24 ===
	# --- ANIMALS ek (127-132) ---
	127: { "tr_sentence": "Aslan kraldır.", "en_sentence": "The lion is the king.", "pronunciation": "lion /ˈlaɪən/" },
	128: { "tr_sentence": "Kaplan hızlı koşar.", "en_sentence": "The tiger runs fast.", "pronunciation": "tiger /ˈtaɪɡər/" },
	129: { "tr_sentence": "Ayı bal yer.", "en_sentence": "The bear eats honey.", "pronunciation": "bear /beər/" },
	130: { "tr_sentence": "Fil çok büyüktür.", "en_sentence": "The elephant is very big.", "pronunciation": "elephant /ˈelɪfənt/" },
	131: { "tr_sentence": "Maymun ağaca tırmanır.", "en_sentence": "The monkey climbs the tree.", "pronunciation": "monkey /ˈmʌŋki/" },
	132: { "tr_sentence": "Yılan sürünür.", "en_sentence": "The snake slithers.", "pronunciation": "snake /sneɪk/" },
	# --- FOOD ek (133-138) ---
	133: { "tr_sentence": "Çikolata tatlıdır.", "en_sentence": "Chocolate is sweet.", "pronunciation": "chocolate /ˈtʃɒkələt/" },
	134: { "tr_sentence": "Bal tatlıdır.", "en_sentence": "Honey is sweet.", "pronunciation": "honey /ˈhʌni/" },
	135: { "tr_sentence": "Çay sıcaktır.", "en_sentence": "Tea is hot.", "pronunciation": "tea /tiː/" },
	136: { "tr_sentence": "Kahve kahverengidir.", "en_sentence": "Coffee is brown.", "pronunciation": "coffee /ˈkɒfi/" },
	137: { "tr_sentence": "Şeker tatlıdır.", "en_sentence": "Sugar is sweet.", "pronunciation": "sugar /ˈʃʊɡər/" },
	138: { "tr_sentence": "Tuz tuzludur.", "en_sentence": "Salt is salty.", "pronunciation": "salt /sɒlt/" },
	# --- NATURE ek (139-144) ---
	139: { "tr_sentence": "Dağ çok yüksek.", "en_sentence": "The mountain is very high.", "pronunciation": "mountain /ˈmaʊntən/" },
	140: { "tr_sentence": "Deniz mavi.", "en_sentence": "The sea is blue.", "pronunciation": "sea /siː/" },
	141: { "tr_sentence": "Göl durgun.", "en_sentence": "The lake is calm.", "pronunciation": "lake /leɪk/" },
	142: { "tr_sentence": "Nehir akıyor.", "en_sentence": "The river flows.", "pronunciation": "river /ˈrɪvər/" },
	143: { "tr_sentence": "Orman karanlık.", "en_sentence": "The forest is dark.", "pronunciation": "forest /ˈfɒrɪst/" },
	144: { "tr_sentence": "Kum sıcak.", "en_sentence": "The sand is hot.", "pronunciation": "sand /sænd/" },
	# --- HOUSE ek (145-150) ---
	145: { "tr_sentence": "Halı yumuşak.", "en_sentence": "The carpet is soft.", "pronunciation": "carpet /ˈkɑːrpɪt/" },
	146: { "tr_sentence": "Dolap dolu.", "en_sentence": "The closet is full.", "pronunciation": "closet /ˈklɒzət/" },
	147: { "tr_sentence": "Çekmece açık.", "en_sentence": "The drawer is open.", "pronunciation": "drawer /ˈdrɔːər/" },
	148: { "tr_sentence": "Çöp kokuyor.", "en_sentence": "The trash smells.", "pronunciation": "trash /træʃ/" },
	149: { "tr_sentence": "Anahtar kayboldu.", "en_sentence": "The key is lost.", "pronunciation": "key /kiː/" },
	150: { "tr_sentence": "Kilit kapalı.", "en_sentence": "The lock is closed.", "pronunciation": "lock /lɒk/" },
	# --- BODY ek (151-156) ---
	151: { "tr_sentence": "Boynum ağrıyor.", "en_sentence": "My neck hurts.", "pronunciation": "neck /nek/" },
	152: { "tr_sentence": "Omuz geniş.", "en_sentence": "The shoulder is broad.", "pronunciation": "shoulder /ˈʃoʊldər/" },
	153: { "tr_sentence": "Kol uzun.", "en_sentence": "The arm is long.", "pronunciation": "arm /ɑːrm/" },
	154: { "tr_sentence": "Bacak yorgun.", "en_sentence": "The leg is tired.", "pronunciation": "leg /leɡ/" },
	155: { "tr_sentence": "Parmak kesildi.", "en_sentence": "The finger is cut.", "pronunciation": "finger /ˈfɪŋɡər/" },
	156: { "tr_sentence": "Tırnak uzadı.", "en_sentence": "The nail grew.", "pronunciation": "nail /neɪl/" },
	# --- SCHOOL ek (157-162) ---
	157: { "tr_sentence": "Silgi ile sil.", "en_sentence": "Erase with eraser.", "pronunciation": "erase /ɪˈreɪs/" },
	158: { "tr_sentence": "Yazmak kolay.", "en_sentence": "Writing is easy.", "pronunciation": "write /raɪt/" },
	159: { "tr_sentence": "Okumak güzel.", "en_sentence": "Reading is nice.", "pronunciation": "read /riːd/" },
	160: { "tr_sentence": "Öğrenmek önemli.", "en_sentence": "Learning is important.", "pronunciation": "learn /lɜːrn/" },
	161: { "tr_sentence": "Bilgi güçtür.", "en_sentence": "Knowledge is power.", "pronunciation": "knowledge /ˈnɒlɪdʒ/" },
	162: { "tr_sentence": "Ders zor.", "en_sentence": "The lesson is hard.", "pronunciation": "lesson /ˈlesən/" },
	# --- CLOTHING ek (163-168) ---
	163: { "tr_sentence": "Etek uzun.", "en_sentence": "The skirt is long.", "pronunciation": "skirt /skɜːrt/" },
	164: { "tr_sentence": "Tşört pamuklu.", "en_sentence": "The tshirt is cotton.", "pronunciation": "tshirt /ˈtiːʃɜːrt/" },
	165: { "tr_sentence": "Bot deri.", "en_sentence": "The boot is leather.", "pronunciation": "boot /buːt/" },
	166: { "tr_sentence": "Şort kısa.", "en_sentence": "The shorts are short.", "pronunciation": "shorts /ʃɔːrts/" },
	167: { "tr_sentence": "Kravat renkli.", "en_sentence": "The tie is colorful.", "pronunciation": "tie /taɪ/" },
	168: { "tr_sentence": "Kemer deri.", "en_sentence": "The belt is leather.", "pronunciation": "belt /belt/" },
	# --- COLORS ek (169-174) ---
	169: { "tr_sentence": "Gri bulut.", "en_sentence": "Gray cloud.", "pronunciation": "gray /ɡreɪ/" },
	170: { "tr_sentence": "Kahverengi toprak.", "en_sentence": "Brown earth.", "pronunciation": "brown /braʊn/" },
	171: { "tr_sentence": "Altın parlar.", "en_sentence": "Gold shines.", "pronunciation": "gold /ɡoʊld/" },
	172: { "tr_sentence": "Gümüş değerli.", "en_sentence": "Silver is precious.", "pronunciation": "silver /ˈsɪlvər/" },
	173: { "tr_sentence": "Bej nötr.", "en_sentence": "Beige is neutral.", "pronunciation": "beige /beɪʒ/" },
	174: { "tr_sentence": "Lacivert koyu.", "en_sentence": "Navy is dark.", "pronunciation": "navy /ˈneɪvi/" },
	# --- NUMBERS ek (175-180) ---
	175: { "tr_sentence": "On parmak.", "en_sentence": "Ten fingers.", "pronunciation": "ten /ten/" },
	176: { "tr_sentence": "Yirmi kişi.", "en_sentence": "Twenty people.", "pronunciation": "twenty /ˈtwenti/" },
	177: { "tr_sentence": "Otuz gün.", "en_sentence": "Thirty days.", "pronunciation": "thirty /ˈθɜːrti/" },
	178: { "tr_sentence": "Kırk yıl.", "en_sentence": "Forty years.", "pronunciation": "forty /ˈfɔːrti/" },
	179: { "tr_sentence": "Elli kilo.", "en_sentence": "Fifty kilos.", "pronunciation": "fifty /ˈfɪfti/" },
	180: { "tr_sentence": "Yüz yıl.", "en_sentence": "Hundred years.", "pronunciation": "hundred /ˈhʌndrəd/" },
	# --- FAMILY ek (181-186) ---
	181: { "tr_sentence": "Oğlum okulda.", "en_sentence": "My son is at school.", "pronunciation": "son /sʌn/" },
	182: { "tr_sentence": "Kızım güzel.", "en_sentence": "My daughter is beautiful.", "pronunciation": "daughter /ˈdɔːtər/" },
	183: { "tr_sentence": "Torum sevimli.", "en_sentence": "The grandchild is cute.", "pronunciation": "grandchild /ˈɡræntʃaɪld/" },
	184: { "tr_sentence": "Damat genç.", "en_sentence": "The groom is young.", "pronunciation": "groom /ɡruːm/" },
	185: { "tr_sentence": "Gelin güzel.", "en_sentence": "The bride is beautiful.", "pronunciation": "bride /braɪd/" },
	186: { "tr_sentence": "Kayınvalide tatlı.", "en_sentence": "Motherinlaw is sweet.", "pronunciation": "motherinlaw /ˈmʌðərɪnlɔː/" },
	# --- PROFESSIONS ek (187-192) ---
	187: { "tr_sentence": "Öğretmen anlatır.", "en_sentence": "The teacher explains.", "pronunciation": "teacher /ˈtiːtʃər/" },
	188: { "tr_sentence": "Avukat savunur.", "en_sentence": "The lawyer defends.", "pronunciation": "lawyer /ˈlɔːjər/" },
	189: { "tr_sentence": "Tüccar satar.", "en_sentence": "The merchant sells.", "pronunciation": "merchant /ˈmɜːrtʃənt/" },
	190: { "tr_sentence": "Çiftçi eker.", "en_sentence": "The farmer plants.", "pronunciation": "farmer /ˈfɑːrmər/" },
	191: { "tr_sentence": "Asker korur.", "en_sentence": "The soldier protects.", "pronunciation": "soldier /ˈsoʊldʒər/" },
	192: { "tr_sentence": "Postacı mektup getirir.", "en_sentence": "The postman brings mail.", "pronunciation": "postman /ˈpoʊstmən/" },
	# --- EMOTIONS ek (193-198) ---
	193: { "tr_sentence": "Gururluyum.", "en_sentence": "I am proud.", "pronunciation": "proud /praʊd/" },
	194: { "tr_sentence": "Küskünüm.", "en_sentence": "I am upset.", "pronunciation": "upset /ʌpˈset/" },
	195: { "tr_sentence": "Sabırlıyım.", "en_sentence": "I am patient.", "pronunciation": "patient /ˈpeɪʃənt/" },
	196: { "tr_sentence": "Cesaretliyim.", "en_sentence": "I am brave.", "pronunciation": "brave /breɪv/" },
	197: { "tr_sentence": "Utanganım.", "en_sentence": "I am shy.", "pronunciation": "shy /ʃaɪ/" },
	198: { "tr_sentence": "Neşeliyim.", "en_sentence": "I am cheerful.", "pronunciation": "cheerful /ˈtʃɪərfəl/" },
	# --- WEATHER ek (199-204) ---
	199: { "tr_sentence": "İlkbahar geldi.", "en_sentence": "Spring has come.", "pronunciation": "spring /sprɪŋ/" },
	200: { "tr_sentence": "Yaz sıcak.", "en_sentence": "Summer is hot.", "pronunciation": "summer /ˈsʌmər/" },
	201: { "tr_sentence": "Sonbahar renkli.", "en_sentence": "Autumn is colorful.", "pronunciation": "autumn /ˈɔːtəm/" },
	202: { "tr_sentence": "Kış soğuk.", "en_sentence": "Winter is cold.", "pronunciation": "winter /ˈwɪntər/" },
	203: { "tr_sentence": "Nem yüksek.", "en_sentence": "Humidity is high.", "pronunciation": "humidity /hjuːˈmɪdəti/" },
	204: { "tr_sentence": "Esinti serin.", "en_sentence": "The breeze is cool.", "pronunciation": "breeze /briːz/" },
	# --- TRANSPORT ek (205-210) ---
	205: { "tr_sentence": "Taksi sarı.", "en_sentence": "The taxi is yellow.", "pronunciation": "taxi /ˈtæksi/" },
	206: { "tr_sentence": "Tramvay şehirde.", "en_sentence": "The tram is in the city.", "pronunciation": "tram /træm/" },
	207: { "tr_sentence": "Vapur denizde.", "en_sentence": "The ferry is at sea.", "pronunciation": "ferry /ˈferi/" },
	208: { "tr_sentence": "Helikopter uçuyor.", "en_sentence": "The helicopter flies.", "pronunciation": "helicopter /ˈhelɪkɒptər/" },
	209: { "tr_sentence": "Roket fırlar.", "en_sentence": "The rocket launches.", "pronunciation": "rocket /ˈrɒkɪt/" },
	210: { "tr_sentence": "Skuter hızlı.", "en_sentence": "The scooter is fast.", "pronunciation": "scooter /ˈskuːtər/" },
}


# Verilen pair_id için örnek cümle ve telaffuz döndür.
# Elle yazılmış veri (EXAMPLES) yoksa fallback üretilir.
# Dönüş Dictionary'si her zaman şu 3 anahtarı içerir:
#   "tr_sentence" : String
#   "en_sentence" : String
#   "pronunciation": String
# pair_id <= 0 ise boş string değerleri döner (crash yok).
# pair_id > 210 (WordData havuz dışı) ise _find_pair boş döner →
# boş string değerleri döner (crash yok).
func get_example(pair_id: int) -> Dictionary:
	if pair_id <= 0:
		return { "tr_sentence": "", "en_sentence": "", "pronunciation": "" }
	if EXAMPLES.has(pair_id):
		var ex: Dictionary = EXAMPLES[pair_id]
		return {
			"tr_sentence": String(ex.get("tr_sentence", "")),
			"en_sentence": String(ex.get("en_sentence", "")),
			"pronunciation": String(ex.get("pronunciation", "")),
		}
	# Fallback: WordData'dan çifti bul (pair_id WordData'da var ama
	# EXAMPLES'ta yoksa — şu an 1-210 tamamen dolu olduğu için bu yol
	# sadece WordData çift sayısı > 210 olursa çalışır).
	var pair: Dictionary = _find_pair(pair_id)
	if pair.is_empty():
		return { "tr_sentence": "", "en_sentence": "", "pronunciation": "" }
	return _generate_fallback(pair)


# Bu pair_id için elle yazılmış örnek var mı?
func has_example(pair_id: int) -> bool:
	return EXAMPLES.has(pair_id)


# Elle yazılmış örnek sayısı (210).
func get_example_count() -> int:
	return EXAMPLES.size()


# WordData.WORD_PAIRS içinden pair_id'yi arar (yardımcı fonksiyon).
# Boş Dictionary dönerse bulunamadı demektir.
func _find_pair(pair_id: int) -> Dictionary:
	if WordData == null:
		return {}
	for p in WordData.WORD_PAIRS:
		if int(p.get("pair_id", -1)) == pair_id:
			return p
	return {}


# WordData çifti var ama EXAMPLES'ta yoksa otomatik örnek üretir
# (defensive: şu an 1-210 tamamen dolu; gelecekte havuz genişlerse
# yeni çiftler için geçici çözüm).
# tr_sentence : "{TR} öğreniyorum." (uzunsa "{TR} kelimesini biliyorum.")
# en_sentence : "I am learning {EN}." (uzunsa "{EN} is a new word.")
# pronunciation: "/{en_lower}/" (basit gösterim)
func _generate_fallback(pair: Dictionary) -> Dictionary:
	var tr: String = String(pair.get("turkish", ""))
	var en: String = String(pair.get("english", ""))
	var tr_sentence: String = ""
	var en_sentence: String = ""
	if tr.length() > 10:
		tr_sentence = "%s kelimesini biliyorum." % tr
	else:
		tr_sentence = "%s öğreniyorum." % tr
	if en.length() > 10:
		en_sentence = "%s is a new word." % en.capitalize()
	else:
		en_sentence = "I am learning %s." % en.to_lower()
	var pron: String = "/%s/" % en.to_lower()
	return {
		"tr_sentence": tr_sentence,
		"en_sentence": en_sentence,
		"pronunciation": pron,
	}
