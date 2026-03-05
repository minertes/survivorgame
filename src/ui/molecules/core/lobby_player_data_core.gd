# 🏢 LOBBY PLAYER DATA CORE
# Lobi oyuncu veri temel sınıfı
class_name LobbyPlayerDataCore
extends Node

# === SIGNALS ===
signal player_data_changed()
signal xp_changed(old_xp: int, new_xp: int)
signal character_changed(old_character: String, new_character: String)
signal weapon_changed(old_weapon: String, new_weapon: String)
signal flag_changed(old_flag: String, new_flag: String)
signal purchase_made(item_type: String, item_id: String, cost: int)

# === COMPONENT REFERENCES ===
var xp_manager: LobbyXPManager = null
var inventory_manager: LobbyInventoryManager = null
var stats_manager: LobbyStatsManager = null
var purchase_manager: LobbyPurchaseManager = null

# === LIFECYCLE ===

func _ready() -> void:
	_create_components()
	_connect_components()

# === PUBLIC API ===

func set_player_data(data: Dictionary) -> void:
	if xp_manager:
		xp_manager.set_xp(data.get("xp", 0))
	
	if inventory_manager:
		inventory_manager.set_inventory_data({
			"owned_characters": data.get("owned_characters", ["male_soldier"]),
			"selected_character": data.get("selected_character", "male_soldier"),
			"owned_weapons": data.get("owned_weapons", {"machinegun": 1}),
			"selected_weapon": data.get("selected_weapon", "machinegun"),
			"owned_flags": data.get("owned_flags", ["turkey"]),
			"selected_flag": data.get("selected_flag", "turkey")
		})
	
	if stats_manager:
		stats_manager.set_stats(data.get("stats", {}))
	
	player_data_changed.emit()

func get_player_data() -> Dictionary:
	var data = {}
	
	if xp_manager:
		data["xp"] = xp_manager.get_current_xp()
	
	if inventory_manager:
		var inventory_data = inventory_manager.get_inventory_data()
		data.merge(inventory_data)
	
	if stats_manager:
		data["stats"] = stats_manager.get_stats()
	
	return data

func get_selected_items() -> Dictionary:
	if inventory_manager:
		return inventory_manager.get_selected_items()
	return {}

func get_current_xp() -> int:
	if xp_manager:
		return xp_manager.get_current_xp()
	return 0

func can_afford(cost: int) -> bool:
	if xp_manager:
		return xp_manager.can_afford(cost)
	return false

# === COMPONENT MANAGEMENT ===

func _create_components() -> void:
	# XP Manager
	xp_manager = LobbyXPManager.new()
	xp_manager.name = "XPManager"
	add_child(xp_manager)
	
	# Inventory Manager
	inventory_manager = LobbyInventoryManager.new()
	inventory_manager.name = "InventoryManager"
	add_child(inventory_manager)
	
	# Stats Manager
	stats_manager = LobbyStatsManager.new()
	stats_manager.name = "StatsManager"
	add_child(stats_manager)
	
	# Purchase Manager
	purchase_manager = LobbyPurchaseManager.new()
	purchase_manager.name = "PurchaseManager"
	add_child(purchase_manager)

func _connect_components() -> void:
	# XP Manager sinyalleri
	if xp_manager:
		xp_manager.xp_changed.connect(_on_xp_changed)
	
	# Inventory Manager sinyalleri
	if inventory_manager:
		inventory_manager.character_changed.connect(_on_character_changed)
		inventory_manager.weapon_changed.connect(_on_weapon_changed)
		inventory_manager.flag_changed.connect(_on_flag_changed)
	
	# Purchase Manager sinyalleri
	if purchase_manager:
		purchase_manager.purchase_made.connect(_on_purchase_made)

# === EVENT HANDLERS ===

func _on_xp_changed(old_xp: int, new_xp: int) -> void:
	xp_changed.emit(old_xp, new_xp)
	player_data_changed.emit()

func _on_character_changed(old_character: String, new_character: String) -> void:
	character_changed.emit(old_character, new_character)
	player_data_changed.emit()

func _on_weapon_changed(old_weapon: String, new_weapon: String) -> void:
	weapon_changed.emit(old_weapon, new_weapon)
	player_data_changed.emit()

func _on_flag_changed(old_flag: String, new_flag: String) -> void:
	flag_changed.emit(old_flag, new_flag)
	player_data_changed.emit()

func _on_purchase_made(item_type: String, item_id: String, cost: int) -> void:
	purchase_made.emit(item_type, item_id, cost)
	player_data_changed.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyPlayerDataCore ===")
	print("Components:")
	print("  XP Manager: %s" % ("Loaded" if xp_manager else "Not Loaded"))
	print("  Inventory Manager: %s" % ("Loaded" if inventory_manager else "Not Loaded"))
	print("  Stats Manager: %s" % ("Loaded" if stats_manager else "Not Loaded"))
	print("  Purchase Manager: %s" % ("Loaded" if purchase_manager else "Not Loaded"))
	
	if xp_manager:
		xp_manager.print_debug_info()
	
	if inventory_manager:
		inventory_manager.print_debug_info()
	
	if stats_manager:
		stats_manager.print_debug_info()