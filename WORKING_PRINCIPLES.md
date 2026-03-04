# 🎯 ÇALIŞMA PRENSİPLERİ

## 📝 TEMEL KURALLAR

### 1. Dosya Düzenleme
- **ASLA** tüm dosyayı yeniden yazma
- **HER ZAMAN** sadece değişen kısımları göster
- **ÖNCE** dosyayı oku, sonra düzenle

### 2. Edit Araçları
- **Tek satır:** `single_find_and_replace`
- **Çok satır:** `edit_existing_file` (sadece değişen kısımlar)
- **Okuma:** `read_file` / `read_file_range`

### 3. Atomic Design
- **Atoms:** En küçük bileşenler (Button, Label)
- **Molecules:** Atom grupları (SearchBar, Card)
- **Organisms:** Molekül grupları (Header, Sidebar)
- **Systems:** Organizma grupları (SaveSystem, UITestManager)

## 🛠️ PRATİK REHBER

### Single Find & Replace
```gdscript
# DOĞRU:
single_find_and_replace("dosya.gd", "eski_kod", "yeni_kod")

# old_string benzersiz olmalı!
```

### Edit Existing File
```gdscript
# DOĞRU - Minimal:
edit_existing_file("dosya.gd", """
func example() -> void:
    // ... existing code ...
    
    {{ modified code here }}
    
    // ... rest of function ...
""")
```

### Atomic Design Örneği
```
src/ui/atoms/button_atom.gd          # Atom
src/ui/molecules/search_bar.gd       # Molekül  
src/ui/organisms/header_organism.gd  # Organism
src/ui/systems/main_menu.gd          # System
```

## 📁 DOSYA YAPISI

### Standart Dizinler
```
src/
├── ui/                    # UI bileşenleri
│   ├── atoms/            # Atomlar
│   ├── molecules/        # Moleküller
│   ├── organisms/        # Organizmalar
│   └── systems/          # Sistemler
├── core/                 # Core sistemler
│   ├── systems/          # Game sistemleri
│   └── components/       # Gameplay bileşenleri
└── test/                 # Testler
    ├── modules/          # Test modülleri
    └── systems/          # Sistem testleri
```

### Test Yapısı
```
src/test/
├── ui_test_manager.gd           # Ana test sistemi
├── modules/
│   ├── ui_test_base.gd          # Temel test sınıfı (Atom)
│   ├── mainmenu_test_module.gd  # Test modülü (Organism)
│   └── ui_test_orchestrator.gd  # Test koordinatörü (System)
└── systems/
    └── save_system/
        ├── test/                # SaveSystem testleri
        └── save_manager.gd      # SaveSystem
```

## 🔧 KOD STANDARTLARI

### Import Düzeni
```gdscript
# 1. Class tanımı
# 2. Import'lar
# 3. Sabitler
# 4. Değişkenler (@onready önce)
# 5. Fonksiyonlar (_ready, _process, public, private)
```

### Fonksiyon Yapısı
```gdscript
# DOĞRU:
func function_name(param: Type) -> ReturnType:
    """Kısa açıklama"""
    # Kod
    return value

# Tip belirt, açıklama ekle
```

### Değişken İsimlendirme
- `snake_case` kullan
- Anlamlı isimler seç
- Türkçe karakter YOK

## 🚨 HATA ÖNLEME

### Düzenleme Öncesi Checklist
1. [ ] Dosyayı okudum mu? (`read_file`)
2. [ ] Benzersiz string buldum mu?
3. [ ] Minimal değişiklik planladım mı?

### Hata Durumunda
1. Hata mesajını oku
2. Nedenini bul
3. Alternatif yöntem dene

## 📋 ÖRNEK WORKFLOW

### Senaryo: SaveSystem Testi Ekleme
1. **Analiz:** Mevcut test yapısını oku
2. **Plan:** Atomic Design'e uygun modüller oluştur
3. **Uygula:**
   - `save_test_base.gd` (Atom)
   - `save_unit_tests.gd` (Molecule)
   - `save_test_orchestrator.gd` (Organism)
4. **Entegre:** UI Test Orchestrator'a ekle
5. **Test:** F12/Ctrl+Shift+S ile çalıştır

## 🎯 HATIRLATICILAR

- **Minimal değişiklik** her zaman daha iyi
- **Önce oku**, sonra yaz
- **Atomic Design** prensiplerine uy
- **Test edilebilir** kod yaz
- **Benzersiz string** bul

---

*Bu dosya pratik çalışma için referans olarak kullanılacaktır.*
*Gerektikçe güncellenecektir.*