# 🗂️ CLOUD SAVE ADAPTER
# Atomic Design prensiplerine uygun cloud save adapter (abstract implementation)
class_name CloudSaveAdapter
extends Node

# === CLOUD SERVICE TYPES ===
enum CloudService {
	NONE = 0,
	STEAM_CLOUD = 1,
	EPIC_CLOUD = 2,
	CUSTOM = 3
}

# === SYNC STATUS ===
enum SyncStatus {
	IDLE = 0,
	SYNCING = 1,
	SYNCED = 2,
	CONFLICT = 3,
	ERROR = 4
}

# === COMPONENT STATE ===
var cloud_service: CloudService = CloudService.NONE
var is_enabled: bool = false
var is_initialized: bool = false
var sync_status: SyncStatus = SyncStatus.IDLE
var last_sync_time: float = 0.0
var sync_interval: float = 300.0  # 5 minutes
var max_cloud_size: int = 100 * 1024 * 1024  # 100 MB
var conflict_resolution: String = "local"  # "local", "cloud", "newest", "manual"

# === CLOUD DATA STRUCTURES ===
class CloudFileInfo:
	var file_name: String
	var file_size: int
	var last_modified: float
	var checksum: String
	var is_corrupted: bool = false
	
	func _init(name: String, size: int, modified: float, checksum_val: String = ""):
		file_name = name
		file_size = size
		last_modified = modified
		checksum = checksum_val
	
	func _to_string() -> String:
		return "[CloudFile: %s, %d bytes, modified: %.0f]" % [file_name, file_size, last_modified]

class SyncConflict:
	var slot_index: int
	var local_file_info: CloudFileInfo
	var cloud_file_info: CloudFileInfo
	var local_data: Variant = null
	var cloud_data: Variant = null
	var resolution: String = ""
	
	func _init(slot: int, local_info: CloudFileInfo, cloud_info: CloudFileInfo):
		slot_index = slot
		local_file_info = local_info
		cloud_file_info = cloud_info
	
	func _to_string() -> String:
		return "[SyncConflict Slot %d: Local %s vs Cloud %s]" % [
			slot_index,
			local_file_info,
			cloud_file_info
		]

# === SIGNALS ===
signal cloud_service_initialized(service: CloudService, success: bool)
signal cloud_service_disconnected()
signal sync_started(slot_index: int = -1)  # -1 means all slots
signal sync_completed(slot_index: int, success: bool, error: String = "")
signal sync_conflict_detected(conflict: SyncConflict)
signal sync_conflict_resolved(conflict: SyncConflict, resolution: String)
signal cloud_file_uploaded(slot_index: int, file_name: String, file_size: int)
signal cloud_file_downloaded(slot_index: int, file_name: String, file_size: int)
signal cloud_file_deleted(slot_index: int, file_name: String)
signal cloud_quota_updated(used_bytes: int, total_bytes: int, percent_used: float)
signal cloud_error_occurred(error_code: int, error_message: String)

# === LIFECYCLE ===

func _ready() -> void:
	# Try to auto-detect cloud service
	_auto_detect_cloud_service()
	print("CloudSaveAdapter initialized")

# === PUBLIC API ===

# Initialize cloud service
func initialize() -> Dictionary:
	if is_initialized:
		return {"success": true, "service": cloud_service, "already_initialized": true}
	
	var start_time = Time.get_ticks_msec()
	
	match cloud_service:
		CloudService.STEAM_CLOUD:
			var result = _initialize_steam_cloud()
			is_initialized = result.success
			cloud_service_initialized.emit(CloudService.STEAM_CLOUD, result.success)
			
			if result.success:
				print("Steam Cloud initialized successfully")
			else:
				print("Steam Cloud initialization failed: " + result.error)
			
			return result
		
		CloudService.EPIC_CLOUD:
			var result = _initialize_epic_cloud()
			is_initialized = result.success
			cloud_service_initialized.emit(CloudService.EPIC_CLOUD, result.success)
			
			if result.success:
				print("Epic Cloud initialized successfully")
			else:
				print("Epic Cloud initialization failed: " + result.error)
			
			return result
		
		CloudService.CUSTOM:
			var result = _initialize_custom_cloud()
			is_initialized = result.success
			cloud_service_initialized.emit(CloudService.CUSTOM, result.success)
			
			if result.success:
				print("Custom cloud service initialized successfully")
			else:
				print("Custom cloud service initialization failed: " + result.error)
			
			return result
		
		_:
			var result = {"success": false, "error": "No cloud service configured"}
			cloud_service_initialized.emit(CloudService.NONE, false)
			return result

