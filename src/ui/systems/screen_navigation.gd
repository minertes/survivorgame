# 🚀 SCREEN NAVIGATION SYSTEM
# Ekran geçişlerini ve yığın yönetimini sağlar
class_name ScreenNavigation
extends Node

# === SCREEN TYPES ===
enum ScreenType {
	MAIN_MENU,
	GAME_HUD,
	UPGRADE_SCREEN,
	SETTINGS_SCREEN,
	PAUSE_SCREEN,
	GAME_OVER
}

# === TRANSITION TYPES ===
enum TransitionType {
	NONE,
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	CROSSFADE
}

# === NODES ===
@onready var screen_container: Control = $ScreenContainer
@onready var transition_overlay: ColorRect = $TransitionOverlay
var transition_tween: Tween

# === STATE ===
var current_screen: Control = null
var previous_screen: Control = null
var screen_stack: Array = []  # ScreenType'ları tutar
var screen_instances: Dictionary = {}  # ScreenType → Control
var transition_history: Array = []
var is_transitioning: bool = false
var default_transition: TransitionType = TransitionType.FADE
var transition_duration: float = 0.3

# === CONFIG ===
var screen_configs: Dictionary = {
	ScreenType.MAIN_MENU: {
		"scene_path": "res://src/ui/organisms/mainmenu_organism.tscn",
		"allow_back": false,
		"persistent": false,
		"clear_stack": true,
		"lifecycle_hooks": true
	},
	ScreenType.GAME_HUD: {
		"scene_path": "res://src/ui/organisms/game_hud_organism.tscn",
		"allow_back": false,
		"persistent": true,
		"clear_stack": false,
		"lifecycle_hooks": true
	},
	ScreenType.UPGRADE_SCREEN: {
		"scene_path": "res://src/ui/organisms/upgradescreen_organism.tscn",
		"allow_back": true,
		"persistent": false,
		"clear_stack": false,
		"lifecycle_hooks": true
	},
	ScreenType.SETTINGS_SCREEN: {
		"scene_path": "res://src/ui/organisms/settingsscreen_organism.tscn",
		"allow_back": true,
		"persistent": false,
		"clear_stack": false,
		"lifecycle_hooks": true
	},
	ScreenType.PAUSE_SCREEN: {
		"scene_path": "",
		"allow_back": true,
		"persistent": false,
		"clear_stack": false,
		"lifecycle_hooks": false
	},
	ScreenType.GAME_OVER: {
		"scene_path": "",
		"allow_back": false,
		"persistent": false,
		"clear_stack": true,
		"lifecycle_hooks": false
	}
}

# === EVENTS ===
signal screen_changed(old_screen: ScreenType, new_screen: ScreenType)
signal transition_started(from_screen: ScreenType, to_screen: ScreenType, transition: TransitionType)
signal transition_completed(from_screen: ScreenType, to_screen: ScreenType, transition: TransitionType)
signal screen_stack_updated(stack: Array)
signal navigation_blocked(reason: String)
signal navigation_resumed

# === LIFECYCLE ===

func _ready() -> void:
	print("ScreenNavigation initialized")
	
	# Transition overlay'ı gizle
	transition_overlay.visible = false
	transition_overlay.color = Color.TRANSPARENT
	
	# EventBus subscription'ları
	_setup_event_bus_subscriptions()
	
	# Varsayılan ekranı yükle
	_show_default_screen()

# === PUBLIC API ===

func show_screen(screen_type: ScreenType, transition_type: TransitionType = -1, data: Dictionary = {}) -> void:
	if is_transitioning:
		push_warning("Navigation blocked: Transition in progress")
		navigation_blocked.emit("Transition in progress")
		return
	
	if transition_type == -1:
		transition_type = default_transition
	
	var old_screen_type = _get_current_screen_type()
	
	# Transition başlat
	transition_started.emit(old_screen_type, screen_type, transition_type)
	is_transitioning = true
	
	# Yeni ekranı yükle veya getir
	var new_screen = _get_or_create_screen(screen_type)
	if not new_screen:
		push_error("Failed to load screen: %s" % ScreenType.keys()[screen_type])
		is_transitioning = false
		return
	
	# Ekran verilerini ayarla
	_set_screen_data(new_screen, data)
	
	# Transition'ı gerçekleştir
	_perform_transition(current_screen, new_screen, transition_type, screen_type, old_screen_type)

