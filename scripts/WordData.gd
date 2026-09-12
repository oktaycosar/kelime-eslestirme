# ============================================================
# WordData.gd  (Autoload singleton)
# Merkezi kelime havuzu. 14 kategori × 15 çift = 210 çift.
# ------------------------------------------------------------
# Yapı:
#   {"pair_id": int, "turkish": String, "english": String, "category": String}
# Yeni çift eklemek için diziye yeni bir satır ekleyin.
# pair_id benzersiz olmalıdır.
# category, CATEGORIES içindeki bir id ile eşleşmelidir.
# ------------------------------------------------------------
# Kategoriler (web src/lib/word-data.ts ile birebir parite):
#   1-15    animals     16-30  food      31-45  nature   46-60  house
#   61-75   body        76-90  school    91-105 clothing 106-120 colors
#   121-135 numbers    136-150 family
#   151-165 professions 166-180 emotions 181-195 weather 196-210 transport
# Task 16 (pair_id 91-126): 4 yeni kategori × 9 çift = 36 çift
# Task 18 (pair_id 127-210): her kategori +6 çift → her kategori 15 çift
# ============================================================
extends Node

# --- Kategori sabitleri (web ile parite) ---
const CATEGORY_ANIMALS: String = "animals"
const CATEGORY_FOOD: String = "food"
const CATEGORY_NATURE: String = "nature"
const CATEGORY_HOUSE: String = "house"
const CATEGORY_BODY: String = "body"
const CATEGORY_SCHOOL: String = "school"
const CATEGORY_CLOTHING: String = "clothing"
const CATEGORY_COLORS: String = "colors"
const CATEGORY_NUMBERS: String = "numbers"
const CATEGORY_FAMILY: String = "family"

# Task 16: 4 yeni kategori (Web src/lib/word-data.ts Task 15 paritesi)
const CATEGORY_PROFESSIONS: String = "professions"
const CATEGORY_EMOTIONS: String = "emotions"
const CATEGORY_WEATHER: String = "weather"
const CATEGORY_TRANSPORT: String = "transport"

# --- Kategori meta bilgileri (UI'da gösterim için) ---
# Dictionary yapısı: { id, label, label_en, emoji, description }
const CATEGORIES: Array = [
        { "id": "animals",      "label": "Hayvanlar",    "label_en": "Animals",      "emoji": "🐶",   "description": "Köpek, kedi, kuş ve daha fazlası" },
        { "id": "food",         "label": "Yiyecekler",  "label_en": "Food",         "emoji": "🍎",   "description": "Elma, ekmek, süt ve daha fazlası" },
        { "id": "nature",       "label": "Doğa",        "label_en": "Nature",      "emoji": "🌳",   "description": "Ağaç, güneş, ay ve daha fazlası" },
        { "id": "house",        "label": "Ev & Eşya",   "label_en": "House",       "emoji": "🏠",   "description": "Ev, masa, kapı ve daha fazlası" },
        { "id": "body",         "label": "Vücut",       "label_en": "Body",        "emoji": "👁️",  "description": "Göz, burun, el ve daha fazlası" },
        { "id": "school",       "label": "Okul",        "label_en": "School",      "emoji": "📚",   "description": "Kitap, kalem, öğretmen ve daha fazlası" },
        { "id": "clothing",     "label": "Giyim",       "label_en": "Clothing",    "emoji": "👕",   "description": "Ayakkabı, şapka, çanta ve daha fazlası" },
        { "id": "colors",       "label": "Renkler",     "label_en": "Colors",      "emoji": "🎨",   "description": "Kırmızı, mavi, yeşil ve daha fazlası" },
        { "id": "numbers",      "label": "Sayılar",     "label_en": "Numbers",     "emoji": "🔢",   "description": "Bir, iki, üç ve daha fazlası" },
        { "id": "family",       "label": "Aile",        "label_en": "Family",      "emoji": "👪",   "description": "Anne, baba, kardeş ve daha fazlası" },
        # Task 16: 4 yeni kategori (web Task 15 paritesi)
        { "id": "professions",  "label": "Meslekler",   "label_en": "Professions", "emoji": "👨‍⚕️", "description": "Doktor, hemşire, polis ve daha fazlası" },
        { "id": "emotions",     "label": "Duygular",    "label_en": "Emotions",    "emoji": "😊",   "description": "Mutlu, üzgün, kızgın ve daha fazlası" },
        { "id": "weather",      "label": "Hava Durumu", "label_en": "Weather",     "emoji": "⛅",   "description": "Güneşli, yağmurlu, bulutlu ve daha fazlası" },
        { "id": "transport",    "label": "Ulaşım",      "label_en": "Transport",   "emoji": "🚗",   "description": "Araba, otobüs, tren ve daha fazlası" },
]