# Enable/disable cloud saves
func set_enabled(enabled: bool) -> void:
	if enabled and not is_initialized:
		# Try to initialize if enabling
		var init_result = initialize()
		if not init_result.success:
			print("Failed to enable cloud saves: " + init_result.error)
			return
	
	is_enabled = enabled
	print("Cloud saves %s" % ("enabled" if enabled else "disabled"))

# Check if cloud saves are available
func is_available() -> bool:
	return is_initialized and is_enabled

# Sync specific slot with cloud
func sync_slot(slot_index: int) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "Cloud saves not available"}
	
	if slot_index < 0:
		return {"success": false, "error": "Invalid slot index"}
	
	sync_started.emit(slot_index)
	sync_status = SyncStatus.SYNCING
	
	var start_time = Time.get_ticks_msec()
	
	# Get local file info
	var local_save_handler = SaveManager.get_instance().local_save_handler
	var local_file_info = local_save_handler.get_save_file_info(slot_index)
	
	if not local_file_info.success:
		sync_status = SyncStatus.ERROR
		sync_completed.emit(slot_index, false, "Failed to get local file info")
		return {"success": false, "error": "Failed to get local file info"}
	
	# Get cloud file info
	var cloud_file_info_result = _get_cloud_file_info(slot_index)
	
	var sync_result = {"success": false}
	
	if cloud_file_info_result.success:
		# Cloud file exists, check for conflicts
		var cloud_file_info = cloud_file_info_result.file_info
		var conflict = _check_for_conflict(slot_index, local_file_info, cloud_file_info)
		
		if conflict != null:
			# Conflict detected
			sync_conflict_detected.emit(conflict)
			sync_status = SyncStatus.CONFLICT
			
			# Resolve conflict
			var resolution_result = _resolve_conflict(conflict)
			if resolution_result.success:
				sync_conflict_resolved.emit(conflict, resolution_result.resolution)
				sync_result = resolution_result.sync_result
			else:
				sync_result = {"success": false, "error": "Failed to resolve conflict"}
		else:
			# No conflict, sync based on which is newer
			if local_file_info.modified_time > cloud_file_info.last_modified:
				# Local is newer, upload to cloud
				sync_result = _upload_to_cloud(slot_index, local_file_info)
			else:
				# Cloud is newer or same, download from cloud
				sync_result = _download_from_cloud(slot_index, cloud_file_info)
	else:
		# No cloud file exists, upload local file
		sync_result = _upload_to_cloud(slot_index, local_file_info)
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	last_sync_time = Time.get_unix_time_from_system()
	
	if sync_result.success:
		sync_status = SyncStatus.SYNCED
		sync_completed.emit(slot_index, true, "")
		print("Slot %d synced successfully in %d ms" % [slot_index, elapsed_time])
	else:
		sync_status = SyncStatus.ERROR
		sync_completed.emit(slot_index, false, sync_result.error)
		print("Slot %d sync failed: %s" % [slot_index, sync_result.error])
	
	return {
		"success": sync_result.success,
		"slot_index": slot_index,
		"time_ms": elapsed_time,
		"error": sync_result.error if not sync_result.success else ""
	}

