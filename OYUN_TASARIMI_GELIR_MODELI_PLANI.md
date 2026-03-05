# 🎮 SURVIVOR GAME - OYUN TASARIMI & GELİR MODELİ PLANI
**Versiyon:** 1.0  
**Oyun Türü:** Survivor/Roguelike/Action  
**Hedef Platform:** Mobile (iOS/Android) + PC  
**Hedef Kitle:** Casual - Mid-core Gamers (18-35 yaş)

**Birlikte geliştirilen plan:** Bu doküman, **UYGULAMA_PLANI_BIRLESIK.md** (Birleşik Uygulama Planı) ile birlikte kullanılır. Tasarım ve gelir kararları burada; uygulama adımları (Faz 0–7) Birleşik Plan’da. İki plan senkron güncellenir; yeni özellik geliştirirken her iki dokümana da bakılır.

**Fiyatlar:** Bu planda tüm fiyatlar **USD ($)** bazında verilir. Mağazada bölgeye göre TRY, EUR vb. gösterilebilir.

**Göstergeler (her madde/ tablo satırında):**
| İşaret | Anlamı |
|--------|--------|
| ✅ | Uygulandı |
| ⏳ | Kısmen uygulandı / altyapı var |
| ❌ | Uygulanmadı |

---

## ✅ ANA PLAN KAPSAMINDA UYGULAMA DURUMU

**Referans:** Ana plan = `UYGULAMA_PLANI_BIRLESIK.md`. Uygulama **Faz 0–7** ile yapılır; bu dokmandaki içerik, ilgili fazlarla **eşleşen kısımları** kapsar. Aşağıda bu dokmandaki bölümlerin ne kadarının şu an oyunda olduğu özetlenir.

| Bölüm | Uygulama | Açıklama |
|--------|----------|----------|
| **Core Gameplay Loop** | ✅ Uygulandı | Lobi (karakter/silah/bayrak/tema/mod) → Oyun (wave, XP, upgrade) → Tekrar. Boss her 5 wave. (Faz 0–1, 7) |
| **Wave Design** | ✅ Kısmen | Dalga bandları 1–10 / 11–30 / 31+; boss dalgaları; “Power-up Rain” vb. özel event’ler tam tablo kadar detaylı değil (Faz 1–2) |
| **Gelir Modeli – IAP** | ✅ Altyapı | Gems, IAPService, ürün konfig, test satın alma, mağaza sahnesi. Fiyat/kampanya bu dokmandaki tabloya göre sonra ayarlanır (Faz 4) |
| **Gelir Modeli – Rewarded Ads** | ✅ Altyapı | AdService (consent, rewarded/interstitial stub). Placement/frequency bu dokmandaki tabloya göre sonra (Faz 4) |
| **Gelir Modeli – Battle Pass** | ⏳ Sonraki | GameData’da battle_pass_season/level/xp/premium alanları iskelet; sezon ödülleri ve ekran yok (Faz 4 sonrası) |
| **Gelir Modeli – VIP/Abonelik** | ⏳ Sonraki | GameData is_vip / vip_expires_at; satın alma ve ekran yok (Faz 4 sonrası) |
| **Karakter Sistemi** | ✅ MVP | 4 karakter (BIG BOSS, NIGHT STALKER, HEAVY GUNNER, COMBAT MEDIC). 8 sınıf/skill tree/cosmetics tier’ları sonraki içerik (Faz 7.4) |
| **Silah & Item Sistemi** | ✅ MVP | 5 silah (makineli, pompalı, keskin nişancı, sihir asası, alev makinesi). Item/consumable/amulet sistemi yok (Faz 2, 7.4) |
| **Güçlendirme (Power-ups)** | ✅ MVP | Upgrade paneli (STAT_UPGRADES: can, hasar, hız, kritik vb.); level up’ta seçim. In-game geçici power-up’lar sınırlı (Faz 2) |
| **Düşman & Boss** | ✅ MVP | 5 tür (Zombi, Koşucu, Dev, İblis, Boss); boss dalgası; Boss Rush modu. Çok fazlı boss tasarımları sadeleştirilmiş (Faz 2, 7.3) |
| **Grafik & UI** | ✅ Kısmen | Menü, lobi, HUD (can, XP, dalga), upgrade ekranı, pause, game over. Renk paleti ve 3D/stil bu dokmandaki hedefe kademeli yaklaşılır (Faz 1, 2) |
| **Player Retention** | ✅ Uygulandı | Günlük giriş ödülü (streak + claim), günlük meydan okuma, prestij, başarılar, günlük görev iskeleti (Faz 5, 7) |
| **Social & Competitive** | ✅ Kısmen | Liderlik tablosu (günlük/haftalık), skor paylaşımı. Arkadaş/clan, PvP, ranked yok (Faz 5; sonraki aşama) |
| **Content Roadmap** | ✅ Kısmen | Season 1 MVP: 4 karakter, 5 silah, 4 tema, modlar (Normal, Sonsuz, Boss Rush, Günlük). Season 2–4 (clan, PvP, co-op) sonraki (Faz 7) |

