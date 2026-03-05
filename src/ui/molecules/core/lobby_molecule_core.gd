# 🏢 LOBBY MOLECULE CORE
# Lobi molekülü çekirdek sınıfı
class_name LobbyMoleculeCore
extends LobbyMoleculeBase

# === COMPONENT REFERENCES ===
var header_component: LobbyHeaderComponent = null
var content_manager: LobbyContentManager = null
var player_data_manager: Node = null

# === INITIALIZATION STATE ===
var components_initialized: bool = false
var data_loaded: bool = false

# === LIFECYCLE ===

func _initialize() -> void:
	print("🔧 LobbyMoleculeCore: Initializing...")
	
	# Component referanslarını al
	_get_component_references()
	
	# Component'leri başlat
	_initialize_components()
	
	# Signal'leri bağla
	_connect_component_signals()
	
	components_initialized = true
	print("✅ LobbyMoleculeCore: Initialized successfully")

# === COMPONENT MANAGEMENT ===

func _get_component_references() -> void:
	# Header component
	if has_node("HeaderComponent"):
		header_component = get_node("HeaderComponent")
		print("✅ HeaderComponent reference acquired")
	else:
		print("❌ HeaderComponent not found")
	
	# Content manager
	if has_node("ContentManager"):
		content_manager = get_node("ContentManager")
		print("✅ ContentManager reference acquired")
	else:
		print("❌ ContentManager not found")
	
	# Player data manager
	if has_node("PlayerDataManager"):
		player_data_manager = get_node("PlayerDataManager")
		print("✅ PlayerDataManager reference acquired")
	else:
		print("❌ PlayerDataManager not found")

func _initialize_components() -> void:
	if not components_initialized:
		print("🔄 Initializing components...")
		
		# Her component'in initialize edilmesini bekle
		await get_tree().process_frame
		
		print("✅ Components initialized")

func _connect_component_signals() -> void:
	print("🔗 Connecting component signals...")
	
	# Header component sinyalleri
	if header_component:
		header_component.back_pressed.connect(_on_header_back_pressed)
		header_component.xp_updated.connect(_on_xp_updated)
		print("✅ Header component signals connected")
	
	# Content manager sinyalleri
	if content_manager:
		content_manager.play_button_pressed.connect(_on_play_button_pressed)
		content_manager.tab_changed.connect(_on_tab_changed)
		content_manager.component_loaded.connect(_on_component_loaded)
		print("✅ Content manager signals connected")
	
	# Player data manager sinyalleri
	if player_data_manager:
		player_data_manager.player_data_changed.connect(_on_player_data_changed)
		player_data_manager.xp_changed.connect(_on_xp_changed)
		player_data_manager.character_changed.connect(_on_character_changed)
		player_data_manager.weapon_changed.connect(_on_weapon_changed)
		player_data_manager.flag_changed.connect(_on_flag_changed)
		player_data_manager.purchase_made.connect(_on_purchase_made)
		print("✅ Player data manager signals connected")
	
	print("✅ All component signals connected")

# === PUBLIC API ===

func set_player_data(data: Dictionary) -> void:
	if player_data_manager:
		player_data_manager.set_player_data(data)
		data_loaded = true
		_refresh_all_components()
	else:
		print("❌ PlayerDataManager not available")

func get_player_data() -> Dictionary:
	if player_data_manager:
		return player_data_manager.get_player_data()
	return {}

func update_player_xp(new_xp: int, animate: bool = true) -> void:
	if player_data_manager:
		player_data_manager.update_xp(new_xp, animate)
	if header_component:
		header_component.set_player_xp(new_xp, animate)

func add_player_xp(amount: int, animate: bool = true) -> void:
	if player_data_manager:
		player_data_manager.add_xp(amount, animate)
	if header_component:
		header_component.add_xp(amount, animate)

func spend_player_xp(amount: int, animate: bool = true) -> bool:
	if player_data_manager and header_component:
		var success = player_data_manager.spend_xp(amount, animate)
		if success:
			header_component.spend_xp(amount, animate)
		return success
	return false

func start_game() -> void:
	if player_data_manager:
		var selected_items = player_data_manager.get_selected_items()
		game_start_requested.emit(
			selected_items["character"],
			selected_items["weapon"],
			selected_items["flag"]
		)
	else:
		# Fallback
		game_start_requested.emit("male_soldier", "machinegun", "turkey")

# === PROTECTED METHODS ===

func _refresh_all_components() -> void:
	if not components_initialized or not data_loaded:
		return
	
	print("🔄 Refreshing all components...")
	
	var player_data = get_player_data()
	
	# Header component
	if header_component:
		header_component.set_player_xp(player_data.get("xp", 0), false)
	
	# Atomic bileşenler content_manager tarafından yönetilecek
	# Burada sadece data manager'ı güncelle
	print("✅ Components refreshed")

# === EVENT HANDLERS ===

func _on_header_back_pressed() -> void:
	print("🔙 Header: Back pressed")
	navigation_back.emit()

func _on_play_button_pressed() -> void:
	print("🎮 Content: Play button pressed")
	start_game()

func _on_tab_changed(tab_index: int, tab_name: String) -> void:
	print("📑 Tab changed: %s" % tab_name)

func _on_component_loaded(component_name: String, success: bool) -> void:
	print("🔧 Component loaded: %s (%s)" % [component_name, "Success" if success else "Failed"])

func _on_player_data_changed() -> void:
	print("📊 Player data changed")
	player_data_updated.emit()

func _on_xp_changed(old_xp: int, new_xp: int) -> void:
	print("💰 XP changed: %d → %d" % [old_xp, new_xp])

func _on_character_changed(old_char: String, new_char: String) -> void:
	print("👤 Character changed: %s → %s" % [old_char, new_char])

func _on_weapon_changed(old_weapon: String, new_weapon: String) -> void:
	print("🔫 Weapon changed: %s → %s" % [old_weapon, new_weapon])

func _on_flag_changed(old_flag: String, new_flag: String) -> void:
	print("🏴 Flag changed: %s → %s" % [old_flag, new_flag])

func _on_purchase_made(item_type: String, item_id: String, cost: int) -> void:
	print("💰 Purchase made: %s - %s (%d XP)" % [item_type, item_id, cost])
	purchase_made.emit(item_type, item_id, cost)

func _on_xp_updated(new_xp: int) -> void:
	if player_data_manager:
		player_data_manager.update_xp(new_xp, false)

# === DEBUG ===

func print_debug_info() -> void:
	super.print_debug_info()
	
	print("\n=== LobbyMoleculeCore Debug ===")
	print("Components Initialized: %s" % str(components_initialized))
	print("Data Loaded: %s" % str(data_loaded))
	print("\nComponent Status:")
	print("  Header Component: %s" % ("Loaded" if header_component else "Not Loaded"))
	print("  Content Manager: %s" % ("Loaded" if content_manager else "Not Loaded"))
	print("  Player Data Manager: %s" % ("Loaded" if player_data_manager else "Not Loaded"))
	
	if player_data_manager:
		print("\nPlayer Data:")
		var data = player_data_manager.get_player_data()
		print("  XP: %d" % data.get("xp", 0))
		print("  Selected Character: %s" % data.get("selected_character", "N/A"))
		print("  Selected Weapon: %s" % data.get("selected_weapon", "N/A"))
		print("  Selected Flag: %s" % data.get("selected_flag", "N/A"))