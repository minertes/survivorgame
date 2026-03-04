# 🎮 SURVIVOR GAME - 100M OYUNCU HEDEFLİ PROFESYONEL GELİŞTİRME PLANI

## 📊 TEMEL PRENSİPLER (KESİNLİKLE UYULACAK)

### **1. ATOMIC DESIGN PRENSİBİ**
```
Atoms → Molecules → Organisms → Templates → Pages
```

**Atoms (Temel Bileşenler):**
- Button, Label, Icon, ProgressBar gibi en küçük bileşenler
- Her atom tek bir iş yapar
- Maximum reusability

**Molecules (Moleküller):**
- Atomların birleşimi (Örn: HealthBar = ProgressBar + Label + Icon)
- Belirli bir fonksiyonu olan bileşen grupları

**Organisms (Organizmalar):**
- Moleküllerin birleşimi (Örn: PlayerHUD = HealthBar + XPBar + WeaponInfo)
- Kompleks UI bölümleri

**Templates (Şablonlar):**
- Organizmaların düzeni (Örn: GameScreen template)
- Layout yapısı

**Pages (Sayfalar):**
- Template'lerin içeriği (Örn: MainGame page)

### **2. MODÜLER BİLEŞEN SİSTEMİ**
- Her bileşen bağımsız çalışır
- Dependency injection ile bağlantı
- Plug-and-play architecture
- Unit test edilebilir

### **3. DATA-DRIVEN DESIGN**
- Tüm game balance JSON config'lerde
- Runtime'da config değişikliği
- Modding support için açık API

### **4. EVENT-DRIVEN ARCHITECTURE**
- Global EventBus ile decoupled communication
- Priority-based event queuing
- Async/sync event handling
- 30+ predefined event types

### **5. ORCHESTRATOR PATTERN**
- Complex entities coordinate atomic components
- Drop system as atomic component
- AI system as atomic component
- Stats system as atomic component

### **6. MODÜLER TEST SİSTEMİ**
- Monolitik test dosyaları modüllere ayrılır
- Her modül bağımsız çalışır
- Test orchestrator tüm modülleri yönetir
- Performance ve memory test modülleri

## 🏗️ PROJE YAPISI (MINIMALIST - GÜNCELLENDİ)

```
survivor-game/
├── 📁 src/                          # Tüm kaynak kod
│   ├── 📁 core/                     # Çekirdek sistemler
│   │   ├── 📁 components/           # Atomic bileşenler
│   │   │   ├── component.gd         ✅ Component base class
│   │   │   ├── health_component.gd  ✅ Health component
│   │   │   ├── movement_component.gd ✅ Movement component  
│   │   │   ├── weapon_component.gd  ✅ Weapon component
│   │   │   ├── inventory_component.gd ✅ Inventory component
│   │   │   ├── experience_component.gd ✅ Experience component
│   │   │   ├── drop_component.gd    ✅ Drop component
│   │   │   ├── enemy_ai_component.gd ✅ Enemy AI component
│   │   │   └── enemy_stats_component.gd ✅ Enemy Stats component
│   │   ├── 📁 systems/              # Sistem yöneticileri
│   │   │   ├── component_manager.gd ✅ Component manager
│   │   │   ├── config_manager.gd    ✅ Config manager
│   │   │   ├── event_bus.gd         ✅ EventBus system
│   │   │   ├── combat_system.gd     ✅ Combat system
│   │   │   ├── economy.gd           ⏳
│   │   │   └── progression.gd       ⏳
│   │   └── 📁 utils/                # Yardımcı fonksiyonlar
│   │
│   ├── 📁 gameplay/                 # Oyun mekanikleri
│   │   ├── 📁 entities/             # Oyun varlıkları
│   │   │   ├── entity.gd            ✅ Entity base class
│   │   │   ├── player_entity.gd     ✅ Player entity
│   │   │   ├── enemy_entity.gd      ✅ Enemy entity (ORCHESTRATOR!)
│   │   │   ├── projectile_entity.gd ✅ Projectile entity
│   │   │   └── item_entity.gd       ✅ Item entity
│   │   ├── 📁 weapons/              # Silah sistemleri
│   │   └── 📁 items/                # Item sistemleri
│   │
│   ├── 📁 ui/                       # Kullanıcı arayüzü
│   │   ├── 📁 atoms/                # Temel UI bileşenleri
│   │   │   ├── button_atom.gd       ✅ Temel buton component
│   │   │   ├── label_atom.gd        ✅ Temel label component  
│   │   │   ├── progress_bar_atom.gd ✅ Temel progress bar
│   │   │   ├── icon_atom.gd         ✅ Temel icon component
│   │   │   └── panel_atom.gd        ✅ Temel panel container
│   │   ├── 📁 molecules/            # Bileşen grupları
│   │   │   ├── health_bar_molecule.gd ✅ HealthBar (ProgressBar + Label + Icon)
│   │   │   ├── weapon_card_molecule.gd ✅ WeaponCard (Icon + Name + Stats)
│   │   │   └── inventory_slot_molecule.gd ✅ InventorySlot (Panel + Icon + Count)
│   │   ├── 📁 organisms/            # Kompleks UI bölümleri
│   │   │   ├── game_hud_organism.gd ✅ GameHUD (HealthBar + XPBar + WeaponInfo + Inventory)
│   │   │   ├── mainmenu_organism.gd ✅ MainMenu (Panel + Label + Button + Icon)
│   │   │   ├── upgradescreen_organism.gd ✅ UpgradeScreen (Panel + Label + WeaponCard + ProgressBar + Button) - YENİ!
│   │   │   └── settingsscreen_organism.gd ✅ SettingsScreen (Panel + Label + Button + ProgressBar + Icon) - YENİ!
│   │   ├── 📁 systems/              # UI sistemleri
│   │   │   └── screen_navigation.gd ✅ Screen Navigation System
│   │   └── 📁 screens/              # Ekran şablonları
│   │
│   ├── 📁 test/                     # Test component'ları
│   │   ├── item_pickup_test.gd      ✅ Item pickup test
│   │   ├── weapon_firing_test.gd    ✅ Weapon firing test
│   │   ├── enemy_drop_test.gd       ✅ Enemy drop test
│   │   ├── ui_atoms_test.gd         ✅ UI Atoms test
│   │   ├── ui_molecules_test.gd     ✅ UI Molecules test
│   │   ├── ui_organisms_test.gd     ✅ UI Organisms test
│   │   ├── ui_screens_test.gd       ✅ UI Screens test (MODÜLER HALE GETİRİLDİ!)
│   │   ├── ui_test_manager.gd       ✅ UI Test Manager (F19-F31) - GÜNCELLENDİ!
│   │   └── test_orchestrator.gd     ✅ Test orchestrator
│   │
│   ├── 📁 test/modules/             # MODÜLER TEST SİSTEMİ - YENİ!
│   │   ├── ui_test_base.gd          ✅ Temel test sınıfı
│   │   ├── mainmenu_test_module.gd  ✅ MainMenu testleri
│   │   ├── screennavigation_test_module.gd ✅ ScreenNavigation testleri
│   │   ├── upgradescreen_test_module.gd ✅ UpgradeScreen testleri
│   │   ├── settingsscreen_test_module.gd ✅ SettingsScreen testleri
│   │   ├── performance_test_module.gd ✅ Performans testleri
│   │   └── ui_test_orchestrator.gd  ✅ Tüm modülleri yöneten orchestrator
│   │
│   └── 📁 data/                     # Data-driven config'ler
│       ├── weapons.json             ✅ 8 temel silah
│       ├── enemies.json             ✅ 8 düşman tipi
│       ├── items.json               ✅ 17 item tipi
│       ├── balance.json             ✅ Game balance config
│       └── ui.json                  ✅ UI config (screens güncellendi) - GÜNCELLENDİ!
│
├── 📁 assets/                       # Medya dosyaları
│   ├── 📁 audio/
│   ├── 📁 fonts/
│   └── 📁 textures/
│
├── 📁 config/                       # Proje konfigürasyonu
│   ├── project.godot
│   └── export_presets.cfg
│
├── 📁 tests/                        # Test dosyaları
│   ├── unit/
│   └── integration/
│
└── 📄 SURVIVOR_GAME_100M_PLAN.md    # Bu plan
```

