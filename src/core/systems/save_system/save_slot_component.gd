# 🗂️ SAVE SLOT COMPONENT
# Atomic Design prensiplerine uygun save slot yönetimi
class_name SaveSlotComponent
extends Node

# === SAVE SLOT DATA STRUCTURE ===
class SaveSlotData:
	var slot_index: int = 0
	var has_data: bool = false
	var last_save_time: float = 0.0
	var total_play_time: float = 0.0
	var player_name: String = "Player"
	var player_level: int = 1
	var player_health: float = 100.0
	var player_max_health: float = 100.0
	var current_level: int = 1
	var difficulty: String = "normal"
	var thumbnail_path: String = ""
	var metadata: Dictionary = {}
	
	func _to_string() -> String:
		return "[SaveSlot %d: %s, Level %d, Play Time: %.1f]" % [
			slot_index,
			"Has Data" if has_data else "Empty",
			player_level,
			total_play_time
		]
	
	func to_dictionary() -> Dictionary:
		return {
			"slot_index": slot_index,
			"has_data": has_data,
			"last_save_time": last_save_time,
			"total_play_time": total_play_time,
			"player_name": player_name,
			"player_level": player_level,
			"player_health": player_health,
			"player_max_health": player_max_health,
			"current_level": current_level,
			"difficulty": difficulty,
			"thumbnail_path": thumbnail_path,
			"metadata": metadata.duplicate(true)
		}
	
	static func from_dictionary(data: Dictionary) -> SaveSlotData:
		var slot = SaveSlotData.new()
		slot.slot_index = data.get("slot_index", 0)
		slot.has_data = data.get("has_data", false)
		slot.last_save_time = data.get("last_save_time", 0.0)
		slot.total_play_time = data.get("total_play_time", 0.0)
		slot.player_name = data.get("player_name", "Player")
		slot.player_level = data.get("player_level", 1)
		slot.player_health = data.get("player_health", 100.0)
		slot.player_max_health = data.get("player_max_health", 100.0)
		slot.current_level = data.get("current_level", 1)
		slot.difficulty = data.get("difficulty", "normal")
		slot.thumbnail_path = data.get("thumbnail_path", "")
		slot.metadata = data.get("metadata", {}).duplicate(true)
		return slot

# === SAVE DATA STRUCTURE ===
class SaveData:
	var slot_index: int = 0
	var version: String = "1.0.0"
	var game_state: Dictionary = {}
	var metadata: Dictionary = {}
	
	func _init(slot_idx: int, game_state_data: Dictionary, save_metadata: Dictionary):
		slot_index = slot_idx
		game_state = game_state_data.duplicate(true)
		metadata = save_metadata.duplicate(true)
	
	func _to_string() -> String:
		return "[SaveData Slot %d, Version %s]" % [slot_index, version]
	
	func to_dictionary() -> Dictionary:
		return {
			"slot_index": slot_index,
			"version": version,
			"game_state": game_state.duplicate(true),
			"metadata": metadata.duplicate(true)
		}
	
	static func from_dictionary(data: Dictionary) -> SaveData:
		var save = SaveData.new(
			data.get("slot_index", 0),
			data.get("game_state", {}),
			data.get("metadata", {})
		)
		save.version = data.get("version", "1.0.0")
		return save

# === SAVE METADATA STRUCTURE ===
class SaveMetadata:
	var save_time: Dictionary = {}  # Time.get_datetime_dict_from_system() result
	var total_play_time: float = 0.0
	var game_version: String = "1.0.0"
	var checksum: String = ""
	var is_corrupted: bool = false
	var backup_index: int = 0
	
	func _init(save_time_dict: Dictionary, play_time: float):
		save_time = save_time_dict.duplicate(true)
		total_play_time = play_time
		game_version = ProjectSettings.get_setting("application/config/version", "1.0.0")
	
	func _to_string() -> String:
		return "[SaveMetadata: %s, Play Time: %.1f]" % [
			"%04d-%02d-%02d %02d:%02d:%02d" % [
				save_time.get("year", 0),
				save_time.get("month", 0),
				save_time.get("day", 0),
				save_time.get("hour", 0),
				save_time.get("minute", 0),
				save_time.get("second", 0)
			],
			total_play_time
		]
	
	func to_dictionary() -> Dictionary:
		return {
			"save_time": save_time.duplicate(true),
			"total_play_time": total_play_time,
			"game_version": game_version,
			"checksum": checksum,
			"is_corrupted": is_corrupted,
			"backup_index": backup_index
		}
	
	static func from_dictionary(data: Dictionary) -> SaveMetadata:
		var metadata = SaveMetadata.new(
			data.get("save_time", {}),
			data.get("total_play_time", 0.0)
		)
		metadata.game_version = data.get("game_version", "1.0.0")
		metadata.checksum = data.get("checksum", "")
		metadata.is_corrupted = data.get("is_corrupted", false)
		metadata.backup_index = data.get("backup_index", 0)
		return metadata

