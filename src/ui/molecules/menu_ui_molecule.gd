# 🎮 MENU UI MOLECULE
# Tüm UI atomic bileşenlerini birleştiren ana molekül
class_name MenuUIMolecule
extends Control

# === SIGNALS ===
signal molecule_initialized()
signal start_button_pressed()
signal sound_settings_pressed()
signal shop_button_pressed()
signal leaderboard_button_pressed()
signal quit_button_pressed()
signal sync_cloud_button_pressed()
signal version_info_clicked()
signal component_loaded(component_name: String, success: bool)

# === CONSTANTS === (tasarım viewport — project.godot ile aynı)
const VP := Vector2(720.0, 1280.0)
# Karakter kartı: (190, 242), boyut 340×430 → alt sınır y=672
const CARD_BOTTOM_Y := 672
const BTN_COLUMN_TOP := 690  # Kartın altına 18px boşluk
const BTN_START_W := 340
const BTN_START_H := 64
const BTN_SECONDARY_W := 240
const BTN_SECONDARY_H := 44
const BTN_GAP := 14

# === EXPORT VARIABLES ===
@export var show_start_button: bool = true
@export var show_sound_button: bool = true
@export var show_shop_button: bool = true
@export var show_leaderboard_button: bool = true
@export var show_quit_button: bool = true
@export var show_version_info: bool = true
@export var button_spacing: float = 64.0

# === NODE REFERENCES ===
var start_button: Button = null  # Kodla oluşturulacak
var sound_button: Button = null  # Kodla oluşturulacak
var shop_button: Button = null   # Kodla oluşturulacak (Faz 4)
var leaderboard_button: Button = null  # Faz 5
var quit_button: Button = null   # Kodla oluşturulacak
var sync_cloud_button: Button = null  # Bulut senkronize et
var version_label: Label = null  # Kodla oluşturulacak

# === STATE ===
var is_initialized: bool = false
var components_loaded: Dictionary = {}
var button_states: Dictionary = {
	"start": {"enabled": true, "visible": true},
	"sound": {"enabled": true, "visible": true},
	"shop": {"enabled": true, "visible": true},
	"leaderboard": {"enabled": true, "visible": true},
	"quit": {"enabled": true, "visible": true}
}

# === LIFECYCLE ===

func _ready() -> void:
	print("MenuUIMolecule: _ready() called")
	_setup_ui()
	_connect_signals()
	_load_game_data()
	is_initialized = true
	molecule_initialized.emit()
	print("MenuUIMolecule: Initialization completed")

# === PUBLIC API ===

func initialize_components() -> void:
	components_loaded = {
		"start_button": start_button != null,
		"sound_button": sound_button != null,
		"shop_button": shop_button != null,
		"leaderboard_button": leaderboard_button != null,
		"quit_button": quit_button != null,
		"version_label": version_label != null
	}
	
	for component in components_loaded:
		component_loaded.emit(component, components_loaded[component])

func set_button_state(button_name: String, enabled: bool, visible: bool = true) -> void:
	if not button_name in button_states:
		push_warning("Unknown button: %s" % button_name)
		return
	
	button_states[button_name] = {"enabled": enabled, "visible": visible}
	_update_button_states()

func set_start_button_text(text: String) -> void:
	if start_button:
		start_button.text = text

func set_sound_button_text(text: String) -> void:
	if sound_button:
		sound_button.text = text

func set_version_text(text: String) -> void:
	if version_label:
		version_label.text = text

func update_sound_button() -> void:
	if not sound_button:
		print("MenuUIMolecule: Sound button not available")
		return
	
	var sound_enabled = true
	if has_node("/root/GameData"):
		var game_data = get_node("/root/GameData")
		sound_enabled = game_data.sound_enabled
		print("MenuUIMolecule: Sound enabled from GameData: %s" % str(sound_enabled))
	else:
		print("MenuUIMolecule: GameData not found, using default")
	
	sound_button.text = "🔊 Ses: Açık" if sound_enabled else "🔇 Ses: Kapalı"
	print("MenuUIMolecule: Sound button text updated")

func fade_in_buttons(duration: float = 0.5) -> void:
	if start_button:
		start_button.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(start_button, "modulate:a", 1.0, duration)
	
	if sound_button:
		sound_button.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_interval(duration * 0.3)
		tween.tween_property(sound_button, "modulate:a", 1.0, duration)

func fade_out_buttons(duration: float = 0.3) -> void:
	if start_button:
		var tween = create_tween()
		tween.tween_property(start_button, "modulate:a", 0.0, duration)
	
	if sound_button:
		var tween = create_tween()
		tween.tween_property(sound_button, "modulate:a", 0.0, duration)

func get_button_position(button_name: String) -> Vector2:
	var btn: Button = null
	match button_name:
		"start": btn = start_button
		"sound": btn = sound_button
		"shop": btn = shop_button
		"leaderboard": btn = leaderboard_button
		"quit": btn = quit_button
	if btn and is_instance_valid(btn):
		return btn.global_position
	return Vector2.ZERO

