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
	# MenuScene'i yükle
	_load_menu_scene()
	
	# Sinyalleri bağla
	_connect_signals()
	
	is_initialized = true
	menu_loaded.emit()
	
	print("Modern menu system loaded successfully")

# === PUBLIC API ===

func reload_menu() -> void:
	if menu_scene:
		menu_scene.reload_scene()

func transition_to_lobby() -> void:
	if menu_scene:
		menu_scene.transition_to_scene("res://lobby.tscn")
	else:
		# Fallback: eski sistem
		get_tree().change_scene_to_file("res://lobby.tscn")

func update_game_data() -> void:
	if menu_scene:
		menu_scene.update_game_data()

func show_debug_info() -> void:
	if menu_scene:
		menu_scene.show_debug_info()
	else:
		print("MenuScene not available")

# === PRIVATE METHODS ===

func _load_menu_scene() -> void:
	# MenuScene'i yükle
	print("Loading MenuScene...")
	var scene = preload("res://menu_scene.tscn")
	var instance = scene.instantiate()
	instance.name = "MenuScene"
	add_child(instance)
	
	menu_scene = instance
	print("MenuScene loaded and added to scene tree")

func _connect_signals() -> void:
	if not menu_scene:
		return
	
	# MenuScene sinyallerini dinle
	menu_scene.scene_transition_started.connect(_on_scene_transition_started)
	menu_scene.scene_transition_completed.connect(_on_scene_transition_completed)
	menu_scene.game_data_loaded.connect(_on_game_data_loaded)

# === EVENT HANDLERS ===

func _on_scene_transition_started(target_scene: String) -> void:
	print("Transition started to: %s" % target_scene)
	transition_started.emit()

func _on_scene_transition_completed() -> void:
	print("Transition completed")

func _on_game_data_loaded(success: bool) -> void:
	if success:
		print("GameData loaded successfully")
	else:
		print("GameData not available")

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
