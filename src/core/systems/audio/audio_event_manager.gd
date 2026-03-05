# 🎵 AUDIO EVENT MANAGER (ORGANISM)
# Event-based audio sistemi, EventBus ile entegre
class_name AudioEventManager
extends Node

# === EVENT CATEGORIES ===
enum AudioEventCategory {
	GAMEPLAY,
	UI,
	AMBIENT,
	MUSIC,
	VOICE,
	SYSTEM
}

# === EVENT PRIORITIES ===
enum EventPriority {
	CRITICAL = 100,     # Can't miss (damage, death)
	HIGH = 75,          # Important (pickups, level up)
	NORMAL = 50,        # Standard (attacks, movements)
	LOW = 25,           # Background (ambient, footsteps)
	MINIMAL = 0         # Optional (UI clicks, minor effects)
}

# === EVENT CONFIGURATION ===
var _event_configs: Dictionary = {}  # event_name → event_config
var _event_handlers: Dictionary = {} # event_type → handler_function
var _active_events: Array = []       # Aktif event'ler
var _event_history: Array = []       # Event geçmişi
var _max_history_size: int = 100

# === DEPENDENCIES ===
var audio_system: Node = null  # Ana AudioSystem referansı
var audio_settings: AudioSettings = null

# === SIGNALS ===
signal event_received(event_name: String, data: Dictionary)
signal event_processed(event_name: String, success: bool)
signal event_queued(event_name: String, priority: EventPriority)
signal event_discarded(event_name: String, reason: String)
signal event_history_updated(history_size: int)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioEventManager initializing...")
	
	# Event konfigürasyonlarını yükle
	_load_event_configs()
	
	# EventBus subscription'larını ayarla
	_setup_event_bus_subscriptions()
	
	print("AudioEventManager initialized")

func set_dependencies(audio_sys: Node, settings: AudioSettings) -> void:
	# Dependency'leri ayarla
	audio_system = audio_sys
	audio_settings = settings

# === PUBLIC API ===

func register_event_handler(event_type: String, handler: Callable, priority: EventPriority = EventPriority.NORMAL) -> bool:
	# Event handler kaydet
	if not event_type or not handler:
		return false
	
	if not event_type in _event_handlers:
		_event_handlers[event_type] = []
	
	# Handler zaten kayıtlı mı kontrol et
	for existing in _event_handlers[event_type]:
		if existing.handler == handler:
			print("Handler already registered for event: %s" % event_type)
			return false
	
	_event_handlers[event_type].append({
		"handler": handler,
		"priority": priority
	})
	
	# Priority'ye göre sırala
	_event_handlers[event_type].sort_custom(func(a, b): return a.priority > b.priority)
	
	print("Registered handler for event: %s (priority: %d)" % [event_type, priority])
	return true

func unregister_event_handler(event_type: String, handler: Callable) -> bool:
	# Event handler kaldır
	if not event_type in _event_handlers:
		return false
	
	for i in range(_event_handlers[event_type].size()):
		if _event_handlers[event_type][i].handler == handler:
			_event_handlers[event_type].remove_at(i)
			
			# Boş array'leri temizle
			if _event_handlers[event_type].is_empty():
				_event_handlers.erase(event_type)
			
			print("Unregistered handler for event: %s" % event_type)
			return true
	
	return false

func process_event(event_name: String, event_data: Dictionary = {}, source: Node = null) -> bool:
	# Event işle
	if not _should_process_event(event_name, event_data):
		event_discarded.emit(event_name, "Filtered out")
		return false
	
	event_received.emit(event_name, event_data)
	_add_to_history(event_name, event_data, source)
	
	# Event'i işle
	var success = _handle_event(event_name, event_data)
	
	event_processed.emit(event_name, success)
	return success

func queue_event(event_name: String, event_data: Dictionary = {}, priority: EventPriority = EventPriority.NORMAL) -> void:
	# Event'i kuyruğa al (async)
	event_queued.emit(event_name, priority)
	
	# Bir sonraki frame'de işle
	call_deferred("process_event", event_name, event_data)

