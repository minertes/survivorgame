# 🏢 LOBBY PLAYER DATA MANAGER (MODULAR CORE - class_name yok, sadece components sahne kullanır)
extends LobbyPlayerDataCore

# === PUBLIC API (Extended) ===

func purchase_character(character_id: String, cost: int) -> bool:
	if purchase_manager:
		return purchase_manager.purchase_character(character_id, cost)
	return false

func purchase_weapon(weapon_id: String, cost: int) -> bool:
	if purchase_manager:
		return purchase_manager.purchase_weapon(weapon_id, cost)
	return false

func purchase_flag(flag_id: String, cost: int) -> bool:
	if purchase_manager:
		return purchase_manager.purchase_flag(flag_id, cost)
	return false

func upgrade_weapon(weapon_id: String, cost: int) -> bool:
	if purchase_manager:
		return purchase_manager.upgrade_weapon(weapon_id, cost)
	return false

func select_character(character_id: String) -> void:
	if inventory_manager:
		inventory_manager.select_character(character_id)

func select_weapon(weapon_id: String) -> void:
	if inventory_manager:
		inventory_manager.select_weapon(weapon_id)

func select_flag(flag_id: String) -> void:
	if inventory_manager:
		inventory_manager.select_flag(flag_id)

func update_xp(new_xp: int, animate: bool = true) -> void:
	if xp_manager:
		xp_manager.update_xp(new_xp, animate)

func add_xp(amount: int, animate: bool = true) -> void:
	if xp_manager:
		xp_manager.add_xp(amount, animate)

func spend_xp(amount: int, animate: bool = true) -> bool:
	if xp_manager:
		return xp_manager.spend_xp(amount, animate)
	return false

func update_stats(new_stats: Dictionary) -> void:
	if stats_manager:
		stats_manager.set_stats(new_stats)

func is_character_owned(character_id: String) -> bool:
	if inventory_manager:
		return inventory_manager.is_character_owned(character_id)
	return false

func is_weapon_owned(weapon_id: String) -> bool:
	if inventory_manager:
		return inventory_manager.is_weapon_owned(weapon_id)
	return false

func is_flag_owned(flag_id: String) -> bool:
	if inventory_manager:
		return inventory_manager.is_flag_owned(flag_id)
	return false

func get_weapon_level(weapon_id: String) -> int:
	if inventory_manager:
		return inventory_manager.get_weapon_level(weapon_id)
	return 0

# === DEBUG (Extended) ===

func print_debug_info() -> void:
	super.print_debug_info()
	
	print("\n=== LobbyPlayerDataManager (Extended) ===")
	print("Purchase Manager: %s" % ("Available" if purchase_manager else "Not Available"))
	
	if purchase_manager:
		purchase_manager.print_debug_info()