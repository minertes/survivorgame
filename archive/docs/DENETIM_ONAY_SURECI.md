# Denetim ve Onay Süreci

**Amaç:** UI/UX ve görsel değişikliklerde kalite kontrolü; “görsel rezalet” ve tutarsız arayüzün önlenmesi.

**Kapsam:** Yeni ekran, mağaza, lobi, menü veya öne çıkan UI güncellemesi.

---

## 1. Roller

| Rol | Kim | Sorumluluk |
|-----|-----|------------|
| **Görsel Tasarım Denetimi** | Tasarımcı veya atanmış kişi | Checklist doldurur; renk, font, hizalama, boşluk, responsive kontrolü. |
| **Frontend Lead** | Frontend/UI sorumlusu | Değişikliğin merge/release öncesi onayı; tutarlılık ve teknik UI kalitesi. |

*Küçük ekipte aynı kişi her iki rolü de üstlenebilir; önemli olan adımların atlanmamasıdır.*

---

## 2. Akış (Her UI Değişikliğinde)

```
[Değişiklik yapıldı] → [Görsel checklist doldurulur] → [Frontend lead onayı] → [Merge/Release]
```

1. **Görsel tasarım checklist**  
   `docs/GORSEL_TASARIM_CHECKLIST.md` dosyasındaki ilgili bölüm (veya ekran adı) doldurulur.  
   Tüm maddeler “Evet” veya “N/A” olmalı; “Hayır” varsa düzeltilip tekrar kontrol edilir.

2. **Frontend lead onayı**  
   - PR açıldıysa: PR açıklamasında “Görsel checklist tamamlandı” yazılır; Frontend lead review ister, onaylar.  
   - PR yoksa: `docs/GORSEL_TASARIM_CHECKLIST.md` içinde ilgili ekranın “Onay” satırına tarih ve (varsa) onaylayan isim yazılır.

3. **Merge / Release**  
   Onay alındıktan sonra değişiklik merge edilir veya release’e dahil edilir.

---

## 3. Ne Zaman Uygulanır

- Yeni ekran (menü, lobi, mağaza, ayarlar, game over vb.)
- Mevcut ekranın görsel/yerleşim değişikliği (layout, renk, font, bileşen ekleme)
- Yeni UI bileşeni (buton seti, kart, modal) oyun genelinde kullanılacaksa

**Uygulanmaz:** Sadece bug fix (görsel değişiklik yok), sadece backend/veri değişikliği, sadece config/değer güncellemesi.

---

## 4. Onay Kaydı

Checklist’te her ekran için “Onay” satırı:

- **Tarih:** GG.AA.YYYY
- **Onaylayan:** Frontend Lead (veya atanmış kişi) adı/rumuzu

Örnek: `Onay: 05.03.2026 – [Frontend Lead]`

---

## 5. İlişkili Belgeler

- **Birleşik plan:** `UYGULAMA_PLANI_BIRLESIK.md` → “Denetim ve Onay Süreçleri”
- **Checklist:** `docs/GORSEL_TASARIM_CHECKLIST.md`
