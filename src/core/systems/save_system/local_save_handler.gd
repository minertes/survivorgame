# 🗂️ LOCAL SAVE HANDLER
# Atomic Design prensiplerine uygun local file system save handler
class_name LocalSaveHandler
extends Node

# === FILE SYSTEM CONFIG ===
const SAVE_DIRECTORY: String = "user://saves/"
const SAVE_FILE_PREFIX: String = "save_"
const SAVE_FILE_EXTENSION: String = ".dat"
const BACKUP_PREFIX: String = "backup_"
const THUMBNAIL_DIRECTORY: String = "user://saves/thumbnails/"
const THUMBNAIL_EXTENSION: String = ".png"
const MAX_FILE_SIZE: int = 10 * 1024 * 1024  # 10 MB
const FILE_PERMISSIONS: int = 511  # 0777 in octal - read/write/execute for all

# === COMPONENT STATE ===
var backup_count: int = 3
var compression_enabled: bool = true
var encryption_enabled: bool = true
var save_serializer: SaveSerializer = null
var is_initialized: bool = false

# === SIGNALS ===
signal file_system_initialized(success: bool)
signal save_file_created(slot_index: int, file_path: String, file_size: int)
signal save_file_loaded(slot_index: int, file_path: String, file_size: int)
signal save_file_deleted(slot_index: int, file_path: String)
signal backup_created(slot_index: int, backup_index: int, file_path: String)
signal backup_loaded(slot_index: int, backup_index: int, file_path: String)
signal backup_deleted(slot_index: int, backup_index: int)
signal thumbnail_saved(slot_index: int, file_path: String)
signal thumbnail_loaded(slot_index: int, file_path: String)
signal file_size_exceeded(slot_index: int, actual_size: int, max_size: int)
signal file_corruption_detected(slot_index: int, file_path: String, error: String)
signal directory_created(path: String)
signal directory_cleaned(path: String, files_removed: int)

# === LIFECYCLE ===

func _ready() -> void:
	_initialize_file_system()
	save_serializer = SaveSerializer.new()
	print("LocalSaveHandler initialized")

# === PUBLIC API ===

# Save data to slot
func save_save_data(slot_index: int, save_data: SaveSlotComponent.SaveData) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	var start_time = Time.get_ticks_msec()
	
	# Serialize save data
	var serialize_result = save_serializer.serialize_save_data(save_data)
	if not serialize_result.success:
		return {"success": false, "error": "Serialization failed: " + serialize_result.error}
	
	var bytes = serialize_result.bytes
	
	# Check file size
	if bytes.size() > MAX_FILE_SIZE:
		file_size_exceeded.emit(slot_index, bytes.size(), MAX_FILE_SIZE)
		return {"success": false, "error": "File size exceeded: %d > %d" % [bytes.size(), MAX_FILE_SIZE]}
	
	# Create backup of existing file
	if _save_file_exists(slot_index):
		var backup_result = _create_backup(slot_index)
		if not backup_result.success:
			print("Warning: Failed to create backup for slot %d: %s" % [slot_index, backup_result.error])
	
	# Save main file
	var save_result = _write_save_file(slot_index, bytes)
	if not save_result.success:
		return save_result
	
	# Clean up old backups
	_cleanup_old_backups(slot_index)
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	save_file_created.emit(slot_index, save_result.file_path, bytes.size())
	
	print("Save completed for slot %d: %d bytes in %d ms" % [slot_index, bytes.size(), elapsed_time])
	
	return {
		"success": true,
		"slot_index": slot_index,
		"file_path": save_result.file_path,
		"file_size": bytes.size(),
		"time_ms": elapsed_time
	}

# Load data from slot
func load_save_data(slot_index: int) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	var start_time = Time.get_ticks_msec()
	
	# Try to load main file
	var load_result = _read_save_file(slot_index)
	if not load_result.success:
		return load_result
	
	var bytes = load_result.bytes
	
	# Deserialize bytes
	var deserialize_result = save_serializer.deserialize_save_data(bytes)
	if not deserialize_result.success:
		# Try to load from backup
		var backup_result = _load_from_backup(slot_index)
		if backup_result.success:
			# Restore backup as main file
			var restore_result = _write_save_file(slot_index, backup_result.bytes)
			if restore_result.success:
				print("Restored corrupted save from backup for slot %d" % slot_index)
				deserialize_result = save_serializer.deserialize_save_data(backup_result.bytes)
		
		if not deserialize_result.success:
			file_corruption_detected.emit(slot_index, load_result.file_path, deserialize_result.error)
			return {"success": false, "error": "Deserialization failed: " + deserialize_result.error}
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	save_file_loaded.emit(slot_index, load_result.file_path, bytes.size())
	
	print("Load completed for slot %d: %d bytes in %d ms" % [slot_index, bytes.size(), elapsed_time])
	
	return {
		"success": true,
		"slot_index": slot_index,
		"data": deserialize_result.data,
		"file_path": load_result.file_path,
		"file_size": bytes.size(),
		"time_ms": elapsed_time
	}