# --- 210 çift kelime havuzu (web ile birebir aynı) ---
const WORD_PAIRS: Array = [
        # === ANIMALS (Hayvanlar) ===
        { "pair_id": 1,  "turkish": "KÖPEK",   "english": "DOG",      "category": "animals" },
        { "pair_id": 2,  "turkish": "KEDİ",    "english": "CAT",      "category": "animals" },
        { "pair_id": 3,  "turkish": "KUŞ",    "english": "BIRD",     "category": "animals" },
        { "pair_id": 4,  "turkish": "BALIK",   "english": "FISH",     "category": "animals" },
        { "pair_id": 5,  "turkish": "AT",     "english": "HORSE",    "category": "animals" },
        { "pair_id": 6,  "turkish": "TAVŞAN",  "english": "RABBIT",   "category": "animals" },
        { "pair_id": 7,  "turkish": "TAVUK",   "english": "CHICKEN",  "category": "animals" },
        { "pair_id": 8,  "turkish": "İNEK",   "english": "COW",      "category": "animals" },
        { "pair_id": 9,  "turkish": "ARILAR",  "english": "BEE",      "category": "animals" },
        # === FOOD (Yiyecekler) ===
        { "pair_id": 10, "turkish": "ELMA",    "english": "APPLE",    "category": "food" },
        { "pair_id": 11, "turkish": "EKMEK",   "english": "BREAD",    "category": "food" },
        { "pair_id": 12, "turkish": "SÜT",    "english": "MILK",     "category": "food" },
        { "pair_id": 13, "turkish": "SU",     "english": "WATER",    "category": "food" },
        { "pair_id": 14, "turkish": "PEYNİR",  "english": "CHEESE",   "category": "food" },
        { "pair_id": 15, "turkish": "YUMURTA", "english": "EGG",      "category": "food" },
        { "pair_id": 16, "turkish": "MUZ",    "english": "BANANA",   "category": "food" },
        { "pair_id": 17, "turkish": "PORTAKAL", "english": "ORANGE",  "category": "food" },
        { "pair_id": 18, "turkish": "DOMATES", "english": "TOMATO",   "category": "food" },
        # === NATURE (Doğa) ===
        { "pair_id": 19, "turkish": "AĞAÇ",   "english": "TREE",     "category": "nature" },
        { "pair_id": 20, "turkish": "GÜNEŞ",   "english": "SUN",      "category": "nature" },
        { "pair_id": 21, "turkish": "AY",     "english": "MOON",     "category": "nature" },
        { "pair_id": 22, "turkish": "YILDIZ",  "english": "STAR",     "category": "nature" },
        { "pair_id": 23, "turkish": "ÇİÇEK",   "english": "FLOWER",   "category": "nature" },
        { "pair_id": 24, "turkish": "BULUT",   "english": "CLOUD",    "category": "nature" },
        { "pair_id": 25, "turkish": "YAĞMUR",  "english": "RAIN",     "category": "nature" },
        { "pair_id": 26, "turkish": "KAR",    "english": "SNOW",     "category": "nature" },
        { "pair_id": 27, "turkish": "RÜZGAR",  "english": "WIND",     "category": "nature" },
        # === HOUSE (Ev & Eşya) ===
        { "pair_id": 28, "turkish": "EV",      "english": "HOUSE",    "category": "house" },
        { "pair_id": 29, "turkish": "MASA",    "english": "TABLE",    "category": "house" },
        { "pair_id": 30, "turkish": "SANDALYE", "english": "CHAIR",    "category": "house" },
        { "pair_id": 31, "turkish": "KAPI",    "english": "DOOR",     "category": "house" },
        { "pair_id": 32, "turkish": "PENCERE", "english": "WINDOW",   "category": "house" },
        { "pair_id": 33, "turkish": "SAAT",    "english": "CLOCK",    "category": "house" },
        { "pair_id": 34, "turkish": "YATAK",   "english": "BED",      "category": "house" },
        { "pair_id": 35, "turkish": "LAMBA",   "english": "LAMP",     "category": "house" },
        { "pair_id": 36, "turkish": "AYNA",    "english": "MIRROR",   "category": "house" },
        # === BODY (Vücut) ===
        { "pair_id": 37, "turkish": "GÖZ",    "english": "EYE",      "category": "body" },
        { "pair_id": 38, "turkish": "BURUN",   "english": "NOSE",     "category": "body" },
        { "pair_id": 39, "turkish": "AĞIZ",   "english": "MOUTH",    "category": "body" },
        { "pair_id": 40, "turkish": "KULAK",   "english": "EAR",      "category": "body" },
        { "pair_id": 41, "turkish": "EL",      "english": "HAND",     "category": "body" },
        { "pair_id": 42, "turkish": "AYAK",    "english": "FOOT",     "category": "body" },
        { "pair_id": 43, "turkish": "BAŞ",    "english": "HEAD",     "category": "body" },
        { "pair_id": 44, "turkish": "DİŞ",    "english": "TOOTH",    "category": "body" },
        { "pair_id": 45, "turkish": "SAÇ",    "english": "HAIR",     "category": "body" },
        # === SCHOOL (Okul) ===
        { "pair_id": 46, "turkish": "KİTAP",   "english": "BOOK",     "category": "school" },
        { "pair_id": 47, "turkish": "KALEM",   "english": "PEN",      "category": "school" },
        { "pair_id": 48, "turkish": "OKUL",    "english": "SCHOOL",  "category": "school" },
        { "pair_id": 49, "turkish": "ÖĞRETMEN", "english": "TEACHER", "category": "school" },
        { "pair_id": 50, "turkish": "ÖĞRENCİ", "english": "STUDENT", "category": "school" },
        { "pair_id": 51, "turkish": "DEFTER",  "english": "NOTEBOOK", "category": "school" },
        { "pair_id": 52, "turkish": "SILGI",   "english": "ERASER",   "category": "school" },
        { "pair_id": 53, "turkish": "CETVEL",  "english": "RULER",    "category": "school" },
        { "pair_id": 54, "turkish": "TAHTA",   "english": "BOARD",    "category": "school" },
        # === CLOTHING (Giyim) ===
        { "pair_id": 55, "turkish": "AYAKKABI", "english": "SHOE",    "category": "clothing" },
        { "pair_id": 56, "turkish": "ŞAPKA",   "english": "HAT",      "category": "clothing" },
        { "pair_id": 57, "turkish": "ÇANTA",   "english": "BAG",      "category": "clothing" },
        { "pair_id": 58, "turkish": "GÖMLEK",  "english": "SHIRT",    "category": "clothing" },
        { "pair_id": 59, "turkish": "PANTOLON", "english": "PANTS",   "category": "clothing" },
        { "pair_id": 60, "turkish": "CEKET",   "english": "JACKET",   "category": "clothing" },
        { "pair_id": 61, "turkish": "ÇORAP",   "english": "SOCK",      "category": "clothing" },
        { "pair_id": 62, "turkish": "ELDİVEN", "english": "GLOVE",    "category": "clothing" },
        { "pair_id": 63, "turkish": "ATKI",    "english": "SCARF",     "category": "clothing" },
        # === COLORS (Renkler) ===
        { "pair_id": 64, "turkish": "KIRMIZI", "english": "RED",      "category": "colors" },
        { "pair_id": 65, "turkish": "MAVİ",   "english": "BLUE",     "category": "colors" },
        { "pair_id": 66, "turkish": "YEŞİL",  "english": "GREEN",    "category": "colors" },
        { "pair_id": 67, "turkish": "SARI",   "english": "YELLOW",   "category": "colors" },
        { "pair_id": 68, "turkish": "SİYAH",  "english": "BLACK",    "category": "colors" },
        { "pair_id": 69, "turkish": "BEYAZ",  "english": "WHITE",    "category": "colors" },
        { "pair_id": 70, "turkish": "MOR",    "english": "PURPLE",   "category": "colors" },
        { "pair_id": 71, "turkish": "TURUNCU", "english": "ORANGE",  "category": "colors" },
        { "pair_id": 72, "turkish": "PEMBE",  "english": "PINK",     "category": "colors" },
        # === NUMBERS (Sayılar) ===
        { "pair_id": 73, "turkish": "BİR",    "english": "ONE",      "category": "numbers" },
        { "pair_id": 74, "turkish": "İKİ",   "english": "TWO",      "category": "numbers" },
        { "pair_id": 75, "turkish": "ÜÇ",    "english": "THREE",    "category": "numbers" },
        { "pair_id": 76, "turkish": "DÖRT",   "english": "FOUR",     "category": "numbers" },
        { "pair_id": 77, "turkish": "BEŞ",    "english": "FIVE",     "category": "numbers" },
        { "pair_id": 78, "turkish": "ALTI",   "english": "SIX",      "category": "numbers" },
        { "pair_id": 79, "turkish": "YEDİ",   "english": "SEVEN",    "category": "numbers" },
        { "pair_id": 80, "turkish": "SEKİZ",  "english": "EIGHT",    "category": "numbers" },
        { "pair_id": 81, "turkish": "DOKUZ",  "english": "NINE",     "category": "numbers" },
        # === FAMILY (Aile) ===
        { "pair_id": 82, "turkish": "ANNE",     "english": "MOTHER",       "category": "family" },
        { "pair_id": 83, "turkish": "BABA",     "english": "FATHER",       "category": "family" },
        { "pair_id": 84, "turkish": "KARDEŞ",   "english": "SIBLING",       "category": "family" },
        { "pair_id": 85, "turkish": "ABLA",     "english": "SISTER",        "category": "family" },
        { "pair_id": 86, "turkish": "AĞABEY",   "english": "BROTHER",       "category": "family" },
        { "pair_id": 87, "turkish": "DEDE",     "english": "GRANDFATHER",   "category": "family" },
        { "pair_id": 88, "turkish": "BABAANNE", "english": "GRANDMOTHER",   "category": "family" },
        { "pair_id": 89, "turkish": "TEYZE",    "english": "AUNT",          "category": "family" },
        { "pair_id": 90, "turkish": "AMCA",     "english": "UNCLE",         "category": "family" },
        # === PROFESSIONS (Meslekler) - Task 16 ===
        { "pair_id": 91,  "turkish": "DOKTOR",   "english": "DOCTOR",      "category": "professions" },
        { "pair_id": 92,  "turkish": "HEMŞİRE",   "english": "NURSE",       "category": "professions" },
        { "pair_id": 93,  "turkish": "POLİS",    "english": "POLICE",      "category": "professions" },
        { "pair_id": 94,  "turkish": "İTFAİYE",   "english": "FIREFIGHTER", "category": "professions" },
        { "pair_id": 95,  "turkish": "AŞÇI",     "english": "CHEF",        "category": "professions" },
        { "pair_id": 96,  "turkish": "ŞOFÖR",    "english": "DRIVER",      "category": "professions" },
        { "pair_id": 97,  "turkish": "BERBER",    "english": "BARBER",      "category": "professions" },
        { "pair_id": 98,  "turkish": "MÜHENDİS",  "english": "ENGINEER",    "category": "professions" },
        { "pair_id": 99,  "turkish": "RESSAM",    "english": "PAINTER",     "category": "professions" },
        # === EMOTIONS (Duygular) - Task 16 ===
        { "pair_id": 100, "turkish": "MUTLU",     "english": "HAPPY",       "category": "emotions" },
        { "pair_id": 101, "turkish": "ÜZGÜN",     "english": "SAD",         "category": "emotions" },
        { "pair_id": 102, "turkish": "KIZGIN",    "english": "ANGRY",       "category": "emotions" },
        { "pair_id": 103, "turkish": "KORKMUŞ",   "english": "AFRAID",      "category": "emotions" },
        { "pair_id": 104, "turkish": "ŞAŞKIN",    "english": "SURPRISED",   "category": "emotions" },
        { "pair_id": 105, "turkish": "YORGUN",    "english": "TIRED",       "category": "emotions" },
        { "pair_id": 106, "turkish": "SİKİNTİLİ", "english": "BORED",        "category": "emotions" },
        { "pair_id": 107, "turkish": "HEYECANLI", "english": "EXCITED",      "category": "emotions" },
        { "pair_id": 108, "turkish": "RAHAT",     "english": "CALM",         "category": "emotions" },
        # === WEATHER (Hava Durumu) - Task 16 ===
        { "pair_id": 109, "turkish": "GÜNEŞLİ",   "english": "SUNNY",       "category": "weather" },
        { "pair_id": 110, "turkish": "YAĞMURLU",  "english": "RAINY",       "category": "weather" },
        { "pair_id": 111, "turkish": "BULUTLU",   "english": "CLOUDY",      "category": "weather" },
        { "pair_id": 112, "turkish": "KARLI",     "english": "SNOWY",       "category": "weather" },
        { "pair_id": 113, "turkish": "RÜZGARLI",  "english": "WINDY",       "category": "weather" },
        { "pair_id": 114, "turkish": "SICAK",     "english": "HOT",         "category": "weather" },
        { "pair_id": 115, "turkish": "SOĞUK",     "english": "COLD",         "category": "weather" },
        { "pair_id": 116, "turkish": "FIRTINALI", "english": "STORMY",      "category": "weather" },
        { "pair_id": 117, "turkish": "SİSLİ",     "english": "FOGGY",       "category": "weather" },
        # === TRANSPORT (Ulaşım) - Task 16 ===
        { "pair_id": 118, "turkish": "ARABA",     "english": "CAR",         "category": "transport" },
        { "pair_id": 119, "turkish": "OTOBÜS",    "english": "BUS",         "category": "transport" },
        { "pair_id": 120, "turkish": "TREN",      "english": "TRAIN",       "category": "transport" },
        { "pair_id": 121, "turkish": "UÇAK",      "english": "PLANE",       "category": "transport" },
        { "pair_id": 122, "turkish": "GEMİ",      "english": "SHIP",        "category": "transport" },
        { "pair_id": 123, "turkish": "BİSİKLET",  "english": "BICYCLE",     "category": "transport" },
        { "pair_id": 124, "turkish": "MOTOR",      "english": "MOTORCYCLE",  "category": "transport" },
        { "pair_id": 125, "turkish": "KAMİYON",   "english": "TRUCK",       "category": "transport" },
        { "pair_id": 126, "turkish": "METRO",      "english": "SUBWAY",      "category": "transport" },
        # === Task 18: 84 yeni çift (pair_id 127-210) — her kategori +6 çift → 15 çift ===
        # === ANIMALS ek (127-132) ===
        { "pair_id": 127, "turkish": "ASLAN",    "english": "LION",      "category": "animals" },
        { "pair_id": 128, "turkish": "KAPLAN",   "english": "TIGER",     "category": "animals" },
        { "pair_id": 129, "turkish": "AYI",      "english": "BEAR",      "category": "animals" },
        { "pair_id": 130, "turkish": "FİL",      "english": "ELEPHANT",  "category": "animals" },
        { "pair_id": 131, "turkish": "MAYMUN",   "english": "MONKEY",    "category": "animals" },
        { "pair_id": 132, "turkish": "YILAN",    "english": "SNAKE",     "category": "animals" },
        # === FOOD ek (133-138) ===
        { "pair_id": 133, "turkish": "ÇİKOLATA", "english": "CHOCOLATE", "category": "food" },
        { "pair_id": 134, "turkish": "BAL",      "english": "HONEY",    "category": "food" },
        { "pair_id": 135, "turkish": "ÇAY",      "english": "TEA",       "category": "food" },
        { "pair_id": 136, "turkish": "KAHVE",    "english": "COFFEE",   "category": "food" },
        { "pair_id": 137, "turkish": "ŞEKER",    "english": "SUGAR",    "category": "food" },
        { "pair_id": 138, "turkish": "TUZ",      "english": "SALT",      "category": "food" },
        # === NATURE ek (139-144) ===
        { "pair_id": 139, "turkish": "DAĞ",      "english": "MOUNTAIN", "category": "nature" },
        { "pair_id": 140, "turkish": "DENİZ",    "english": "SEA",      "category": "nature" },
        { "pair_id": 141, "turkish": "GÖL",      "english": "LAKE",     "category": "nature" },
        { "pair_id": 142, "turkish": "NEHİR",    "english": "RIVER",    "category": "nature" },
        { "pair_id": 143, "turkish": "ORMAN",    "english": "FOREST",   "category": "nature" },
        { "pair_id": 144, "turkish": "KUM",      "english": "SAND",      "category": "nature" },
        # === HOUSE ek (145-150) ===
        { "pair_id": 145, "turkish": "HALI",     "english": "CARPET",   "category": "house" },
        { "pair_id": 146, "turkish": "DOLAP",    "english": "CLOSET",   "category": "house" },
        { "pair_id": 147, "turkish": "ÇEKMECE",  "english": "DRAWER",    "category": "house" },
        { "pair_id": 148, "turkish": "ÇÖP",      "english": "TRASH",    "category": "house" },
        { "pair_id": 149, "turkish": "ANAHTAR",  "english": "KEY",      "category": "house" },
        { "pair_id": 150, "turkish": "KİLİT",    "english": "LOCK",      "category": "house" },
        # === BODY ek (151-156) ===
        { "pair_id": 151, "turkish": "BOYUN",    "english": "NECK",     "category": "body" },
        { "pair_id": 152, "turkish": "OMUZ",     "english": "SHOULDER", "category": "body" },
        { "pair_id": 153, "turkish": "KOL",      "english": "ARM",      "category": "body" },
        { "pair_id": 154, "turkish": "BACAK",    "english": "LEG",      "category": "body" },
        { "pair_id": 155, "turkish": "PARMAK",   "english": "FINGER",   "category": "body" },
        { "pair_id": 156, "turkish": "TIRNAK",   "english": "NAIL",     "category": "body" },
        # === SCHOOL ek (157-162) ===
        { "pair_id": 157, "turkish": "SİLMEK",   "english": "ERASE",    "category": "school" },
        { "pair_id": 158, "turkish": "YAZMAK",   "english": "WRITE",    "category": "school" },
        { "pair_id": 159, "turkish": "OKUMAK",   "english": "READ",     "category": "school" },
        { "pair_id": 160, "turkish": "ÖĞRENMEK", "english": "LEARN",    "category": "school" },
        { "pair_id": 161, "turkish": "BİLGİ",    "english": "KNOWLEDGE","category": "school" },
        { "pair_id": 162, "turkish": "DERS",     "english": "LESSON",   "category": "school" },
        # === CLOTHING ek (163-168) ===
        { "pair_id": 163, "turkish": "ETEK",     "english": "SKIRT",    "category": "clothing" },
        { "pair_id": 164, "turkish": "TŞÖRT",    "english": "TSHIRT",   "category": "clothing" },
        { "pair_id": 165, "turkish": "BOT",      "english": "BOOT",    "category": "clothing" },
        { "pair_id": 166, "turkish": "ŞORT",     "english": "SHORTS",   "category": "clothing" },
        { "pair_id": 167, "turkish": "KRAVAT",   "english": "TIE",      "category": "clothing" },
        { "pair_id": 168, "turkish": "KEMER",    "english": "BELT",    "category": "clothing" },
        # === COLORS ek (169-174) ===
        { "pair_id": 169, "turkish": "GRİ",         "english": "GRAY",   "category": "colors" },
        { "pair_id": 170, "turkish": "KAHVERENGİ",  "english": "BROWN",  "category": "colors" },
        { "pair_id": 171, "turkish": "ALTIN",       "english": "GOLD",   "category": "colors" },
        { "pair_id": 172, "turkish": "GÜMÜŞ",       "english": "SILVER", "category": "colors" },
        { "pair_id": 173, "turkish": "BEJ",         "english": "BEIGE",  "category": "colors" },
        { "pair_id": 174, "turkish": "LACİVERT",    "english": "NAVY",   "category": "colors" },
        # === NUMBERS ek (175-180) ===
        { "pair_id": 175, "turkish": "ON",      "english": "TEN",      "category": "numbers" },
        { "pair_id": 176, "turkish": "YİRMİ",   "english": "TWENTY",   "category": "numbers" },
        { "pair_id": 177, "turkish": "OTUZ",    "english": "THIRTY",  "category": "numbers" },
        { "pair_id": 178, "turkish": "KIRK",    "english": "FORTY",   "category": "numbers" },
        { "pair_id": 179, "turkish": "ELLİ",    "english": "FIFTY",   "category": "numbers" },
        { "pair_id": 180, "turkish": "YÜZ",     "english": "HUNDRED",  "category": "numbers" },
        # === FAMILY ek (181-186) ===
        { "pair_id": 181, "turkish": "OĞUL",        "english": "SON",         "category": "family" },
        { "pair_id": 182, "turkish": "KIZ EVLAT",   "english": "DAUGHTER",    "category": "family" },
        { "pair_id": 183, "turkish": "TORUN",       "english": "GRANDCHILD",  "category": "family" },
        { "pair_id": 184, "turkish": "DAMAT",       "english": "GROOM",       "category": "family" },
        { "pair_id": 185, "turkish": "GELİN",       "english": "BRIDE",       "category": "family" },
        { "pair_id": 186, "turkish": "KAYINVALİDE", "english": "MOTHERINLAW", "category": "family" },
        # === PROFESSIONS ek (187-192) ===
        { "pair_id": 187, "turkish": "ÖĞRETMEN", "english": "TEACHER",  "category": "professions" },
        { "pair_id": 188, "turkish": "AVUKAT",   "english": "LAWYER",   "category": "professions" },
        { "pair_id": 189, "turkish": "TÜCCAR",   "english": "MERCHANT", "category": "professions" },
        { "pair_id": 190, "turkish": "ÇİFTÇİ",   "english": "FARMER",   "category": "professions" },
        { "pair_id": 191, "turkish": "ASKER",    "english": "SOLDIER",  "category": "professions" },
        { "pair_id": 192, "turkish": "POSTACI",  "english": "POSTMAN",  "category": "professions" },
        # === EMOTIONS ek (193-198) ===
        { "pair_id": 193, "turkish": "GURURLU",   "english": "PROUD",    "category": "emotions" },
        { "pair_id": 194, "turkish": "KÜSKÜN",   "english": "UPSET",    "category": "emotions" },
        { "pair_id": 195, "turkish": "SABIRLI",  "english": "PATIENT",  "category": "emotions" },
        { "pair_id": 196, "turkish": "CESARETLİ","english": "BRAVE",    "category": "emotions" },
        { "pair_id": 197, "turkish": "UTANGAN",  "english": "SHY",      "category": "emotions" },
        { "pair_id": 198, "turkish": "NEŞELİ",   "english": "CHEERFUL", "category": "emotions" },
        # === WEATHER ek (199-204) ===
        { "pair_id": 199, "turkish": "İLKBAHAR", "english": "SPRING",   "category": "weather" },
        { "pair_id": 200, "turkish": "YAZ",      "english": "SUMMER",   "category": "weather" },
        { "pair_id": 201, "turkish": "SONBAHAR", "english": "AUTUMN",   "category": "weather" },
        { "pair_id": 202, "turkish": "KIŞ",      "english": "WINTER",   "category": "weather" },
        { "pair_id": 203, "turkish": "NEM",      "english": "HUMIDITY", "category": "weather" },
        { "pair_id": 204, "turkish": "ESİNTİ",   "english": "BREEZE",   "category": "weather" },
        # === TRANSPORT ek (205-210) ===
        { "pair_id": 205, "turkish": "TAKSİ",      "english": "TAXI",       "category": "transport" },
        { "pair_id": 206, "turkish": "TRAMVAY",    "english": "TRAM",       "category": "transport" },
        { "pair_id": 207, "turkish": "VAPUR",      "english": "FERRY",      "category": "transport" },
        { "pair_id": 208, "turkish": "HELİKOPTER", "english": "HELICOPTER", "category": "transport" },
        { "pair_id": 209, "turkish": "ROKET",      "english": "ROCKET",     "category": "transport" },
        { "pair_id": 210, "turkish": "SKUTER",     "english": "SCOOTER",    "category": "transport" },
]


