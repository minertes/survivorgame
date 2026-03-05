# 🎮 MENU SCENE
# Tüm bileşenleri birleştiren ana sahne
class_name MenuScene
extends Node2D

# === SIGNALS ===
signal scene_initialized()
signal scene_transition_started(target_scene: String)
signal scene_transition_completed()
signal game_data_loaded(success: bool)

# === CONSTANTS ===
const VP := Vector2(720.0, 1280.0)

# === NODE REFERENCES ===
@onready var space_background = $SpaceBackgroundAtom
@onready var warrior_card = $WarriorCardAtom
@onready var button_effects = $ButtonEffectsAtom
@onready var menu_stats = $MenuStatsDisplayAtom
@onready var menu_ui = $MenuUIMolecule
@onready var entrance_animator = $EntranceAnimationController
@onready var sound_integration = $SoundManagerIntegration

# === STATE ===
var is_initialized: bool = false
var components_initialized: Dictionary = {}
var game_data_available: bool = false
var is_transitioning: bool = false

# === LIFECYCLE ===

func _ready() -> void:
	print("MenuScene: _ready() called")
	# Bileşenleri bekleyebilmek için bir frame bekle
	call_deferred("_initialize_scene")

func _initialize_scene() -> void:
	# Bileşen referanslarını kontrol et
	_check_components()
	
	# GameData'yi yükle
	_load_game_data()
	
	# Bileşenleri başlat
	_initialize_components()
	
	# Sinyalleri bağla
	_connect_signals()
	
	# Giriş animasyonunu başlat
	_start_entrance_animation()
	
	is_initialized = true
	scene_initialized.emit()

# === PUBLIC API ===

func reload_scene() -> void:
	# Tüm bileşenleri yeniden başlat
	_load_game_data()
	_initialize_components()
	
	# Animasyonları sıfırla
	if entrance_animator:
		entrance_animator.reset_animations()
	
	print("MenuScene reloaded")

func transition_to_scene(scene_path: String) -> void:
	if is_transitioning:
		print("Already transitioning, skipping...")
		return
	
	is_transitioning = true
	scene_transition_started.emit(scene_path)
	
	print("Transitioning to scene: %s" % scene_path)
	
	# Kısa bir bekleme (animasyon yerine)
	print("Waiting 0.1 seconds before scene change...")
	await get_tree().create_timer(0.1).timeout
	
	# Scene geçişi
	print("Changing scene to: %s" % scene_path)
	var result = get_tree().change_scene_to_file(scene_path)
	print("Scene change result: %s" % str(result))
	
	is_transitioning = false
	scene_transition_completed.emit()

func update_game_data() -> void:
	_load_game_data()
	
	# Bileşenleri güncelle
	if warrior_card and game_data_available:
		var game_data = get_node("/root/GameData")
		var character_data = game_data.CHARACTERS.get(game_data.selected_character, {})
		var weapon_data = game_data.WEAPONS.get(game_data.equipped_weapon, {})
		warrior_card.initialize(character_data, weapon_data)
	
	if menu_stats:
		menu_stats._load_stats_from_gamedata()
	
	if menu_ui:
		menu_ui.update_sound_button()

func get_component_status() -> Dictionary:
	return {
		"space_background": space_background != null,
		"warrior_card": warrior_card != null,
		"button_effects": button_effects != null,
		"menu_stats": menu_stats != null,
		"menu_ui": menu_ui != null,
		"entrance_animator": entrance_animator != null,
		"sound_integration": sound_integration != null,
		"game_data_available": game_data_available
	}

func play_button_effect(button_name: String) -> void:
	if button_effects:
		button_effects.trigger_glow_pulse()
		
		if sound_integration:
			sound_integration.play_button_sound()