# Sync all slots with cloud
func sync_all_slots() -> Dictionary:
	if not is_available():
		return {"success": false, "error": "Cloud saves not available"}
	
	sync_started.emit(-1)
	sync_status = SyncStatus.SYNCING
	
	var start_time = Time.get_ticks_msec()
	var results = []
	var successful_syncs = 0
	
	# Sync each slot
	for slot_index in range(SaveManager.get_instance().MAX_SAVE_SLOTS):
		var save_manager = SaveManager.get_instance()
		if save_manager.has_save_data(slot_index):
			var sync_result = sync_slot(slot_index)
			results.append({
				"slot_index": slot_index,
				"success": sync_result.success,
				"error": sync_result.error if not sync_result.success else ""
			})
			
			if sync_result.success:
				successful_syncs += 1
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	last_sync_time = Time.get_unix_time_from_system()
	
	if successful_syncs == results.size():
		sync_status = SyncStatus.SYNCED
	else:
		sync_status = SyncStatus.ERROR if successful_syncs == 0 else SyncStatus.CONFLICT
	
	sync_completed.emit(-1, successful_syncs == results.size(), "")
	
	print("All slots sync completed: %d/%d successful in %d ms" % [successful_syncs, results.size(), elapsed_time])
	
	return {
		"success": successful_syncs == results.size(),
		"total_slots": results.size(),
		"successful_slots": successful_syncs,
		"results": results,
		"time_ms": elapsed_time
	}

# Force upload local file to cloud (overwrites cloud)
func force_upload_to_cloud(slot_index: int) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "Cloud saves not available"}
	
	sync_started.emit(slot_index)
	
	var local_save_handler = SaveManager.get_instance().local_save_handler
	var local_file_info = local_save_handler.get_save_file_info(slot_index)
	
	if not local_file_info.success:
		return {"success": false, "error": "Failed to get local file info"}
	
	var result = _upload_to_cloud(slot_index, local_file_info)
	
	if result.success:
		sync_completed.emit(slot_index, true, "Force upload completed")
	else:
		sync_completed.emit(slot_index, false, result.error)
	
	return result

# Force download from cloud to local (overwrites local)
func force_download_from_cloud(slot_index: int) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "Cloud saves not available"}
	
	sync_started.emit(slot_index)
	
	var cloud_file_info_result = _get_cloud_file_info(slot_index)
	if not cloud_file_info_result.success:
		return {"success": false, "error": "Failed to get cloud file info"}
	
	var result = _download_from_cloud(slot_index, cloud_file_info_result.file_info)
	
	if result.success:
		sync_completed.emit(slot_index, true, "Force download completed")
	else:
		sync_completed.emit(slot_index, false, result.error)
	
	return result

# Delete cloud file
func delete_cloud_file(slot_index: int) -> Dictionary:
	if not is_available():
		return {"success": false, "error": "Cloud saves not available"}
	
	var file_name = _get_cloud_file_name(slot_index)
	var result = _delete_cloud_file(file_name)
	
	if result.success:
		cloud_file_deleted.emit(slot_index, file_name)
	
	return result

# Get cloud quota information
func get_cloud_quota() -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "Cloud service not initialized"}
	
	match cloud_service:
		CloudService.STEAM_CLOUD:
			return _get_steam_cloud_quota()
		CloudService.EPIC_CLOUD:
			return _get_epic_cloud_quota()
		CloudService.CUSTOM:
			return _get_custom_cloud_quota()
		_:
			return {"success": false, "error": "Cloud service not supported"}

# Get cloud file list
func get_cloud_file_list() -> Dictionary:
	if not is_initialized:
		return {"success": false, "error": "Cloud service not initialized"}
	
	match cloud_service:
		CloudService.STEAM_CLOUD:
			return _get_steam_cloud_file_list()
		CloudService.EPIC_CLOUD:
			return _get_epic_cloud_file_list()
		CloudService.CUSTOM:
			return _get_custom_cloud_file_list()
		_:
			return {"success": false, "error": "Cloud service not supported"}

# Set conflict resolution strategy
func set_conflict_resolution(strategy: String) -> void:
	var valid_strategies = ["local", "cloud", "newest", "manual"]
	if valid_strategies.has(strategy):
		conflict_resolution = strategy
		print("Conflict resolution strategy set to: %s" % strategy)
	else:
		push_warning("Invalid conflict resolution strategy: %s" % strategy)

# Set sync interval
func set_sync_interval(interval_seconds: float) -> void:
	sync_interval = max(30.0, interval_seconds)  # Minimum 30 seconds
	print("Sync interval set to %.1f seconds" % sync_interval)

# Get sync status
func get_sync_status() -> Dictionary:
	return {
		"service": _cloud_service_to_string(cloud_service),
		"enabled": is_enabled,
		"initialized": is_initialized,
		"sync_status": _sync_status_to_string(sync_status),
		"last_sync_time": last_sync_time,
		"sync_interval": sync_interval,
		"conflict_resolution": conflict_resolution
	}