## 🔧 TEKNİK MİMARİ

### **Component-Based Entity System**
```gdscript
# src/core/components/health_component.gd
class_name HealthComponent
extends Component

signal health_changed(old_value, new_value)
signal died

var max_health: float = 100
var current_health: float = 100
var is_invincible: bool = false

func take_damage(amount: float) -> void:
    if is_invincible:
        return
    
    var old_health = current_health
    current_health = max(0, current_health - amount)
    emit_signal("health_changed", old_health, current_health)
    
    if current_health <= 0:
        emit_signal("died")

# ---

# src/core/components/movement_component.gd
class_name MovementComponent
extends Component

var speed: float = 200
var velocity: Vector2 = Vector2.ZERO

func move(direction: Vector2) -> void:
    input_direction = direction.normalized() if direction.length() > 0.1 else Vector2.ZERO
```

### **EventBus System (Global Communication)**
```gdscript
# src/core/systems/event_bus.gd
class_name EventBus
extends Node

# 30+ predefined event types
const PLAYER_HEALTH_CHANGED = "player_health_changed"
const PLAYER_LEVEL_UP = "player_level_up"
const ENEMY_DIED = "enemy_died"
const PROJECTILE_HIT = "projectile_hit"
const DAMAGE_DEALT = "damage_dealt"
const ITEM_DROPPED = "item_dropped"
const ITEM_PICKED_UP = "item_picked_up"
const UI_BUTTON_CLICKED = "ui_button_clicked"
const SCREEN_CHANGED = "screen_changed"  # YENİ!
const SETTING_CHANGED = "setting_changed"  # YENİ!

# Subscribe to events
EventBus.subscribe_static(PLAYER_HEALTH_CHANGED, _on_player_health_changed)

# Emit events
EventBus.emit_now_static(DAMAGE_DEALT, {
    "attacker": player,
    "target": enemy,
    "damage": 50.0,
    "is_critical": true
})
```

### **Combat System (Damage & Status Effects)**
```gdscript
# src/core/systems/combat_system.gd
class_name CombatSystem
extends Node

enum StatusEffect { BURN, FREEZE, POISON, STUN, SLOW, WEAKEN, BLEED }

# Calculate damage with all modifiers
func calculate_damage(base_damage: float, attacker: Node, target: Node, damage_type: String) -> Dictionary:
    # Applies critical hits, resistances, bonuses, etc.
    return {
        "final_damage": final_damage,
        "is_critical": is_critical,
        "critical_multiplier": crit_multiplier
    }

# Apply status effects
func apply_status_effect(target: Node, effect_type: StatusEffect, duration: float, intensity: float) -> bool:
    # Applies burn, freeze, poison, etc.
    return true
```

### **Drop System (Atomic Component)**
```gdscript
# src/core/components/drop_component.gd
class_name DropComponent
extends Component

var drop_table: Array = []  # {item_id, weight, min_count, max_count}
var guaranteed_drops: Array = []
var currency_drop_range: Dictionary = {"min": 0, "max": 10}

func generate_drops(difficulty: int = 1) -> Array:
    # Weighted random drops with difficulty scaling
    return drops

func spawn_drops(drops: Array, spawn_position: Vector2) -> void:
    # Spawn item entities with visual effects
    pass
```

