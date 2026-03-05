# 🚀 EVENT BUS SYSTEM
# Global event communication for decoupled components
class_name EventBus
extends Node

# === STATIC ACCESS ===
static var instance: EventBus = null

# === EVENT REGISTRY ===
var _event_listeners: Dictionary = {}           # event_type → Array[Callable]
var _event_queue: Array = []                    # Pending events
var _is_processing: bool = false                # Queue processing flag
var _max_queue_size: int = 1000                 # Prevent memory overflow

# === EVENT PRIORITIES ===
enum EventPriority {
	HIGHEST = 100,      # Critical system events
	HIGH = 75,          # Important gameplay events
	NORMAL = 50,        # Standard events (default)
	LOW = 25,           # Non-critical events
	LOWEST = 0          # Background events
}

# === EVENT STRUCTURE ===
class Event:
	var type: String
	var data: Dictionary
	var source: Node = null
	var timestamp: int
	var priority: int = EventPriority.NORMAL
	
	func _init(event_type: String, event_data: Dictionary = {}, event_source: Node = null, event_priority: int = EventPriority.NORMAL):
		type = event_type
		data = event_data
		source = event_source
		timestamp = Time.get_ticks_msec()
		priority = event_priority
	
	func _to_string() -> String:
		return "[Event: %s, Priority: %d, Source: %s]" % [type, priority, source.name if source else "null"]

# === SIGNALS ===
signal event_emitted(event: Event)
signal event_processed(event: Event)
signal event_discarded(event: Event)
signal listener_added(event_type: String, listener: Callable)
signal listener_removed(event_type: String, listener: Callable)

# === LIFECYCLE ===

func _ready() -> void:
	if instance != null:
		push_warning("Multiple EventBus instances detected!")
		queue_free()
		return
	
	instance = self
	print("EventBus initialized")
	
	# Start processing queue
	set_process(true)

func _exit_tree() -> void:
	if instance == self:
		instance = null
		print("EventBus destroyed")

func _process(delta: float) -> void:
	_process_event_queue()

# === PUBLIC API ===

# Subscribe to an event type
func subscribe(event_type: String, listener: Callable, priority: int = EventPriority.NORMAL) -> bool:
	if not event_type or not listener:
		push_error("Invalid subscription attempt")
		return false
	
	# Add priority to listener data
	var listener_data = {
		"callable": listener,
		"priority": priority
	}
	
	if not event_type in _event_listeners:
		_event_listeners[event_type] = []
	
	# Check if already subscribed
	for existing in _event_listeners[event_type]:
		if existing["callable"] == listener:
			push_warning("Listener already subscribed to event: %s" % event_type)
			return false
	
	_event_listeners[event_type].append(listener_data)
	
	# Sort by priority (highest first)
	_event_listeners[event_type].sort_custom(func(a, b): return a["priority"] > b["priority"])
	
	listener_added.emit(event_type, listener)
	return true

# Unsubscribe from an event type
func unsubscribe(event_type: String, listener: Callable) -> bool:
	if not event_type in _event_listeners:
		return false
	
	for i in range(_event_listeners[event_type].size()):
		if _event_listeners[event_type][i]["callable"] == listener:
			_event_listeners[event_type].remove_at(i)
			listener_removed.emit(event_type, listener)
			
			# Clean up empty arrays
			if _event_listeners[event_type].is_empty():
				_event_listeners.erase(event_type)
			
			return true
	
	return false

# Unsubscribe all listeners for a specific object
func unsubscribe_all_for_object(obj: Object) -> void:
	var events_to_remove = []
	
	for event_type in _event_listeners:
		var listeners = _event_listeners[event_type]
		var to_remove = []
		
		for i in range(listeners.size()):
			var listener_data = listeners[i]
			var listener = listener_data["callable"]
			
			# Check if listener belongs to the object
			if listener.get_object() == obj:
				to_remove.append(i)
		
		# Remove in reverse order
		to_remove.reverse()
		for i in to_remove:
			var removed_listener = listeners[i]["callable"]
			listeners.remove_at(i)
			listener_removed.emit(event_type, removed_listener)
		
		if listeners.is_empty():
			events_to_remove.append(event_type)
	
	# Clean up empty event types
	for event_type in events_to_remove:
		_event_listeners.erase(event_type)

