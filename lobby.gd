# 🏢 LOBBY SCENE (ENTERPRISE EDITION)
# Sağlam, modüler ve hatasız lobi sahnesi
extends Node2D

# === CONSTANTS ===
const VIEWPORT_SIZE := Vector2(720.0, 1280.0)

# === COMPONENT REFERENCES ===
var lobby_molecule: Control = null
var background_layer: Control = null
var ui_layer: CanvasLayer = null
var audio_system: Node = null
var game_data: Node = null

# === STATE ===
var _time := 0.0
var _is_initialized := false
var _is_transitioning := false
var _esc_menu: Control = null  # ESC ile açılan 3'lü buton menüsü

# === LIFECYCLE ===

func _ready() -> void:
	print("🚀 Lobby Scene: Initializing...")
	
	# Sistem referanslarını al
	_get_system_references()
	
	# Katmanları oluştur
	_create_layers()
	
	# LobbyMolecule'ü yükle
	_load_lobby_molecule()
	
	# Oyun verilerini yükle
	_load_game_data()
	
	_is_initialized = true
	print("✅ Lobby Scene: Initialized successfully")

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_esc_menu()
		get_viewport().set_input_as_handled()

func _toggle_esc_menu() -> void:
	if _is_transitioning:
		return
	if _esc_menu and is_instance_valid(_esc_menu) and _esc_menu.visible:
		_close_esc_menu()
		return
	_show_esc_menu()

func _show_esc_menu() -> void:
	if _esc_menu and is_instance_valid(_esc_menu):
		_esc_menu.show()
		return
	var size_view := Vector2(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y)
	var root := Control.new()
	root.name = "EscMenu"
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2.ZERO
	root.size = size_view
	if ui_layer:
		ui_layer.add_child(root)
	else:
		add_child(root)
	_esc_menu = root

	var overlay := ColorRect.new()
	overlay.color = Color(0.06, 0.06, 0.12, 0.88)
	overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)
	overlay.position = Vector2.ZERO
	overlay.size = size_view
	root.add_child(overlay)

	var center := size_view / 2.0
	var title := Label.new()
	title.text = "MENÜ"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	title.position = center - Vector2(60, 140)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "ESC — Menüyü kapat"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.75))
	hint.position = center - Vector2(70, 100)
	root.add_child(hint)

	var btn_w := 300
	var btn_h := 52
	var gap := 14
	var by := center.y - 90.0

	var stay_btn := Button.new()
	stay_btn.text = "  ▶  Lobide Devam"
	stay_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	stay_btn.position = Vector2(center.x - btn_w / 2.0, by)
	stay_btn.add_theme_font_size_override("font_size", 20)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.18, 0.5, 0.22)
	rs.set_corner_radius_all(8)
	rs.set_border_width_all(1)
	rs.border_color = Color(0.35, 0.8, 0.4, 0.6)
	stay_btn.add_theme_stylebox_override("normal", rs)
	stay_btn.add_theme_stylebox_override("hover", _lobby_btn_hover(rs))
	stay_btn.pressed.connect(_close_esc_menu)
	root.add_child(stay_btn)

	var menu_btn := Button.new()
	menu_btn.text = "  📋  Ana Menü"
	menu_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	menu_btn.position = Vector2(center.x - btn_w / 2.0, by + (btn_h + gap))
	menu_btn.add_theme_font_size_override("font_size", 20)
	var ms := StyleBoxFlat.new()
	ms.bg_color = Color(0.25, 0.2, 0.2)
	ms.set_corner_radius_all(8)
	ms.set_border_width_all(1)
	ms.border_color = Color(0.55, 0.35, 0.35, 0.6)
	menu_btn.add_theme_stylebox_override("normal", ms)
	menu_btn.add_theme_stylebox_override("hover", _lobby_btn_hover(ms))
	menu_btn.pressed.connect(func() -> void:
		_close_esc_menu()
		_on_navigation_back())
	root.add_child(menu_btn)

	var quit_btn := Button.new()
	quit_btn.text = "  🚪  Oyundan Çık"
	quit_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	quit_btn.position = Vector2(center.x - btn_w / 2.0, by + 2 * (btn_h + gap))
	quit_btn.add_theme_font_size_override("font_size", 20)
	var qs := StyleBoxFlat.new()
	qs.bg_color = Color(0.35, 0.15, 0.15)
	qs.set_corner_radius_all(8)
	qs.set_border_width_all(1)
	qs.border_color = Color(0.7, 0.3, 0.3, 0.6)
	quit_btn.add_theme_stylebox_override("normal", qs)
	quit_btn.add_theme_stylebox_override("hover", _lobby_btn_hover(qs))
	quit_btn.pressed.connect(func() -> void:
		_close_esc_menu()
		get_tree().quit())
	root.add_child(quit_btn)

