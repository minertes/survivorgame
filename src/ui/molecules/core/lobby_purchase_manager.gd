# 🏢 LOBBY PURCHASE MANAGER
# Lobi satın alma yöneticisi
class_name LobbyPurchaseManager
extends Node

# === DEPENDENCIES ===
var xp_manager: LobbyXPManager = null
var inventory_manager: LobbyInventoryManager = null

# === SIGNALS ===
signal purchase_made(item_type: String, item_id: String, cost: int)
signal purchase_successful(item_type: String, item_id: String)
signal purchase_failed(item_type: String, item_id: String, reason: String)

# === LIFECYCLE ===

func _ready() -> void:
	# Bağımlılıkları bul
	_find_dependencies()

# === PUBLIC API ===

func purchase_character(character_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		purchase_failed.emit("character", character_id, "Dependencies not available")
		return false
	
	if inventory_manager.is_character_owned(character_id):
		purchase_failed.emit("character", character_id, "Already owned")
		return false
	
	if not xp_manager.can_afford(cost):
		purchase_failed.emit("character", character_id, "Not enough XP")
		return false
	
	if xp_manager.spend_xp(cost):
		inventory_manager.add_character(character_id)
		purchase_made.emit("character", character_id, cost)
		purchase_successful.emit("character", character_id)
		return true
	
	purchase_failed.emit("character", character_id, "XP spend failed")
	return false

func purchase_weapon(weapon_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		purchase_failed.emit("weapon", weapon_id, "Dependencies not available")
		return false
	
	if inventory_manager.is_weapon_owned(weapon_id):
		purchase_failed.emit("weapon", weapon_id, "Already owned")
		return false
	
	if not xp_manager.can_afford(cost):
		purchase_failed.emit("weapon", weapon_id, "Not enough XP")
		return false
	
	if xp_manager.spend_xp(cost):
		inventory_manager.add_weapon(weapon_id)
		purchase_made.emit("weapon", weapon_id, cost)
		purchase_successful.emit("weapon", weapon_id)
		return true
	
	purchase_failed.emit("weapon", weapon_id, "XP spend failed")
	return false

func purchase_flag(flag_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		purchase_failed.emit("flag", flag_id, "Dependencies not available")
		return false
	
	if inventory_manager.is_flag_owned(flag_id):
		purchase_failed.emit("flag", flag_id, "Already owned")
		return false
	
	if not xp_manager.can_afford(cost):
		purchase_failed.emit("flag", flag_id, "Not enough XP")
		return false
	
	if xp_manager.spend_xp(cost):
		inventory_manager.add_flag(flag_id)
		purchase_made.emit("flag", flag_id, cost)
		purchase_successful.emit("flag", flag_id)
		return true
	
	purchase_failed.emit("flag", flag_id, "XP spend failed")
	return false

func upgrade_weapon(weapon_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		purchase_failed.emit("weapon_upgrade", weapon_id, "Dependencies not available")
		return false
	
	if not inventory_manager.is_weapon_owned(weapon_id):
		purchase_failed.emit("weapon_upgrade", weapon_id, "Weapon not owned")
		return false
	
	if not xp_manager.can_afford(cost):
		purchase_failed.emit("weapon_upgrade", weapon_id, "Not enough XP")
		return false
	
	if xp_manager.spend_xp(cost):
		inventory_manager.upgrade_weapon(weapon_id)
		purchase_made.emit("weapon_upgrade", weapon_id, cost)
		purchase_successful.emit("weapon_upgrade", weapon_id)
		return true
	
	purchase_failed.emit("weapon_upgrade", weapon_id, "XP spend failed")
	return false

func can_purchase_character(character_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		return false
	
	if inventory_manager.is_character_owned(character_id):
		return false
	
	return xp_manager.can_afford(cost)

func can_purchase_weapon(weapon_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		return false
	
	if inventory_manager.is_weapon_owned(weapon_id):
		return false
	
	return xp_manager.can_afford(cost)

func can_purchase_flag(flag_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		return false
	
	if inventory_manager.is_flag_owned(flag_id):
		return false
	
	return xp_manager.can_afford(cost)

func can_upgrade_weapon(weapon_id: String, cost: int) -> bool:
	if not xp_manager or not inventory_manager:
		return false
	
	if not inventory_manager.is_weapon_owned(weapon_id):
		return false
	
	return xp_manager.can_afford(cost)

# === PRIVATE METHODS ===

func _find_dependencies() -> void:
	# Parent'tan bağımlılıkları bul
	var parent = get_parent()
	if parent:
		if parent.has_method("get_xp_manager"):
			xp_manager = parent.get_xp_manager()
		elif parent.has_node("XPManager"):
			xp_manager = parent.get_node("XPManager")
		
		if parent.has_method("get_inventory_manager"):
			inventory_manager = parent.get_inventory_manager()
		elif parent.has_node("InventoryManager"):
			inventory_manager = parent.get_node("InventoryManager")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyPurchaseManager ===")
	print("XP Manager: %s" % ("Available" if xp_manager else "Not Available"))
	print("Inventory Manager: %s" % ("Available" if inventory_manager else "Not Available"))