func get_button_size(button_name: String) -> Vector2:
	var btn: Button = null
	match button_name:
		"start": btn = start_button
		"sound": btn = sound_button
		"shop": btn = shop_button
		"leaderboard": btn = leaderboard_button
		"quit": btn = quit_button
	if btn and is_instance_valid(btn):
		return btn.size
	return Vector2.ZERO

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	# Tasarım boyutu sabit (720x1280) — stretch mode ile ölçeklenir, sayfa dışına taşmaz
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = VP.x
	offset_bottom = VP.y

	# Butonlar karakter kartının hemen altında, ortalanmış
	var btn_container := Control.new()
	btn_container.name = "ButtonContainer"
	btn_container.position = Vector2((VP.x - BTN_START_W) / 2.0, BTN_COLUMN_TOP)
	btn_container.size = Vector2(BTN_START_W, VP.y - BTN_COLUMN_TOP - 80)
	add_child(btn_container)

	var vbox := VBoxContainer.new()
	vbox.name = "ButtonColumn"
	vbox.add_theme_constant_override("separation", BTN_GAP)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.position = Vector2.ZERO
	vbox.size = btn_container.size
	btn_container.add_child(vbox)

	if show_start_button:
		start_button = _make_start_button()
		start_button.custom_minimum_size = Vector2(BTN_START_W, BTN_START_H)
		start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(start_button)

	if show_shop_button:
		shop_button = _make_shop_button()
		shop_button.custom_minimum_size = Vector2(BTN_SECONDARY_W, BTN_SECONDARY_H)
		shop_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(shop_button)

	if show_leaderboard_button:
		leaderboard_button = _make_leaderboard_button()
		leaderboard_button.custom_minimum_size = Vector2(BTN_SECONDARY_W, BTN_SECONDARY_H)
		leaderboard_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(leaderboard_button)

	if show_sound_button:
		sound_button = _make_sound_button()
		sound_button.custom_minimum_size = Vector2(BTN_SECONDARY_W, BTN_SECONDARY_H)
		sound_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(sound_button)

	if show_quit_button:
		quit_button = _make_quit_button()
		quit_button.custom_minimum_size = Vector2(BTN_SECONDARY_W, BTN_SECONDARY_H)
		quit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(quit_button)

	# Bulut — sağ üst, tasarım koordinatları
	sync_cloud_button = Button.new()
	sync_cloud_button.name = "SyncCloudButton"
	sync_cloud_button.text = "☁ Senkronize"
	sync_cloud_button.custom_minimum_size = Vector2(140, 40)
	sync_cloud_button.position = Vector2(VP.x - 152, 12)
	sync_cloud_button.add_theme_font_size_override("font_size", 14)
	sync_cloud_button.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	var sty_sync := StyleBoxFlat.new()
	sty_sync.bg_color = Color(0.1, 0.14, 0.28)
	sty_sync.set_corner_radius_all(6)
	sty_sync.border_color = Color(0.35, 0.5, 0.9, 0.5)
	sty_sync.set_border_width_all(1)
	sync_cloud_button.add_theme_stylebox_override("normal", sty_sync)
	add_child(sync_cloud_button)

	if show_version_info:
		version_label = Label.new()
		version_label.name = "VersionLabel"
		version_label.text = "v0.1 Beta"
		version_label.add_theme_font_size_override("font_size", 11)
		version_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.45))
		version_label.position = Vector2(12, VP.y - 22)
		add_child(version_label)

func _make_start_button() -> Button:
	var b := Button.new()
	b.name = "StartButton"
	b.text = "▶ OYUNA BAŞLA"
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_color_override("font_color", Color(0.98, 1.0, 0.98))
	var sty_s := StyleBoxFlat.new()
	sty_s.bg_color = Color(0.12, 0.42, 0.14)
	sty_s.set_corner_radius_all(12)
	sty_s.border_color = Color(0.28, 0.75, 0.32, 0.9)
	sty_s.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sty_s)
	var sty_sh := StyleBoxFlat.new()
	sty_sh.bg_color = Color(0.18, 0.55, 0.22)
	sty_sh.set_corner_radius_all(12)
	sty_sh.border_color = Color(0.4, 0.9, 0.45, 1.0)
	sty_sh.set_border_width_all(2)
	b.add_theme_stylebox_override("hover", sty_sh)
	var sty_sp := StyleBoxFlat.new()
	sty_sp.bg_color = Color(0.08, 0.28, 0.1)
	sty_sp.set_corner_radius_all(12)
	b.add_theme_stylebox_override("pressed", sty_sp)
	return b

func _make_shop_button() -> Button:
	var b := Button.new()
	b.name = "ShopButton"
	b.text = "💎 Mağaza"
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.98, 0.88, 0.55))
	var sty_shop := StyleBoxFlat.new()
	sty_shop.bg_color = Color(0.2, 0.16, 0.1)
	sty_shop.set_corner_radius_all(8)
	sty_shop.border_color = Color(0.6, 0.48, 0.22, 0.8)
	sty_shop.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sty_shop)
	var sty_shoph := StyleBoxFlat.new()
	sty_shoph.bg_color = Color(0.3, 0.24, 0.14)
	sty_shoph.set_corner_radius_all(8)
	b.add_theme_stylebox_override("hover", sty_shoph)
	return b