func go_back(data: Dictionary = {}) -> bool:
	if is_transitioning:
		push_warning("Navigation blocked: Transition in progress")
		navigation_blocked.emit("Transition in progress")
		return false
	
	if screen_stack.size() <= 1:
		push_warning("Cannot go back: No previous screen")
		return false
	
	# Önceki ekranı al
	var current_type = screen_stack.pop_back()
	var previous_type = screen_stack.back()
	
	# Önceki ekrana dön
	show_screen(previous_type, TransitionType.SLIDE_RIGHT, data)
	
	return true

func go_to_main_menu(data: Dictionary = {}) -> void:
	# Stack'i temizle ve ana menüye git
	screen_stack.clear()
	show_screen(ScreenType.MAIN_MENU, TransitionType.FADE, data)

func go_to_game_hud(data: Dictionary = {}) -> void:
	# Stack'i temizle ve oyun HUD'una git
	screen_stack.clear()
	show_screen(ScreenType.GAME_HUD, TransitionType.FADE, data)

func get_current_screen_type() -> ScreenType:
	return _get_current_screen_type()

func get_previous_screen_type() -> ScreenType:
	if screen_stack.size() > 1:
		return screen_stack[screen_stack.size() - 2]
	return ScreenType.MAIN_MENU

func get_screen_stack() -> Array:
	return screen_stack.duplicate()

func clear_screen_stack() -> void:
	screen_stack.clear()
	screen_stack_updated.emit(screen_stack)

func is_screen_visible(screen_type: ScreenType) -> bool:
	return current_screen == screen_instances.get(screen_type)

func get_screen_instance(screen_type: ScreenType) -> Control:
	return screen_instances.get(screen_type)

func set_transition_duration(duration: float) -> void:
	transition_duration = max(0.1, duration)

func set_default_transition(transition: TransitionType) -> void:
	default_transition = transition

func block_navigation() -> void:
	is_transitioning = true

func resume_navigation() -> void:
	is_transitioning = false
	navigation_resumed.emit()

# === SCREEN MANAGEMENT ===

func _show_default_screen() -> void:
	# Varsayılan olarak ana menüyü göster
	show_screen(ScreenType.MAIN_MENU, TransitionType.NONE)

func _get_or_create_screen(screen_type: ScreenType) -> Control:
	# Önceden yüklenmiş ekranı kontrol et
	if screen_type in screen_instances:
		return screen_instances[screen_type]
	
	# Config'den scene path'ini al
	var config = screen_configs.get(screen_type, {})
	var scene_path = config.get("scene_path", "")
	
	if scene_path.is_empty():
		push_error("No scene path configured for screen type: %s" % ScreenType.keys()[screen_type])
		return null
	
	# Scene'i yükle
	var scene = load(scene_path)
	if not scene:
		push_error("Failed to load scene: %s" % scene_path)
		return null
	
	# Instance oluştur
	var screen_instance = scene.instantiate()
	if not screen_instance is Control:
		push_error("Screen is not a Control node: %s" % scene_path)
		return null
	
	# Container'a ekle (başlangıçta gizli)
	screen_container.add_child(screen_instance)
	screen_instance.visible = false
	
	# Kaydet
	screen_instances[screen_type] = screen_instance
	
	return screen_instance

func _set_screen_data(screen: Control, data: Dictionary) -> void:
	# Ekrana özel verileri ayarla
	if screen.has_method("set_screen_data"):
		screen.set_screen_data(data)

func _cleanup_unused_screens() -> void:
	# Kullanılmayan persistent olmayan ekranları temizle
	var screens_to_remove = []
	
	for screen_type in screen_instances:
		var config = screen_configs.get(screen_type, {})
		var is_persistent = config.get("persistent", false)
		
		if not is_persistent and screen_type != _get_current_screen_type():
			var screen = screen_instances[screen_type]
			if screen:
				screen.queue_free()
			screens_to_remove.append(screen_type)
	
	for screen_type in screens_to_remove:
		screen_instances.erase(screen_type)

# === TRANSITION MANAGEMENT ===