func show_debug_info() -> void:
	print("=== MenuScene Debug Info ===")
	print("Initialized: %s" % str(is_initialized))
	print("Transitioning: %s" % str(is_transitioning))
	print("Game Data Available: %s" % str(game_data_available))
	
	print("\nComponent Status:")
	var status = get_component_status()
	for component in status:
		print("  %s: %s" % [component, str(status[component])])
	
	print("\nComponents Initialized:")
	for component in components_initialized:
		print("  %s: %s" % [component, str(components_initialized[component])])

# === PRIVATE METHODS ===

func _check_components() -> void:
	# Tüm bileşenlerin yüklü olup olmadığını kontrol et
	components_initialized = {
		"space_background": space_background != null,
		"warrior_card": warrior_card != null,
		"button_effects": button_effects != null,
		"menu_stats": menu_stats != null,
		"menu_ui": menu_ui != null,
		"entrance_animator": entrance_animator != null,
		"sound_integration": sound_integration != null
	}

func _load_game_data() -> void:
	# GameData'nin mevcut olup olmadığını kontrol et
	if has_node("/root/GameData"):
		game_data_available = true
		GameData.on_login_tick()
		if has_node("/root/AchievementsService"):
			AchievementsService.check_all()
		game_data_loaded.emit(true)
	else:
		game_data_available = false
		game_data_loaded.emit(false)
		push_warning("GameData not found in root")

func _initialize_components() -> void:
	# SpaceBackgroundAtom
	if space_background:
		space_background.initialize()
	
	# WarriorCardAtom
	if warrior_card and game_data_available:
		var game_data = get_node("/root/GameData")
		var character_data = game_data.CHARACTERS.get(game_data.selected_character, {})
		var weapon_data = game_data.WEAPONS.get(game_data.equipped_weapon, {})
		warrior_card.initialize(character_data, weapon_data)
	
	# ButtonEffectsAtom
	if button_effects and menu_ui:
		var start_button_pos = menu_ui.get_button_position("start")
		var start_button_size = menu_ui.get_button_size("start")
		button_effects.set_button_position(start_button_pos + start_button_size / 2)
		button_effects.set_button_size(start_button_size)
		button_effects.activate()
	
	# MenuStatsDisplayAtom
	if menu_stats and game_data_available:
		menu_stats._load_stats_from_gamedata()
	
	# MenuUIMolecule
	if menu_ui:
		menu_ui.initialize_components()
		menu_ui.update_sound_button()
	
	# SoundManagerIntegration
	if sound_integration:
		sound_integration.initialize()

func _connect_signals() -> void:
	# Faz 5.2 – Başarı açıldığında kısa bildirim
	if has_node("/root/AchievementsService"):
		AchievementsService.achievement_unlocked.connect(_on_achievement_unlocked)
	
	# MenuUIMolecule sinyalleri
	if menu_ui:
		menu_ui.start_button_pressed.connect(_on_start_button_pressed)
		menu_ui.sound_settings_pressed.connect(_on_sound_button_pressed)
		menu_ui.shop_button_pressed.connect(_on_shop_button_pressed)
		menu_ui.leaderboard_button_pressed.connect(_on_leaderboard_button_pressed)
		menu_ui.quit_button_pressed.connect(_on_quit_button_pressed)
		menu_ui.sync_cloud_button_pressed.connect(_on_sync_cloud_button_pressed)
	
	# EntranceAnimationController sinyalleri
	if entrance_animator:
		entrance_animator.animation_completed.connect(_on_entrance_animation_completed)
	
	# WarriorCardAtom sinyalleri
	if warrior_card:
		warrior_card.card_clicked.connect(_on_warrior_card_clicked)
	
	# MenuStatsDisplayAtom sinyalleri
	if menu_stats:
		menu_stats.stat_clicked.connect(_on_stat_clicked)

func _start_entrance_animation() -> void:
	if entrance_animator:
		entrance_animator.play_entrance_animation()
	else:
		# Fallback: basit fade-in
		modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.5)

# === EVENT HANDLERS ===

func _on_start_button_pressed() -> void:
	print("MenuScene: Start game requested")
	play_button_effect("start")
	transition_to_scene("res://lobby.tscn")