**Özet:** Ana plan (Faz 0–7) kapsamında bu dokmandaki **core loop, wave/combat, karakter/silah MVP, güçlendirme, düşman/boss, retention (günlük ödül, prestij, başarılar), liderlik ve paylaşım, IAP/reklam altyapısı** uygulandı. **Battle Pass/VIP ekranları, arkadaş/clan, PvP, ranked, tam item/consumable sistemi ve dokmandaki tüm sayısal hedefler (15 silah, 10 harita vb.)** sonraki aşamaya bırakıldı; tasarım bu dokmanda referans olarak duruyor.

---

## 📋 İÇİNDEKİLER
1. [Core Gameplay Loop](#core-gameplay-loop)
2. [Gelir Modeli (Monetization)](#gelir-modeli-monetization)
3. [Karakter Sistemi](#karakter-sistemi)
4. [Silah & Item Sistemi](#silah--item-sistemi)
5. [Güçlendirme (Power-ups)](#güçlendirme-power-ups)
6. [Düşman & Boss Tasarımı](#düşman--boss-tasarımı)
7. [Grafik & UI Tasarımı](#grafik--ui-tasarımı)
8. [Player Retention Features](#player-retention-features)
9. [Social & Competitive Features](#social--competitive-features)
10. [Content Roadmap](#content-roadmap)

## 🎯 CORE GAMEPLAY LOOP  
*Durum: ✅ Uygulandı*

### TEMEL MEKANİKLER
```
1. LOBBY → 2. GAME → 3. UPGRADE → 4. REPEAT
```

**1. LOBBY PHASE (30-60 saniye)**
- ✅ Karakter seçimi (farklı yetenekler)
- ✅ Silah seçimi (primary/secondary)
- ✅ Bayrak seçimi (ülke bonusları)
- ⏳ Inventory management (kısmen; tam envanter ekranı yok)
- ❌ Cosmetics preview (skin altyapısı var, önizleme ekranı yok)

**2. GAME PHASE (3-10 dakika)**
- ✅ Wave-based survival
- ✅ Enemy spawning (artarak zorlaşan)
- ✅ XP toplama (düşen gem'ler)
- ⏳ Power-up collection (level-up upgrade seçimi var; in-game geçici power-up sınırlı)
- ✅ Boss fights (her 5 wave'de)
- ❌ Environmental hazards (yok)

**3. UPGRADE PHASE (1-2 dakika)**
- ✅ XP harcama (skill tree benzeri stat seçimleri)
- ✅ Silah yükseltme
- ⏳ Yeni yetenekler açma (stat upgrade’ler var; ayrı yetenek ağacı yok)
- ⏳ Cosmetics satın alma (mağazada cosmetic_set IAP var; ekran kısmen)
- ✅ Leaderboard check (Liderlik & Başarılar ekranı)

### WAVE DESIGN  
*Durum: ⏳ Kısmen (dalga bandları ve boss var; özel event’ler sadeleştirilmiş)*
| Wave | Enemy Count | Enemy Types | Boss | Special Events |
|------|-------------|-------------|------|----------------|
| 1-5 | 10-30 | Basic, Fast | - | XP Bonus |
| 6-10 | 20-50 | Ranged, Tank | Mini-Boss | ⏳ Power-up Rain (yok) |
| 11-15 | 30-70 | Elite, Swarm | Boss 1 | ⏳ Double XP (yok) |
| 16-20 | 40-90 | Special, Flying | Boss 2 | ❌ Treasure Chest (yok) |
| 21+ | 50-120 | All Types | Random Boss | ✅ Survival Mode (sonsuz mod) |

## 💰 GELİR MODELİ (MONETIZATION)  
*Tüm fiyatlar USD ($) bazındadır; mağazada bölgeye göre yerel para birimi (₺, € vb.) gösterilebilir.*

**Hedef:** Hybrid model (IAP + Reklam + Battle Pass). ARPU: ~$1–3.

### 2. IN-APP PURCHASES (IAP)  
*Durum: ✅ Uygulandı (iap_service.gd PRODUCTS; değerler aynı, fiyatlar $ referanslı)*

**Uygulama:** Bu tablo `src/core/systems/iap_service.gd` içindeki `PRODUCTS` ile uygulandı. **Fiyatlar planda USD ($) bazında; uygulamada mağaza bölgesine göre TRY/EUR vb. gösterilebilir.**

| Ürün | Fiyat (USD) | Değer | Satış Noktası |
|------|-------------|-------|---------------|
| **Starter Pack** | $0.99 | 100 Gems + 1 Rare Character | First-time offer |
| **Gem Pack S** | $1.99 | 250 Gems | Small spenders |
| **Gem Pack M** | $4.99 | 700 Gems | Regular players |
| **Gem Pack L** | $9.99 | 1500 Gems | Whales |
| **Gem Pack XL** | $19.99 | 3500 Gems + Bonus | Big spenders |
| **Character Pack** | $2.99 | Exclusive Character | Limited time |
| **Weapon Bundle** | $3.99 | 3 Epic Weapons | Thematic bundles |
| **Cosmetic Set** | $1.99 | Full Skin Set | Fashion players |

### 3. REWARDED ADS  
*Durum: ⏳ Altyapı var (AdService); placement/frequency sonra*
| Ad Type | Reward | Frequency | Placement |
|---------|--------|-----------|-----------|
| **Continue Game** | Extra Life | 3/game | After death |
| **Double Rewards** | 2x XP/Gems | 5/day | End of game |
| **Free Spin** | Random Item | 3/day | Lucky wheel |
| **Speed Up** | Instant Upgrade | 2/day | Upgrade screen |
| **Resource Boost** | +50% Resources | 4/day | Resource collection |

### 4. BATTLE PASS SYSTEM  
*Durum: ❌ Uygulanmadı (GameData’da alanlar var; ekran ve ödül akışı yok)*
**Season Duration:** 30 gün  
**Free Track:** Tüm oyuncular  
**Premium Track:** $4.99/season (USD)

**Free Track Rewards:**
- Common Skins (5)
- Small Gem Packs (3)
- Basic Emotes (2)
- Currency Boosts

**Premium Track Rewards:**
- Exclusive Legendary Skin (1)
- Epic Weapons (3)
- Character Unlocks (2)
- Large Gem Packs (5)
- Special Emotes (3)
- Profile Customizations

### 5. SUBSCRIPTION MODEL  
*Durum: ❌ Uygulanmadı (GameData is_vip alanı var; satın alma/ekran yok)*
**VIP Club:** $2.99/ay (USD)
- Daily Gem Bonus (50/day)
- Ad Removal (optional)
- Exclusive Events
- Priority Support
- Special Badge

## 👤 KARAKTER SİSTEMİ  
*Durum: ⏳ MVP (4 karakter uygulandı; 8 sınıf ve tam skill tree sonraki)*

### CHARACTER CLASSES
| Sınıf | Özellik | Yetenek | Playstyle | Uygulama |
|-------|---------|---------|-----------|----------|
| **Soldier** | Balanced | Rapid Fire | All-rounder | ✅ (BIG BOSS) |
| **Sniper** | High Damage | Critical Hit | Long-range | ✅ (keskin nişancı silah) |
| **Tank** | High HP | Shield Wall | Frontline | ✅ (HEAVY GUNNER) |
| **Scout** | High Speed | Stealth | Hit & Run | ✅ (NIGHT STALKER) |
| **Engineer** | Support | Turret Deploy | Defensive | ❌ |
| **Mage** | Area Damage | Magic Missiles | Crowd Control | ⏳ (sihir asası silah) |
| **Assassin** | Burst Damage | Backstab | Single Target | ❌ |
| **Healer** | Support | Healing Aura | Team Support | ✅ (COMBAT MEDIC) |

### CHARACTER PROGRESSION  
*Durum: ⏳ Kısmen (prestij var; 1-50 level ve yetenek ağacı sadeleştirilmiş)*
**Level System (1-50):**
- ✅ Her level'da stat artışı (upgrade paneli)
- ❌ Her 5 level'da yeni yetenek (yok)
- ✅ Her 10 level'da prestige option (dalga 30+ prestij)

**Skill Tree (3 Branches):** ❌ (Offense/Defense/Utility dalları yok; tek seçimli stat upgrade’ler var)

### COSMETICS SYSTEM  
*Durum: ⏳ Altyapı var (skin_id, owned_*); tier ve ekranlar sonraki*
**Skin Tiers:**
- **Common** (Grey) - Basic recolors
- **Rare** (Blue) - New textures
- **Epic** (Purple) - Model changes
- **Legendary** (Orange) - Full redesign + effects
- **Mythic** (Red) - Animated + unique abilities

**Customization Options:**
- ⏳ Character Skins (alan var; tam ekran yok)
- ⏳ Weapon Skins (alan var; tam ekran yok)
- ❌ Emotes (8-directional)
- ❌ Kill Effects / Trail Effects / Profile Frames / Name Colors

## 🔫 SİLAH & ITEM SİSTEMİ  
*Durum: ⏳ MVP (5 silah uygulandı; item/consumable yok)*

### WEAPON CATEGORIES
| Kategori | Özellikler | Örnek Silahlar | Uygulama |
|----------|------------|----------------|----------|
| **Assault** | Balanced | Machine Gun, Rifle | ✅ machinegun |
| **Shotgun** | Close-range | Pump Shotgun | ✅ shotgun |
| **Sniper** | Long-range | Bolt-action, Semi-auto | ✅ sniper |
| **Explosive** | AOE Damage | Rocket Launcher | ❌ |
| **Energy** | Special Effects | Laser, Plasma | ⏳ magic_wand |
| **Melee** | Melee | Sword, Hammer | ❌ |
| **Special** | Unique | Flamethrower | ✅ flamethrower |

### WEAPON STATS  
*Durum: ✅ Uygulandı (damage, fire rate vb. GameData.WEAPONS ve player’da)*
- **Damage** (Base damage)
- **Fire Rate** (Shots per second)
- **Range** (Effective distance)
- **Accuracy** (Spread angle)
- **Magazine Size** (Ammo capacity)
- **Reload Speed** (Seconds)
- **Special Effect** (Burn, Freeze, Shock)

### ITEM SYSTEM  
*Durum: ❌ Uygulanmadı*
**Consumables (In-game):**
- ❌ Health Potion / Shield Potion / Speed Boost / Damage Boost / XP Magnet

**Permanent Items:**
- ❌ Amulet / Ring / Artifact / Charm

## ⚡ GÜÇLENDİRME (POWER-UPS)  
*Durum: ⏳ Kalıcı upgrade’ler var; in-game geçici power-up’lar sınırlı*

### IN-GAME POWER-UPS  
*Durum: ❌ (plan tablosu uygulanmadı; level-up’ta sadece kalıcı stat seçimi var)*
| Power-up | Efekt | Süre | Görsel | Uygulama |
|----------|-------|------|--------|----------|
| **Double Damage** | 2x Damage | 15s | Red Sword | ❌ |
| **Speed Boost** | 2x Speed | 20s | Blue Boots | ❌ |
| **Invincibility** | No Damage | 10s | Golden Shield | ❌ |
| **Magnet** | Auto-collect | 30s | Magnet Icon | ❌ |
| **Multi-shot** | 3 Projectiles | 25s | Triple Arrow | ❌ |
| **Piercing** | Penetrate enemies | 20s | Arrow through shield | ❌ |
| **Bounce** | Ricochet shots | 25s | Bouncing ball | ❌ |
| **Homing** | Auto-aim | 30s | Target icon | ❌ |

### PERMANENT UPGRADES  
*Durum: ✅ Uygulandı (upgrade_panel STAT_UPGRADES; XP ile seçim)*
**Upgrade Shop (XP ile satın alma):**
- ✅ Health Increase (Max HP)
- ✅ Damage Increase (Base damage)
- ✅ Speed Increase (Movement)
- ✅ Luck Increase / Critical Chance / Critical Damage (kritik vb.)
- ⏳ XP Gain Increase (Faster leveling) – dolaylı

## 👾 DÜŞMAN & BOSS TASARIMI  
*Durum: ⏳ MVP (5 tür; çok fazlı boss sadeleştirilmiş)*

### ENEMY TIERS
| Tier | HP | Damage | Speed | Special | Uygulama |
|------|----|--------|-------|---------|----------|
| **Grunt** | 10-50 | 5-10 | Normal | None | ✅ (Zombi) |
| **Elite** | 100-200 | 15-25 | Fast | Shield | ✅ (Koşucu, İblis) |
| **Mini-Boss** | 500-1000 | 30-50 | Slow | AOE | ⏳ (Dev) |
| **Boss** | 2000-5000 | 50-100 | Varies | Phases | ✅ (Boss tipi; fazlar sade) |
| **World Boss** | 10000+ | 100+ | Slow | Raid | ❌ |

### ENEMY TYPES
1. **Melee Enemies**
   - ✅ Zombie (slow, high HP)
   - ✅ Runner (fast, low HP)
   - ✅ Brute (Dev – slow, high damage)

2. **Ranged Enemies**
   - ⏳ (İblis benzeri)
   - ❌ Mage (AOE) / Sniper (long range)

3. **Special Enemies**
   - ❌ Healer / Bomber / Summoner

### BOSS DESIGNS  
*Durum: ⏳ Tek boss tipi var; çok fazlı tasarım uygulanmadı*
**Boss 1: The Colossus** – ❌ (genel boss dalgası var, Colossus özel değil)
**Boss 2: Sky Serpent** – ❌  
**Boss 3: Crystal Golem** – ❌

## 🎨 GRAFİK & UI TASARIMI  
*Durum: ⏳ Kısmen (ekranlar var; 3D/stil hedefe kademeli)*

### ART STYLE  
*Durum: ⏳ 2D/top-down mevcut; 3D hedef sonraki*
- **Characters:** ⏳ 2D sprite (3D hedef)
- **Environment:** ⏳ 2D tile/background (Low-poly 3D hedef)
- **Effects:** ⏳ Temel efektler
- **UI:** ✅ Clean, mobile-friendly

### COLOR PALETTE  
*Durum: ⏳ Kısmen uyumlu*
- **Primary:** Blues and Purples (futuristic)
- **Secondary:** Oranges and Reds (danger/warning)
- **Accent:** Gold and Silver (premium)
- **Background:** Dark blues/black (space theme)

### UI/UX DESIGN PRINCIPLES
1. ✅ **Mobile First** - Touch-friendly, large buttons
2. ✅ **3-Tap Rule** - Önemli özellikler 3 dokunuşta
3. ✅ **Visual Hierarchy** - Net öncelik
4. ✅ **Feedback** - Görsel, ses
5. ✅ **Consistency** - Tutarlı pattern

### SCREEN DESIGNS
**1. Main Menu:** ✅
- ✅ Play button (center, large)
- ✅ Character preview (WarriorCard)
- ✅ Daily rewards (Liderlik & Başarılar → Günlük)
- ✅ Shop icon
- ✅ Settings (Ses)

**2. Lobby Screen:** ✅
- ✅ Character selection
- ✅ Weapon loadout
- ✅ Start button
- ⏳ Inventory button (tam ekran yok)
- ✅ Shop shortcut

**3. Game HUD:** ✅
- ✅ Health bar (top left)
- ✅ XP bar (top center)
- ⏳ Minimap (varsa)
- ❌ Ability buttons (yok)
- ✅ Joystick (left) / Fire (right) – dokunmatik

**4. Upgrade Screen:** ✅
- ✅ Stat seçimleri (skill tree benzeri)
- ✅ Upgrade costs
- ⏳ Preview effects (kısmen)

## 📈 PLAYER RETENTION FEATURES  
*Durum: ✅ Uygulandı (günlük ödül, streak, prestij, başarılar, günlük görev iskeleti)*

### DAILY ENGAGEMENT
1. **Daily Login Rewards** ✅
   - ✅ Streak + claim (XP/elmas); gün 1–7 takvimi sadeleştirilmiş
   - ❌ Day 2: Common Skin / Day 7: Epic Weapon / Day 30: Legendary (ödül tablosu farklı)

2. **Daily Quests** ⏳
   - ✅ Play 3 games, Kill 100 enemies, Upgrade weapon, Share on social (GameData daily_quests)
   - ❌ Watch 2 ads (reklam entegre, quest tetikleyici yok)

3. **Daily Events** ❌
   - ❌ Double XP Hour / Gem Rush / Boss Hunt / Survival Challenge (günlük meydan okuma modu var, özel event’ler yok)

### PROGRESSION SYSTEMS
1. ✅ **Level System** (oyun içi level + XP)
2. ✅ **Prestige System** (dalga 30+ prestij, kalıcı bonus)
3. ✅ **Achievements** (AchievementsService, rozetler)
4. ❌ **Collection Book** / **Trophy Room**

### RETENTION MECHANICS
1. ✅ **Streak System** - Günlük giriş serisi
2. ❌ **Time-gated Content** - Haftalık içerik
3. ❌ **Limited Events** - FOMO
4. ❌ **Social Pressure** - Arkadaş karşılaştırma
5. ✅ **Progression Gates** - Prestij, başarılar, dalga hedefi

## 🤝 SOCIAL & COMPETITIVE FEATURES  
*Durum: ⏳ Kısmen (liderlik + paylaşım var; arkadaş/clan/PvP yok)*

### SOCIAL FEATURES
1. **Friend System** ❌
   - ❌ Add friends / Send-receive gifts / Compare stats / Cooperative play

2. **Clan/Guild System** ❌
   - ❌ Create/join clans / Clan chat / Clan wars / Shared rewards

3. **Social Sharing** ✅
   - ✅ Share achievements (skor paylaşımı – panoya)
   - ❌ Invite friends / Social media integration / Referral program

### COMPETITIVE FEATURES
1. **Leaderboards** ✅
   - ✅ Global ranking (günlük/haftalık; LeaderboardService)
   - ❌ Friends ranking
   - ✅ Weekly reset (haftalık period)
   - ❌ Season rewards

2. **PvP Modes** ❌
   - ❌ 1v1 Duels / Team Deathmatch / Battle Royale / Tournament

3. **Ranked System** ❌
   - ❌ Bronze→Diamond / Seasonal rewards / Matchmaking

## 🗺️ CONTENT ROADMAP  
*Tüm gelir hedefleri USD ($) bazındadır.*

### SEASON 1: LAUNCH (3 AY)  
*Durum: ⏳ MVP tamamlandı (4 karakter, 5 silah, 4 tema, modlar; sayılar planın altında)*
**Theme:** Space Survival
- ⏳ 5 Characters → ✅ 4 (MVP)
- ⏳ 15 Weapons → ✅ 5 (MVP)
- ⏳ 3 Bosses → ✅ 1 boss tipi + Boss Rush modu
- ⏳ 10 Maps → ✅ 4 tema (Mezarlık, Orman, Çöl, Cehennem)
- ❌ Basic Battle Pass

### SEASON 2: EXPANSION (AY 4-6)  
*Durum: ❌ Uygulanmadı*
**Theme:** Cyberpunk City
- 3 New Characters / 10 New Weapons / 2 New Bosses / 5 New Maps / Clan System

### SEASON 3: PvP (AY 7-9)  
*Durum: ❌ Uygulanmadı*
**Theme:** Arena Combat
- PvP Modes / Tournament / Ranking / Spectator

### SEASON 4: CO-OP (AY 10-12)  
*Durum: ❌ Uygulanmadı*
**Theme:** Raid Bosses
- 4-player Co-op / World Bosses / Raid Mechanics / Guild Wars

## 📊 MONETIZATION METRİKLERİ  
*Tüm gelir ve ARPU değerleri USD ($) bazındadır.*

### KPI'LAR (Key Performance Indicators)  
*Durum: ⏳ AnalyticsService ile event’ler toplanıyor; KPI dashboard sonraki*
| Metrik | Hedef | Ölçüm | Uygulama |
|--------|-------|-------|----------|
| **Daily Active Users (DAU)** | 10,000 | Analytics | ⏳ session_start/end var |
| **Monthly Active Users (MAU)** | 50,000 | Analytics | ⏳ |
| **Average Session Length** | 8 dakika | Analytics | ⏳ |
| **Day 1/7/30 Retention** | 40% / 20% / 10% | Cohort | ❌ dashboard yok |
| **Conversion Rate** | 3% | IAP/User | ⏳ |
| **ARPU** | $1.50 | Revenue/User | ⏳ |
| **LTV** | $4.50 | Total revenue/user | ⏳ |

### REVENUE PROJECTIONS (USD)
| Ay | DAU | Conversion Rate | ARPU (USD) | Monthly Revenue (USD) |
|----|-----|-----------------|------------|------------------------|
| 1 | 5,000 | 2% | $1.00 | $10,000 |
| 3 | 15,000 | 2.5% | $1.25 | $46,875 |
| 6 | 30,000 | 3% | $1.50 | $135,000 |
| 12 | 50,000 | 3.5% | $1.75 | $306,250 |

## 🎯 BAŞARI FAKTÖRLERİ

### CRITICAL SUCCESS FACTORS
1. **Addictive Gameplay** - Simple to learn, hard to master
2. **Fair Monetization** - Pay to progress faster, not to win
3. **Regular Updates** - New content every 2-4 weeks
4. **Community Engagement** - Listen to player feedback
5. **Performance** - Smooth 60 FPS on target devices

### RISK MITIGATION
1. **Player Churn** - Regular events, new content
2. **Monetization Backlash** - Fair pricing, no pay-to-win
3. **Technical Issues** - Rigorous testing, quick patches
4. **Market Competition** - Unique features, better polish
5. **User Acquisition Costs** - Viral features, referral program

---
**Plan Sahibi:** Game Design Team  
**Onay:** [ ] Creative Director  
**Onay:** [ ] Product Manager  
**Sonraki Review:** 2 Hafta Sonra

**İlişkili belge:** Uygulama adımları ve faz eşleşmesi için → `UYGULAMA_PLANI_BIRLESIK.md` (Oyun Tasarımı & Gelir Planı ile Eşleşme bölümü).