func _perform_transition(old_screen: Control, new_screen: Control, transition_type: TransitionType, 
						new_screen_type: ScreenType, old_screen_type: ScreenType) -> void:
	
	# Yeni ekranı hazırla
	new_screen.visible = true
	
	# Transition tipine göre animasyon uygula
	match transition_type:
		TransitionType.NONE:
			_apply_none_transition(old_screen, new_screen)
		TransitionType.FADE:
			_apply_fade_transition(old_screen, new_screen)
		TransitionType.SLIDE_LEFT:
			_apply_slide_transition(old_screen, new_screen, Vector2(1, 0), Vector2(0, 0))
		TransitionType.SLIDE_RIGHT:
			_apply_slide_transition(old_screen, new_screen, Vector2(-1, 0), Vector2(0, 0))
		TransitionType.SLIDE_UP:
			_apply_slide_transition(old_screen, new_screen, Vector2(0, 1), Vector2(0, 0))
		TransitionType.SLIDE_DOWN:
			_apply_slide_transition(old_screen, new_screen, Vector2(0, -1), Vector2(0, 0))
		TransitionType.CROSSFADE:
			_apply_crossfade_transition(old_screen, new_screen)
		_:
			_apply_fade_transition(old_screen, new_screen)  # Varsayılan
	
	# State'i güncelle
	previous_screen = old_screen
	current_screen = new_screen
	
	# Stack'i güncelle
	_update_screen_stack(new_screen_type, old_screen_type)
	
	# Transition tamamlandığında callback
	await get_tree().create_timer(transition_duration).timeout
	
	# Eski ekranı gizle
	if old_screen and old_screen != new_screen:
		old_screen.visible = false
	
	# Kullanılmayan ekranları temizle
	_cleanup_unused_screens()
	
	# Transition tamamlandı
	is_transitioning = false
	transition_completed.emit(old_screen_type, new_screen_type, transition_type)
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static("screen_changed", {
			"old_screen": old_screen_type,
			"new_screen": new_screen_type,
			"transition": TransitionType.keys()[transition_type],
			"duration": transition_duration
		})

func _apply_none_transition(old_screen: Control, new_screen: Control) -> void:
	# Hemen değiştir
	if old_screen:
		old_screen.visible = false
	new_screen.visible = true

func _apply_fade_transition(old_screen: Control, new_screen: Control) -> void:
	# Fade overlay'ını göster
	transition_overlay.visible = true
	transition_overlay.color = Color.TRANSPARENT
	
	if transition_tween:
		transition_tween.kill()
	
	transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_CUBIC)
	transition_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Fade in
	transition_tween.tween_property(transition_overlay, "color", Color.BLACK, transition_duration / 2)
	transition_tween.tween_callback(func():
		# Ekranları değiştir
		if old_screen:
			old_screen.visible = false
		new_screen.visible = true
	)
	# Fade out
	transition_tween.tween_property(transition_overlay, "color", Color.TRANSPARENT, transition_duration / 2)
	transition_tween.tween_callback(func():
		transition_overlay.visible = false
	)

func _apply_slide_transition(old_screen: Control, new_screen: Control, start_offset: Vector2, end_offset: Vector2) -> void:
	var screen_size = screen_container.size
	
	# Yeni ekranı başlangıç pozisyonuna ayarla
	new_screen.position = start_offset * screen_size
	
	if transition_tween:
		transition_tween.kill()
	
	transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_CUBIC)
	transition_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Eski ekranı kaydır
	if old_screen:
		transition_tween.tween_property(old_screen, "position", -start_offset * screen_size, transition_duration)
	
	# Yeni ekranı kaydır
	transition_tween.parallel().tween_property(new_screen, "position", end_offset * screen_size, transition_duration)
	
	# Eski ekranı gizle
	transition_tween.tween_callback(func():
		if old_screen:
			old_screen.visible = false
			old_screen.position = Vector2.ZERO
		new_screen.position = Vector2.ZERO
	)

func _apply_crossfade_transition(old_screen: Control, new_screen: Control) -> void:
	# Crossfade için her iki ekran da görünür olmalı
	new_screen.modulate = Color.TRANSPARENT
	
	if transition_tween:
		transition_tween.kill()
	
	transition_tween = create_tween()
	transition_tween.set_trans(Tween.TRANS_CUBIC)
	transition_tween.set_ease(Tween.EASE_IN_OUT)
	
	# Eski ekran fade out
	if old_screen:
		transition_tween.tween_property(old_screen, "modulate", Color.TRANSPARENT, transition_duration)
	
	# Yeni ekran fade in
	transition_tween.parallel().tween_property(new_screen, "modulate", Color.WHITE, transition_duration)
	
	# Eski ekranı gizle
	transition_tween.tween_callback(func():
		if old_screen:
			old_screen.visible = false
			old_screen.modulate = Color.WHITE
		new_screen.modulate = Color.WHITE
	)

