# 🏢 LOBBY INVENTORY MANAGER
# Lobi envanter yöneticisi
class_name LobbyInventoryManager
extends Node

# === INVENTORY DATA ===
var owned_characters: Array[String] = ["male_soldier"]
var selected_character: String = "male_soldier"
var owned_weapons: Dictionary = {"machinegun": 1}
var selected_weapon: String = "machinegun"
var owned_flags: Array[String] = ["turkey"]
var selected_flag: String = "turkey"

# === SIGNALS ===
signal character_changed(old_character: String, new_character: String)
signal weapon_changed(old_weapon: String, new_weapon: String)
signal flag_changed(old_flag: String, new_flag: String)
signal inventory_updated()

# === PUBLIC API ===

func set_inventory_data(data: Dictionary) -> void:
	owned_characters = data.get("owned_characters", ["male_soldier"]).duplicate()
	selected_character = data.get("selected_character", "male_soldier")
	owned_weapons = data.get("owned_weapons", {"machinegun": 1}).duplicate()
	selected_weapon = data.get("selected_weapon", "machinegun")
	owned_flags = data.get("owned_flags", ["turkey"]).duplicate()
	selected_flag = data.get("selected_flag", "turkey")
	
	inventory_updated.emit()

func get_inventory_data() -> Dictionary:
	return {
		"owned_characters": owned_characters.duplicate(),
		"selected_character": selected_character,
		"owned_weapons": owned_weapons.duplicate(),
		"selected_weapon": selected_weapon,
		"owned_flags": owned_flags.duplicate(),
		"selected_flag": selected_flag
	}

func get_selected_items() -> Dictionary:
	return {
		"character": selected_character,
		"weapon": selected_weapon,
		"flag": selected_flag
	}

func select_character(character_id: String) -> bool:
	if character_id in owned_characters:
		var old_character = selected_character
		selected_character = character_id
		character_changed.emit(old_character, character_id)
		return true
	return false

func select_weapon(weapon_id: String) -> bool:
	if weapon_id in owned_weapons:
		var old_weapon = selected_weapon
		selected_weapon = weapon_id
		weapon_changed.emit(old_weapon, weapon_id)
		return true
	return false

func select_flag(flag_id: String) -> bool:
	if flag_id in owned_flags:
		var old_flag = selected_flag
		selected_flag = flag_id
		flag_changed.emit(old_flag, flag_id)
		return true
	return false

func add_character(character_id: String) -> void:
	if character_id not in owned_characters:
		owned_characters.append(character_id)
		inventory_updated.emit()

func add_weapon(weapon_id: String, level: int = 1) -> void:
	if weapon_id not in owned_weapons:
		owned_weapons[weapon_id] = level
		inventory_updated.emit()

func add_flag(flag_id: String) -> void:
	if flag_id not in owned_flags:
		owned_flags.append(flag_id)
		inventory_updated.emit()

func upgrade_weapon(weapon_id: String) -> bool:
	if weapon_id in owned_weapons:
		owned_weapons[weapon_id] += 1
		inventory_updated.emit()
		return true
	return false

func is_character_owned(character_id: String) -> bool:
	return character_id in owned_characters

func is_weapon_owned(weapon_id: String) -> bool:
	return weapon_id in owned_weapons

func is_flag_owned(flag_id: String) -> bool:
	return flag_id in owned_flags

func get_weapon_level(weapon_id: String) -> int:
	return owned_weapons.get(weapon_id, 0)

func get_character_count() -> int:
	return owned_characters.size()

func get_weapon_count() -> int:
	return owned_weapons.size()

func get_flag_count() -> int:
	return owned_flags.size()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyInventoryManager ===")
	print("Selected Character: %s" % selected_character)
	print("Selected Weapon: %s" % selected_weapon)
	print("Selected Flag: %s" % selected_flag)
	print("Owned Characters (%d): %s" % [owned_characters.size(), str(owned_characters)])
	print("Owned Weapons (%d): %s" % [owned_weapons.size(), str(owned_weapons)])
	print("Owned Flags (%d): %s" % [owned_flags.size(), str(owned_flags)])