func _lobby_btn_hover(base: StyleBoxFlat) -> StyleBoxFlat:
	var h := base.duplicate() as StyleBoxFlat
	h.bg_color = Color(h.bg_color.r + 0.12, h.bg_color.g + 0.12, h.bg_color.b + 0.12)
	return h

func _close_esc_menu() -> void:
	if _esc_menu and is_instance_valid(_esc_menu):
		_esc_menu.hide()

# === SYSTEM INTEGRATION ===

func _get_system_references() -> void:
	# AudioSystem referansı
	if has_node("/root/AudioSystem"):
		audio_system = get_node("/root/AudioSystem")
		print("🔊 AudioSystem: Found")
	else:
		print("⚠️ AudioSystem: Not found")
	
	# GameData referansı
	if has_node("/root/GameData"):
		game_data = get_node("/root/GameData")
		print("💾 GameData: Found")
	else:
		print("⚠️ GameData: Not found")

# === LAYER MANAGEMENT ===

func _create_layers() -> void:
	# Arka plan katmanı
	background_layer = Control.new()
	background_layer.name = "BackgroundLayer"
	background_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_layer)
	print("🎨 Background layer created")
	
	# UI katmanı (CanvasLayer) — lobi UI burada
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 1
	add_child(ui_layer)
	# CanvasLayer içinde tam ekran arka plan (lobi görünsün diye)
	var vs := get_viewport().get_visible_rect().size
	var bg_rect := ColorRect.new()
	bg_rect.name = "LobbyBackground"
	bg_rect.color = Color(0.08, 0.06, 0.14, 1.0)
	bg_rect.position = Vector2.ZERO
	bg_rect.size = vs
	bg_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ui_layer.add_child(bg_rect)
	print("🖥️ UI layer created")

# === LOBBY MOLECULE LOADING ===

func _load_lobby_molecule() -> void:
	print("🔄 Loading LobbyMolecule...")
	
	# Scene dosyasını yükle
	var lobby_scene_path = "res://src/ui/molecules/lobby_molecule.tscn"
	
	if not ResourceLoader.exists(lobby_scene_path):
		print("❌ LobbyMolecule scene not found: %s" % lobby_scene_path)
		_create_minimal_lobby()
		return
	
	var lobby_scene = load(lobby_scene_path)
	if not lobby_scene:
		print("❌ Failed to load LobbyMolecule scene")
		_create_minimal_lobby()
		return
	
	# Scene instance oluştur
	lobby_molecule = lobby_scene.instantiate()
	lobby_molecule.name = "LobbyMolecule"
	
	# UI katmanına ekle (önce ekle ki _ready sonrası boyut geçerli olsun)
	ui_layer.add_child(lobby_molecule)
	
	# Boyut/offset _apply_lobby_molecule_size (deferred) içinde verilecek; anchor burada değiştirilir
	lobby_molecule.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lobby_molecule.visible = true
	
	# Signal'leri bağla
	_connect_lobby_signals()
	
	# _ready sonrası boyutun kalıcı olması için ertelenmiş atama
	call_deferred("_apply_lobby_molecule_size")
	
	print("✅ LobbyMolecule loaded successfully")

func _apply_lobby_molecule_size() -> void:
	if not is_instance_valid(lobby_molecule):
		return
	var vs := get_viewport().get_visible_rect().size
	lobby_molecule.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lobby_molecule.position = Vector2.ZERO
	lobby_molecule.size = vs
	lobby_molecule.custom_minimum_size = vs
	lobby_molecule.offset_left = 0
	lobby_molecule.offset_top = 0
	lobby_molecule.offset_right = vs.x
	lobby_molecule.offset_bottom = vs.y
	lobby_molecule.visible = true