func _make_leaderboard_button() -> Button:
	var b := Button.new()
	b.name = "LeaderboardButton"
	b.text = "🏆 Liderlik & Başarılar"
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
	var sty_lb := StyleBoxFlat.new()
	sty_lb.bg_color = Color(0.18, 0.14, 0.1)
	sty_lb.set_corner_radius_all(8)
	sty_lb.border_color = Color(0.55, 0.42, 0.2, 0.7)
	sty_lb.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sty_lb)
	var sty_lbh := StyleBoxFlat.new()
	sty_lbh.bg_color = Color(0.28, 0.22, 0.14)
	sty_lbh.set_corner_radius_all(8)
	b.add_theme_stylebox_override("hover", sty_lbh)
	return b

func _make_sound_button() -> Button:
	var b := Button.new()
	b.name = "SoundButton"
	b.text = "🔊 Ses: Açık"
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	var sty_snd := StyleBoxFlat.new()
	sty_snd.bg_color = Color(0.08, 0.1, 0.22)
	sty_snd.set_corner_radius_all(8)
	sty_snd.border_color = Color(0.25, 0.38, 0.7, 0.6)
	sty_snd.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sty_snd)
	var sty_sndh := StyleBoxFlat.new()
	sty_sndh.bg_color = Color(0.14, 0.18, 0.38)
	sty_sndh.set_corner_radius_all(8)
	b.add_theme_stylebox_override("hover", sty_sndh)
	return b

func _make_quit_button() -> Button:
	var b := Button.new()
	b.name = "QuitButton"
	b.text = "🚪 Çıkış"
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))
	var sty_q := StyleBoxFlat.new()
	sty_q.bg_color = Color(0.28, 0.1, 0.1)
	sty_q.set_corner_radius_all(8)
	sty_q.border_color = Color(0.65, 0.25, 0.25, 0.75)
	sty_q.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sty_q)
	var sty_qh := StyleBoxFlat.new()
	sty_qh.bg_color = Color(0.42, 0.16, 0.16)
	sty_qh.set_corner_radius_all(8)
	b.add_theme_stylebox_override("hover", sty_qh)
	return b

func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	
	if sound_button:
		sound_button.pressed.connect(_on_sound_button_pressed)
	
	if shop_button:
		shop_button.pressed.connect(_on_shop_button_pressed)
	
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	if sync_cloud_button:
		sync_cloud_button.pressed.connect(_on_sync_cloud_button_pressed)
	
	if version_label:
		version_label.gui_input.connect(_on_version_label_gui_input)

func _load_game_data() -> void:
	# Ses durumunu güncelle
	update_sound_button()

func _update_button_states() -> void:
	if start_button:
		start_button.visible = show_start_button and button_states.start.visible
		start_button.disabled = not button_states.start.enabled
	
	if sound_button:
		sound_button.visible = show_sound_button and button_states.sound.visible
		sound_button.disabled = not button_states.sound.enabled
	
	if shop_button:
		shop_button.visible = show_shop_button and button_states.shop.visible
		shop_button.disabled = not button_states.shop.enabled
	
	if leaderboard_button:
		leaderboard_button.visible = show_leaderboard_button and button_states.leaderboard.visible
		leaderboard_button.disabled = not button_states.leaderboard.enabled
	
	if quit_button:
		quit_button.visible = show_quit_button and button_states.quit.visible
		quit_button.disabled = not button_states.quit.enabled

# === EVENT HANDLERS ===

func _on_start_button_pressed() -> void:
	print("MenuUIMolecule: Start button pressed")
	start_button_pressed.emit()

func _on_sound_button_pressed() -> void:
	print("MenuUIMolecule: Sound button pressed")
	sound_settings_pressed.emit()

func _on_shop_button_pressed() -> void:
	print("MenuUIMolecule: Shop button pressed")
	shop_button_pressed.emit()

func _on_leaderboard_button_pressed() -> void:
	print("MenuUIMolecule: Leaderboard button pressed")
	leaderboard_button_pressed.emit()

func _on_quit_button_pressed() -> void:
	print("MenuUIMolecule: Quit button pressed")
	quit_button_pressed.emit()
	# Önce pencere kapatma bildirimi, sonra çıkış (Godot dokümantasyonu)


func _on_sync_cloud_button_pressed() -> void:
	print("MenuUIMolecule: Sync cloud button pressed")
	sync_cloud_button_pressed.emit()

func _on_version_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			version_info_clicked.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== MenuUIMolecule ===")
	print("Initialized: %s" % str(is_initialized))
	print("Show Start Button: %s" % str(show_start_button))
	print("Show Sound Button: %s" % str(show_sound_button))
	print("Show Version Info: %s" % str(show_version_info))
	print("Button Spacing: %.1f" % button_spacing)
	print("Components Loaded:")
	for component in components_loaded:
		print("  %s: %s" % [component, str(components_loaded[component])])
	print("Button States:")
	for button_name in button_states:
		var state = button_states[button_name]
		print("  %s: enabled=%s, visible=%s" % [button_name, str(state.enabled), str(state.visible)])