### **Enemy AI System (Atomic Component)**
```gdscript
# src/core/components/enemy_ai_component.gd
class_name EnemyAIComponent
extends Component

enum AIState { IDLE, CHASING, ATTACKING, FLEEING, PATROLLING }

var ai_state: AIState = AIState.IDLE
var target: Node2D = null
var detection_range: float = 300.0
var attack_range: float = 50.0

func get_movement_direction() -> Vector2:
    # Calculate movement based on AI state
    return direction

func get_movement_speed_multiplier() -> float:
    # Speed multiplier based on AI state
    return multiplier
```

### **UI Atomic System (ButtonAtom Example)**
```gdscript
# src/ui/atoms/button_atom.gd
class_name ButtonAtom
extends Control

# Config
var button_text: String = "Button"
var button_style: String = "default"
var is_disabled: bool = false

# Events
signal button_pressed
signal button_hovered
signal button_exited

# Data-driven
func load_config(config_id: String) -> void:
    var config = ConfigManager.get_ui_config(config_id)
    button_text = config.get("text", "Button")
    button_style = config.get("style", "default")
    update_visuals()
```

### **UI Molecule System (HealthBarMolecule Example)**
```gdscript
# src/ui/molecules/health_bar_molecule.gd
class_name HealthBarMolecule
extends Control

# Atoms
@onready var progress_bar: ProgressBarAtom = $ProgressBar
@onready var label: LabelAtom = $Label
@onready var icon: IconAtom = $Icon

# Data binding
func bind_to_entity(entity: Entity) -> void:
    var health_component = entity.get_component("HealthComponent")
    if health_component:
        health_component.health_changed.connect(_on_health_changed)
        update_display(health_component.current_health, health_component.max_health)
```

### **UI Organism System (UpgradeScreenOrganism Example)**
```gdscript
# src/ui/organisms/upgradescreen_organism.gd
class_name UpgradeScreenOrganism
extends Control

# Atoms ve Molecules
@onready var background_panel: PanelAtom = $BackgroundPanel
@onready var title_label: LabelAtom = $CenterContainer/VBoxContainer/TitleLabel
@onready var weapon_cards_container: HBoxContainer = $CenterContainer/VBoxContainer/WeaponCardsContainer
@onready var upgrade_button: ButtonAtom = $CenterContainer/VBoxContainer/UpgradeButton
@onready var back_button: ButtonAtom = $CenterContainer/VBoxContainer/BackButton

# Events
signal upgrade_screen_initialized
signal weapon_upgraded(weapon_id: String, new_level: int)
signal back_pressed

# Data-driven config
func _load_config() -> void:
    var config = ConfigManager.get_instance().get_config_value("ui.json", "screens.upgrade_screen", {})
    title_label.set_text(config.get("title", "UPGRADES"))
    upgrade_button.set_text(config.get("upgrade_button_text", "UPGRADE"))
    back_button.set_text(config.get("back_button_text", "BACK"))
```

### **SettingsScreenOrganism (Ayarlar Ekranı)**
```gdscript
# src/ui/organisms/settingsscreen_organism.gd
class_name SettingsScreenOrganism
extends Control

# Sections
@onready var audio_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/AudioSection
@onready var graphics_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GraphicsSection
@onready var controls_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/ControlsSection
@onready var gameplay_section: PanelAtom = $CenterContainer/VBoxContainer/SectionsContainer/GameplaySection

# Events
signal settings_screen_initialized
signal setting_changed(section: String, key: String, value)
signal settings_saved(settings: Dictionary)
signal back_pressed

# Settings management
func set_setting(section: String, key: String, value) -> void:
    current_settings[section][key] = value
    settings_changed = true
    setting_changed.emit(section, key, value)
```

### **Screen Navigation System**
```gdscript
# src/ui/systems/screen_navigation.gd
class_name ScreenNavigation
extends Node

enum ScreenType { MAIN_MENU, GAME_HUD, UPGRADE_SCREEN, SETTINGS_SCREEN, PAUSE_SCREEN, GAME_OVER }
enum TransitionType { NONE, FADE, SLIDE_LEFT, SLIDE_RIGHT, SLIDE_UP, SLIDE_DOWN, CROSSFADE }

func show_screen(screen_type: ScreenType, transition_type: TransitionType = TransitionType.FADE, data: Dictionary = {}) -> void:
    # Hide current screen with transition
    # Load/create new screen
    # Apply transition animation
    # Update screen stack
    # Emit events
    
    EventBus.emit_now_static("screen_changed", {
        "old_screen": _get_current_screen_type(),
        "new_screen": screen_type,
        "transition": transition_type,
        "data": data
    })
```

### **Modüler Test Sistemi**
```gdscript
# src/test/modules/ui_test_base.gd
class_name UITestBase
extends Node

# Tüm test modülleri için temel sınıf
var module_name: String = "Base"
var test_queue: Array = []
var test_results: Dictionary = {}
var is_testing: bool = false

func run_all_tests() -> void:
    is_testing = true
    test_queue = test_cases.duplicate()
    _run_next_test()

# ---

# src/test/modules/ui_test_orchestrator.gd
class_name UITestOrchestrator
extends Node

# Tüm test modüllerini yöneten orchestrator
var test_modules = [
    {"name": "MainMenu", "class": MainMenuTestModule},
    {"name": "ScreenNavigation", "class": ScreenNavigationTestModule},
    {"name": "UpgradeScreen", "class": UpgradeScreenTestModule},
    {"name": "SettingsScreen", "class": SettingsScreenTestModule},
    {"name": "Performance", "class": PerformanceTestModule}
]

func run_all_tests() -> void:
    # Tüm modülleri sırayla çalıştır
    for module_info in test_modules:
        _run_module(module_info)
```

