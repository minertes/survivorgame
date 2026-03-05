# 🏢 LOBBY COMPONENT INITIALIZER
# Lobi bileşen başlatıcısı (tip bağımlılıkları kaldırıldı — parse hatası önlemi)
extends Node

# === ATOMIC COMPONENTS ===
var character_selector = null
var weapon_selector = null
var flag_selector = null
var stats_display = null
var lobby_settings = null
var currency_display = null
var tab_navigation = null

# === STATE ===
var components_loaded: Dictionary = {}
var initialization_complete: bool = false

# === SIGNALS ===
signal component_initialized(component_name: String, success: bool)
signal all_components_initialized()
signal initialization_failed(error_message: String)

# === PUBLIC API ===

func initialize_components(content_manager: Control) -> void:
	print("🔧 Initializing atomic components...")
	
	if not content_manager:
		initialization_failed.emit("ContentManager not provided")
		return
	
	# Atomic bileşenleri oluştur
	_create_atomic_components()
	
	# Content manager'a bileşenleri ata
	_assign_components_to_manager(content_manager)
	
	# Tab içeriğini güncelle (sahne _ready'de selector'lar yoktu, placeholder gösterilmiş olabilir)
	if content_manager.has_method("get_current_tab") and content_manager.has_method("show_tab"):
		content_manager.show_tab(content_manager.get_current_tab())
	
	# Signal'leri bağla
	_connect_atomic_signals()
	
	initialization_complete = true
	all_components_initialized.emit()
	print("✅ All atomic components initialized")

func get_component_status() -> Dictionary:
	return components_loaded.duplicate()

func is_component_loaded(component_name: String) -> bool:
	return components_loaded.get(component_name, false)

func get_component(component_name: String):
	match component_name:
		"character_selector": return character_selector
		"weapon_selector": return weapon_selector
		"flag_selector": return flag_selector
		"stats_display": return stats_display
		"lobby_settings": return lobby_settings
		"currency_display": return currency_display
		"tab_navigation": return tab_navigation
		_: return null

# === PRIVATE METHODS ===

func _create_atomic_components() -> void:
	print("🛠️ Creating atomic components...")
	
	# CharacterSelectorAtom
	character_selector = _try_create_component(
		"CharacterSelectorAtom",
		"res://src/ui/components/character_selector_atom.gd"
	)
	
	# WeaponSelectorAtom
	weapon_selector = _try_create_component(
		"WeaponSelectorAtom",
		"res://src/ui/components/weapon_selector_atom.gd"
	)
	
	# FlagSelectorAtom
	flag_selector = _try_create_component(
		"FlagSelectorAtom",
		"res://src/ui/components/flag_selector_atom.gd"
	)
	
	# StatsDisplayAtom
	stats_display = _try_create_component(
		"StatsDisplayAtom",
		"res://src/ui/components/stats_display_atom.gd"
	)
	
	# LobbySettingsAtom
	lobby_settings = _try_create_component(
		"LobbySettingsAtom",
		"res://src/ui/components/lobby_settings_atom.gd"
	)
	
	# CurrencyDisplayAtom (scene'de zaten var)
	currency_display = null  # Scene'den gelecek
	
	# TabNavigationAtom
	tab_navigation = _try_create_component(
		"TabNavigationAtom",
		"res://src/ui/components/tab_navigation_atom.gd"
	)

func _try_create_component(component_name: String, script_path: String):
	print("  Creating %s..." % component_name)
	
	if not ResourceLoader.exists(script_path):
		print("  ❌ Script not found: %s" % script_path)
		components_loaded[component_name] = false
		component_initialized.emit(component_name, false)
		return null
	
	var script_res = load(script_path) as GDScript
	if not script_res:
		print("  ❌ Failed to load script: %s" % script_path)
		components_loaded[component_name] = false
		component_initialized.emit(component_name, false)
		return null
	
	# script.new() bazen başarısız; Control + set_script kullan
	var component = Control.new()
	component.set_script(script_res)
	components_loaded[component_name] = true
	component_initialized.emit(component_name, true)
	print("  ✅ %s created successfully" % component_name)
	return component

func _assign_components_to_manager(content_manager: Control) -> void:
	print("🔗 Assigning components to ContentManager...")
	
	if character_selector and content_manager.has_method("set_character_selector"):
		content_manager.set_character_selector(character_selector)
		print("  ✅ CharacterSelector assigned")
	
	if weapon_selector and content_manager.has_method("set_weapon_selector"):
		content_manager.set_weapon_selector(weapon_selector)
		print("  ✅ WeaponSelector assigned")
	
	if flag_selector and content_manager.has_method("set_flag_selector"):
		content_manager.set_flag_selector(flag_selector)
		print("  ✅ FlagSelector assigned")
	
	if stats_display and content_manager.has_method("set_stats_display"):
		content_manager.set_stats_display(stats_display)
		print("  ✅ StatsDisplay assigned")
	
	if lobby_settings and content_manager.has_method("set_lobby_settings"):
		content_manager.set_lobby_settings(lobby_settings)
		print("  ✅ LobbySettings assigned")
	
	if tab_navigation and content_manager.has_method("set_tab_navigation"):
		content_manager.set_tab_navigation(tab_navigation)
		print("  ✅ TabNavigation assigned")

func _connect_atomic_signals() -> void:
	print("🔌 Connecting atomic component signals...")
	
	# CharacterSelectorAtom sinyalleri
	if character_selector:
		if character_selector.has_signal("character_selected"):
			# Signal bağlantıları ana sınıfta yapılacak
			print("  ✅ CharacterSelector signals available")
	
	# WeaponSelectorAtom sinyalleri
	if weapon_selector:
		if weapon_selector.has_signal("weapon_selected"):
			print("  ✅ WeaponSelector signals available")
	
	# FlagSelectorAtom sinyalleri
	if flag_selector:
		if flag_selector.has_signal("flag_selected"):
			print("  ✅ FlagSelector signals available")
	
	print("✅ Atomic component signals checked")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyComponentInitializer Debug ===")
	print("Initialization Complete: %s" % str(initialization_complete))
	print("\nComponent Status:")
	for component in components_loaded:
		print("  %s: %s" % [component, "Loaded" if components_loaded[component] else "Not Loaded"])
	
	print("\nComponent References:")
	print("  Character Selector: %s" % ("Available" if character_selector else "Not Available"))
	print("  Weapon Selector: %s" % ("Available" if weapon_selector else "Not Available"))
	print("  Flag Selector: %s" % ("Available" if flag_selector else "Not Available"))
	print("  Stats Display: %s" % ("Available" if stats_display else "Not Available"))
	print("  Currency Display: %s" % ("Available" if currency_display else "Not Available"))
	print("  Tab Navigation: %s" % ("Available" if tab_navigation else "Not Available"))