# Tüm kategorilerin meta listesini döndür (UI için).
func get_categories() -> Array:
        return CATEGORIES.duplicate(true)


# Kategori id'sinden meta bilgisi döndürür (yoksa boş dict).
func get_category_info(category_id: String) -> Dictionary:
        for c in CATEGORIES:
                if c["id"] == category_id:
                        return c.duplicate(true)
        return {}


# Bir kategoride kaç çift var?
func get_category_pair_count(category_id: String) -> int:
        var n: int = 0
        for p in WORD_PAIRS:
                if p.get("category", "") == category_id:
                        n += 1
        return n


# Belirli kategorilerde toplam kaç çift var?
# categories boş ise tüm havuzun sayısını döndürür.
func get_pool_pair_count(categories: Array = []) -> int:
        if categories.is_empty():
                return WORD_PAIRS.size()
        var n: int = 0
        for p in WORD_PAIRS:
                if categories.has(p.get("category", "")):
                        n += 1
        return n


# Verilen sayıda rastgele çifti döndürür.
# categories boş ise tüm havuzdan, değilse yalnızca seçili kategorilerden seçer.
# count <= 0 ise boş array döner.
# count > havuz boyutu ise havuzun tamamını döndürür.
func get_random_pairs(count: int, categories: Array = []) -> Array:
        var pool: Array = []
        if categories.is_empty():
                pool = WORD_PAIRS.duplicate(true)
        else:
                for p in WORD_PAIRS:
                        if categories.has(p.get("category", "")):
                                pool.append(p.duplicate(true))
        if count <= 0:
                return []
        if pool.is_empty():
                return []
        pool.shuffle()
        var c: int = clampi(count, 1, pool.size())
        return pool.slice(0, c)


