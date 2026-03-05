# Uygulama Sonrası İyileştirme Önerileri

Plan (Faz 0–7) uygulandı; aşağıdakiler “bu esnada bunlar da olsa iyi olurdu” diyebileceğim iyileştirmeler.

---

## 1. Backend ve bulut senkronu

- **Bulut çekme:** Şu an sadece `push_cloud_save` kullanılıyor; açılışta veya “Senkronize et” butonu ile `pull_cloud_save` + `GameData.apply_cloud_data` yok. Eklenirse “son yazma kazanır” veya merge mantığı gerçekten iki yönlü çalışır.
- **Backend örnek:** `config/default_env.cfg` ve `backend_url` boş; `config/README.md` veya `.env.example` ile staging/prod URL’lerinin nasıl verileceği yazılabilir.
- **Liderlik tablosu:** Client hazır; sunucuda `PUT /leaderboard/submit` ve `GET /leaderboard/list` endpoint’leri tanımlanıp dokümante edilmedi. Bunlar olmadan liderlik sadece yerel fallback’te kalır.

---

## 2. IAP ve reklam

- **Gerçek mağaza:** IAP şu an test (simülasyon); Google Play / App Store için Godot eklentisi (GodotGooglePlayBilling, InAppStore vb.) bağlanıp `_do_platform_purchase` doldurulmalı.
- **Makbuz doğrulama:** Production’da satın alma makbuzunun sunucuda doğrulanması daha güvenli; client sadece ödülü vermeden önce backend’den onay almalı.
- **Reklam:** AdService arayüzü var; gerçek ödüllü / interstitial için AdMob veya Unity Ads entegrasyonu yapılabilir.

---

## 3. Günlük meydan okuma ve prestij

- **Günlük kural çeşidi:** Günlük mod şu an sadece tarih tohumu + ek ödül; “bugün 2x hasar”, “yarım can” gibi günlük değişen kurallar (tohumdan türetilebilir) eklenirse mod daha hissedilir olur.
- **Oyuncu hasarı çarpanı:** `main.gd`’de `_daily_challenge_damage_mult` tanımlı ama player hasarına uygulanmıyor; günlük modda çarpanın gerçekten kullanılması iyi olur.
- **Prestij:** `prestige_level` ve `get_prestige_bonus()` var; “Dalga 30’da prestij yap” gibi bir aksiyon ve UI (oyun sonu / menü) yok. Prestij yapınca bonusun kalıcı uygulanması ve belki skor sıfırlama netleştirilmeli.

---

## 4. Tema ve lobi

- **Tema seçici:** `Background.set_theme_by_id` ve `GameState.theme_id` hazır; lobide harita/tema seçenekleri (Mezarlık, Orman, Çöl, Cehennem) gösterilmiyor, hep `default` gidiyor. Lobiye tema butonları veya dropdown eklenebilir.
- **Mod seçici konumu:** Mod butonları ekranın altında; lobi molekülü ile çakışmıyorsa sorun yok, çakışıyorsa konum/katman düzenlenebilir.

---

## 5. Test ve CI

- **Godot sürümü:** CI’da 4.2, projede 4.6 kullanılıyor; CI’ı 4.6’ya çekmek veya en azından aynı minor’da tutmak uyumluluk için iyi olur.
- **Export preset:** `.github/workflows` içinde export adımı var ama `export_presets.cfg` repo’da yok; editörde preset tanımlayıp commit’lemek veya CI’da “export atla” demek mantıklı.
- **Daha fazla birim test:** Save, wave, para birimi testleri var; upgrade paneli, günlük ödül claim, başarı açılma gibi kritik akışlar da test edilebilir.

---

## 6. Loglama ve ortam

- **Log seviyesi ortamdan:** Production’da DEBUG/INFO’yu kısmak için `EnvConfig` veya ortam değişkeni ile `GameLogger.setup(min_level)` (örn. WARN/ERROR) ayarlanabilir.
- **Hata toplama:** ERROR/FATAL `error.log`’a yazılıyor; production’da bu dosyanın merkezi bir yere (Crashlytics, Sentry, backend) gönderilmesi eklenebilir.

---

## 7. Genel

- **GameState.selected_character:** Hâlâ "male"/"female" gibi eski değerler kullanılıyorsa, tek kaynak `GameData.selected_character` (male_soldier vb.) olacak şekilde temizlenebilir.
- **Yeni içerik dengesi:** Medic ve Alev Makinesi için sayılar (can, hasar, maliyet) placeholder; oynanış testi ile dengeye çekilmeli.
- **Yerelleştirme:** Tüm metinler Türkçe; ileride çoklu dil için bir i18n/locale sistemi düşünülebilir.
- **Erişilebilirlik:** Yazı boyutu ölçekleme, kontrast veya basit erişilebilirlik seçenekleri eklenebilir.

---

Bu maddeler planın “eksik” kısmı değil; plan tamamlandı. Bunlar, projeyi bir sonraki adımda daha sağlam ve yayına hazır hale getirmek için önerilen iyileştirmelerdir.
