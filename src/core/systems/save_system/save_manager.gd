# 🗂️ SAVE MANAGER
# Atomic Design prensiplerine uygun ana save yöneticisi
class_name SaveManager
extends Node

# === STATIC ACCESS ===
static var instance: SaveManager = null

# === SAVE SYSTEM COMPONENTS ===
var save_slot_component: SaveSlotComponent = null
var save_serializer: SaveSerializer = null
var save_data_validator: SaveDataValidator = null
var local_save_handler: LocalSaveHandler = null
var cloud_save_adapter: CloudSaveAdapter = null

# === SAVE SYSTEM CONFIG ===
const SAVE_DIRECTORY: String = "user://saves/"
const SAVE_FILE_EXTENSION: String = ".save"
const AUTO_SAVE_INTERVAL: float = 300.0  # 5 dakika
const MAX_SAVE_SLOTS: int = 5
const BACKUP_COUNT: int = 3

# === SAVE STATE ===
var current_slot_index: int = 0
var save_slots: Array = []  # Array of SaveSlotData
var is_saving: bool = false
var is_loading: bool = false
var last_save_time: float = 0.0
var auto_save_timer: Timer = null

# === SIGNALS ===
signal save_started(slot_index: int)
signal save_completed(slot_index: int, success: bool, error: String = "")
signal load_started(slot_index: int)
signal load_completed(slot_index: int, success: bool, error: String = "")
signal save_slot_changed(old_slot: int, new_slot: int)
signal auto_save_triggered(slot_index: int)
signal save_data_corrupted(slot_index: int, error: String)
signal save_system_initialized(success: bool)

# === LIFECYCLE ===

func _ready() -> void:
	if instance != null:
		push_warning("Multiple SaveManager instances detected!")
		queue_free()
		return
	
	instance = self
	print("SaveManager initializing...")
	
	# Initialize components
	_initialize_components()
	
	# Create save directory if it doesn't exist
	_ensure_save_directory()
	
	# Load save slots
	_load_save_slots()
	
	# Setup auto-save timer
	_setup_auto_save_timer()
	
	save_system_initialized.emit(true)
	print("SaveManager initialized successfully")

func _exit_tree() -> void:
	if instance == self:
		instance = null
		print("SaveManager destroyed")

# === PUBLIC API ===

# Save game to current slot
func save_game(slot_index: int = -1, force: bool = false) -> Dictionary:
	if is_saving:
		return {"success": false, "error": "Already saving", "slot": slot_index}
	
	if slot_index == -1:
		slot_index = current_slot_index
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return {"success": false, "error": "Invalid slot index", "slot": slot_index}
	
	is_saving = true
	save_started.emit(slot_index)
	
	var result = _perform_save(slot_index, force)
	
	is_saving = false
	save_completed.emit(slot_index, result.success, result.error)
	
	return result

# Load game from slot
func load_game(slot_index: int = -1) -> Dictionary:
	if is_loading:
		return {"success": false, "error": "Already loading", "slot": slot_index}
	
	if slot_index == -1:
		slot_index = current_slot_index
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return {"success": false, "error": "Invalid slot index", "slot": slot_index}
	
	is_loading = true
	load_started.emit(slot_index)
	
	var result = _perform_load(slot_index)
	
	is_loading = false
	load_completed.emit(slot_index, result.success, result.error)
	
	return result

# Delete save slot
func delete_save_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return {"success": false, "error": "Invalid slot index", "slot": slot_index}
	
	var result = local_save_handler.delete_save_slot(slot_index)
	
	if result.success:
		# Update save slots
		save_slots[slot_index] = save_slot_component.create_empty_slot_data(slot_index)
		EventBus.emit_now_static(EventBus.SAVE_GAME, {
			"action": "delete",
			"slot": slot_index,
			"success": true
		})
	
	return result

