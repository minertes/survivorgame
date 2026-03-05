# 🏢 LOBBY PLAYER DATA MANAGER
# Lobi oyuncu veri yöneticisi (class_name kaldırıldı - "hides" hatası önlemi)
extends Node

# === PLAYER DATA STRUCTURE ===
var player_data: Dictionary = {
	"xp": 0,
	"owned_characters": ["male_soldier"],
	"selected_character": "male_soldier",
	"owned_weapons": {"machinegun": 1},
	"selected_weapon": "machinegun",
	"owned_flags": ["turkey"],
	"selected_flag": "turkey",
	"stats": {
		"best_wave": 0,
		"total_kills": 0,
		"total_games": 0,
		"total_xp_earned": 0,
		"total_play_time": 0,
		"accuracy": 0.0,
		"survival_rate": 0.0
	}
}

# === SIGNALS ===
signal player_data_changed()
signal xp_changed(old_xp: int, new_xp: int)
signal character_changed(old_char: String, new_char: String)
signal weapon_changed(old_weapon: String, new_weapon: String)
signal flag_changed(old_flag: String, new_flag: String)
signal purchase_made(item_type: String, item_id: String, cost: int)

# === PUBLIC API ===

func set_player_data(data: Dictionary) -> void:
	var old_data = player_data.duplicate(true)
	player_data = data
	player_data_changed.emit()
	
	# Değişiklikleri kontrol et ve sinyal gönder
	if old_data.get("xp", 0) != data.get("xp", 0):
		xp_changed.emit(old_data.get("xp", 0), data.get("xp", 0))
	
	if old_data.get("selected_character", "") != data.get("selected_character", ""):
		character_changed.emit(old_data.get("selected_character", ""), data.get("selected_character", ""))
	
	if old_data.get("selected_weapon", "") != data.get("selected_weapon", ""):
		weapon_changed.emit(old_data.get("selected_weapon", ""), data.get("selected_weapon", ""))
	
	if old_data.get("selected_flag", "") != data.get("selected_flag", ""):
		flag_changed.emit(old_data.get("selected_flag", ""), data.get("selected_flag", ""))

func get_player_data() -> Dictionary:
	return player_data.duplicate(true)

func update_xp(new_xp: int, animate: bool = true) -> void:
	var old_xp = player_data["xp"]
	player_data["xp"] = new_xp
	xp_changed.emit(old_xp, new_xp)
	player_data_changed.emit()

func add_xp(amount: int, animate: bool = true) -> void:
	var old_xp = player_data["xp"]
	player_data["xp"] += amount
	player_data["stats"]["total_xp_earned"] += amount
	xp_changed.emit(old_xp, player_data["xp"])
	player_data_changed.emit()

func spend_xp(amount: int, animate: bool = true) -> bool:
	if player_data["xp"] < amount:
		return false
	
	var old_xp = player_data["xp"]
	player_data["xp"] -= amount
	xp_changed.emit(old_xp, player_data["xp"])
	player_data_changed.emit()
	return true

func purchase_character(character_id: String, cost: int) -> bool:
	if not spend_xp(cost):
		return false
	
	if not character_id in player_data["owned_characters"]:
		player_data["owned_characters"].append(character_id)
	
	purchase_made.emit("character", character_id, cost)
	player_data_changed.emit()
	return true

func purchase_weapon(weapon_id: String, cost: int) -> bool:
	if not spend_xp(cost):
		return false
	
	if not weapon_id in player_data["owned_weapons"]:
		player_data["owned_weapons"][weapon_id] = 1
	
	purchase_made.emit("weapon", weapon_id, cost)
	player_data_changed.emit()
	return true

func purchase_flag(flag_id: String, cost: int) -> bool:
	if not spend_xp(cost):
		return false
	
	if not flag_id in player_data["owned_flags"]:
		player_data["owned_flags"].append(flag_id)
	
	purchase_made.emit("flag", flag_id, cost)
	player_data_changed.emit()
	return true

func upgrade_weapon(weapon_id: String, cost: int) -> bool:
	if not spend_xp(cost):
		return false
	
	var current_level = player_data["owned_weapons"].get(weapon_id, 0)
	player_data["owned_weapons"][weapon_id] = current_level + 1
	
	purchase_made.emit("weapon_upgrade", weapon_id, cost)
	player_data_changed.emit()
	return true

func select_character(character_id: String) -> bool:
	if character_id in player_data["owned_characters"]:
		var old_char = player_data["selected_character"]
		player_data["selected_character"] = character_id
		character_changed.emit(old_char, character_id)
		player_data_changed.emit()
		return true
	return false

func select_weapon(weapon_id: String) -> bool:
	if weapon_id in player_data["owned_weapons"]:
		var old_weapon = player_data["selected_weapon"]
		player_data["selected_weapon"] = weapon_id
		weapon_changed.emit(old_weapon, weapon_id)
		player_data_changed.emit()
		return true
	return false

func select_flag(flag_id: String) -> bool:
	if flag_id in player_data["owned_flags"]:
		var old_flag = player_data["selected_flag"]
		player_data["selected_flag"] = flag_id
		flag_changed.emit(old_flag, flag_id)
		player_data_changed.emit()
		return true
	return false

func update_stats(new_stats: Dictionary) -> void:
	player_data["stats"] = new_stats
	player_data_changed.emit()

func get_selected_items() -> Dictionary:
	return {
		"character": player_data["selected_character"],
		"weapon": player_data["selected_weapon"],
		"flag": player_data["selected_flag"]
	}

func can_afford(cost: int) -> bool:
	return player_data["xp"] >= cost

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyPlayerDataManager ===")
	print("Player XP: %d" % player_data["xp"])
	print("Selected Character: %s" % player_data["selected_character"])
	print("Selected Weapon: %s" % player_data["selected_weapon"])
	print("Selected Flag: %s" % player_data["selected_flag"])
	print("Owned Characters: %s" % player_data["owned_characters"])
	print("Owned Weapons: %s" % player_data["owned_weapons"])
	print("Owned Flags: %s" % player_data["owned_flags"])
	print("Stats:")
	for stat in player_data["stats"]:
		print("  %s: %s" % [stat, str(player_data["stats"][stat])])