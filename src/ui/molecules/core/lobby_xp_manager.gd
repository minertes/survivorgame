# 🏢 LOBBY XP MANAGER
# Lobi XP yöneticisi
class_name LobbyXPManager
extends Node

# === PROPERTIES ===
var current_xp: int = 0

# === SIGNALS ===
signal xp_changed(old_xp: int, new_xp: int)
signal xp_earned(amount: int)
signal xp_spent(amount: int)

# === PUBLIC API ===

func set_xp(new_xp: int) -> void:
	var old_xp = current_xp
	current_xp = new_xp
	xp_changed.emit(old_xp, new_xp)

func get_current_xp() -> int:
	return current_xp

func add_xp(amount: int, animate: bool = true) -> void:
	var old_xp = current_xp
	current_xp += amount
	xp_changed.emit(old_xp, current_xp)
	xp_earned.emit(amount)

func spend_xp(amount: int, animate: bool = true) -> bool:
	if current_xp < amount:
		return false
	
	var old_xp = current_xp
	current_xp -= amount
	xp_changed.emit(old_xp, current_xp)
	xp_spent.emit(amount)
	return true

func can_afford(cost: int) -> bool:
	return current_xp >= cost

func update_xp(new_xp: int, animate: bool = true) -> void:
	set_xp(new_xp)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyXPManager ===")
	print("Current XP: %d" % current_xp)