# Get save slot info
func get_save_slot_info(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return {"success": false, "error": "Invalid slot index"}
	
	return save_slots[slot_index]

# Get all save slots info
func get_all_save_slots() -> Array:
	return save_slots.duplicate()

# Switch current save slot
func switch_save_slot(new_slot: int) -> bool:
	if new_slot < 0 or new_slot >= MAX_SAVE_SLOTS:
		return false
	
	var old_slot = current_slot_index
	current_slot_index = new_slot
	
	save_slot_changed.emit(old_slot, new_slot)
	EventBus.emit_now_static(EventBus.SAVE_GAME, {
		"action": "slot_changed",
		"old_slot": old_slot,
		"new_slot": new_slot
	})
	
	return true

# Quick save (to current slot)
func quick_save() -> Dictionary:
	return save_game(current_slot_index)

# Quick load (from current slot)
func quick_load() -> Dictionary:
	return load_game(current_slot_index)

# Check if slot has save data
func has_save_data(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return false
	
	return save_slots[slot_index].has_data

# Get last save time for slot
func get_last_save_time(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return 0.0
	
	return save_slots[slot_index].last_save_time

# Get total play time for slot
func get_total_play_time(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return 0.0
	
	return save_slots[slot_index].total_play_time

# === AUTO SAVE ===

func enable_auto_save(enabled: bool = true) -> void:
	if auto_save_timer:
		auto_save_timer.paused = not enabled

func disable_auto_save() -> void:
	enable_auto_save(false)

func is_auto_save_enabled() -> bool:
	if auto_save_timer:
		return not auto_save_timer.paused
	return false

# === CLOUD SAVE ===

func enable_cloud_save(enabled: bool = true) -> void:
	if cloud_save_adapter:
		cloud_save_adapter.set_enabled(enabled)

func sync_with_cloud(slot_index: int = -1) -> Dictionary:
	if not cloud_save_adapter or not cloud_save_adapter.is_enabled():
		return {"success": false, "error": "Cloud save not available"}
	
	if slot_index == -1:
		slot_index = current_slot_index
	
	return cloud_save_adapter.sync_slot(slot_index)

# === STATIC ACCESS ===

static func get_instance() -> SaveManager:
	return instance

static func is_available() -> bool:
	return instance != null

static func save_game_static(slot_index: int = -1, force: bool = false) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "SaveManager not available"}
	return instance.save_game(slot_index, force)

static func load_game_static(slot_index: int = -1) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "SaveManager not available"}
	return instance.load_game(slot_index)

# === PRIVATE METHODS ===

func _initialize_components() -> void:
	# Initialize all atomic components
	save_slot_component = SaveSlotComponent.new()
	save_serializer = SaveSerializer.new()
	save_data_validator = SaveDataValidator.new()
	local_save_handler = LocalSaveHandler.new()
	cloud_save_adapter = CloudSaveAdapter.new()
	
	# Configure components
	save_serializer.set_compression_enabled(true)
	save_data_validator.set_validation_strictness(SaveDataValidator.ValidationStrictness.MEDIUM)
	local_save_handler.set_backup_count(BACKUP_COUNT)

func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(SAVE_DIRECTORY):
		var error = dir.make_dir_recursive(SAVE_DIRECTORY)
		if error != OK:
			push_error("Failed to create save directory: %s" % error_string(error))

func _load_save_slots() -> void:
	save_slots.clear()
	
	for i in range(MAX_SAVE_SLOTS):
		var slot_data = save_slot_component.create_empty_slot_data(i)
		
		# Try to load existing save data
		var load_result = local_save_handler.load_save_data(i)
		if load_result.success:
			var validated_data = save_data_validator.validate_save_data(load_result.data)
			if validated_data.success:
				slot_data = save_slot_component.update_slot_from_save_data(slot_data, validated_data.data)
			else:
				# Try to recover from backup
				var recovery_result = _attempt_data_recovery(i)
				if recovery_result.success:
					slot_data = save_slot_component.update_slot_from_save_data(slot_data, recovery_result.data)
				else:
					save_data_corrupted.emit(i, validated_data.error)
		
		save_slots.append(slot_data)

func _perform_save(slot_index: int, force: bool) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# Collect game state data
	var game_state_data = _collect_game_state_data()
	
	# Create save data structure
	var save_data = save_slot_component.create_save_data(
		slot_index,
		game_state_data,
		OS.get_datetime(),
		Time.get_ticks_msec() / 1000.0  # Convert to seconds
	)
	
	# Validate save data before saving
	var validation_result = save_data_validator.validate_save_data(save_data)
	if not validation_result.success and not force:
		return {"success": false, "error": "Save data validation failed: " + validation_result.error, "slot": slot_index}
	
	# Serialize save data
	var serialization_result = save_serializer.serialize_save_data(save_data)
	if not serialization_result.success:
		return {"success": false, "error": "Serialization failed: " + serialization_result.error, "slot": slot_index}
	
	# Save to local storage
	var save_result = local_save_handler.save_save_data(slot_index, serialization_result.data)
	if not save_result.success:
		return {"success": false, "error": "Save failed: " + save_result.error, "slot": slot_index}
	
	# Update save slot info
	save_slots[slot_index] = save_slot_component.update_slot_from_save_data(save_slots[slot_index], save_data)
	
	# Update last save time
	last_save_time = Time.get_ticks_msec() / 1000.0
	
	# Sync with cloud if enabled
	if cloud_save_adapter and cloud_save_adapter.is_enabled():
		cloud_save_adapter.sync_slot(slot_index)
	
	# Emit event
	EventBus.emit_now_static(EventBus.SAVE_GAME, {
		"action": "save",
		"slot": slot_index,
		"success": true,
		"play_time": save_data.metadata.total_play_time,
		"save_time": save_data.metadata.save_time
	})
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	print("Save completed in %d ms" % elapsed_time)
	
	return {"success": true, "slot": slot_index, "time_ms": elapsed_time}

func _perform_load(slot_index: int) -> Dictionary:
	var start_time = Time.get_ticks_msec()
	
	# Load from local storage
	var load_result = local_save_handler.load_save_data(slot_index)
	if not load_result.success:
		return {"success": false, "error": "Load failed: " + load_result.error, "slot": slot_index}
	
	# Validate loaded data
	var validation_result = save_data_validator.validate_save_data(load_result.data)
	if not validation_result.success:
		# Try to recover from backup
		var recovery_result = _attempt_data_recovery(slot_index)
		if not recovery_result.success:
			save_data_corrupted.emit(slot_index, validation_result.error)
			return {"success": false, "error": "Save data corrupted: " + validation_result.error, "slot": slot_index}
		
		load_result = recovery_result
	
	# Deserialize if needed (local_save_handler already returns deserialized data)
	var save_data = load_result.data
	
	# Apply game state
	var apply_result = _apply_game_state_data(save_data.game_state)
	if not apply_result.success:
		return {"success": false, "error": "Failed to apply game state: " + apply_result.error, "slot": slot_index}
	
	# Update save slot info
	save_slots[slot_index] = save_slot_component.update_slot_from_save_data(save_slots[slot_index], save_data)
	
	# Emit event
	EventBus.emit_now_static(EventBus.LOAD_GAME, {
		"action": "load",
		"slot": slot_index,
		"success": true,
		"play_time": save_data.metadata.total_play_time,
		"save_time": save_data.metadata.save_time
	})
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	print("Load completed in %d ms" % elapsed_time)
	
	return {"success": true, "slot": slot_index, "time_ms": elapsed_time}

func _collect_game_state_data() -> Dictionary:
	# Collect all game state data from various systems
	var game_state = {}
	
	# Get player data
	if has_node("/root/Game/Player"):
		var player = get_node("/root/Game/Player")
		game_state["player"] = {
			"position": player.position,
			"health": player.health,
			"max_health": player.max_health,
			"experience": player.experience,
			"level": player.level,
			"currency": player.currency
		}
	
	# Get inventory data
	if has_node("/root/Game/InventorySystem"):
		var inventory = get_node("/root/Game/InventorySystem")
		game_state["inventory"] = inventory.get_save_data()
	
	# Get progression data
	if has_node("/root/Game/ProgressionSystem"):
		var progression = get_node("/root/Game/ProgressionSystem")
		game_state["progression"] = progression.get_save_data()
	
	# Get game world data
	game_state["world"] = {
		"current_level": 1,  # TODO: Get from level manager
		"game_time": Time.get_ticks_msec() / 1000.0,
		"difficulty": "normal"  # TODO: Get from difficulty manager
	}
	
	# Get settings
	game_state["settings"] = {
		"volume": {
			"master": 1.0,
			"music": 1.0,
			"sfx": 1.0
		},
		"controls": {},  # TODO: Get from input manager
		"graphics": {}   # TODO: Get from graphics settings
	}
	
	return game_state

func _apply_game_state_data(game_state: Dictionary) -> Dictionary:
	# Apply game state data to various systems
	
	# Apply player data
	if game_state.has("player") and has_node("/root/Game/Player"):
		var player = get_node("/root/Game/Player")
		var player_data = game_state["player"]
		
		player.position = player_data.get("position", player.position)
		player.health = player_data.get("health", player.health)
		player.max_health = player_data.get("max_health", player.max_health)
		player.experience = player_data.get("experience", player.experience)
		player.level = player_data.get("level", player.level)
		player.currency = player_data.get("currency", player.currency)
	
	# Apply inventory data
	if game_state.has("inventory") and has_node("/root/Game/InventorySystem"):
		var inventory = get_node("/root/Game/InventorySystem")
		inventory.load_save_data(game_state["inventory"])
	
	# Apply progression data
	if game_state.has("progression") and has_node("/root/Game/ProgressionSystem"):
		var progression = get_node("/root/Game/ProgressionSystem")
		progression.load_save_data(game_state["progression"])
	
	# Apply settings
	if game_state.has("settings"):
		var settings = game_state["settings"]
		
		# Apply audio settings
		if settings.has("volume"):
			var volume = settings["volume"]
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume.get("master", 1.0)))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(volume.get("music", 1.0)))
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(volume.get("sfx", 1.0)))
	
	return {"success": true}