func _update_screen_stack(new_screen_type: ScreenType, old_screen_type: ScreenType) -> void:
	var config = screen_configs.get(new_screen_type, {})
	var clear_stack = config.get("clear_stack", false)
	var allow_back = config.get("allow_back", true)
	
	if clear_stack:
		screen_stack.clear()
	
	# Stack'e ekle (eğer zaten en üstte değilse)
	if screen_stack.is_empty() or screen_stack.back() != new_screen_type:
		screen_stack.append(new_screen_type)
	
	# Stack güncellendi sinyali gönder
	screen_stack_updated.emit(screen_stack)
	
	# Transition geçmişine ekle
	transition_history.append({
		"from": old_screen_type,
		"to": new_screen_type,
		"timestamp": Time.get_unix_time_from_system(),
		"stack_size": screen_stack.size()
	})
	
	# Geçmişi sınırla (son 50 transition)
	if transition_history.size() > 50:
		transition_history.pop_front()

func _get_current_screen_type() -> ScreenType:
	for screen_type in screen_instances:
		if screen_instances[screen_type] == current_screen:
			return screen_type
	return ScreenType.MAIN_MENU

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	# Navigation events
	EventBus.subscribe_static("navigate_to_screen", _on_navigate_to_screen)
	EventBus.subscribe_static("navigate_back", _on_navigate_back)
	EventBus.subscribe_static("navigate_to_main_menu", _on_navigate_to_main_menu)
	EventBus.subscribe_static("navigate_to_game_hud", _on_navigate_to_game_hud)
	
	# Game state events
	EventBus.subscribe_static(EventBus.GAME_STARTED, _on_game_started)
	EventBus.subscribe_static(EventBus.GAME_PAUSED, _on_game_paused)
	EventBus.subscribe_static(EventBus.GAME_RESUMED, _on_game_resumed)
	EventBus.subscribe_static(EventBus.GAME_OVER, _on_game_over)

func _remove_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	EventBus.get_instance().unsubscribe_all_for_object(self)

# === EVENT HANDLERS ===

func _on_navigate_to_screen(event: EventBus.Event) -> void:
	var screen_type = event.data.get("screen_type", ScreenType.MAIN_MENU)
	var transition = event.data.get("transition", -1)
	var data = event.data.get("data", {})
	
	show_screen(screen_type, transition, data)

func _on_navigate_back(event: EventBus.Event) -> void:
	var data = event.data.get("data", {})
	go_back(data)

func _on_navigate_to_main_menu(event: EventBus.Event) -> void:
	var data = event.data.get("data", {})
	go_to_main_menu(data)

func _on_navigate_to_game_hud(event: EventBus.Event) -> void:
	var data = event.data.get("data", {})
	go_to_game_hud(data)

func _on_game_started(event: EventBus.Event) -> void:
	# Oyun başladığında Game HUD'a git
	go_to_game_hud()

func _on_game_paused(event: EventBus.Event) -> void:
	# Oyun durduğunda Pause screen'e git (henüz yoksa ana menü)
	show_screen(ScreenType.MAIN_MENU, TransitionType.FADE)

func _on_game_resumed(event: EventBus.Event) -> void:
	# Oyun devam ettiğinde Game HUD'a geri dön
	go_to_game_hud()

func _on_game_over(event: EventBus.Event) -> void:
	# Game over screen'e git (henüz yoksa ana menü)
	show_screen(ScreenType.MAIN_MENU, TransitionType.FADE)

# === CLEANUP ===

func _exit_tree() -> void:
	_remove_event_bus_subscriptions()

# === DEBUG ===

func _to_string() -> String:
	var current_type = _get_current_screen_type()
	return "[ScreenNavigation: Current: %s, Stack: %d, Transitioning: %s]" % [
		ScreenType.keys()[current_type],
		screen_stack.size(),
		str(is_transitioning)
	]

func print_debug_info() -> void:
	print("=== ScreenNavigation Debug ===")
	print("Current Screen: %s" % ScreenType.keys()[_get_current_screen_type()])
	print("Previous Screen: %s" % ScreenType.keys()[get_previous_screen_type()])
	print("Screen Stack: %s" % str(screen_stack.map(func(t): return ScreenType.keys()[t])))
	print("Is Transitioning: %s" % str(is_transitioning))
	print("Transition Duration: %.2f" % transition_duration)
	print("Default Transition: %s" % TransitionType.keys()[default_transition])
	print("Loaded Screens: %s" % str(screen_instances.keys().map(func(t): return ScreenType.keys()[t])))
	print("Transition History: %d entries" % transition_history.size())
	
	# Son 5 transition'ı göster
	print("Recent Transitions:")
	for i in range(min(5, transition_history.size())):
		var entry = transition_history[-(i + 1)]
		print("  %d. %s → %s" % [
			i + 1,
			ScreenType.keys()[entry.from],
			ScreenType.keys()[entry.to]
		])