# Emit an event immediately (synchronous)
func emit_now(event_type: String, data: Dictionary = {}, source: Node = null, priority: int = EventPriority.NORMAL) -> void:
	var event = Event.new(event_type, data, source, priority)
	_emit_event(event)

# Emit an event to the queue (asynchronous)
func emit_later(event_type: String, data: Dictionary = {}, source: Node = null, priority: int = EventPriority.NORMAL) -> void:
	var event = Event.new(event_type, data, source, priority)
	_queue_event(event)

# Check if there are listeners for an event type
func has_listeners(event_type: String) -> bool:
	return event_type in _event_listeners and not _event_listeners[event_type].is_empty()

# Get listener count for an event type
func get_listener_count(event_type: String) -> int:
	if not event_type in _event_listeners:
		return 0
	return _event_listeners[event_type].size()

# === STATIC HELPERS ===

static func get_instance() -> EventBus:
	return instance

static func is_available() -> bool:
	return instance != null

# Subscribe with static access
static func subscribe_static(event_type: String, listener: Callable, priority: int = EventPriority.NORMAL) -> bool:
	if not is_available():
		push_error("EventBus not available")
		return false
	return instance.subscribe(event_type, listener, priority)

# Emit now with static access
static func emit_now_static(event_type: String, data: Dictionary = {}, source: Node = null, priority: int = EventPriority.NORMAL) -> void:
	if not is_available():
		push_error("EventBus not available")
		return
	instance.emit_now(event_type, data, source, priority)

# Emit later with static access
static func emit_later_static(event_type: String, data: Dictionary = {}, source: Node = null, priority: int = EventPriority.NORMAL) -> void:
	if not is_available():
		push_error("EventBus not available")
		return
	instance.emit_later(event_type, data, source, priority)

# === PRIVATE METHODS ===

func _emit_event(event: Event) -> void:
	event_emitted.emit(event)
	
	# Notify listeners
	if event.type in _event_listeners:
		var listeners = _event_listeners[event.type].duplicate()  # Copy to avoid modification during iteration
		
		for listener_data in listeners:
			var listener = listener_data["callable"]
			
			# Check if listener is still valid
			if not listener.is_valid():
				unsubscribe(event.type, listener)
				continue
			
			# Call the listener
			var result = await listener.call(event)
	
	event_processed.emit(event)

func _queue_event(event: Event) -> void:
	if _event_queue.size() >= _max_queue_size:
		# Queue is full, discard lowest priority event
		var lowest_priority_index = -1
		var lowest_priority = EventPriority.NORMAL
		
		for i in range(_event_queue.size()):
			if _event_queue[i].priority < lowest_priority:
				lowest_priority = _event_queue[i].priority
				lowest_priority_index = i
		
		if lowest_priority_index >= 0 and event.priority > lowest_priority:
			var discarded = _event_queue[lowest_priority_index]
			_event_queue.remove_at(lowest_priority_index)
			event_discarded.emit(discarded)
		else:
			# New event has lower priority than all in queue, discard it
			event_discarded.emit(event)
			return
	
	# Add to queue and sort by priority (highest first)
	_event_queue.append(event)
	_event_queue.sort_custom(func(a, b): return a.priority > b.priority)

func _process_event_queue() -> void:
	if _is_processing or _event_queue.is_empty():
		return
	
	_is_processing = true
	
	# Process up to 10 events per frame to prevent frame drops
	var processed = 0
	var max_per_frame = 10
	
	while not _event_queue.is_empty() and processed < max_per_frame:
		var event = _event_queue.pop_front()
		_emit_event(event)
		processed += 1
	
	_is_processing = false

# === DEBUG & STATS ===

func get_stats() -> Dictionary:
	var total_listeners = 0
	for event_type in _event_listeners:
		total_listeners += _event_listeners[event_type].size()
	
	return {
		"total_event_types": _event_listeners.size(),
		"total_listeners": total_listeners,
		"queued_events": _event_queue.size(),
		"is_processing": _is_processing,
		"event_types": _event_listeners.keys()
	}