# Verilen çift listesinden Türkçe + İngilizce kartları karıştırılmış döndürür.
# Her çift için 2 kart (Türkçe + İngilizce) oluşturulur, toplam 2*len(pairs) kart.
# Kartlar karıştırılır.
# Kart veri yapısı (Dictionary):
#   word      -> String  (örn "APPLE")
#   language  -> String  ("turkish" veya "english")
#   pair_id   -> int
#   category  -> String  (kategori id; web ile parite)
#   is_open   -> bool
#   is_matched-> bool
func build_cards(pairs: Array) -> Array:
        var cards: Array = []
        for pair in pairs:
                var cat: String = pair.get("category", "")
                cards.append({
                        "word": pair["turkish"],
                        "language": "turkish",
                        "pair_id": pair["pair_id"],
                        "category": cat,
                        "is_open": false,
                        "is_matched": false
                })
                cards.append({
                        "word": pair["english"],
                        "language": "english",
                        "pair_id": pair["pair_id"],
                        "category": cat,
                        "is_open": false,
                        "is_matched": false
                })
        cards.shuffle()
        return cards


# Toplam çift sayısı (debug / UI için)
func get_total_pair_count() -> int:
        return WORD_PAIRS.size()


# count çift için yeterli havuz var mı?
func has_enough_pairs(count: int, categories: Array = []) -> bool:
        return get_pool_pair_count(categories) >= count