func _connect_lobby_signals() -> void:
	if not lobby_molecule:
		return
	
	# Game start signal
	if lobby_molecule.has_signal("game_start_requested"):
		lobby_molecule.game_start_requested.connect(_on_game_start_requested)
	else:
		print("⚠️ LobbyMolecule: game_start_requested signal not found")
	
	# Navigation back signal
	if lobby_molecule.has_signal("navigation_back"):
		lobby_molecule.navigation_back.connect(_on_navigation_back)
	else:
		print("⚠️ LobbyMolecule: navigation_back signal not found")
	
	# Purchase made signal
	if lobby_molecule.has_signal("purchase_made"):
		lobby_molecule.purchase_made.connect(_on_purchase_made)
	else:
		print("⚠️ LobbyMolecule: purchase_made signal not found")
	
	# Yedek: OYUNA BAŞLA butonuna doğrudan bağlan (molekül sinyali atlarsa çalışsın)
	call_deferred("_connect_play_button_fallback")

func _connect_play_button_fallback() -> void:
	var play_btn = lobby_molecule.get_node_or_null("ContentManager/PlayButton") if lobby_molecule else null
	if play_btn and not play_btn.is_connected("pressed", _on_play_button_direct):
		play_btn.pressed.connect(_on_play_button_direct)
		print("🔗 Lobby: Play button direct fallback connected")

func _on_play_button_direct() -> void:
	# Seçimleri molekülden al veya varsayılan kullan
	var c := "male_soldier"
	var w := "machinegun"
	var f := "turkey"
	if lobby_molecule and lobby_molecule.has_method("get_player_data"):
		var pd = lobby_molecule.get_player_data()
		c = pd.get("selected_character", c)
		w = pd.get("selected_weapon", w)
		f = pd.get("selected_flag", f)
	_on_game_start_requested(c, w, f)

# === GAME DATA INTEGRATION ===

func _load_game_data() -> void:
	print("📊 Loading game data...")
	
	if not game_data:
		print("⚠️ GameData not available, using defaults")
		_set_default_game_data()
		return
	
	# XP 0 veya düşükse varsayılana çek ve kaydet; lobiye giderken en az varsayılan kullan
	var xp_val: int = maxi(int(game_data.xp_coins), game_data.DEFAULT_STARTING_XP)
	if game_data.xp_coins <= 0:
		game_data.xp_coins = xp_val
		game_data.save_data()
	# Sahip olunan listeler boşsa varsayılan ver (ilk açılışta SEÇ görünsün)
	var owned_chars: Array = game_data.owned_characters.duplicate()
	if owned_chars.is_empty():
		owned_chars = ["male_soldier"]
	var owned_weps: Dictionary = game_data.owned_weapons.duplicate()
	if owned_weps.is_empty():
		owned_weps = {"machinegun": 1}
	var owned_flgs: Array = game_data.owned_flags.duplicate()
	if owned_flgs.is_empty():
		owned_flgs = ["turkey"]
	# GameData'den oyuncu verilerini al
	var player_data = {
		"xp": xp_val,
		"owned_characters": owned_chars,
		"selected_character": game_data.selected_character,
		"owned_weapons": owned_weps,
		"selected_weapon": game_data.equipped_weapon,
		"owned_flags": owned_flgs,
		"selected_flag": game_data.equipped_flag,
		"stats": {
			"best_wave": game_data.best_wave,
			"total_kills": game_data.total_kills,
			"total_games": game_data.total_games,
			"total_xp_earned": game_data.total_xp_earned,
			"total_play_time": game_data.total_play_time,
			"accuracy": game_data.accuracy,
			"survival_rate": game_data.survival_rate
		}
	}
	
	# LobbyMolecule'e verileri yükle
	if lobby_molecule and lobby_molecule.has_method("set_player_data"):
		lobby_molecule.set_player_data(player_data)
		print("✅ Game data loaded into LobbyMolecule")
	else:
		print("⚠️ LobbyMolecule.set_player_data method not found")

func _set_default_game_data() -> void:
	# Varsayılan oyuncu verileri (GameData yoksa)
	var default_data = {
		"xp": 10000,
		"owned_characters": ["male_soldier"],
		"selected_character": "male_soldier",
		"owned_weapons": {"machinegun": 1},
		"selected_weapon": "machinegun",
		"owned_flags": ["turkey"],
		"selected_flag": "turkey",
		"stats": {
			"best_wave": 0,
			"total_kills": 0,
			"total_games": 0,
			"total_xp_earned": 0,
			"total_play_time": 0,
			"accuracy": 0.0,
			"survival_rate": 0.0
		}
	}
	
	if lobby_molecule and lobby_molecule.has_method("set_player_data"):
		lobby_molecule.set_player_data(default_data)
		print("✅ Default game data set")

