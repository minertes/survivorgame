# 🎮 SURVIVOR GAME - OYUN TASARIMI & GELİR MODELİ PLANI
**Versiyon:** 1.0  
**Oyun Türü:** Survivor/Roguelike/Action  
**Hedef Platform:** Mobile (iOS/Android) + PC  
**Hedef Kitle:** Casual - Mid-core Gamers (18-35 yaş)

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

### TEMEL MEKANİKLER
```
1. LOBBY → 2. GAME → 3. UPGRADE → 4. REPEAT
```

**1. LOBBY PHASE (30-60 saniye)**
- Karakter seçimi (farklı yetenekler)
- Silah seçimi (primary/secondary)
- Bayrak seçimi (ülke bonusları)
- Inventory management
- Cosmetics preview

**2. GAME PHASE (3-10 dakika)**
- Wave-based survival
- Enemy spawning (artarak zorlaşan)
- XP toplama (düşen gem'ler)
- Power-up collection
- Boss fights (her 5 wave'de)
- Environmental hazards

**3. UPGRADE PHASE (1-2 dakika)**
- XP harcama (skill tree)
- Silah yükseltme
- Yeni yetenekler açma
- Cosmetics satın alma
- Leaderboard check

### WAVE DESIGN
| Wave | Enemy Count | Enemy Types | Boss | Special Events |
|------|-------------|-------------|------|----------------|
| 1-5 | 10-30 | Basic, Fast | - | XP Bonus |
| 6-10 | 20-50 | Ranged, Tank | Mini-Boss | Power-up Rain |
| 11-15 | 30-70 | Elite, Swarm | Boss 1 | Double XP |
| 16-20 | 40-90 | Special, Flying | Boss 2 | Treasure Chest |
| 21+ | 50-120 | All Types | Random Boss | Survival Mode |

## 💰 GELİR MODELİ (MONETIZATION)

### 1. HYBRID MODEL (IAP + Ads + Battle Pass)
**Hedef:** $1-3 ARPU (Average Revenue Per User)

### 2. IN-APP PURCHASES (IAP)
| Ürün | Fiyat | Değer | Satış Noktası |
|------|-------|-------|---------------|
| **Starter Pack** | $0.99 | 100 Gems + 1 Rare Character | First-time offer |
| **Gem Pack S** | $1.99 | 250 Gems | Small spenders |
| **Gem Pack M** | $4.99 | 700 Gems | Regular players |
| **Gem Pack L** | $9.99 | 1500 Gems | Whales |
| **Gem Pack XL** | $19.99 | 3500 Gems + Bonus | Big spenders |
| **Character Pack** | $2.99 | Exclusive Character | Limited time |
| **Weapon Bundle** | $3.99 | 3 Epic Weapons | Thematic bundles |
| **Cosmetic Set** | $1.99 | Full Skin Set | Fashion players |

### 3. REWARDED ADS
| Ad Type | Reward | Frequency | Placement |
|---------|--------|-----------|-----------|
| **Continue Game** | Extra Life | 3/game | After death |
| **Double Rewards** | 2x XP/Gems | 5/day | End of game |
| **Free Spin** | Random Item | 3/day | Lucky wheel |
| **Speed Up** | Instant Upgrade | 2/day | Upgrade screen |
| **Resource Boost** | +50% Resources | 4/day | Resource collection |

### 4. BATTLE PASS SYSTEM
**Season Duration:** 30 gün  
**Free Track:** Tüm oyuncular  
**Premium Track:** $4.99/season

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
**VIP Club:** $2.99/ay
- Daily Gem Bonus (50/day)
- Ad Removal (optional)
- Exclusive Events
- Priority Support
- Special Badge

## 👤 KARAKTER SİSTEMİ

### CHARACTER CLASSES
| Sınıf | Özellik | Yetenek | Playstyle |
|-------|---------|---------|-----------|
| **Soldier** | Balanced | Rapid Fire | All-rounder |
| **Sniper** | High Damage | Critical Hit | Long-range |
| **Tank** | High HP | Shield Wall | Frontline |
| **Scout** | High Speed | Stealth | Hit & Run |
| **Engineer** | Support | Turret Deploy | Defensive |
| **Mage** | Area Damage | Magic Missiles | Crowd Control |
| **Assassin** | Burst Damage | Backstab | Single Target |
| **Healer** | Support | Healing Aura | Team Support |

### CHARACTER PROGRESSION
**Level System (1-50):**
- Her level'da stat artışı
- Her 5 level'da yeni yetenek
- Her 10 level'da prestige option

**Skill Tree (3 Branches):**
1. **Offense Branch** - Damage, Crit, Fire Rate
2. **Defense Branch** - HP, Armor, Regen
3. **Utility Branch** - Speed, XP Gain, Luck

### COSMETICS SYSTEM
**Skin Tiers:**
- **Common** (Grey) - Basic recolors
- **Rare** (Blue) - New textures
- **Epic** (Purple) - Model changes
- **Legendary** (Orange) - Full redesign + effects
- **Mythic** (Red) - Animated + unique abilities

**Customization Options:**
- Character Skins
- Weapon Skins
- Emotes (8-directional)
- Kill Effects
- Trail Effects
- Profile Frames
- Name Colors

## 🔫 SİLAH & ITEM SİSTEMİ

### WEAPON CATEGORIES
| Kategori | Özellikler | Örnek Silahlar |
|----------|------------|----------------|
| **Assault** | Balanced | Machine Gun, Rifle |
| **Shotgun** | Close-range | Pump Shotgun, Auto Shotgun |
| **Sniper** | Long-range | Bolt-action, Semi-auto |
| **Explosive** | AOE Damage | Rocket Launcher, Grenade Launcher |
| **Energy** | Special Effects | Laser Rifle, Plasma Gun |
| **Melee** | Melee | Sword, Hammer, Katana |
| **Special** | Unique | Flamethrower, Tesla Coil |

### WEAPON STATS
- **Damage** (Base damage)
- **Fire Rate** (Shots per second)
- **Range** (Effective distance)
- **Accuracy** (Spread angle)
- **Magazine Size** (Ammo capacity)
- **Reload Speed** (Seconds)
- **Special Effect** (Burn, Freeze, Shock)

### ITEM SYSTEM
**Consumables (In-game):**
- Health Potion (Instant heal)
- Shield Potion (Temporary shield)
- Speed Boost (Movement speed)
- Damage Boost (Increased damage)
- XP Magnet (Auto-collect XP)

**Permanent Items:**
- Amulet (Stat bonuses)
- Ring (Special abilities)
- Artifact (Game-changing effects)
- Charm (Luck-based bonuses)

## ⚡ GÜÇLENDİRME (POWER-UPS)

### IN-GAME POWER-UPS
| Power-up | Efekt | Süre | Görsel |
|----------|-------|------|--------|
| **Double Damage** | 2x Damage | 15s | Red Sword |
| **Speed Boost** | 2x Speed | 20s | Blue Boots |
| **Invincibility** | No Damage | 10s | Golden Shield |
| **Magnet** | Auto-collect | 30s | Magnet Icon |
| **Multi-shot** | 3 Projectiles | 25s | Triple Arrow |
| **Piercing** | Penetrate enemies | 20s | Arrow through shield |
| **Bounce** | Ricochet shots | 25s | Bouncing ball |
| **Homing** | Auto-aim | 30s | Target icon |

### PERMANENT UPGRADES
**Upgrade Shop (XP ile satın alma):**
- Health Increase (Max HP)
- Damage Increase (Base damage)
- Speed Increase (Movement)
- Luck Increase (Better drops)
- XP Gain Increase (Faster leveling)
- Critical Chance (Crit %)
- Critical Damage (Crit multiplier)

## 👾 DÜŞMAN & BOSS TASARIMI

### ENEMY TIERS
| Tier | HP | Damage | Speed | Special |
|------|----|--------|-------|---------|
| **Grunt** | 10-50 | 5-10 | Normal | None |
| **Elite** | 100-200 | 15-25 | Fast | Shield |
| **Mini-Boss** | 500-1000 | 30-50 | Slow | AOE Attack |
| **Boss** | 2000-5000 | 50-100 | Varies | Multiple Phases |
| **World Boss** | 10000+ | 100+ | Slow | Raid Mechanics |

### ENEMY TYPES
1. **Melee Enemies**
   - Zombie (slow, high HP)
   - Runner (fast, low HP)
   - Brute (slow, high damage)

2. **Ranged Enemies**
   - Archer (single target)
   - Mage (AOE spells)
   - Sniper (long range)

3. **Special Enemies**
   - Healer (heals other enemies)
   - Tank (damage reduction)
   - Bomber (suicide attack)
   - Summoner (spawns minions)

### BOSS DESIGNS
**Boss 1: The Colossus**
- Phase 1: Melee attacks
- Phase 2: Ground slam (AOE)
- Phase 3: Enrage mode

**Boss 2: Sky Serpent**
- Phase 1: Flying, projectile attacks
- Phase 2: Dive attacks
- Phase 3: Lightning storm

**Boss 3: Crystal Golem**
- Phase 1: Crystal shards
- Phase 2: Laser beams
- Phase 3: Crystal explosion

## 🎨 GRAFİK & UI TASARIMI

### ART STYLE
**Target:** Colorful, Cartoonish, Modern
- **Characters:** Stylized 3D models
- **Environment:** Low-poly 3D
- **Effects:** Particle-heavy, vibrant
- **UI:** Clean, modern, mobile-friendly

### COLOR PALETTE
- **Primary:** Blues and Purples (futuristic)
- **Secondary:** Oranges and Reds (danger/warning)
- **Accent:** Gold and Silver (premium)
- **Background:** Dark blues/black (space theme)

### UI/UX DESIGN PRINCIPLES
1. **Mobile First** - Touch-friendly, large buttons
2. **3-Tap Rule** - Important features within 3 taps
3. **Visual Hierarchy** - Clear importance levels
4. **Feedback** - Haptic, visual, audio feedback
5. **Consistency** - Same patterns throughout

### SCREEN DESIGNS
**1. Main Menu:**
- Play button (center, large)
- Character preview (rotating)
- Daily rewards (top right)
- Shop icon (top left)
- Settings (bottom)

**2. Lobby Screen:**
- Character selection (carousel)
- Weapon loadout (grid)
- Start button (prominent)
- Inventory button
- Shop shortcut

**3. Game HUD:**
- Health bar (top left)
- XP bar (top center)
- Minimap (top right)
- Ability buttons (bottom)
- Joystick (left)
- Fire button (right)

**4. Upgrade Screen:**
- Skill tree (visual)
- Stat comparisons
- Upgrade costs
- Preview effects

## 📈 PLAYER RETENTION FEATURES

### DAILY ENGAGEMENT
1. **Daily Login Rewards**
   - Day 1: 50 Gems
   - Day 2: Common Skin
   - Day 3: 100 Gems
   - Day 7: Epic Weapon
   - Day 30: Legendary Skin

2. **Daily Quests**
   - Play 3 games
   - Kill 100 enemies
   - Upgrade weapon
   - Watch 2 ads
   - Share on social

3. **Daily Events**
   - Double XP Hour (2x XP)
   - Gem Rush (extra gems)
   - Boss Hunt (special boss)
   - Survival Challenge

### PROGRESSION SYSTEMS
1. **Level System** (1-100)
2. **Prestige System** (reset for bonuses)
3. **Achievements** (100+ achievements)
4. **Collection Book** (collect all items)
5. **Trophy Room** (display accomplishments)

### RETENTION MECHANICS
1. **Streak System** - Daily play rewards
2. **Time-gated Content** - New content weekly
3. **Limited Events** - FOMO (Fear Of Missing Out)
4. **Social Pressure** - Friends comparison
5. **Progression Gates** - Always something to achieve

## 🤝 SOCIAL & COMPETITIVE FEATURES

### SOCIAL FEATURES
1. **Friend System**
   - Add friends
   - Send/receive gifts
   - Compare stats
   - Cooperative play

2. **Clan/Guild System**
   - Create/join clans
   - Clan chat
   - Clan wars
   - Shared rewards

3. **Social Sharing**
   - Share achievements
   - Invite friends
   - Social media integration
   - Referral program

### COMPETITIVE FEATURES
1. **Leaderboards**
   - Global ranking
   - Friends ranking
   - Weekly reset
   - Season rewards

2. **PvP Modes**
   - 1v1 Duels
   - Team Deathmatch
   - Battle Royale
   - Tournament mode

3. **Ranked System**
   - Bronze → Silver → Gold → Platinum → Diamond
   - Seasonal rewards
   - Promotion/demotion
   - Matchmaking rating

## 🗺️ CONTENT ROADMAP

### SEASON 1: LAUNCH (3 AY)
**Theme:** Space Survival
- 5 Characters
- 15 Weapons
- 3 Bosses
- 10 Maps
- Basic Battle Pass

### SEASON 2: EXPANSION (AY 4-6)
**Theme:** Cyberpunk City
- 3 New Characters
- 10 New Weapons
- 2 New Bosses
- 5 New Maps
- Clan System

### SEASON 3: PvP (AY 7-9)
**Theme:** Arena Combat
- PvP Modes
- Tournament System
- Ranking System
- Spectator Mode

### SEASON 4: CO-OP (AY 10-12)
**Theme:** Raid Bosses
- 4-player Co-op
- World Bosses
- Raid Mechanics
- Guild Wars

## 📊 MONETIZATION METRİKLERİ

### KPI'LAR (Key Performance Indicators)
| Metrik | Hedef | Ölçüm |
|--------|-------|-------|
| **Daily Active Users (DAU)** | 10,000 | Analytics |
| **Monthly Active Users (MAU)** | 50,000 | Analytics |
| **Average Session Length** | 8 dakika | Analytics |
| **Day 1 Retention** | 40% | Cohort analysis |
| **Day 7 Retention** | 20% | Cohort analysis |
| **Day 30 Retention** | 10% | Cohort analysis |
| **Conversion Rate** | 3% | IAP/User |
| **Average Revenue Per User** | $1.50 | Revenue/User |
| **Lifetime Value (LTV)** | $4.50 | Total revenue/user |

### REVENUE PROJECTIONS
| Ay | DAU | Conversion Rate | ARPU | Monthly Revenue |
|----|-----|-----------------|------|-----------------|
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

Şu anda elimde iki kod versiyonu var: orijinal kod ve önerilen düzenlenmiş kod. İkisi de tamamen aynı görünüyor. Bu durumda, herhangi bir değişiklik uygulamama gerek yok çünkü ikisi özdeş.

Ancak, kullanıcının "önerilen düzenlemeyi uygula" dediğini göz önünde bulundurarak, belki de farkı göremediğim için karşılaştırmam gerekiyor. İki kodu satır satır karşılaştırdığımda, hiçbir fark bulamadım. Bu nedenle, mevcut kodda herhangi bir değişiklik yapmama gerek yok.

Eğer kullanıcı, önerilen düzenlemenin belirli bir kısmını işaret etmiş olsaydı, ona göre hareket ederdim. Ancak, bu durumda, kod zaten güncel. Bu yüzden, mevcut kodu olduğu gibi bırakıyorum.Kodunuzu inceledim. Önerilen düzenleme metni mevcut kodunuzla birebir aynıdır. Herhangi bir değişiklik veya güncelleme içermemektedir. Bu nedenle, mevcut kodunuzda herhangi bir değişiklik yapılmasına gerek yoktur.

Oyun tasarım ve gelir modeli planınız kapsamlı, detaylı ve profesyonel bir şekilde hazırlanmıştır. Tüm bölümler (core gameplay, monetization, karakterler, içerik roadmap vb.) net bir şekilde tanımlanmış ve mobile/PC survivor oyunu için sağlam bir temel oluşturuyor.

Planınızda herhangi bir spesifik değişiklik veya geliştirme yapılmasını isterseniz, lütfen belirtin.