func print_stats() -> void:
	var stats = get_stats()
	print("=== EventBus Stats ===")
	print("Total Event Types: %d" % stats.total_event_types)
	print("Total Listeners: %d" % stats.total_listeners)
	print("Queued Events: %d" % stats.queued_events)
	print("Is Processing: %s" % str(stats.is_processing))
	print("Event Types: %s" % str(stats.event_types))

func get_queue_info() -> Array:
	var info = []
	for event in _event_queue:
		info.append(str(event))
	return info

# === COMMON EVENT TYPES (Predefined for consistency) ===

# Game State Events
const GAME_STARTED = "game_started"
const GAME_PAUSED = "game_paused"
const GAME_RESUMED = "game_resumed"
const GAME_OVER = "game_over"
const LEVEL_STARTED = "level_started"
const LEVEL_COMPLETED = "level_completed"

# Player Events
const PLAYER_SPAWNED = "player_spawned"
const PLAYER_DIED = "player_died"
const PLAYER_HEALTH_CHANGED = "player_health_changed"
const PLAYER_EXPERIENCE_CHANGED = "player_experience_changed"
const PLAYER_LEVEL_UP = "player_level_up"
const PLAYER_DAMAGED = "player_damaged"
const PLAYER_HEALED = "player_healed"

# Enemy Events
const ENEMY_SPAWNED = "enemy_spawned"
const ENEMY_DIED = "enemy_died"
const ENEMY_DAMAGED = "enemy_damaged"
const ENEMY_TARGET_CHANGED = "enemy_target_changed"

# Combat Events
const PROJECTILE_FIRED = "projectile_fired"
const PROJECTILE_HIT = "projectile_hit"
const MELEE_ATTACK = "melee_attack"
const DAMAGE_DEALT = "damage_dealt"
const CRITICAL_HIT = "critical_hit"

# Item Events
const ITEM_PICKED_UP = "item_picked_up"
const ITEM_DROPPED = "item_dropped"
const ITEM_USED = "item_used"
const INVENTORY_CHANGED = "inventory_changed"
const WEAPON_CHANGED = "weapon_changed"
const WEAPON_UPGRADED = "weapon_upgraded"
const WEAPON_FIRED = "weapon_fired"
const PLAYER_STATS_CHANGED = "player_stats_changed"

# UI Events
const UI_SHOW = "ui_show"
const UI_HIDE = "ui_hide"
const UI_BUTTON_CLICKED = "ui_button_clicked"
const UI_SLIDER_CHANGED = "ui_slider_changed"

# Audio Events
const PLAY_SOUND = "play_sound"
const PLAY_MUSIC = "play_music"
const STOP_MUSIC = "stop_music"
const SET_VOLUME = "set_volume"

# System Events
const SAVE_GAME = "save_game"
const LOAD_GAME = "load_game"
const SETTINGS_CHANGED = "settings_changed"

# === CONVENIENCE METHODS ===

# Quick subscription for common patterns
func subscribe_to_player_events(listener: Callable) -> void:
	subscribe(PLAYER_HEALTH_CHANGED, listener)
	subscribe(PLAYER_EXPERIENCE_CHANGED, listener)
	subscribe(PLAYER_LEVEL_UP, listener)
	subscribe(PLAYER_DAMAGED, listener)

func subscribe_to_combat_events(listener: Callable) -> void:
	subscribe(PROJECTILE_FIRED, listener)
	subscribe(PROJECTILE_HIT, listener)
	subscribe(DAMAGE_DEALT, listener)
	subscribe(CRITICAL_HIT, listener)

func subscribe_to_item_events(listener: Callable) -> void:
	subscribe(ITEM_PICKED_UP, listener)
	subscribe(INVENTORY_CHANGED, listener)
	subscribe(WEAPON_CHANGED, listener)
	subscribe(WEAPON_UPGRADED, listener)

# === DEBUG ===

func _to_string() -> String:
	return "[EventBus: %d event types, %d listeners]" % [
		_event_listeners.size(),
		get_stats().total_listeners
	]