func _attempt_data_recovery(slot_index: int) -> Dictionary:
	# Try to recover from backup files
	for backup_index in range(BACKUP_COUNT):
		var recovery_result = local_save_handler.load_backup_data(slot_index, backup_index)
		if recovery_result.success:
			var validation_result = save_data_validator.validate_save_data(recovery_result.data)
			if validation_result.success:
				print("Recovered save data from backup %d for slot %d" % [backup_index, slot_index])
				
				# Restore the recovered data as main save
				var save_result = local_save_handler.save_save_data(slot_index, recovery_result.data)
				if save_result.success:
					return recovery_result
	
	return {"success": false, "error": "No valid backup found"}

func _setup_auto_save_timer() -> void:
	auto_save_timer = Timer.new()
	auto_save_timer.name = "AutoSaveTimer"
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.autostart = true
	auto_save_timer.one_shot = false
	
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	add_child(auto_save_timer)

func _on_auto_save_timeout() -> void:
	if has_save_data(current_slot_index):
		auto_save_triggered.emit(current_slot_index)
		save_game(current_slot_index)
		
		EventBus.emit_now_static(EventBus.SAVE_GAME, {
			"action": "auto_save",
			"slot": current_slot_index,
			"success": true
		})

# === DEBUG & UTILITY ===