# === MINIMAL LOBBY (FALLBACK) ===

func _create_minimal_lobby() -> void:
	print("🛠️ Creating minimal lobby (fallback)...")
	
	var minimal_lobby = Control.new()
	minimal_lobby.name = "MinimalLobby"
	minimal_lobby.size = VIEWPORT_SIZE
	
	# Başlık
	var title = Label.new()
	title.text = "🏢 LOBBİ"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(VIEWPORT_SIZE.x / 2 - 100, 100)
	minimal_lobby.add_child(title)
	
	# Oyun başlat butonu
	var play_btn = _create_button(
		"🎮 OYUNA BAŞLA",
		Vector2(VIEWPORT_SIZE.x / 2 - 200, 300),
		Vector2(400, 80),
		Color(0.12, 0.5, 0.12),
		Color(0.4, 0.9, 0.4),
		_on_minimal_play_pressed
	)
	minimal_lobby.add_child(play_btn)
	
	# Geri butonu
	var back_btn = _create_button(
		"◀ MENÜYE DÖN",
		Vector2(VIEWPORT_SIZE.x / 2 - 150, 400),
		Vector2(300, 60),
		Color(0.15, 0.1, 0.25),
		Color(0.3, 0.2, 0.5),
		_on_navigation_back
	)
	minimal_lobby.add_child(back_btn)
	
	# UI katmanına ekle
	ui_layer.add_child(minimal_lobby)
	lobby_molecule = minimal_lobby
	
	print("✅ Minimal lobby created")

func _create_button(text: String, position: Vector2, size: Vector2, 
				   bg_color: Color, border_color: Color, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.position = position
	button.custom_minimum_size = size
	button.add_theme_font_size_override("font_size", 24 if size.y > 70 else 20)
	button.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(10)
	style.border_color = border_color
	style.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(bg_color.r + 0.1, bg_color.g + 0.1, bg_color.b + 0.1)
	hover_style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("hover", hover_style)
	
	button.pressed.connect(callback)
	return button

# === BACKGROUND RENDERING ===

func _draw() -> void:
	# Sadece background_layer üzerine çiz
	if background_layer:
		_draw_background()

func _draw_background() -> void:
	# Koyu uzay arka planı
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.05, 0.04, 0.10))
	
	# Yıldızlar
	_draw_stars()
	
	# Nebula efektleri
	_draw_nebula()
	
	# Izgara deseni
	_draw_grid()

func _draw_stars() -> void:
	randomize()
	for i in 100:
		var x = randf() * VIEWPORT_SIZE.x
		var y = randf() * VIEWPORT_SIZE.y
		var size = randf_range(0.5, 2.0)
		var brightness = randf_range(0.3, 0.8)
		var pulse = sin(_time * 2.0 + i) * 0.3 + 0.7
		
		draw_circle(Vector2(x, y), size, Color(1.0, 1.0, 1.0, brightness * pulse))

func _draw_nebula() -> void:
	var nebula_colors = [
		Color(0.3, 0.1, 0.5, 0.05),
		Color(0.1, 0.2, 0.6, 0.04),
		Color(0.5, 0.1, 0.3, 0.03)
	]
	
	for i in 3:
		var center_x = VIEWPORT_SIZE.x * 0.5 + sin(_time * 0.3 + i) * 100
		var center_y = VIEWPORT_SIZE.y * 0.3 + cos(_time * 0.4 + i) * 80
		var radius = 150 + sin(_time * 0.5 + i) * 30
		
		draw_circle(Vector2(center_x, center_y), radius, nebula_colors[i])

func _draw_grid() -> void:
	var grid_color = Color(0.2, 0.3, 0.6, 0.05)
	var grid_size = 40
	
	for x in range(0, int(VIEWPORT_SIZE.x) + 1, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, VIEWPORT_SIZE.y), grid_color, 1.0)
	
	for y in range(0, int(VIEWPORT_SIZE.y) + 1, grid_size):
		draw_line(Vector2(0, y), Vector2(VIEWPORT_SIZE.x, y), grid_color, 1.0)

# === EVENT HANDLERS ===