func register_event_config(event_name: String, config: Dictionary) -> bool:
	# Event konfigürasyonu kaydet
	if not event_name or config.is_empty():
		return false
	
	_event_configs[event_name] = config
	print("Registered event config: %s" % event_name)
	return true

func get_event_config(event_name: String) -> Dictionary:
	# Event konfigürasyonunu al
	return _event_configs.get(event_name, {}).duplicate(true)

func get_active_events() -> Array:
	# Aktif event'leri al
	return _active_events.duplicate()

func get_event_history(count: int = 10) -> Array:
	# Event geçmişini al
	var start_index = max(0, _event_history.size() - count)
	return _event_history.slice(start_index, _event_history.size())

func clear_event_history() -> void:
	# Event geçmişini temizle
	_event_history.clear()
	event_history_updated.emit(0)

func get_event_stats() -> Dictionary:
	# Event istatistiklerini al
	var stats = {
		"total_events_processed": _event_history.size(),
		"active_events": _active_events.size(),
		"registered_handlers": 0,
		"event_types": []
	}
	
	for event_type in _event_handlers:
		stats["registered_handlers"] += _event_handlers[event_type].size()
		stats["event_types"].append(event_type)
	
	return stats

# === PRIVATE METHODS ===

func _load_event_configs() -> void:
	# Varsayılan event konfigürasyonlarını yükle
	
	# Gameplay events
	register_event_config("player_damaged", {
		"category": AudioEventCategory.GAMEPLAY,
		"default_sound": "hit",
		"volume": 0.9,
		"pitch_variation": 0.1,
		"priority": EventPriority.HIGH,
		"cooldown": 0.1,
		"max_concurrent": 3
	})
	
	register_event_config("player_healed", {
		"category": AudioEventCategory.GAMEPLAY,
		"default_sound": "heal",
		"volume": 0.8,
		"pitch_variation": 0.05,
		"priority": EventPriority.NORMAL
	})
	
	register_event_config("enemy_died", {
		"category": AudioEventCategory.GAMEPLAY,
		"default_sound": "explosion",
		"volume": 1.0,
		"pitch_variation": 0.15,
		"priority": EventPriority.NORMAL,
		"spatial": true
	})
	
	# UI events
	register_event_config("ui_button_click", {
		"category": AudioEventCategory.UI,
		"default_sound": "click",
		"volume": 0.7,
		"pitch_variation": 0.0,
		"priority": EventPriority.MINIMAL,
		"cooldown": 0.05
	})
	
	register_event_config("ui_slider_change", {
		"category": AudioEventCategory.UI,
		"default_sound": "slide",
		"volume": 0.5,
		"pitch_variation": 0.0,
		"priority": EventPriority.MINIMAL
	})
	
	# Music events
	register_event_config("music_transition", {
		"category": AudioEventCategory.MUSIC,
		"default_music": "",
		"fade_in": 1.0,
		"fade_out": 1.0,
		"priority": EventPriority.LOW
	})
	
	print("Loaded %d event configurations" % _event_configs.size())

func _setup_event_bus_subscriptions() -> void:
	# EventBus subscription'larını ayarla
	if not EventBus.is_available():
		print("EventBus not available for AudioEventManager")
		return
	
	# Gameplay events
	EventBus.subscribe_static(EventBus.PLAYER_DAMAGED, _on_player_damaged)
	EventBus.subscribe_static(EventBus.PLAYER_HEALED, _on_player_healed)
	EventBus.subscribe_static(EventBus.ENEMY_DIED, _on_enemy_died)
	EventBus.subscribe_static(EventBus.ITEM_PICKED_UP, _on_item_picked_up)
	EventBus.subscribe_static(EventBus.WEAPON_CHANGED, _on_weapon_changed)
	
	# UI events
	EventBus.subscribe_static(EventBus.UI_BUTTON_CLICKED, _on_ui_button_clicked)
	EventBus.subscribe_static(EventBus.UI_SLIDER_CHANGED, _on_ui_slider_changed)
	
	# System events
	EventBus.subscribe_static(EventBus.GAME_STARTED, _on_game_started)
	EventBus.subscribe_static(EventBus.GAME_PAUSED, _on_game_paused)
	EventBus.subscribe_static(EventBus.GAME_OVER, _on_game_over)
	
	print("Registered %d EventBus subscriptions" % 9)  # Yukarıdaki 9 subscription