func _on_shop_button_pressed() -> void:
	print("MenuScene: Shop requested")
	play_button_effect("shop")
	transition_to_scene("res://shop.tscn")

func _on_leaderboard_button_pressed() -> void:
	print("MenuScene: Leaderboard requested")
	play_button_effect("leaderboard")
	transition_to_scene("res://social_ops.tscn")

func _on_sound_button_pressed() -> void:
	print("MenuScene: Sound settings requested")
	play_button_effect("sound")
	
	# Ses durumunu değiştir
	if game_data_available:
		print("GameData available, toggling sound...")
		var game_data = get_node("/root/GameData")
		print("Current sound state: %s" % str(game_data.sound_enabled))
		game_data.sound_enabled = not game_data.sound_enabled
		print("New sound state: %s" % str(game_data.sound_enabled))
		game_data.save_data()
		
		# UI'ı güncelle
		if menu_ui:
			print("Updating UI sound button...")
			menu_ui.update_sound_button()
		else:
			print("MenuUI not available")
		
		# Ses sistemini güncelle
		if sound_integration:
			print("Updating sound integration...")
			sound_integration.update_sound_state()
		else:
			print("Sound integration not available")
	else:
		print("GameData not available")
	
	# GameState'i de güncelle (eski sistemle uyumluluk için)
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		print("Updating GameState sound: %s" % str(not game_state.sound_enabled))
		game_state.sound_enabled = not game_state.sound_enabled
	else:
		print("GameState not available")

func _on_quit_button_pressed() -> void:
	print("MenuScene: Quit requested")
	if button_effects:
		button_effects.trigger_glow_pulse()
	if sound_integration and sound_integration.has_method("play_button_sound"):
		sound_integration.play_button_sound()
	# call_deferred ile çık; bazen doğrudan quit() editor/pencerede işlenmiyor
	get_tree().call_deferred("quit")


func _on_sync_cloud_button_pressed() -> void:
	var menu = get_parent()
	if menu and menu.has_method("sync_cloud_save"):
		menu.sync_cloud_save()

func _on_entrance_animation_completed(animation_name: String) -> void:
	print("MenuScene: Entrance animation completed: %s" % animation_name)

func _on_warrior_card_clicked() -> void:
	print("MenuScene: Warrior card clicked")
	# Karakter seçim ekranına geçiş yapılabilir
	# transition_to_scene("res://character_select.tscn")

func _on_stat_clicked(stat_name: String) -> void:
	print("MenuScene: Stat clicked: %s" % stat_name)
	# İstatistik detay ekranı gösterilebilir

func _on_achievement_unlocked(achievement_id: String, data: Dictionary) -> void:
	var name_str: String = data.get("name", achievement_id)
	var icon: String = data.get("icon", "🏅")
	play_button_effect("achievement")
	# Kısa bildirim: üstte label
	var lbl := Label.new()
	lbl.text = "%s Başarı: %s" % [icon, name_str]
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	lbl.position = Vector2(VP.x / 2.0 - 150, 120)
	lbl.z_index = 100
	add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(lbl.queue_free)

# === INPUT HANDLING ===

func _input(event: InputEvent) -> void:
	# Debug için: F5 ile yenile
	if event.is_action_pressed("ui_accept"):
		reload_scene()
	
	# Debug için: F1 ile bilgi göster
	if event.is_action_pressed("ui_cancel"):
		show_debug_info()

# === CLEANUP ===

func _exit_tree() -> void:
	# Animasyonları durdur
	if entrance_animator:
		entrance_animator.stop_all_animations()
	
	# Efektleri durdur
	if button_effects:
		button_effects.deactivate()

# === DEBUG ===

func _to_string() -> String:
	return "[MenuScene: Initialized: %s, Components: %d/%d]" % [
		str(is_initialized),
		components_initialized.values().count(true),
		components_initialized.size()
	]