func get_system_info() -> Dictionary:
	return {
		"save_directory": SAVE_DIRECTORY,
		"max_slots": MAX_SAVE_SLOTS,
		"auto_save_interval": AUTO_SAVE_INTERVAL,
		"backup_count": BACKUP_COUNT,
		"current_slot": current_slot_index,
		"is_saving": is_saving,
		"is_loading": is_loading,
		"last_save_time": last_save_time,
		"auto_save_enabled": is_auto_save_enabled(),
		"cloud_save_available": cloud_save_adapter != null and cloud_save_adapter.is_enabled(),
		"save_slots": save_slots
	}

func print_system_info() -> void:
	var info = get_system_info()
	print("=== SaveSystem Info ===")
	print("Save Directory: %s" % info.save_directory)
	print("Max Slots: %d" % info.max_slots)
	print("Current Slot: %d" % info.current_slot)
	print("Auto-save: %s (every %.1f seconds)" % [str(info.auto_save_enabled), info.auto_save_interval])
	print("Backup Count: %d" % info.backup_count)
	print("Cloud Save: %s" % str(info.cloud_save_available))
	
	for i in range(MAX_SAVE_SLOTS):
		var slot = save_slots[i]
		print("Slot %d: %s (Play Time: %.1f)" % [i, "Has Data" if slot.has_data else "Empty", slot.total_play_time])

func validate_all_saves() -> Array:
	var results = []
	
	for i in range(MAX_SAVE_SLOTS):
		if has_save_data(i):
			var load_result = local_save_handler.load_save_data(i)
			if load_result.success:
				var validation_result = save_data_validator.validate_save_data(load_result.data)
				results.append({
					"slot": i,
					"valid": validation_result.success,
					"error": validation_result.error if not validation_result.success else ""
				})
	
	return results