# === PRIVATE METHODS ===

func _auto_detect_cloud_service() -> void:
	# Try to detect which cloud service is available
	# This is a simplified detection - in reality you'd check for specific APIs
	
	# Check for Steam
	if _is_steam_available():
		cloud_service = CloudService.STEAM_CLOUD
		print("Detected Steam Cloud")
		return
	
	# Check for Epic
	if _is_epic_available():
		cloud_service = CloudService.EPIC_CLOUD
		print("Detected Epic Cloud")
		return
	
	# No cloud service detected
	cloud_service = CloudService.NONE
	print("No cloud service detected")

func _is_steam_available() -> bool:
	# Check if Steam API is available
	# In Godot, you might check for Steam singleton
	return Engine.has_singleton("Steam")

func _is_epic_available() -> bool:
	# Check if Epic Online Services is available
	# This would require specific integration
	return false

func _initialize_steam_cloud() -> Dictionary:
	# Initialize Steam Cloud
	# This is a placeholder implementation
	
	if not _is_steam_available():
		return {"success": false, "error": "Steam not available"}
	
	# Simulate initialization delay
	await get_tree().create_timer(0.1).timeout
	
	# In real implementation, you would:
	# 1. Check if Steam Cloud is enabled for the app
	# 2. Initialize Steam Cloud API
	# 3. Set up callbacks
	
	return {"success": true, "service": CloudService.STEAM_CLOUD}

func _initialize_epic_cloud() -> Dictionary:
	# Initialize Epic Cloud
	# This is a placeholder implementation
	
	if not _is_epic_available():
		return {"success": false, "error": "Epic not available"}
	
	# Simulate initialization delay
	await get_tree().create_timer(0.1).timeout
	
	return {"success": true, "service": CloudService.EPIC_CLOUD}

func _initialize_custom_cloud() -> Dictionary:
	# Initialize custom cloud service
	# This would require custom implementation
	
	# Simulate initialization delay
	await get_tree().create_timer(0.1).timeout
	
	return {"success": true, "service": CloudService.CUSTOM}

func _get_cloud_file_name(slot_index: int) -> String:
	return "save_%d.dat" % slot_index

func _get_cloud_file_info(slot_index: int) -> Dictionary:
	var file_name = _get_cloud_file_name(slot_index)
	
	match cloud_service:
		CloudService.STEAM_CLOUD:
			return _get_steam_cloud_file_info(file_name)
		CloudService.EPIC_CLOUD:
			return _get_epic_cloud_file_info(file_name)
		CloudService.CUSTOM:
			return _get_custom_cloud_file_info(file_name)
		_:
			return {"success": false, "error": "Cloud service not supported"}

func _check_for_conflict(slot_index: int, local_info: Dictionary, cloud_info: CloudFileInfo) -> SyncConflict:
	# Check if files are different
	var local_checksum = _calculate_file_checksum(local_info.file_path)
	var cloud_checksum = cloud_info.checksum
	
	# If checksums are different and both files have been modified since last sync
	if local_checksum != cloud_checksum:
		var local_file_info = CloudFileInfo.new(
			_get_cloud_file_name(slot_index),
			local_info.file_size,
			local_info.modified_time,
			local_checksum
		)
		
		return SyncConflict.new(slot_index, local_file_info, cloud_info)
	
	return null

func _resolve_conflict(conflict: SyncConflict) -> Dictionary:
	var resolution = conflict_resolution
	
	# If manual resolution, return conflict for UI to handle
	if resolution == "manual":
		return {"success": false, "conflict": conflict, "requires_manual_resolution": true}
	
	var sync_result = {"success": false}
	
	match resolution:
		"local":
			# Use local file
			sync_result = _upload_to_cloud(conflict.slot_index, {
				"file_path": SaveManager.get_instance().local_save_handler._get_save_file_path(conflict.slot_index),
				"file_size": conflict.local_file_info.file_size,
				"modified_time": conflict.local_file_info.last_modified
			})
		
		"cloud":
			# Use cloud file
			sync_result = _download_from_cloud(conflict.slot_index, conflict.cloud_file_info)
		
		"newest":
			# Use newest file
			if conflict.local_file_info.last_modified > conflict.cloud_file_info.last_modified:
				sync_result = _upload_to_cloud(conflict.slot_index, {
					"file_path": SaveManager.get_instance().local_save_handler._get_save_file_path(conflict.slot_index),
					"file_size": conflict.local_file_info.file_size,
					"modified_time": conflict.local_file_info.last_modified
				})
			else:
				sync_result = _download_from_cloud(conflict.slot_index, conflict.cloud_file_info)
	
	return {
		"success": sync_result.success,
		"resolution": resolution,
		"sync_result": sync_result
	}