func _should_process_event(event_name: String, event_data: Dictionary) -> bool:
	# Event işlenmeli mi?
	
	# Audio settings kontrolü
	if audio_settings:
		var config = _event_configs.get(event_name, {})
		var category = config.get("category", AudioEventCategory.GAMEPLAY)
		
		# Mute kontrolü
		match category:
			AudioEventCategory.MUSIC:
				if not audio_settings.get_setting("music_enabled", true):
					return false
			AudioEventCategory.GAMEPLAY:
				if not audio_settings.get_setting("sfx_enabled", true):
					return false
			AudioEventCategory.UI:
				if not audio_settings.get_setting("ui_sounds_enabled", true):
					return false
	
	# Cooldown kontrolü
	var config = _event_configs.get(event_name, {})
	var cooldown = config.get("cooldown", 0.0)
	
	if cooldown > 0:
		for active_event in _active_events:
			if active_event.name == event_name and active_event.timestamp + cooldown > Time.get_ticks_msec() / 1000.0:
				return false
	
	# Max concurrent kontrolü
	var max_concurrent = config.get("max_concurrent", 0)
	if max_concurrent > 0:
		var concurrent_count = 0
		for active_event in _active_events:
			if active_event.name == event_name:
				concurrent_count += 1
		
		if concurrent_count >= max_concurrent:
			return false
	
	return true

func _handle_event(event_name: String, event_data: Dictionary) -> bool:
	# Event'i işle
	
	# Aktif event'lere ekle
	var event_record = {
		"name": event_name,
		"data": event_data,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"processed": false
	}
	
	_active_events.append(event_record)
	
	# Custom handler'ları çağır
	if event_name in _event_handlers:
		var handlers = _event_handlers[event_name]
		var success = false
		
		for handler_data in handlers:
			var handler = handler_data.handler
			if handler.is_valid():
				var result = handler.call(event_name, event_data)
				if result is bool and result:
					success = true
		
		event_record.processed = success
		return success
	
	# Varsayılan handler
	var default_success = _handle_default_event(event_name, event_data)
	event_record.processed = default_success
	
	# Aktif event'lerden eski olanları temizle
	_cleanup_active_events()
	
	return default_success

func _handle_default_event(event_name: String, event_data: Dictionary) -> bool:
	# Varsayılan event handler
	var config = _event_configs.get(event_name, {})
	
	if not audio_system:
		return false
	
	# Event tipine göre işle
	match config.get("category", AudioEventCategory.GAMEPLAY):
		AudioEventCategory.GAMEPLAY:
			var sound_name = event_data.get("sound", config.get("default_sound", ""))
			if sound_name:
				var volume = event_data.get("volume", config.get("volume", 1.0))
				var pitch = event_data.get("pitch", 1.0)
				var pitch_variation = config.get("pitch_variation", 0.0)
				
				# Pitch variation uygula
				if pitch_variation > 0:
					pitch += randf_range(-pitch_variation, pitch_variation)
				
				var is_3d = config.get("spatial", false)
				var position = event_data.get("position", Vector3.ZERO)
				
				return audio_system.play_sound(sound_name, linear_to_db(volume), pitch, position, is_3d)
		
		AudioEventCategory.UI:
			var sound_name = event_data.get("sound", config.get("default_sound", ""))
			if sound_name:
				var volume = event_data.get("volume", config.get("volume", 1.0))
				return audio_system.play_ui_sound(sound_name, linear_to_db(volume))
		
		AudioEventCategory.MUSIC:
			var music_name = event_data.get("music", config.get("default_music", ""))
			if music_name:
				var fade_in = event_data.get("fade_in", config.get("fade_in", 0.0))
				var loop = event_data.get("loop", true)
				return audio_system.play_music(music_name, fade_in, loop)
	
	return false