# === COMPONENT CONFIG ===
const DEFAULT_PLAYER_NAME: String = "Survivor"
const MAX_PLAYER_NAME_LENGTH: int = 20
const MIN_PLAYER_LEVEL: int = 1
const MAX_PLAYER_LEVEL: int = 100
const MIN_PLAYER_HEALTH: float = 0.0
const MAX_PLAYER_HEALTH: float = 1000.0

# === SIGNALS ===
signal slot_data_created(slot_data: SaveSlotData)
signal slot_data_updated(slot_data: SaveSlotData)
signal save_data_created(save_data: SaveData)
signal metadata_created(metadata: SaveMetadata)

# === PUBLIC API ===

# Create empty slot data
func create_empty_slot_data(slot_index: int) -> SaveSlotData:
	var slot_data = SaveSlotData.new()
	slot_data.slot_index = slot_index
	slot_data.has_data = false
	slot_data.last_save_time = 0.0
	slot_data.total_play_time = 0.0
	slot_data.player_name = DEFAULT_PLAYER_NAME
	slot_data.player_level = MIN_PLAYER_LEVEL
	slot_data.player_health = 100.0
	slot_data.player_max_health = 100.0
	slot_data.current_level = 1
	slot_data.difficulty = "normal"
	slot_data.thumbnail_path = ""
	slot_data.metadata = {}
	
	slot_data_created.emit(slot_data)
	return slot_data

# Create save data structure
func create_save_data(slot_index: int, game_state: Dictionary, save_time: Dictionary, total_play_time: float) -> SaveData:
	# Create metadata
	var metadata = SaveMetadata.new(save_time, total_play_time)
	
	# Calculate checksum
	metadata.checksum = _calculate_checksum(game_state, metadata)
	
	# Create save data
	var save_data = SaveData.new(slot_index, game_state, metadata.to_dictionary())
	save_data.version = metadata.game_version
	
	save_data_created.emit(save_data)
	metadata_created.emit(metadata)
	
	return save_data

# Update slot data from save data
func update_slot_from_save_data(slot_data: SaveSlotData, save_data: SaveData) -> SaveSlotData:
	var game_state = save_data.game_state
	var metadata = SaveMetadata.from_dictionary(save_data.metadata)
	
	# Update basic info
	slot_data.has_data = true
	slot_data.last_save_time = Time.get_unix_time_from_datetime_dict(metadata.save_time)
	slot_data.total_play_time = metadata.total_play_time
	
	# Update player info from game state
	if game_state.has("player"):
		var player = game_state["player"]
		slot_data.player_name = player.get("name", slot_data.player_name)
		slot_data.player_level = player.get("level", slot_data.player_level)
		slot_data.player_health = player.get("health", slot_data.player_health)
		slot_data.player_max_health = player.get("max_health", slot_data.player_max_health)
	
	# Update game info from game state
	if game_state.has("world"):
		var world = game_state["world"]
		slot_data.current_level = world.get("current_level", slot_data.current_level)
		slot_data.difficulty = world.get("difficulty", slot_data.difficulty)
	
	# Update metadata
	slot_data.metadata = {
		"version": save_data.version,
		"game_version": metadata.game_version,
		"checksum": metadata.checksum,
		"is_corrupted": metadata.is_corrupted,
		"backup_index": metadata.backup_index
	}
	
	# Generate thumbnail path
	slot_data.thumbnail_path = _generate_thumbnail_path(slot_data.slot_index)
	
	slot_data_updated.emit(slot_data)
	return slot_data