# Delete save slot
func delete_save_slot(slot_index: int) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	var deleted_files = []
	
	# Delete main file
	var main_file_path = _get_save_file_path(slot_index)
	if FileAccess.file_exists(main_file_path):
		var error = DirAccess.remove_absolute(main_file_path)
		if error != OK:
			return {"success": false, "error": "Failed to delete main file: " + error_string(error)}
		
		deleted_files.append(main_file_path)
		save_file_deleted.emit(slot_index, main_file_path)
	
	# Delete all backups
	for backup_index in range(backup_count):
		var backup_file_path = _get_backup_file_path(slot_index, backup_index)
		if FileAccess.file_exists(backup_file_path):
			var error = DirAccess.remove_absolute(backup_file_path)
			if error == OK:
				deleted_files.append(backup_file_path)
				backup_deleted.emit(slot_index, backup_index)
	
	# Delete thumbnail
	var thumbnail_path = _get_thumbnail_path(slot_index)
	if FileAccess.file_exists(thumbnail_path):
		var error = DirAccess.remove_absolute(thumbnail_path)
		if error == OK:
			deleted_files.append(thumbnail_path)
	
	print("Deleted %d files for slot %d" % [deleted_files.size(), slot_index])
	
	return {
		"success": true,
		"slot_index": slot_index,
		"deleted_files": deleted_files,
		"deleted_count": deleted_files.size()
	}