func _upload_to_cloud(slot_index: int, local_info: Dictionary) -> Dictionary:
	var file_name = _get_cloud_file_name(slot_index)
	
	# Read local file
	var file = FileAccess.open(local_info.file_path, FileAccess.READ)
	if file == null:
		return {"success": false, "error": "Failed to open local file"}
	
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if bytes.is_empty():
		return {"success": false, "error": "Local file is empty"}
	
	# Upload to cloud
	match cloud_service:
		CloudService.STEAM_CLOUD:
			var result = _upload_to_steam_cloud(file_name, bytes)
			if result.success:
				cloud_file_uploaded.emit(slot_index, file_name, bytes.size())
			return result
		
		CloudService.EPIC_CLOUD:
			var result = _upload_to_epic_cloud(file_name, bytes)
			if result.success:
				cloud_file_uploaded.emit(slot_index, file_name, bytes.size())
			return result
		
		CloudService.CUSTOM:
			var result = _upload_to_custom_cloud(file_name, bytes)
			if result.success:
				cloud_file_uploaded.emit(slot_index, file_name, bytes.size())
			return result
	
	return {"success": false, "error": "Cloud service not supported"}

func _download_from_cloud(slot_index: int, cloud_info: CloudFileInfo) -> Dictionary:
	var file_name = cloud_info.file_name
	
	# Download from cloud
	match cloud_service:
		CloudService.STEAM_CLOUD:
			var result = _download_from_steam_cloud(file_name)
			if result.success:
				# Save to local file
				var save_result = _save_downloaded_file(slot_index, result.bytes)
				if save_result.success:
					cloud_file_downloaded.emit(slot_index, file_name, result.bytes.size())
					return {"success": true, "file_size": result.bytes.size()}
				else:
					return save_result
			return result
		
		CloudService.EPIC_CLOUD:
			var result = _download_from_epic_cloud(file_name)
			if result.success:
				# Save to local file
				var save_result = _save_downloaded_file(slot_index, result.bytes)
				if save_result.success:
					cloud_file_downloaded.emit(slot_index, file_name, result.bytes.size())
					return {"success": true, "file_size": result.bytes.size()}
				else:
					return save_result
			return result
		
		CloudService.CUSTOM:
			var result = _download_from_custom_cloud(file_name)
			if result.success:
				# Save to local file
				var save_result = _save_downloaded_file(slot_index, result.bytes)
				if save_result.success:
					cloud_file_downloaded.emit(slot_index, file_name, result.bytes.size())
					return {"success": true, "file_size": result.bytes.size()}
				else:
					return save_result
			return result
	
	return {"success": false, "error": "Cloud service not supported"}

func _save_downloaded_file(slot_index: int, bytes: PackedByteArray) -> Dictionary:
	var local_save_handler = SaveManager.get_instance().local_save_handler
	var file_path = local_save_handler._get_save_file_path(slot_index)
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "Failed to open local file for writing"}
	
	file.store_buffer(bytes)
	file.close()
	
	return {"success": true, "file_path": file_path, "file_size": bytes.size()}