# Validate slot data
func validate_slot_data(slot_data: SaveSlotData) -> Dictionary:
	var errors = []
	
	# Validate slot index
	if slot_data.slot_index < 0:
		errors.append("Invalid slot index: %d" % slot_data.slot_index)
	
	# Validate player name
	if slot_data.player_name.is_empty():
		errors.append("Player name cannot be empty")
	elif slot_data.player_name.length() > MAX_PLAYER_NAME_LENGTH:
		errors.append("Player name too long: %d characters (max %d)" % [
			slot_data.player_name.length(), MAX_PLAYER_NAME_LENGTH
		])
	
	# Validate player level
	if slot_data.player_level < MIN_PLAYER_LEVEL or slot_data.player_level > MAX_PLAYER_LEVEL:
		errors.append("Invalid player level: %d (must be between %d and %d)" % [
			slot_data.player_level, MIN_PLAYER_LEVEL, MAX_PLAYER_LEVEL
		])
	
	# Validate player health
	if slot_data.player_health < MIN_PLAYER_HEALTH or slot_data.player_health > MAX_PLAYER_HEALTH:
		errors.append("Invalid player health: %.1f (must be between %.1f and %.1f)" % [
			slot_data.player_health, MIN_PLAYER_HEALTH, MAX_PLAYER_HEALTH
		])
	
	if slot_data.player_max_health < MIN_PLAYER_HEALTH or slot_data.player_max_health > MAX_PLAYER_HEALTH:
		errors.append("Invalid player max health: %.1f (must be between %.1f and %.1f)" % [
			slot_data.player_max_health, MIN_PLAYER_HEALTH, MAX_PLAYER_HEALTH
		])
	
	if slot_data.player_health > slot_data.player_max_health:
		errors.append("Player health (%.1f) cannot exceed max health (%.1f)" % [
			slot_data.player_health, slot_data.player_max_health
		])
	
	# Validate play time
	if slot_data.total_play_time < 0:
		errors.append("Invalid total play time: %.1f" % slot_data.total_play_time)
	
	# Validate last save time
	if slot_data.last_save_time < 0:
		errors.append("Invalid last save time: %.1f" % slot_data.last_save_time)
	
	# Validate current level
	if slot_data.current_level < 1:
		errors.append("Invalid current level: %d" % slot_data.current_level)
	
	# Validate difficulty
	var valid_difficulties = ["easy", "normal", "hard", "nightmare"]
	if not valid_difficulties.has(slot_data.difficulty.to_lower()):
		errors.append("Invalid difficulty: %s (must be one of: %s)" % [
			slot_data.difficulty, ", ".join(valid_difficulties)
		])
	
	if errors.is_empty():
		return {"success": true, "slot_data": slot_data}
	else:
		return {"success": false, "errors": errors, "slot_data": slot_data}

# Compare two slot data
func compare_slot_data(slot_a: SaveSlotData, slot_b: SaveSlotData) -> Dictionary:
	var differences = []
	
	if slot_a.slot_index != slot_b.slot_index:
		differences.append("slot_index: %d != %d" % [slot_a.slot_index, slot_b.slot_index])
	
	if slot_a.has_data != slot_b.has_data:
		differences.append("has_data: %s != %s" % [str(slot_a.has_data), str(slot_b.has_data)])
	
	if abs(slot_a.last_save_time - slot_b.last_save_time) > 1.0:
		differences.append("last_save_time: %.1f != %.1f" % [slot_a.last_save_time, slot_b.last_save_time])
	
	if abs(slot_a.total_play_time - slot_b.total_play_time) > 1.0:
		differences.append("total_play_time: %.1f != %.1f" % [slot_a.total_play_time, slot_b.total_play_time])
	
	if slot_a.player_name != slot_b.player_name:
		differences.append("player_name: %s != %s" % [slot_a.player_name, slot_b.player_name])
	
	if slot_a.player_level != slot_b.player_level:
		differences.append("player_level: %d != %d" % [slot_a.player_level, slot_b.player_level])
	
	if abs(slot_a.player_health - slot_b.player_health) > 0.1:
		differences.append("player_health: %.1f != %.1f" % [slot_a.player_health, slot_b.player_health])
	
	if abs(slot_a.player_max_health - slot_b.player_max_health) > 0.1:
		differences.append("player_max_health: %.1f != %.1f" % [slot_a.player_max_health, slot_b.player_max_health])
	
	if slot_a.current_level != slot_b.current_level:
		differences.append("current_level: %d != %d" % [slot_a.current_level, slot_b.current_level])
	
	if slot_a.difficulty != slot_b.difficulty:
		differences.append("difficulty: %s != %s" % [slot_a.difficulty, slot_b.difficulty])
	
	return {
		"are_equal": differences.is_empty(),
		"differences": differences,
		"slot_a": slot_a,
		"slot_b": slot_b
	}

