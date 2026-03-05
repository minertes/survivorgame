# 🏢 LOBBY MOLECULE (ENTERPRISE MODULAR)
# Modüler lobi - class_name kaldırıldı (Windows'ta aynı dosya iki yol ile yüklenip "hides" hatası veriyordu)
extends LobbyMoleculeBase

# Base sınıfın parse sırasında yüklenmesini garantile
const _BASE_CLASS = preload("res://src/ui/molecules/lobby_molecule_base.gd")

# === SCENE NODE REFS (sahne ile eşleşir) ===
var header_component: Node = null
var content_manager: Node = null
var player_data_manager: Node = null
var component_initializer: Node = null
var signal_router: Node = null

# === INITIALIZATION STATE ===
var modular_components_ready: bool = false
var _is_syncing_player_data: bool = false

# === LIFECYCLE ===

func _initialize() -> void:
	print("🚀 LobbyMolecule (Modular): Initializing...")
	
	# Sahne düğümlerini al (lobby_molecule.tscn ile uyumlu)
	header_component = get_node_or_null("HeaderComponent")
	content_manager = get_node_or_null("ContentManager")
	player_data_manager = get_node_or_null("PlayerDataManager")
	
	# ComponentInitializer ve SignalRouter — sahnedekini kullan, yoksa yükle
	component_initializer = get_node_or_null("ComponentInitializer")
	if not component_initializer:
		var init_scene = load("res://src/ui/molecules/core/component_initializer_node.tscn") as PackedScene
		if init_scene:
			component_initializer = init_scene.instantiate()
			add_child(component_initializer)
	
	signal_router = get_node_or_null("SignalRouter")
	if not signal_router:
		var router_scene = load("res://src/ui/molecules/core/signal_router_node.tscn") as PackedScene
		if router_scene:
			signal_router = router_scene.instantiate()
			add_child(signal_router)
	
	# Geri ve Oyun başlat sinyallerini bağla
	_connect_lobby_ui_signals()
	
	# Temel bileşenleri başlat
	super._initialize()
	
	# Atomic bileşenleri başlat (content_manager varsa)
	_initialize_atomic_components()
	
	# Sinyal yönlendirmeyi kur
	_setup_signal_routing()
	
	modular_components_ready = true
	print("✅ LobbyMolecule (Modular): Initialized successfully")

func _initialize_atomic_components() -> void:
	print("🔧 Initializing atomic components...")
	
	if not content_manager or not component_initializer:
		print("❌ ContentManager or ComponentInitializer not available")
		return
	if not component_initializer.has_method("initialize_components"):
		print("❌ ComponentInitializer script not loaded (missing initialize_components)")
		return
	
	# Atomic bileşenleri başlat (tab, karakter, silah, bayrak seçicileri)
	component_initializer.initialize_components(content_manager)
	
	# Tab içeriğini seçili sekmeye göre göster (layout bir frame sonra hazır olsun diye deferred)
	if content_manager.has_method("show_tab") and content_manager.has_method("get_current_tab"):
		content_manager.call_deferred("show_tab", content_manager.get_current_tab())
	
	print("✅ Atomic components initialized")

func _setup_signal_routing() -> void:
	print("🔌 Setting up signal routing...")
	
	if not signal_router or not player_data_manager or not component_initializer:
		print("❌ SignalRouter, PlayerDataManager or ComponentInitializer not available")
		return
	if not component_initializer.has_method("get_component") or not signal_router.has_method("setup_signal_routing"):
		print("❌ SignalRouter or ComponentInitializer script not loaded")
		return
	
	# Atomic bileşenleri al
	var components = {
		"character_selector": component_initializer.get_component("character_selector"),
		"weapon_selector": component_initializer.get_component("weapon_selector"),
		"flag_selector": component_initializer.get_component("flag_selector")
	}
	
	# Sinyal yönlendirmeyi kur
	signal_router.setup_signal_routing(components, player_data_manager)
	# Satın alma sonrası tüm seçicileri güncelle (owned_* değişince SEÇ butonu görünsün)
	if player_data_manager.has_signal("player_data_changed"):
		player_data_manager.player_data_changed.connect(_on_player_data_changed)
	
	print("✅ Signal routing setup completed")

func _connect_lobby_ui_signals() -> void:
	if header_component and header_component.has_signal("back_pressed"):
		header_component.back_pressed.connect(go_back)
		print("🔗 Header back_pressed → go_back connected")
	if content_manager and content_manager.has_signal("play_button_pressed"):
		content_manager.play_button_pressed.connect(_on_play_button_pressed)
		print("🔗 Content play_button_pressed → start_game connected")

func _on_play_button_pressed() -> void:
	print("🎮 LobbyMolecule: Oyuna Başla pressed, calling start_game()")
	start_game()

func _on_player_data_changed() -> void:
	# Kendi set_player_data çağrımız tekrar sinyal tetiklemesin
	if _is_syncing_player_data:
		return
	# Satın alma / seçim sonrası veriyi seçicilere ve header'a tekrar ver
	if player_data_manager and player_data_manager.has_method("get_player_data"):
		_is_syncing_player_data = true
		set_player_data(player_data_manager.get_player_data())
		_is_syncing_player_data = false

# === PUBLIC API (Extended) ===

