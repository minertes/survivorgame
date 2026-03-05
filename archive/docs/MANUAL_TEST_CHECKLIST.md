# Faz 6.1.4 – Manuel Test Senaryoları

Yayın öncesi ve patch sonrası kontrol listesi.

**UI değişikliği varsa:** Önce `docs/GORSEL_TASARIM_CHECKLIST.md` doldurulur ve `docs/DENETIM_ONAY_SURECI.md` uyarınca Frontend lead onayı alınır.

## Genel

- [ ] Oyun sorunsuz açılıyor (menü yükleniyor)
- [ ] Çıkış butonu çalışıyor
- [ ] F11 / tam ekran (varsa) çalışıyor

## Ekranlar

- [ ] **Menü:** Başla, Mağaza, Liderlik & Başarılar, Ses, Çıkış butonları tıklanıyor
- [ ] **Lobi:** Karakter/silah/bayrak seçimi, istatistikler görünüyor, Oyna butonu
- [ ] **Oyun:** HUD (dalga, can, skor), pause, game over ekranı
- [ ] **Mağaza:** Elmas bakiyesi, ürün listesi, Satın Al (test/sandbox), Ana Menü
- [ ] **Liderlik & Başarılar:** Günlük/Haftalık sekmesi, Başarılar listesi, Günlük ödül claim
- [ ] **Ayarlar:** Ses aç/kapa kalıcı

## Ses

- [ ] Menü müziği çalıyor (açıksa)
- [ ] Oyun içi müzik (açıksa)
- [ ] SFX: ateş, hasar, ölüm, level up (varsa)
- [ ] Ses ayarı değişince anında yansıyor

## Kayıt / Yükleme

- [ ] XP, elmas, karakter/silah/bayrak seçimi kapanıp açılınca korunuyor
- [ ] En iyi dalga ve istatistikler korunuyor
- [ ] Günlük ödül serisi (streak) doğru

## IAP (Sandbox)

- [ ] Mağaza açılıyor
- [ ] Test ortamında “Satın Al” ile elmas ekleniyor (veya “store yok” mesajı)
- [ ] Elmas bakiyesi kayıtta kalıyor

## Liderlik & Başarılar

- [ ] Liderlik listesi (yerel veya sunucu) görünüyor
- [ ] Başarılar ilerleme gösteriyor (X/Y)
- [ ] Yeni başarı açıldığında bildirim çıkıyor
- [ ] Günlük ödül: claim edilebiliyor, ertesi gün streak artıyor veya sıfırlanıyor

## Paylaşım

- [ ] Oyun bitti ekranında “Skoru Paylaş” panoya kopyalıyor

## Performans

- [ ] Hedef cihazda 30+ FPS (düşük uç)
- [ ] Uzun oyunda belirgin takılma/crash yok

## Notlar

- Test ortamı: Windows / Android / iOS (hedef platformlar)
- Backend boşsa: bulut kayıt ve liderlik “sunucu yok” veya yerel fallback gösterebilir