# Load backup data
func load_backup_data(slot_index: int, backup_index: int) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0 or backup_index < 0 or backup_index >= backup_count:
		return {"success": false, "error": "Invalid slot or backup index"}
	
	var backup_file_path = _get_backup_file_path(slot_index, backup_index)
	
	if not FileAccess.file_exists(backup_file_path):
		return {"success": false, "error": "Backup file does not exist"}
	
	var file = FileAccess.open(backup_file_path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		return {"success": false, "error": "Failed to open backup file: " + error_string(error)}
	
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if bytes.is_empty():
		return {"success": false, "error": "Backup file is empty"}
	
	# Deserialize bytes
	var deserialize_result = save_serializer.deserialize_save_data(bytes)
	if not deserialize_result.success:
		return {"success": false, "error": "Backup deserialization failed: " + deserialize_result.error}
	
	backup_loaded.emit(slot_index, backup_index, backup_file_path)
	
	return {
		"success": true,
		"slot_index": slot_index,
		"backup_index": backup_index,
		"data": deserialize_result.data,
		"file_path": backup_file_path,
		"file_size": bytes.size()
	}

# Save thumbnail image
func save_thumbnail(slot_index: int, image: Image) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0 or image == null:
		return {"success": false, "error": "Invalid parameters"}
	
	var thumbnail_path = _get_thumbnail_path(slot_index)
	
	# Ensure thumbnail directory exists
	var dir = DirAccess.open(THUMBNAIL_DIRECTORY)
	if dir == null:
		var error = DirAccess.make_dir_recursive_absolute(THUMBNAIL_DIRECTORY)
		if error != OK:
			return {"success": false, "error": "Failed to create thumbnail directory: " + error_string(error)}
	
	# Save image
	var error = image.save_png(thumbnail_path)
	if error != OK:
		return {"success": false, "error": "Failed to save thumbnail: " + error_string(error)}
	
	thumbnail_saved.emit(slot_index, thumbnail_path)
	
	return {
		"success": true,
		"slot_index": slot_index,
		"file_path": thumbnail_path,
		"image_size": Vector2(image.get_width(), image.get_height())
	}

# Load thumbnail image
func load_thumbnail(slot_index: int) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	var thumbnail_path = _get_thumbnail_path(slot_index)
	
	if not FileAccess.file_exists(thumbnail_path):
		return {"success": false, "error": "Thumbnail file does not exist"}
	
	var image = Image.new()
	var error = image.load(thumbnail_path)
	if error != OK:
		return {"success": false, "error": "Failed to load thumbnail: " + error_string(error)}
	
	thumbnail_loaded.emit(slot_index, thumbnail_path)
	
	return {
		"success": true,
		"slot_index": slot_index,
		"image": image,
		"file_path": thumbnail_path,
		"image_size": Vector2(image.get_width(), image.get_height())
	}

# Check if save file exists
func save_file_exists(slot_index: int) -> bool:
	if not is_initialized:
		return false
	
	return _save_file_exists(slot_index)

# Get save file info
func get_save_file_info(slot_index: int) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	var file_path = _get_save_file_path(slot_index)
	
	if not FileAccess.file_exists(file_path):
		return {"success": false, "error": "Save file does not exist"}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {"success": false, "error": "Failed to open file"}
	
	var file_size = file.get_length()
	var modified_time = file.get_modified_time(file_path)
	file.close()
	
	# Get backup info
	var backup_info = []
	for backup_index in range(backup_count):
		var backup_path = _get_backup_file_path(slot_index, backup_index)
		if FileAccess.file_exists(backup_path):
			var backup_file = FileAccess.open(backup_path, FileAccess.READ)
			if backup_file != null:
				var backup_size = backup_file.get_length()
				var backup_modified = backup_file.get_modified_time(backup_path)
				backup_file.close()
				
				backup_info.append({
					"index": backup_index,
					"path": backup_path,
					"size": backup_size,
					"modified_time": backup_modified,
					"exists": true
				})
			else:
				backup_info.append({
					"index": backup_index,
					"path": backup_path,
					"exists": false
				})
		else:
			backup_info.append({
				"index": backup_index,
				"path": backup_path,
				"exists": false
			})
	
	# Check thumbnail
	var thumbnail_path = _get_thumbnail_path(slot_index)
	var thumbnail_exists = FileAccess.file_exists(thumbnail_path)
	
	return {
		"success": true,
		"slot_index": slot_index,
		"file_path": file_path,
		"file_size": file_size,
		"modified_time": modified_time,
		"backup_count": backup_info.size(),
		"backups": backup_info,
		"thumbnail_exists": thumbnail_exists,
		"thumbnail_path": thumbnail_path if thumbnail_exists else ""
	}

# Get all save files info
func get_all_save_files_info() -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	var save_files_info = []
	var total_size = 0
	var file_count = 0
	
	# Check all possible slots (0-9 for safety)
	for slot_index in range(10):
		var file_path = _get_save_file_path(slot_index)
		
		if FileAccess.file_exists(file_path):
			var file_info = get_save_file_info(slot_index)
			if file_info.success:
				save_files_info.append(file_info)
				total_size += file_info.file_size
				file_count += 1
	
	return {
		"success": true,
		"total_slots": save_files_info.size(),
		"total_size": total_size,
		"save_files": save_files_info
	}

# Clean up old files
func cleanup_old_files(max_age_days: int = 30) -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	var current_time = Time.get_unix_time_from_system()
	var max_age_seconds = max_age_days * 24 * 60 * 60
	var files_removed = 0
	var errors = []
	
	# Clean up old backup files
	for slot_index in range(10):
		for backup_index in range(backup_count):
			var backup_path = _get_backup_file_path(slot_index, backup_index)
			
			if FileAccess.file_exists(backup_path):
				var modified_time = FileAccess.get_modified_time(backup_path)
				var age_seconds = current_time - modified_time
				
				if age_seconds > max_age_seconds:
					var error = DirAccess.remove_absolute(backup_path)
					if error == OK:
						files_removed += 1
						backup_deleted.emit(slot_index, backup_index)
					else:
						errors.append("Failed to delete old backup: " + backup_path)
	
	# Clean up orphaned thumbnails
	var dir = DirAccess.open(THUMBNAIL_DIRECTORY)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(THUMBNAIL_EXTENSION):
				var file_path = THUMBNAIL_DIRECTORY + file_name
				var modified_time = FileAccess.get_modified_time(file_path)
				var age_seconds = current_time - modified_time
				
				if age_seconds > max_age_seconds:
					var error = DirAccess.remove_absolute(file_path)
					if error == OK:
						files_removed += 1
					else:
						errors.append("Failed to delete old thumbnail: " + file_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	directory_cleaned.emit(SAVE_DIRECTORY, files_removed)
	
	return {
		"success": errors.is_empty(),
		"files_removed": files_removed,
		"errors": errors
	}

# Set backup count
func set_backup_count(count: int) -> void:
	backup_count = max(0, min(count, 10))  # Limit to 10 backups
	print("LocalSaveHandler: Backup count set to %d" % backup_count)

# Enable/disable compression
func set_compression_enabled(enabled: bool) -> void:
	compression_enabled = enabled
	if save_serializer:
		save_serializer.set_compression_mode(SaveSerializer.CompressionMode.GZIP if enabled else SaveSerializer.CompressionMode.NONE)
	print("LocalSaveHandler: Compression %s" % ("enabled" if enabled else "disabled"))

# Enable/disable encryption
func set_encryption_enabled(enabled: bool) -> void:
	encryption_enabled = enabled
	if save_serializer:
		save_serializer.set_encryption_mode(SaveSerializer.EncryptionMode.XOR if enabled else SaveSerializer.EncryptionMode.NONE)
	print("LocalSaveHandler: Encryption %s" % ("enabled" if enabled else "disabled"))

# Get disk usage info
func get_disk_usage_info() -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "File system not initialized"}
	
	var total_size = 0
	var file_count = 0
	var backup_size = 0
	var backup_count = 0
	var thumbnail_size = 0
	var thumbnail_count = 0
	
	# Scan save directory
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				var file_path = SAVE_DIRECTORY + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file != null:
					var file_size = file.get_length()
					file.close()
					
					total_size += file_size
					file_count += 1
					
					if file_name.begins_with(BACKUP_PREFIX):
						backup_size += file_size
						backup_count += 1
					elif file_name.ends_with(THUMBNAIL_EXTENSION):
						thumbnail_size += file_size
						thumbnail_count += 1
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return {
		"success": true,
		"total_size_bytes": total_size,
		"total_size_mb": float(total_size) / (1024 * 1024),
		"file_count": file_count,
		"backup_size_bytes": backup_size,
		"backup_count": backup_count,
		"thumbnail_size_bytes": thumbnail_size,
		"thumbnail_count": thumbnail_count,
		"save_directory": SAVE_DIRECTORY,
		"free_space": _get_free_disk_space()
	}

# === PRIVATE METHODS ===

func _initialize_file_system() -> void:
	# Create save directory if it doesn't exist
	var dir = DirAccess.open("user://")
	if dir == null:
		file_system_initialized.emit(false)
		return
	
	if not dir.dir_exists(SAVE_DIRECTORY):
		var error = dir.make_dir_recursive(SAVE_DIRECTORY)
		if error != OK:
			push_error("Failed to create save directory: " + error_string(error))
			file_system_initialized.emit(false)
			return
		
		directory_created.emit(SAVE_DIRECTORY)
	
	# Create thumbnail directory
	if not dir.dir_exists(THUMBNAIL_DIRECTORY):
		var error = dir.make_dir_recursive(THUMBNAIL_DIRECTORY)
		if error == OK:
			directory_created.emit(THUMBNAIL_DIRECTORY)
	
	is_initialized = true
	file_system_initialized.emit(true)
	
	print("File system initialized: %s" % SAVE_DIRECTORY)

func _get_save_file_path(slot_index: int) -> String:
	return SAVE_DIRECTORY + SAVE_FILE_PREFIX + str(slot_index) + SAVE_FILE_EXTENSION

func _get_backup_file_path(slot_index: int, backup_index: int) -> String:
	return SAVE_DIRECTORY + BACKUP_PREFIX + str(slot_index) + "_" + str(backup_index) + SAVE_FILE_EXTENSION

func _get_thumbnail_path(slot_index: int) -> String:
	return THUMBNAIL_DIRECTORY + "slot_" + str(slot_index) + THUMBNAIL_EXTENSION

func _save_file_exists(slot_index: int) -> bool:
	var file_path = _get_save_file_path(slot_index)
	return FileAccess.file_exists(file_path)

func _write_save_file(slot_index: int, bytes: PackedByteArray) -> Dictionary:
	var file_path = _get_save_file_path(slot_index)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		return {"success": false, "error": "Failed to open file for writing: " + error_string(error)}
	
	file.store_buffer(bytes)
	file.close()
	
	return {"success": true, "file_path": file_path, "bytes_written": bytes.size()}

func _read_save_file(slot_index: int) -> Dictionary:
	var file_path = _get_save_file_path(slot_index)
	
	if not FileAccess.file_exists(file_path):
		return {"success": false, "error": "Save file does not exist"}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		return {"success": false, "error": "Failed to open file: " + error_string(error)}
	
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if bytes.is_empty():
		return {"success": false, "error": "Save file is empty"}
	
	return {"success": true, "file_path": file_path, "bytes": bytes}

func _create_backup(slot_index: int) -> Dictionary:
	# Find next available backup index
	var backup_index = -1
	for i in range(backup_count):
		var backup_path = _get_backup_file_path(slot_index, i)
		if not FileAccess.file_exists(backup_path):
			backup_index = i
			break
	
	# If all slots are full, use the oldest one
	if backup_index == -1:
		backup_index = 0
		var oldest_time = Time.get_unix_time_from_system()
		
		for i in range(backup_count):
			var backup_path = _get_backup_file_path(slot_index, i)
			var modified_time = FileAccess.get_modified_time(backup_path)
			if modified_time < oldest_time:
				oldest_time = modified_time
				backup_index = i
	
	# Copy main file to backup
	var main_file_path = _get_save_file_path(slot_index)
	var backup_file_path = _get_backup_file_path(slot_index, backup_index)
	
	var main_file = FileAccess.open(main_file_path, FileAccess.READ)
	if main_file == null:
		return {"success": false, "error": "Failed to open main file for backup"}
	
	var bytes = main_file.get_buffer(main_file.get_length())
	main_file.close()
	
	var backup_file = FileAccess.open(backup_file_path, FileAccess.WRITE)
	if backup_file == null:
		return {"success": false, "error": "Failed to open backup file for writing"}
	
	backup_file.store_buffer(bytes)
	backup_file.close()
	
	backup_created.emit(slot_index, backup_index, backup_file_path)
	
	return {"success": true, "backup_index": backup_index, "file_path": backup_file_path}

func _load_from_backup(slot_index: int) -> Dictionary:
	# Try all backups in reverse order (newest first)
	for backup_index in range(backup_count - 1, -1, -1):
		var backup_path = _get_backup_file_path(slot_index, backup_index)
		
		if FileAccess.file_exists(backup_path):
			var file = FileAccess.open(backup_path, FileAccess.READ)
			if file != null:
				var bytes = file.get_buffer(file.get_length())
				file.close()
				
				if not bytes.is_empty():
					return {"success": true, "backup_index": backup_index, "bytes": bytes}
	
	return {"success": false, "error": "No valid backup found"}

func _cleanup_old_backups(slot_index: int) -> void:
	# Keep only the most recent backups
	var backup_files = []
	
	for backup_index in range(backup_count):
		var backup_path = _get_backup_file_path(slot_index, backup_index)
		
		if FileAccess.file_exists(backup_path):
			var modified_time = FileAccess.get_modified_time(backup_path)
			backup_files.append({
				"index": backup_index,
				"path": backup_path,
				"modified_time": modified_time
			})
	
	# Sort by modification time (oldest first)
	backup_files.sort_custom(func(a, b): return a.modified_time < b.modified_time)
	
	# Remove oldest backups if we have more than backup_count
	while backup_files.size() > backup_count:
		var oldest = backup_files.pop_front()
		var error = DirAccess.remove_absolute(oldest.path)
		if error == OK:
			backup_deleted.emit(slot_index, oldest.index)

func _get_free_disk_space() -> int:
	# Note: Godot doesn't have a direct way to get free disk space
	# This is a placeholder that returns 0
	# In a real implementation, you might use OS.execute() to run system commands
	return 0

# === DEBUG & UTILITY ===

func print_disk_usage_info() -> void:
	var usage_info = get_disk_usage_info()
	if not usage_info.success:
		print("Failed to get disk usage info: " + usage_info.error)
		return
	
	print("=== LocalSaveHandler Disk Usage ===")
	print("Save Directory: %s" % usage_info.save_directory)
	print("Total Size: %.2f MB" % usage_info.total_size_mb)
	print("File Count: %d" % usage_info.file_count)
	print("Backup Count: %d (%.2f MB)" % [usage_info.backup_count, float(usage_info.backup_size_bytes) / (1024 * 1024)])
	print("Thumbnail Count: %d (%.2f MB)" % [usage_info.thumbnail_count, float(usage_info.thumbnail_size_bytes) / (1024 * 1024)])

func print_all_save_files_info() -> void:
	var all_info = get_all_save_files_info()
	if not all_info.success:
		print("Failed to get save files info: " + all_info.error)
		return
	
	print("=== All Save Files Info ===")
	print("Total Slots: %d" % all_info.total_slots)
	print("Total Size: %.2f MB" % (float(all_info.total_size) / (1024 * 1024)))
	
	for save_info in all_info.save_files:
		print("Slot %d:" % save_info.slot_index)
		print("  File: %s" % save_info.file_path)
		print("  Size: %d bytes" % save_info.file_size)
		print("  Backups: %d" % save_info.backup_count)
		print("  Thumbnail: %s" % ("Yes" if save_info.thumbnail_exists else "No"))

func test_file_operations() -> Dictionary:
	print("Testing file operations...")
	
	# Create test save data
	var test_save_data = SaveSlotComponent.SaveData.new(
		999,  # Use high slot index for testing
		{
			"test": true,
			"timestamp": Time.get_ticks_msec(),
			"message": "Test save data"
		},
		{
			"save_time": OS.get_datetime(),
			"total_play_time": 0.0,
			"game_version": "1.0.0"
		}
	)
	
	var test_slot = 999
	
	# Test 1: Save
	print("Test 1: Saving data...")
	var save_result = save_save_data(test_slot, test_save_data)
	if not save_result.success:
		return {"success": false, "error": "Save test failed: " + save_result.error}
	
	print("  Saved %d bytes to %s" % [save_result.file_size, save_result.file_path])
	
	# Test 2: Load
	print("Test 2: Loading data...")
	var load_result = load_save_data(test_slot)
	if not load_result.success:
		return {"success": false, "error": "Load test failed: " + load_result.error}
	
	print("  Loaded %d bytes from %s" % [load_result.file_size, load_result.file_path])
	
	# Test 3: File info
	print("Test 3: Getting file info...")
	var info_result = get_save_file_info(test_slot)
	if not info_result.success:
		return {"success": false, "error": "File info test failed: " + info_result.error}
	
	print("  File size: %d bytes" % info_result.file_size)
	print("  Backup count: %d" % info_result.backup_count)
	
	# Test 4: Delete
	print("Test 4: Deleting file...")
	var delete_result = delete_save_slot(test_slot)
	if not delete_result.success:
		return {"success": false, "error": "Delete test failed: " + delete_result.error}
	
	print("  Deleted %d files" % delete_result.deleted_count)
	
	# Test 5: Verify deletion
	print("Test 5: Verifying deletion...")
	var exists = save_file_exists(test_slot)
	if exists:
		return {"success": false, "error": "File still exists after deletion"}
	
	print("  File successfully deleted")
	
	return {"success": true, "tests_passed": 5}

func benchmark_file_operations(iterations: int = 10) -> Dictionary:
	print("Benchmarking file operations (%d iterations)..." % iterations)
	
	var total_save_time = 0
	var total_load_time = 0
	var total_file_size = 0
	var successes = 0
	
	for i in range(iterations):
		# Create unique test data for each iteration
		var test_save_data = SaveSlotComponent.SaveData.new(
			i,
			{
				"iteration": i,
				"timestamp": Time.get_ticks_msec(),
				"data": "x".repeat(1000 + i * 100)  # Varying data size
			},
			{
				"save_time": OS.get_datetime(),
				"total_play_time": float(i) * 60.0,
				"game_version": "1.0.0"
			}
		)
		
		# Save
		var save_result = save_save_data(i, test_save_data)
		if not save_result.success:
			print("Iteration %d: Save failed: %s" % [i, save_result.error])
			continue
		
		total_save_time += save_result.time_ms
		total_file_size += save_result.file_size
		
		# Load
		var load_result = load_save_data(i)
		if not load_result.success:
			print("Iteration %d: Load failed: %s" % [i, load_result.error])
			continue
		
		total_load_time += load_result.time_ms
		successes += 1
		
		# Clean up
		delete_save_slot(i)
	
	if successes == 0:
		return {"success": false, "error": "All benchmark iterations failed"}
	
	var avg_save_time = float(total_save_time) / successes
	var avg_load_time = float(total_load_time) / successes
	var avg_file_size = float(total_file_size) / successes
	
	print("Benchmark completed: %d/%d successful iterations" % [successes, iterations])
	print("Average Save Time: %.2f ms" % avg_save_time)
	print("Average Load Time: %.2f ms" % avg_load_time)
	print("Average File Size: %.0f bytes" % avg_file_size)
	print("Average Throughput: %.2f KB/ms" % (avg_file_size / 1024 / avg_save_time))
	
	return {
		"success": true,
		"iterations": successes,
		"avg_save_time_ms": avg_save_time,
		"avg_load_time_ms": avg_load_time,
		"avg_file_size_bytes": avg_file_size,
		"total_time_ms": total_save_time + total_load_time
	}