func _calculate_file_checksum(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if bytes.is_empty():
		return ""
	
	return bytes.sha256_text().left(16)

# === STEAM CLOUD IMPLEMENTATION (Placeholders) ===

func _get_steam_cloud_quota() -> Dictionary:
	# Placeholder for Steam Cloud quota
	return {
		"success": true,
		"used_bytes": 0,
		"total_bytes": max_cloud_size,
		"percent_used": 0.0
	}

func _get_steam_cloud_file_list() -> Dictionary:
	# Placeholder for Steam Cloud file list
	return {
		"success": true,
		"files": [],
		"file_count": 0
	}

func _get_steam_cloud_file_info(file_name: String) -> Dictionary:
	# Placeholder for Steam Cloud file info
	# In reality, you would check if file exists in Steam Cloud
	return {"success": false, "error": "File not found in Steam Cloud"}

func _upload_to_steam_cloud(file_name: String, bytes: PackedByteArray) -> Dictionary:
	# Placeholder for Steam Cloud upload
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	# Simulate successful upload
	return {
		"success": true,
		"file_name": file_name,
		"file_size": bytes.size(),
		"upload_time_ms": 500
	}

func _download_from_steam_cloud(file_name: String) -> Dictionary:
	# Placeholder for Steam Cloud download
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	# Simulate failed download (no file in cloud)
	return {"success": false, "error": "File not found in Steam Cloud"}

func _delete_steam_cloud_file(file_name: String) -> Dictionary:
	# Placeholder for Steam Cloud delete
	return {"success": true, "file_name": file_name}

# === EPIC CLOUD IMPLEMENTATION (Placeholders) ===

func _get_epic_cloud_quota() -> Dictionary:
	# Placeholder for Epic Cloud quota
	return {
		"success": true,
		"used_bytes": 0,
		"total_bytes": max_cloud_size,
		"percent_used": 0.0
	}

func _get_epic_cloud_file_list() -> Dictionary:
	# Placeholder for Epic Cloud file list
	return {
		"success": true,
		"files": [],
		"file_count": 0
	}

func _get_epic_cloud_file_info(file_name: String) -> Dictionary:
	# Placeholder for Epic Cloud file info
	return {"success": false, "error": "File not found in Epic Cloud"}

func _upload_to_epic_cloud(file_name: String, bytes: PackedByteArray) -> Dictionary:
	# Placeholder for Epic Cloud upload
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	return {
		"success": true,
		"file_name": file_name,
		"file_size": bytes.size(),
		"upload_time_ms": 500
	}

func _download_from_epic_cloud(file_name: String) -> Dictionary:
	# Placeholder for Epic Cloud download
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	return {"success": false, "error": "File not found in Epic Cloud"}

func _delete_epic_cloud_file(file_name: String) -> Dictionary:
	# Placeholder for Epic Cloud delete
	return {"success": true, "file_name": file_name}

# === CUSTOM CLOUD IMPLEMENTATION (Placeholders) ===

func _get_custom_cloud_quota() -> Dictionary:
	# Placeholder for custom cloud quota
	return {
		"success": true,
		"used_bytes": 0,
		"total_bytes": max_cloud_size,
		"percent_used": 0.0
	}

func _get_custom_cloud_file_list() -> Dictionary:
	# Placeholder for custom cloud file list
	return {
		"success": true,
		"files": [],
		"file_count": 0
	}

func _get_custom_cloud_file_info(file_name: String) -> Dictionary:
	# Placeholder for custom cloud file info
	return {"success": false, "error": "File not found in custom cloud"}

func _upload_to_custom_cloud(file_name: String, bytes: PackedByteArray) -> Dictionary:
	# Placeholder for custom cloud upload
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	return {
		"success": true,
		"file_name": file_name,
		"file_size": bytes.size(),
		"upload_time_ms": 500
	}

func _download_from_custom_cloud(file_name: String) -> Dictionary:
	# Placeholder for custom cloud download
	await get_tree().create_timer(0.5).timeout  # Simulate network delay
	
	return {"success": false, "error": "File not found in custom cloud"}

func _delete_custom_cloud_file(file_name: String) -> Dictionary:
	# Placeholder for custom cloud delete
	return {"success": true, "file_name": file_name}

func _delete_cloud_file(file_name: String) -> Dictionary:
	match cloud_service:
		CloudService.STEAM_CLOUD:
			return _delete_steam_cloud_file(file_name)
		CloudService.EPIC_CLOUD:
			return _delete_epic_cloud_file(file_name)
		CloudService.CUSTOM:
			return _delete_custom_cloud_file(file_name)
		_:
			return {"success": false, "error": "Cloud service not supported"}

# === UTILITY METHODS ===

func _cloud_service_to_string(service: CloudService) -> String:
	match service:
		CloudService.NONE: return "NONE"
		CloudService.STEAM_CLOUD: return "STEAM_CLOUD"
		CloudService.EPIC_CLOUD: return "EPIC_CLOUD"
		CloudService.CUSTOM: return "CUSTOM"
		_: return "UNKNOWN"

func _sync_status_to_string(status: SyncStatus) -> String:
	match status:
		SyncStatus.IDLE: return "IDLE"
		SyncStatus.SYNCING: return "SYNCING"
		SyncStatus.SYNCED: return "SYNCED"
		SyncStatus.CONFLICT: return "CONFLICT"
		SyncStatus.ERROR: return "ERROR"
		_: return "UNKNOWN"

# === DEBUG & UTILITY ===

func print_sync_status() -> void:
	var status = get_sync_status()
	print("=== CloudSaveAdapter Status ===")
	print("Service: %s" % status.service)
	print("Enabled: %s" % str(status.enabled))
	print("Initialized: %s" % str(status.initialized))
	print("Sync Status: %s" % status.sync_status)
	print("Last Sync: %.0f seconds ago" % (Time.get_unix_time_from_system() - status.last_sync_time))
	print("Sync Interval: %.1f seconds" % status.sync_interval)
	print("Conflict Resolution: %s" % status.conflict_resolution)

func test_cloud_operations() -> Dictionary:
	print("Testing cloud operations...")
	
	# Test 1: Initialize
	print("Test 1: Initializing cloud service...")
	var init_result = initialize()
	if not init_result.success:
		return {"success": false, "error": "Initialization failed: " + init_result.error}
	
	print("  Cloud service initialized: %s" % _cloud_service_to_string(cloud_service))
	
	# Test 2: Enable
	print("Test 2: Enabling cloud saves...")
	set_enabled(true)
	if not is_available():
		return {"success": false, "error": "Failed to enable cloud saves"}
	
	print("  Cloud saves enabled")
	
	# Test 3: Get quota
	print("Test 3: Getting cloud quota...")
	var quota_result = get_cloud_quota()
	if not quota_result.success:
		return {"success": false, "error": "Failed to get quota: " + quota_result.error}
	
	print("  Cloud quota: %.1f%% used" % quota_result.percent_used)
	
	# Test 4: Get file list
	print("Test 4: Getting cloud file list...")
	var file_list_result = get_cloud_file_list()
	if not file_list_result.success:
		return {"success": false, "error": "Failed to get file list: " + file_list_result.error}
	
	print("  Cloud files: %d" % file_list_result.file_count)
	
	# Test 5: Get sync status
	print("Test 5: Getting sync status...")
	var sync_status = get_sync_status()
	print("  Sync Status: %s" % sync_status.sync_status)
	
	return {"success": true, "tests_passed": 5}

func simulate_sync_scenario() -> Dictionary:
	print("Simulating sync scenarios...")
	
	# Create a test save
	var test_slot = 0
	var test_save_data = SaveSlotComponent.SaveData.new(
		test_slot,
		{
			"test": true,
			"scenario": "sync_test",
			"timestamp": Time.get_ticks_msec()
		},
		{
			"save_time": OS.get_datetime(),
			"total_play_time": 0.0,
			"game_version": "1.0.0"
		}
	)
	
	# Save locally
	var save_manager = SaveManager.get_instance()
	var save_result = save_manager.save_game(test_slot)
	if not save_result.success:
		return {"success": false, "error": "Failed to save test data: " + save_result.error}
	
	print("Test data saved locally")
	
	# Test different conflict resolution strategies
	var strategies = ["local", "cloud", "newest", "manual"]
	var results = []
	
	for strategy in strategies:
		print("\nTesting strategy: %s" % strategy)
		set_conflict_resolution(strategy)
		
		# Simulate sync (would normally upload to cloud)
		# Since we don't have real cloud, we'll simulate the logic
		
		if strategy == "manual":
			print("  Manual resolution required - UI should prompt user")
			results.append({"strategy": strategy, "result": "manual_required"})
		else:
			print("  Strategy would use: %s file" % strategy)
			results.append({"strategy": strategy, "result": "auto_resolved"})
	
	# Clean up
	save_manager.delete_save_slot(test_slot)
	
	return {
		"success": true,
		"scenarios_tested": strategies.size(),
		"results": results
	}