# 🎮 MODERN MENU SYSTEM
# Yeni atomic tasarım sistemine geçiş için wrapper
extends Node2D

# === SIGNALS ===
signal menu_loaded()
signal transition_started()

# === NODE REFERENCES ===
@onready var menu_scene = null  # Başlangıçta null olacak

# === STATE ===
var is_initialized: bool = false

# === LIFECYCLE ===

func _ready() -> void:
	Log.info("Menu: _ready started")
	# Bulut: açılışta pull + apply (son yazma kazanır)
	if has_node("/root/BackendService"):
		var backend = get_node("/root/BackendService")
		if backend.has_signal("cloud_save_pulled"):
			backend.cloud_save_pulled.connect(_on_cloud_save_pulled)
		call_deferred("_pull_cloud_save_on_start")
	# Splash ekranı (Faz 1.2.4) — kısa logo gösterimi
	_show_splash()
	# MenuScene'i yükle
	_load_menu_scene()
	
	# Sinyalleri bağla
	_connect_signals()
	
	# Arka plan müziği (Faz 1.1.2)
	var audio := get_node_or_null("/root/AudioSystem")
	if audio and audio.has_method("play_music"):
		audio.play_music("background_music", 0.4, true)
	
	is_initialized = true
	menu_loaded.emit()
	
	Log.info("Menu: loaded successfully")


func _pull_cloud_save_on_start() -> void:
	if has_node("/root/BackendService") and BackendService.has_method("pull_cloud_save"):
		BackendService.pull_cloud_save()


func _on_cloud_save_pulled(success: bool, data: Dictionary, _error: String) -> void:
	if success and data.size() > 0 and has_node("/root/GameData"):
		GameData.apply_cloud_data(data)
		Log.info("Menu: cloud save applied on pull")
		if menu_scene and menu_scene.has_method("update_game_data"):
			menu_scene.update_game_data()

# === PUBLIC API ===

func reload_menu() -> void:
	if menu_scene:
		menu_scene.reload_scene()

func transition_to_lobby() -> void:
	Log.info("Menu: transition_to_lobby called")
	# Müziği kademeli durdur (Faz 1.1.2)
	var audio_node := get_node_or_null("/root/AudioSystem")
	if audio_node and audio_node.has_method("stop_music"):
		audio_node.stop_music(0.25)
	if menu_scene:
		menu_scene.transition_to_scene("res://lobby.tscn")
	else:
		Log.warn("Menu: MenuScene null, fallback change_scene to lobby")
		get_tree().change_scene_to_file("res://lobby.tscn")

func update_game_data() -> void:
	if menu_scene:
		menu_scene.update_game_data()


func sync_cloud_save() -> void:
	if has_node("/root/BackendService") and BackendService.has_method("pull_cloud_save"):
		BackendService.pull_cloud_save()

func show_debug_info() -> void:
	if menu_scene:
		menu_scene.show_debug_info()
	else:
		Log.warn("Menu: MenuScene not available")

# === PRIVATE METHODS ===

func _show_splash() -> void:
	var vs := get_viewport().get_visible_rect().size
	var layer := CanvasLayer.new()
	layer.name = "SplashLayer"
	layer.layer = 100
	add_child(layer)
	# CanvasLayer has no modulate; use a Control container that has it
	var container := Control.new()
	container.name = "SplashContainer"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 0
	container.offset_top = 0
	container.offset_right = vs.x
	container.offset_bottom = vs.y
	layer.add_child(container)
	var rect := ColorRect.new()
	rect.name = "SplashBg"
	rect.color = Color(0.06, 0.05, 0.12, 1.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.offset_left = 0
	rect.offset_top = 0
	rect.offset_right = vs.x
	rect.offset_bottom = vs.y
	container.add_child(rect)
	var lbl := Label.new()
	lbl.name = "SplashTitle"
	lbl.text = "SURVIVOR"
	lbl.add_theme_font_size_override("font_size", 64)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -120
	lbl.offset_top = -40
	lbl.offset_right = 120
	lbl.offset_bottom = 40
	container.add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(container, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_callback(layer.queue_free)

func _load_menu_scene() -> void:
	# MenuScene'i yükle (Faz 0.3 – Menü → Lobi akışı)
	Log.info("Menu: loading MenuScene")
	var scene = preload("res://menu_scene.tscn")
	var instance = scene.instantiate()
	instance.name = "MenuScene"
	add_child(instance)
	
	menu_scene = instance
	Log.info("Menu: MenuScene loaded and added to scene tree")

func _connect_signals() -> void:
	if not menu_scene:
		return
	
	# MenuScene sinyallerini dinle
	menu_scene.scene_transition_started.connect(_on_scene_transition_started)
	menu_scene.scene_transition_completed.connect(_on_scene_transition_completed)
	menu_scene.game_data_loaded.connect(_on_game_data_loaded)

# === EVENT HANDLERS ===

func _on_scene_transition_started(target_scene: String) -> void:
	Log.info("Menu: transition started", {"target": target_scene})
	transition_started.emit()

func _on_scene_transition_completed() -> void:
	Log.info("Menu: transition completed")

func _on_game_data_loaded(success: bool) -> void:
	if success:
		Log.info("Menu: GameData loaded successfully")
	else:
		Log.warn("Menu: GameData not available")

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	# Debug için: F5 ile yenile
	if event.is_action_pressed("ui_accept"):
		reload_menu()
	
	# Debug için: F1 ile bilgi göster
	if event.is_action_pressed("ui_cancel"):
		show_debug_info()

# === DEBUG ===

func _to_string() -> String:
	return "[ModernMenu: Initialized: %s, MenuScene: %s]" % [
		str(is_initialized),
		"Loaded" if menu_scene else "Not Loaded"
	]