func set_player_data(data: Dictionary) -> void:
	if player_data_manager and player_data_manager.has_method("set_player_data"):
		player_data_manager.set_player_data(data)
	# Selector'lara da veriyi ilet (xp, owned_*, selected_*) yoksa tab içerikleri boş kalır
	var xp: int = data.get("xp", 0)
	# Header'da XP gösterimi (para birimi) — yoksa lobide hep 0 görünür
	if header_component and header_component.has_method("set_player_xp"):
		header_component.set_player_xp(xp, false)
	if content_manager:
		var char_sel = content_manager.character_selector
		if char_sel and char_sel.has_method("set_player_data"):
			char_sel.set_player_data(
				xp,
				data.get("owned_characters", ["male_soldier"]),
				data.get("selected_character", "male_soldier"))
		var wep_sel = content_manager.weapon_selector
		if wep_sel and wep_sel.has_method("set_player_data"):
			wep_sel.set_player_data(
				xp,
				data.get("owned_weapons", {"machinegun": 1}),
				data.get("selected_weapon", "machinegun"))
		var flag_sel = content_manager.flag_selector
		if flag_sel and flag_sel.has_method("set_player_data"):
			flag_sel.set_player_data(
				xp,
				data.get("owned_flags", ["turkey"]),
				data.get("selected_flag", "turkey"))
		var stats = content_manager.stats_display
		if stats:
			if stats.has_method("set_player_stats"):
				stats.set_player_stats(data.get("stats", {}))
			if stats.has_method("set_character_stats"):
				stats.set_character_stats({
					"selected_character": data.get("selected_character", "male_soldier"),
					"character_level": 1,
					"character_xp": xp
				})
			if stats.has_method("set_weapon_stats"):
				var ow: Dictionary = data.get("owned_weapons", {"machinegun": 1})
				var sel_wep: String = data.get("selected_weapon", "machinegun")
				stats.set_weapon_stats({
					"selected_weapon": sel_wep,
					"weapon_level": int(ow.get(sel_wep, 1)),
					"total_damage": 0
				})

func get_player_data() -> Dictionary:
	if player_data_manager and player_data_manager.has_method("get_player_data"):
		return player_data_manager.get_player_data()
	return {}

func purchase_character(character_id: String) -> bool:
	if not player_data_manager:
		return false
	
	var character_selector = component_initializer.get_component("character_selector") if component_initializer else null
	if not character_selector:
		return false
	
	var cost = character_selector.get_character_cost(character_id)
	return player_data_manager.purchase_character(character_id, cost)

func purchase_weapon(weapon_id: String) -> bool:
	if not player_data_manager:
		return false
	
	var weapon_selector = component_initializer.get_component("weapon_selector") if component_initializer else null
	if not weapon_selector:
		return false
	
	var cost = weapon_selector.get_weapon_cost(weapon_id)
	return player_data_manager.purchase_weapon(weapon_id, cost)

func purchase_flag(flag_id: String) -> bool:
	if not player_data_manager:
		return false
	
	var flag_selector = component_initializer.get_component("flag_selector") if component_initializer else null
	if not flag_selector:
		return false
	
	var cost = flag_selector.get_flag_cost(flag_id)
	return player_data_manager.purchase_flag(flag_id, cost)

func upgrade_weapon(weapon_id: String) -> bool:
	if not player_data_manager:
		return false
	
	var weapon_selector = component_initializer.get_component("weapon_selector") if component_initializer else null
	if not weapon_selector:
		return false
	
	var cost = weapon_selector.get_upgrade_cost(weapon_id)
	return player_data_manager.upgrade_weapon(weapon_id, cost)

func select_character(character_id: String) -> void:
	if player_data_manager:
		player_data_manager.select_character(character_id)

func select_weapon(weapon_id: String) -> void:
	if player_data_manager:
		player_data_manager.select_weapon(weapon_id)

func select_flag(flag_id: String) -> void:
	if player_data_manager:
		player_data_manager.select_flag(flag_id)

func update_player_stats(new_stats: Dictionary) -> void:
	if player_data_manager:
		player_data_manager.update_stats(new_stats)

func start_game() -> void:
	var c := "male_soldier"
	var w := "machinegun"
	var f := "turkey"
	if player_data_manager and player_data_manager.has_method("get_selected_items"):
		var sel = player_data_manager.get_selected_items()
		c = sel.get("character", c)
		w = sel.get("weapon", w)
		f = sel.get("flag", f)
		if c.is_empty(): c = "male_soldier"
		if w.is_empty(): w = "machinegun"
		if f.is_empty(): f = "turkey"
	game_start_requested.emit(c, w, f)

# === CLEANUP ===

func _exit_tree() -> void:
	print("🧹 Cleaning up LobbyMolecule...")
	
	# Sinyal bağlantılarını kes
	if signal_router:
		signal_router.disconnect_all_signals()
	
	print("✅ LobbyMolecule cleanup completed")

# === DEBUG ===

func print_debug_info() -> void:
	super.print_debug_info()
	
	print("\n=== LobbyMolecule (Modular) Debug ===")
	print("Modular Components Ready: %s" % str(modular_components_ready))
	print("\nModular Component Status:")
	print("  Component Initializer: %s" % ("Loaded" if component_initializer else "Not Loaded"))
	print("  Signal Router: %s" % ("Loaded" if signal_router else "Not Loaded"))
	
	if component_initializer:
		print("\nAtomic Component Status:")
		component_initializer.print_debug_info()
	
	if signal_router:
		print("\nSignal Routing Status:")
		signal_router.print_debug_info()