func _add_to_history(event_name: String, event_data: Dictionary, source: Node) -> void:
	# Event geçmişine ekle
	var history_entry = {
		"name": event_name,
		"data": event_data,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"source": source.name if source else "unknown"
	}
	
	_event_history.append(history_entry)
	
	# Geçmiş boyutunu sınırla
	if _event_history.size() > _max_history_size:
		_event_history.pop_front()
	
	event_history_updated.emit(_event_history.size())

func _cleanup_active_events() -> void:
	# Eski aktif event'leri temizle
	var current_time = Time.get_ticks_msec() / 1000.0
	var to_remove = []
	
	for i in range(_active_events.size()):
		var event = _active_events[i]
		var config = _event_configs.get(event.name, {})
		var max_age = config.get("max_age", 5.0)  # Varsayılan 5 saniye
		
		if current_time - event.timestamp > max_age:
			to_remove.append(i)
	
	# Ters sırada sil
	to_remove.reverse()
	for index in to_remove:
		_active_events.remove_at(index)

# === EVENT BUS HANDLERS ===

func _on_player_damaged(event: EventBus.Event) -> void:
	process_event("player_damaged", event.data, event.source)

func _on_player_healed(event: EventBus.Event) -> void:
	process_event("player_healed", event.data, event.source)

func _on_enemy_died(event: EventBus.Event) -> void:
	process_event("enemy_died", event.data, event.source)

func _on_item_picked_up(event: EventBus.Event) -> void:
	process_event("item_picked_up", {
		"sound": "pickup",
		"volume": 0.8,
		"item_type": event.data.get("item_type", "unknown")
	}, event.source)

func _on_weapon_changed(event: EventBus.Event) -> void:
	process_event("weapon_changed", {
		"sound": "click",
		"volume": 0.6,
		"weapon": event.data.get("weapon", "unknown")
	}, event.source)

func _on_ui_button_clicked(event: EventBus.Event) -> void:
	process_event("ui_button_click", {
		"sound": "click",
		"volume": 0.7,
		"button": event.data.get("button", "unknown")
	}, event.source)

func _on_ui_slider_changed(event: EventBus.Event) -> void:
	process_event("ui_slider_change", {
		"sound": "slide",
		"volume": 0.5 * event.data.get("value", 1.0),
		"slider": event.data.get("slider", "unknown")
	}, event.source)

func _on_game_started(event: EventBus.Event) -> void:
	process_event("music_transition", {
		"music": "game_start",
		"fade_in": 2.0,
		"loop": true
	}, event.source)

func _on_game_paused(event: EventBus.Event) -> void:
	if audio_system:
		audio_system.pause_music()

func _on_game_over(event: EventBus.Event) -> void:
	process_event("music_transition", {
		"music": "game_over",
		"fade_in": 1.0,
		"loop": false
	}, event.source)

# === DEBUG ===

func print_event_stats() -> void:
	var stats = get_event_stats()
	print("=== AudioEventManager Stats ===")
	print("Total Events Processed: %d" % stats["total_events_processed"])
	print("Active Events: %d" % stats["active_events"])
	print("Registered Handlers: %d" % stats["registered_handlers"])
	print("Event Types: %s" % str(stats["event_types"]))
	
	print("\nRecent Events:")
	var recent_events = get_event_history(5)
	for i in range(recent_events.size()):
		var event = recent_events[i]
		print("  %d. %s (%.1fs ago)" % [
			i + 1,
			event.name,
			Time.get_ticks_msec() / 1000.0 - event.timestamp
		])

func _to_string() -> String:
	return "[AudioEventManager: %d events processed]" % _event_history.size()