## 🚀 ROADMAP (ATOMIC YAKLAŞIM)

### **FAZ 1: CORE COMPONENTS (2 Hafta) - %100 TAMAMLANDI ✅**
```
Hedef: Temel bileşen sistemi
```

**Atomic Components:**
- [x] HealthComponent ✅
- [x] MovementComponent ✅  
- [x] WeaponComponent ✅
- [x] InventoryComponent ✅
- [x] ExperienceComponent ✅
- [x] DropComponent ✅
- [x] EnemyAIComponent ✅
- [x] EnemyStatsComponent ✅

**Core Systems:**
- [x] ComponentManager ✅
- [x] EventBus (global event sistemi) ✅
- [ ] SaveSystem ⏳
- [x] ConfigManager ✅
- [x] CombatSystem ✅

### **FAZ 2: GAMEPLAY ENTITIES (3 Hafta) - %100 TAMAMLANDI ✅**
```
Hedef: Çalışan oyun mekanikleri
```

**Entities:**
- [x] Player (component'ları birleştir) ✅
- [x] Enemy (orchestrator pattern) ✅
- [x] Projectile System ✅
- [x] Item Pickups ✅

**Weapons:**
- [x] 8 temel silah (weapons.json) ✅
- [x] Data-driven weapon config ✅
- [x] Basic evolve sistemi ✅

**Test System:**
- [x] Test Orchestrator ✅
- [x] Item Pickup Test Component ✅
- [x] Weapon Firing Test Component ✅
- [x] Enemy Drop Test Component ✅

### **FAZ 3: UI SYSTEM (2 Hafta) - %95 TAMAMLANDI**
```
Hedef: Atomic UI sistemi
```

**UI Atoms:**
- [x] ButtonAtom ✅
- [x] LabelAtom ✅
- [x] ProgressBarAtom ✅
- [x] IconAtom ✅
- [x] PanelAtom ✅

**UI Molecules:**
- [x] HealthBarMolecule ✅
- [x] WeaponCardMolecule ✅
- [x] InventorySlotMolecule ✅

**UI Organisms:**
- [x] GameHUDOrganism ✅
- [x] MainMenuOrganism ✅
- [x] UpgradeScreenOrganism ✅ - YENİ!
- [x] SettingsScreenOrganism ✅ - YENİ!

**UI Systems:**
- [x] ScreenNavigation ✅

**Modüler Test Sistemi:**
- [x] UI Test Base Class ✅ - YENİ!
- [x] MainMenu Test Module ✅ - YENİ!
- [x] ScreenNavigation Test Module ✅ - YENİ!
- [x] UpgradeScreen Test Module ✅ - YENİ!
- [x] SettingsScreen Test Module ✅ - YENİ!
- [x] Performance Test Module ✅ - YENİ!
- [x] UI Test Orchestrator ✅ - YENİ!

**UI Test System:**
- [x] UI Atoms Test ✅
- [x] UI Molecules Test ✅
- [x] UI Organisms Test ✅
- [x] UI Screens Test ✅ (MODÜLER HALE GETİRİLDİ!)
- [x] UI Test Manager (F19-F31) ✅ (GÜNCELLENDİ!)

### **FAZ 4: GAME BALANCE & PROGRESSION SYSTEM (YENİ CONTEXT)**
```
Hedef: Oyun denge ve ilerleme sistemi
```

**Balance Systems:**
- [ ] Player Progression - Level, XP, skill tree
- [ ] Weapon Balance - Damage, fire rate, upgrade scaling
- [ ] Enemy Scaling - Zorluk curve'ü
- [ ] Economy System - Para, item fiyatları, upgrade maliyetleri
- [ ] Difficulty Settings - Easy/Medium/Hard balance

**Progression:**
- [ ] Skill tree system
- [ ] Prestige system
- [ ] Achievement system
- [ ] Daily/weekly challenges

### **FAZ 5: POLISH & MVP (3 Hafta)**
```
Hedef: Steam Early Access
```

**Polish:**
- [ ] Particle effects
- [ ] Sound system
- [ ] Screen shake
- [ ] Tutorial

**Release:**
- [ ] Steam build
- [ ] Analytics
- [ ] Crash reporting

## 🎯 İLERLEME DURUMU - %95 TAMAMLANDI

### **Tamamlananlar:**
```
✅ Component Foundation (Gün 1-2)
✅ Entity System (Gün 3-4)
✅ Data-Driven Systems (Gün 5-7)
✅ EventBus System (Gün 8)
✅ Combat System (Gün 8)
✅ Projectile System (Gün 8)
✅ Item Pickup System (Gün 8)
✅ Drop System (Gün 8)
✅ AI System (Gün 8)
✅ Test System (Gün 8)
✅ UI Atomic System (Gün 9)
✅ MainMenu Organism (Gün 10)
✅ Screen Navigation (Gün 10)
✅ UI Screens Test (Gün 10)
✅ UpgradeScreen Organism (Gün 11) - YENİ!
✅ SettingsScreen Organism (Gün 11) - YENİ!
✅ Modüler Test Sistemi (Gün 11) - YENİ! (1378 satır → 6 modül)
```

### **Çalışan Sistemler:**
1. Component-based architecture ✅
2. Data-driven config system ✅
3. Event-driven communication ✅
4. Combat mechanics ✅
5. Projectile system ✅
6. AI system ✅
7. Inventory system ✅
8. Experience/leveling ✅
9. Item pickup system ✅
10. Drop system ✅
11. Rarity system ✅
12. Test system ✅
13. UI Atomic System ✅
14. MainMenu Organism ✅
15. UpgradeScreen Organism ✅ - YENİ!
16. SettingsScreen Organism ✅ - YENİ!
17. Screen Navigation ✅
18. **Modüler Test Sistemi** ✅ - YENİ!

## 📁 MEVCUT PROJEYİ DÖNÜŞTÜRME PLANI

### **Adım 1: Component'lara Ayır** ✅
```
player.gd → HealthComponent + MovementComponent + WeaponComponent ✅
```

### **Adım 2: Data-Driven Yap** ✅
```
game_data.gd → JSON config'ler + ConfigManager ✅
```

### **Adım 3: EventBus Kur** ✅
```
signal'ler → EventBus events ✅
```

### **Adım 4: Orchestrator Pattern** ✅
```
enemy.gd → EnemyAIComponent + DropComponent + EnemyStatsComponent ✅
```

### **Adım 5: Test System** ✅
```
test.gd → Atomic test components + Test orchestrator ✅
```

### **Adım 6: UI'ı Atomic Yap** ✅
```
menu.gd → Atomic UI bileşenleri ✅
```

### **Adım 7: Screen Navigation Kur** ✅
```
ekran geçişleri → ScreenNavigation sistemi ✅
```

### **Adım 8: Modüler Test Sistemi Kur** ✅
```
1378 satırlık monolitik test → 6 modül + orchestrator ✅
```

### **Adım 9: Sistemleri Ayır** ⏳
```
sound_manager.gd → AudioSystem
upgrade_panel.gd → UpgradeSystem
```

## 🔄 WORKFLOW PRENSİPLERİ

### **1. Git Branch Strategy:**
```
main (production)
├── develop (integration)
│   ├── feature/component-health ✅
│   ├── feature/weapon-system ✅
│   ├── feature/entity-system ✅
│   ├── feature/config-system ✅
│   ├── feature/eventbus-system ✅
│   ├── feature/combat-system ✅
│   ├── feature/projectile-system ✅
│   ├── feature/item-pickup-system ✅
│   ├── feature/drop-system ✅
│   ├── feature/ai-system ✅
│   ├── feature/test-system ✅
│   ├── feature/ui-atoms ✅
│   ├── feature/ui-molecules ✅
│   ├── feature/ui-organisms ✅
│   ├── feature/mainmenu-organism ✅
│   ├── feature/screen-navigation ✅
│   ├── feature/upgradescreen-organism ✅ - YENİ!
│   ├── feature/settingsscreen-organism ✅ - YENİ!
│   └── feature/modular-test-system ✅ - YENİ!
└── hotfix/ (acil düzeltmeler)
```

### **2. Code Review Checklist:**
- [ ] Atomic design prensiplerine uyuyor mu?
- [ ] Component bağımsız mı?
- [ ] Data-driven mi?
- [ ] EventBus kullanıyor mu?
- [ ] Unit test yazıldı mı?
- [ ] Performance optimizasyonu var mı?
- [ ] Modüler test sistemi entegre edildi mi?

### **3. Daily Standup Format:**
```
1. Dün ne yaptın? (UpgradeScreen, SettingsScreen ve modüler test sistemi geliştirdim)
2. Bugün ne yapacaksın? (Game Balance & Progression System başlayacağım)
3. Engel var mı? (Yok, mükemmel ilerliyor)
```

## 🧪 TEST STRATEJİSİ

### **Unit Tests (Her Component):**
```gdscript
func test_health_component_take_damage():
    var health = HealthComponent.new()
    health.max_health = 100
    health.current_health = 100
    
    health.take_damage(30)
    assert_eq(health.current_health, 70)
```

### **Integration Tests:**
```gdscript
func test_player_combat():
    var player = PlayerEntity.new()
    var enemy = EnemyEntity.new()
    
    player.attack(enemy)
    assert_true(enemy.health < enemy.max_health)
```

### **System Tests:**
```gdscript
func test_eventbus_communication():
    var event_received = false
    EventBus.subscribe_static("test_event", func(e): event_received = true)
    EventBus.emit_now_static("test_event")
    assert_true(event_received)
```

### **Modüler Test Sistemi:**
```
src/test/modules/
├── ui_test_base.gd          # Temel test sınıfı
├── mainmenu_test_module.gd  # MainMenu testleri
├── screennavigation_test_module.gd  # Navigation testleri
├── upgradescreen_test_module.gd     # UpgradeScreen testleri
├── settingsscreen_test_module.gd    # SettingsScreen testleri
├── performance_test_module.gd       # Performans testleri
└── ui_test_orchestrator.gd  # Tüm modülleri yöneten orchestrator
```

### **UI Test Komutları (Yeni F Tuşları):**
```
F1-F12: Core system tests
F13: Item Pickup Test
F14: Weapon Firing Test
F15: Enemy Drop Test
F16: Run All Tests
F17: Show Results
F18: Reset Tests

F19: UI Atoms Test
F20: UI Molecules Test
F21: UI Organisms Test
F22: Full UI Integration Test
F23: SaveSystem Test
F24: AudioSystem Test

F25: MainMenu Test
F26: UpgradeScreen Test - YENİ!
F27: SettingsScreen Test - YENİ!
F28: Navigation System Test
F29: Full UI Integration Test
F30: UI Performance Test
F31: All Modules Test - YENİ!
```

## 📊 PROGRESS TRACKING

### **Component Completion:**
```
HealthComponent: ✅
MovementComponent: ✅
WeaponComponent: ✅
InventoryComponent: ✅
ExperienceComponent: ✅
DropComponent: ✅
EnemyAIComponent: ✅
EnemyStatsComponent: ✅
```

### **System Completion:**
```
ComponentManager: ✅
EventBus: ✅
SaveSystem: ⏳
ConfigManager: ✅
CombatSystem: ✅
ScreenNavigation: ✅
Modüler Test Sistemi: ✅ - YENİ!
```

### **Gameplay Completion:**
```
Player Entity: ✅
Enemy Entity: ✅
Weapon System: ✅
Item System: ✅
Projectile System: ✅
Drop System: ✅
AI System: ✅
```

### **Data Config Completion:**
```
Weapons Config: ✅ (8 weapons)
Enemies Config: ✅ (8 enemies)  
Items Config: ✅ (17 items)
Balance Config: ✅ (Full balance)
UI Config: ✅ (UI Atomic System için) - GÜNCELLENDİ!
```

### **Test System Completion:**
```
Test Orchestrator: ✅
Item Pickup Test: ✅
Weapon Firing Test: ✅
Enemy Drop Test: ✅
UI Atoms Test: ✅
UI Molecules Test: ✅
UI Organisms Test: ✅
UI Screens Test: ✅ (MODÜLER HALE GETİRİLDİ!)
UI Test Manager: ✅ (GÜNCELLENDİ! F19-F31)
Modüler Test Sistemi: ✅ (6 modül + orchestrator) - YENİ!
```

### **UI System Completion:**
```
UI Atoms: ✅ (5 atom)
UI Molecules: ✅ (3 molecule)
UI Organisms: ✅ (4 organism)
UI Systems: ✅ (1 system)
UI Screens: ✅ (4/4 screen)
```

## 🚨 ACİL YAPILACAKLAR

### **Bugün (Başlangıç):** ✅ TAMAMLANDI
1. [x] Component base class oluştur
2. [x] HealthComponent implement et
3. [x] MovementComponent implement et
4. [x] ComponentManager oluştur

### **Bu Hafta:** ✅ %100 TAMAMLANDI
1. [x] Tüm core component'ları bitir ✅
2. [x] Player entity oluştur (component'ları birleştir) ✅
3. [x] weapons.json yapısını tamamla ✅
4. [x] Basic combat sistemi kur ✅
5. [x] EventBus sistemi oluştur ✅
6. [x] Projectile sistemi oluştur ✅
7. [x] Item pickup sistemi oluştur ✅
8. [x] Drop sistemi oluştur ✅
9. [x] AI sistemi oluştur ✅
10. [x] Test sistemi oluştur ✅
11. [x] UI Atomic sistemi başlat ✅
12. [x] MainMenu organism oluştur ✅
13. [x] Screen navigation sistemi oluştur ✅
14. [x] UI Screens test'leri oluştur ✅
15. [x] F25-F30 test komutlarını ekle ✅
16. [x] UpgradeScreen organism oluştur ✅ - YENİ!
17. [x] SettingsScreen organism oluştur ✅ - YENİ!
18. [x] Modüler test sistemi oluştur ✅ - YENİ!
19. [x] F31 test komutunu ekle ✅ - YENİ!

### **Önümüzdeki 2 Hafta:**
1. [ ] Game Balance & Progression System oluştur
2. [ ] SaveSystem oluştur
3. [ ] Steam hazırlığı
4. [ ] İlk playtest

## 🎮 SONRAKİ ADIMLAR

#### **Hemen Yapılacaklar:**
1. [x] EventBus sistemi oluştur (global event communication) ✅
2. [x] Projectile entity ve sistemi oluştur ✅
3. [x] Combat sistemi tamamla (player vs enemy) ✅
4. [x] Item pickup entity ve sistemi oluştur ✅
5. [x] Drop sistemi oluştur ✅
6. [x] AI sistemi oluştur ✅
7. [x] Test sistemi oluştur ✅
8. [x] UI Atomic sistemi başlat ✅
9. [x] MainMenu organism oluştur ✅
10. [x] Screen navigation sistemi oluştur ✅
11. [x] UpgradeScreen organism oluştur ✅
12. [x] SettingsScreen organism oluştur ✅
13. [x] Modüler test sistemi oluştur ✅
14. [x] F25-F31 test komutlarını ekle ✅
15. [ ] SaveSystem oluştur (oyun kaydetme/yükleme) ⏳

### **UI Sistemi Devam:**
1. [x] UI Atom'ları oluştur (Button, Label, ProgressBar, Icon, Panel) ✅
2. [x] HealthBar molecule oluştur ✅
3. [x] WeaponCard molecule oluştur ✅
4. [x] InventorySlot molecule oluştur ✅
5. [x] GameHUD organism oluştur ✅
6. [x] MainMenu organism oluştur ✅
7. [x] Screen navigation sistemi oluştur ✅
8. [x] UpgradeScreen organism oluştur ✅
9. [x] SettingsScreen organism oluştur ✅
10. [x] Modüler test sistemi oluştur ✅
11. [ ] Scene dosyaları oluştur (.tscn) ⏳
12. [ ] UI asset'leri ekle (icon'lar, background'lar, font'lar) ⏳

## 🎮 YENİ CONTEXT: GAME BALANCE & PROGRESSION SYSTEM

### **Hedefler:**
1. **Player Progression System** - Level, XP, skill tree
2. **Weapon Balance System** - Damage scaling, upgrade costs, evolution
3. **Enemy Scaling System** - Difficulty curve, wave progression
4. **Economy System** - Currency, item prices, upgrade costs
5. **Difficulty Settings** - Easy/Medium/Hard/Nightmare balance

### **Mevcut Durum Analizi:**
```
✅ balance.json - Mevcut balance config (tamam)
✅ weapons.json - 8 silah config (tamam)
✅ enemies.json - 8 düşman config (tamam)
✅ items.json - 17 item config (tamam)
⏳ progression_system.gd - Progression sistemi (eksik)
⏳ economy_system.gd - Ekonomi sistemi (eksik)
⏳ difficulty_manager.gd - Zorluk yöneticisi (eksik)
```

### **Yapılacaklar:**
1. **Progression System** - Player level, XP, skill tree
2. **Weapon Balance Manager** - Upgrade scaling, cost calculation
3. **Enemy Scaling Manager** - Wave-based difficulty scaling
4. **Economy Manager** - Currency system, prices, rewards
5. **Difficulty Manager** - Difficulty settings and modifiers

### **Teknik Detaylar:**

#### **1. Progression System**
```gdscript
# src/core/systems/progression_system.gd
class_name ProgressionSystem
extends Node

var player_level: int = 1
var player_xp: int = 0
var xp_to_next_level: int = 100
var skill_points: int = 0
var unlocked_skills: Array = []

func add_xp(amount: int) -> void:
    player_xp += amount
    while player_xp >= xp_to_next_level:
        level_up()
    
    EventBus.emit_now_static("player_xp_gained", {
        "amount": amount,
        "total_xp": player_xp,
        "xp_to_next_level": xp_to_next_level
    })

func level_up() -> void:
    player_level += 1
    player_xp -= xp_to_next_level
    xp_to_next_level = calculate_xp_for_level(player_level)
    skill_points += 1
    
    EventBus.emit_now_static("player_level_up", {
        "new_level": player_level,
        "skill_points_gained": 1,
        "total_skill_points": skill_points
    })
```

#### **2. Weapon Balance Manager**
```gdscript
# src/core/systems/weapon_balance_manager.gd
class_name WeaponBalanceManager
extends Node

func calculate_upgrade_cost(weapon_id: String, current_level: int) -> int:
    var weapon_config = ConfigManager.get_weapon_config(weapon_id)
    var base_cost = weapon_config.get("upgrade_cost_base", 100)
    var multiplier = weapon_config.get("upgrade_cost_multiplier", 1.5)
    
    return int(base_cost * pow(multiplier, current_level - 1))

func calculate_upgrade_stats(weapon_id: String, current_level: int) -> Dictionary:
    var weapon_config = ConfigManager.get_weapon_config(weapon_id)
    var base_damage = weapon_config.get("damage", 10)
    var damage_per_level = weapon_config.get("damage_upgrade_per_level", 0.1)
    
    return {
        "damage": base_damage * (1 + damage_per_level * current_level),
        "fire_rate": calculate_fire_rate(weapon_config, current_level),
        "magazine_size": calculate_magazine_size(weapon_config, current_level),
        "reload_time": calculate_reload_time(weapon_config, current_level)
    }
```

#### **3. Enemy Scaling Manager**
```gdscript
# src/core/systems/enemy_scaling_manager.gd
class_name EnemyScalingManager
extends Node

var current_wave: int = 1
var difficulty_multiplier: float = 1.0

func get_scaled_enemy_stats(enemy_id: String) -> Dictionary:
    var enemy_config = ConfigManager.get_enemy_config(enemy_id)
    var base_health = enemy_config.get("health", 100)
    var base_damage = enemy_config.get("damage", 10)
    var base_speed = enemy_config.get("speed", 100)
    
    var scaling = ConfigManager.get_balance_config("enemies.scaling", {})
    var health_multiplier = scaling.get("health_multiplier_per_wave", 1.15)
    var damage_multiplier = scaling.get("damage_multiplier_per_wave", 1.1)
    var speed_multiplier = scaling.get("speed_multiplier_per_wave", 1.05)
    
    return {
        "health": base_health * pow(health_multiplier, current_wave - 1) * difficulty_multiplier,
        "damage": base_damage * pow(damage_multiplier, current_wave - 1) * difficulty_multiplier,
        "speed": base_speed * pow(speed_multiplier, current_wave - 1)
    }
```

#### **4. Economy Manager**
```gdscript
# src/core/systems/economy_manager.gd
class_name EconomyManager
extends Node

var player_currency: int = 0
var transaction_history: Array = []

func add_currency(amount: int, source: String = "unknown") -> void:
    player_currency += amount
    transaction_history.append({
        "type": "income",
        "amount": amount,
        "source": source,
        "timestamp": Time.get_unix_time_from_system(),
        "balance": player_currency
    })
    
    EventBus.emit_now_static("currency_gained", {
        "amount": amount,
        "source": source,
        "new_balance": player_currency
    })

func spend_currency(amount: int, purpose: String = "unknown") -> bool:
    if player_currency >= amount:
        player_currency -= amount
        transaction_history.append({
            "type": "expense",
            "amount": amount,
            "purpose": purpose,
            "timestamp": Time.get_unix_time_from_system(),
            "balance": player_currency
        })
        
        EventBus.emit_now_static("currency_spent", {
            "amount": amount,
            "purpose": purpose,
            "new_balance": player_currency
        })
        return true
    return false
```

#### **5. Difficulty Manager**
```gdscript
# src/core/systems/difficulty_manager.gd
class_name DifficultyManager
extends Node

enum Difficulty { EASY, NORMAL, HARD, NIGHTMARE }

var current_difficulty: Difficulty = Difficulty.NORMAL
var difficulty_multipliers: Dictionary = {
    Difficulty.EASY: 0.7,
    Difficulty.NORMAL: 1.0,
    Difficulty.HARD: 1.5,
    Difficulty.NIGHTMARE: 2.5
}

func set_difficulty(difficulty: Difficulty) -> void:
    current_difficulty = difficulty
    EventBus.emit_now_static("difficulty_changed", {
        "difficulty": Difficulty.keys()[difficulty],
        "multiplier": difficulty_multipliers[difficulty]
    })

func get_difficulty_multiplier() -> float:
    return difficulty_multipliers[current_difficulty]

func apply_difficulty_modifiers(stats: Dictionary) -> Dictionary:
    var multiplier = get_difficulty_multiplier()
    var modified_stats = stats.duplicate()
    
    # Apply difficulty modifiers
    modified_stats["enemy_health"] *= multiplier
    modified_stats["enemy_damage"] *= multiplier
    modified_stats["enemy_speed"] *= (1 + (multiplier - 1) * 0.2)  # Speed scales slower
    
    # Player gets bonuses on easier difficulties
    if multiplier < 1.0:
        modified_stats["player_damage"] *= (1 + (1 - multiplier) * 0.3)
        modified_stats["player_health_regen"] *= (1 + (1 - multiplier) * 0.5)
    
    return modified_stats
```

## 🚀 SONRAKİ ADIMLAR (ÖNCELİK SIRASI)

### **1. GAME BALANCE & PROGRESSION SYSTEM (ACİL)**
- [ ] ProgressionSystem oluştur
- [ ] WeaponBalanceManager oluştur
- [ ] EnemyScalingManager oluştur
- [ ] EconomyManager oluştur
- [ ] DifficultyManager oluştur
- [ ] Balance config'leri güncelle

### **2. SAVESYSTEM**
- [ ] Game state serialization
- [ ] Config persistence
- [ ] Player progress saving
- [ ] Multiple save slots

### **3. AUDIO SYSTEM**
- [ ] Sound effect management
- [ ] Music system
- [ ] Volume controls
- [ ] Spatial audio

### **4. POLISH & EFFECTS**
- [ ] Particle effects
- [ ] Screen shake
- [ ] Visual feedback
- [ ] Animation system

## 📊 İLERLEME DURUMU - %95 TAMAMLANDI

### **Tamamlananlar:**
```
✅ Component Foundation (Gün 1-2)
✅ Entity System (Gün 3-4)
✅ Data-Driven Systems (Gün 5-7)
✅ EventBus System (Gün 8)
✅ Combat System (Gün 8)
✅ Projectile System (Gün 8)
✅ Item Pickup System (Gün 8)
✅ Drop System (Gün 8)
✅ AI System (Gün 8)
✅ Test System (Gün 8)
✅ UI Atomic System (Gün 9)
✅ MainMenu Organism (Gün 10)
✅ Screen Navigation (Gün 10)
✅ UpgradeScreen Organism (Gün 11)
✅ SettingsScreen Organism (Gün 11)
✅ Modüler Test Sistemi (Gün 11)
✅ F25-F31 Test Komutları (Gün 11)
```

### **Çalışan Sistemler:**
1. Component-based architecture ✅
2. Data-driven config system ✅
3. Event-driven communication ✅
4. Combat mechanics ✅
5. Projectile system ✅
6. AI system ✅
7. Inventory system ✅
8. Experience/leveling ✅
9. Item pickup system ✅
10. Drop system ✅
11. Rarity system ✅
12. Test system ✅
13. UI Atomic System ✅
14. MainMenu Organism ✅
15. Screen Navigation ✅
16. UpgradeScreen Organism ✅
17. SettingsScreen Organism ✅
18. Modüler Test Sistemi ✅

## 🎮 SON SÖZ

**KURAL #1:** Her şey component olsun ✅
**KURAL #2:** Her şey data-driven olsun ✅  
**KURAL #3:** EventBus ile iletişim kurulsun ✅
**KURAL #4:** Orchestrator pattern kullan ✅
**KURAL #5:** Atomic design prensibine uy ✅
**KURAL #6:** Modüler ve test edilebilir olsun ✅
**KURAL #7:** Screen navigation sistemi kur ✅
**KURAL #8:** Modüler test sistemi kur ✅

**Başarı Formülü:**
```
Atomic Components + Data-Driven Design + EventBus + Orchestrator Pattern + 
UI Atomic Design + Screen Navigation + Modüler Test Sistemi = 100M Oyuncu
```

**İlerleme Durumu:** 🚀 **MÜKEMMEL İLERLEME!** 
- Tüm core component'lar tamamlandı ✅
- Entity sistemi kuruldu ✅
- Data-driven config'ler hazır ✅
- ComponentManager ve ConfigManager çalışıyor ✅
- EventBus sistemi kuruldu ✅
- Combat sistemi kuruldu ✅
- Projectile sistemi kuruldu ✅
- Item pickup sistemi kuruldu ✅
- Drop sistemi kuruldu ✅
- AI sistemi kuruldu ✅
- Test sistemi kuruldu ✅
- UI Atomic sistemi %95 tamamlandı ✅
- MainMenu organism tamamlandı ✅
- UpgradeScreen organism tamamlandı ✅
- SettingsScreen organism tamamlandı ✅
- Screen navigation sistemi tamamlandı ✅
- Modüler test sistemi kuruldu ✅
- F25-F31 test komutları eklendi ✅

**SONRAKİ HEDEF:** Game Balance & Progression System oluştur!

---
*Bu plan canlı bir dokümandır. Her component tamamlandıkça güncellenecektir.*
*Son güncelleme: 2024-01-15 - FAZ 1 %100, FAZ 2 %100, FAZ 3 %95 TAMAMLANDI*