func _on_game_start_requested(character_id: String, weapon_id: String, flag_id: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	print("🎮 Lobby: game_start_requested received, transitioning to game...")
	print("🎮 Game starting with:")
	print("   Character: %s" % character_id)
	print("   Weapon: %s" % weapon_id)
	print("   Flag: %s" % flag_id)
	
	# Oyun verilerini kaydet
	_save_game_data()
	
	# Ses efekti
	_play_ui_sound("click")
	
	# Geçiş efekti
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_transition_to_game)

func _on_navigation_back() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	print("🔙 Navigating back to menu")
	
	# Oyun verilerini kaydet
	_save_game_data()
	
	# Ses efekti
	_play_ui_sound("click")
	
	# Geçiş efekti
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_transition_to_menu)

func _on_purchase_made(item_type: String, item_id: String, cost: int) -> void:
	print("💰 Purchase made: %s - %s (%d XP)" % [item_type, item_id, cost])
	
	# Ses efekti
	_play_ui_sound("click")
	
	# Oyun verilerini kaydet
	_save_game_data()

func _on_minimal_play_pressed() -> void:
	# Minimal lobi için oyun başlatma
	_on_game_start_requested("male_soldier", "machinegun", "turkey")

# === TRANSITION METHODS ===

func _transition_to_game() -> void:
	print("🔄 Transitioning to game scene...")
	get_tree().change_scene_to_file("res://main.tscn")
	_is_transitioning = false

func _transition_to_menu() -> void:
	print("🔄 Transitioning to menu scene...")
	get_tree().change_scene_to_file("res://menu.tscn")
	_is_transitioning = false

# === UTILITY METHODS ===

func _play_ui_sound(sound_name: String) -> void:
	var played = false
	if audio_system and audio_system.has_method("play_ui_sound"):
		played = audio_system.play_ui_sound(sound_name)
	# Fallback: modüler sistem çalmadıysa doğrudan bir kez çal (test/feedback için)
	if not played:
		var path := "res://assets/audio/ui/%s.wav" % sound_name
		if not ResourceLoader.exists(path):
			path = "res://assets/audio/ui/click.wav"
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				var one_shot = AudioStreamPlayer.new()
				one_shot.stream = stream
				var bus_name := "UI"
				if AudioServer.get_bus_index(bus_name) < 0:
					bus_name = "Master"
				one_shot.bus = bus_name
				get_tree().root.add_child(one_shot)
				one_shot.finished.connect(one_shot.queue_free)
				one_shot.play()
				played = true
		if not played:
			print("🔇 UI sound '%s': could not play (AudioSystem or fallback failed)" % sound_name)

func _save_game_data() -> void:
	# Lobideki seçim ve satın almaları GameData'ya yaz (yoksa bir sonraki girişte kaybolur)
	if lobby_molecule and lobby_molecule.has_method("get_player_data") and game_data:
		var pd = lobby_molecule.get_player_data()
		game_data.xp_coins = pd.get("xp", game_data.xp_coins)
		game_data.owned_characters = pd.get("owned_characters", game_data.owned_characters)
		game_data.selected_character = pd.get("selected_character", game_data.selected_character)
		game_data.owned_weapons = pd.get("owned_weapons", game_data.owned_weapons)
		game_data.equipped_weapon = pd.get("selected_weapon", game_data.equipped_weapon)
		game_data.owned_flags = pd.get("owned_flags", game_data.owned_flags)
		game_data.equipped_flag = pd.get("selected_flag", game_data.equipped_flag)
	if game_data and game_data.has_method("save_data"):
		game_data.save_data()
		print("💾 Game data saved")
	else:
		print("⚠️ GameData.save_data method not available")

# === DEBUG ===

func print_debug_info() -> void:
	print("=== Lobby Scene Debug ===")
	print("Initialized: %s" % str(_is_initialized))
	print("Transitioning: %s" % str(_is_transitioning))
	print("Viewport Size: %s" % str(VIEWPORT_SIZE))
	print("Lobby Molecule: %s" % ("Loaded" if lobby_molecule else "Not Loaded"))
	print("Background Layer: %s" % ("Loaded" if background_layer else "Not Loaded"))
	print("UI Layer: %s" % ("Loaded" if ui_layer else "Not Loaded"))
	print("Audio System: %s" % ("Available" if audio_system else "Not Available"))
	print("Game Data: %s" % ("Available" if game_data else "Not Available"))