# Get formatted save time string
func get_formatted_save_time(slot_data: SaveSlotData) -> String:
	if not slot_data.has_data or slot_data.last_save_time <= 0:
		return "No save data"
	
	var datetime = Time.get_datetime_dict_from_unix_time(int(slot_data.last_save_time))
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute,
		datetime.second
	]

# Get formatted play time string
func get_formatted_play_time(slot_data: SaveSlotData) -> String:
	if not slot_data.has_data:
		return "0:00"
	
	var hours = int(slot_data.total_play_time / 3600)
	var minutes = int((slot_data.total_play_time - hours * 3600) / 60)
	var seconds = int(slot_data.total_play_time - hours * 3600 - minutes * 60)
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%d:%02d" % [minutes, seconds]

# Create slot data from dictionary
func create_slot_data_from_dict(data: Dictionary) -> SaveSlotData:
	return SaveSlotData.from_dictionary(data)

# Create save data from dictionary
func create_save_data_from_dict(data: Dictionary) -> SaveData:
	return SaveData.from_dictionary(data)

# Create metadata from dictionary
func create_metadata_from_dict(data: Dictionary) -> SaveMetadata:
	return SaveMetadata.from_dictionary(data)

# === PRIVATE METHODS ===

func _calculate_checksum(game_state: Dictionary, metadata: SaveMetadata) -> String:
	# Simple checksum calculation for data integrity
	var data_string = JSON.stringify(game_state) + JSON.stringify(metadata.to_dictionary())
	var checksum = data_string.sha256_text()
	return checksum.left(16)  # Use first 16 chars for efficiency

func _generate_thumbnail_path(slot_index: int) -> String:
	# Generate path for save slot thumbnail
	return "user://saves/thumbnails/slot_%d.png" % slot_index

# === DEBUG & UTILITY ===

func print_slot_data(slot_data: SaveSlotData) -> void:
	print("=== Save Slot %d ===" % slot_data.slot_index)
	print("Has Data: %s" % str(slot_data.has_data))
	print("Player: %s (Level %d)" % [slot_data.player_name, slot_data.player_level])
	print("Health: %.1f/%.1f" % [slot_data.player_health, slot_data.player_max_health])
	print("Level: %d, Difficulty: %s" % [slot_data.current_level, slot_data.difficulty])
	print("Play Time: %s" % get_formatted_play_time(slot_data))
	print("Last Save: %s" % get_formatted_save_time(slot_data))
	
	if not slot_data.metadata.is_empty():
		print("Metadata:")
		for key in slot_data.metadata:
			print("  %s: %s" % [key, str(slot_data.metadata[key])])

func print_save_data(save_data: SaveData) -> void:
	print("=== Save Data Slot %d ===" % save_data.slot_index)
	print("Version: %s" % save_data.version)
	
	var metadata = SaveMetadata.from_dictionary(save_data.metadata)
	print("Save Time: %s" % metadata)
	print("Game State Keys: %s" % str(save_data.game_state.keys()))
	
	# Print player info if available
	if save_data.game_state.has("player"):
		var player = save_data.game_state["player"]
		print("Player Position: %s" % str(player.get("position", "N/A")))
		print("Player Health: %.1f/%.1f" % [
			player.get("health", 0.0),
			player.get("max_health", 0.0)
		])

func get_component_info() -> Dictionary:
	return {
		"component_name": "SaveSlotComponent",
		"default_player_name": DEFAULT_PLAYER_NAME,
		"max_player_name_length": MAX_PLAYER_NAME_LENGTH,
		"player_level_range": [MIN_PLAYER_LEVEL, MAX_PLAYER_LEVEL],
		"player_health_range": [MIN_PLAYER_HEALTH, MAX_PLAYER_HEALTH],
		"data_structures": ["SaveSlotData", "SaveData", "SaveMetadata"]
	}