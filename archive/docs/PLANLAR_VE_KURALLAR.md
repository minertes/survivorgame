# Planlar ve Kurallar

Yeni context'te hangi planın uygulanacağını netleştirmek için bu dokümana bakın.

## Ana plan (günlük uygulama)

| Dosya | Açıklama |
|-------|----------|
| **UYGULAMA_PLANI_BIRLESIK.md** | Birleşik uygulama planı (Faz 0–7). "Ana planı uygula" denince **sadece bu** kullanılır. |

## Ana plana bağlı kurallar

- **Faz sonrası denetim:** Her faz bitince `docs/FAZ_SONRASI_DENETIM.md` checklist'i uygulanır; denetim bitmeden sonraki faza geçilmez (Cursor kuralı: `.cursor/rules/faz-sonrasi-denetim.mdc`).
- **UI denetimi:** Görsel/UI değişikliklerinde `docs/GORSEL_TASARIM_CHECKLIST.md` ve `docs/DENETIM_ONAY_SURECI.md` (Cursor kuralı: `.cursor/rules/ui-denetim.mdc`).

## Birlikte kullanılan plan

| Dosya | Açıklama |
|-------|----------|
| **OYUN_TASARIMI_GELIR_MODELI_PLANI.md** | Oyun tasarımı, gelir modeli, karakter/silah/düşman; ana plandaki ilgili maddelerle eşleşir. |

## Referans planlar (archive)

Kök dizini sade tutmak için referans / eski planlar `archive/` altındadır. **"Ana planı uygula" denince bunlar otomatik dahil edilmez**; kullanıcı özellikle birini isterse kullanılır.

| Konum | İçerik |
|-------|--------|
| **archive/REALISTIC_20K_PLAN/** | 20K planı (Executive Summary, Game Design, Backend, Monetization, Marketing, Technical). |
| **archive/** | ENTERPRISE_HAZIRLIK_PLANI.md, ENTERPRISE_BACKEND_PLANI.md, production_ready_plan.md, vb. |

## Özet

- **Ana planı uygula** → `UYGULAMA_PLANI_BIRLESIK.md` + faz-sonrası + UI denetim kuralları.
- **Oyun tasarımı ile birlikte** → Yukarıdakiler + `OYUN_TASARIMI_GELIR_MODELI_PLANI.md`.
- **Başka bir planı uygula** → Kullanıcı hangi planı söylüyorsa (örn. REALISTIC_20K, Enterprise) o dosya/klasör kullanılır.
