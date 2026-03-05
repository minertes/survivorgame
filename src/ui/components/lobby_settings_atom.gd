# ⚙️ LOBBY SETTINGS ATOM
# Lobi içinde ses, görüntü ve backend kullanıcı ayarları
class_name LobbySettingsAtom
extends Control

# === SIGNALS ===
signal volume_changed(bus_name: String, value: float)
signal fullscreen_changed(enabled: bool)
signal sound_enabled_changed(enabled: bool)
signal tutorial_reset_requested()
signal skin_changed(skin_type: String, skin_id: String)

# === CONSTANTS ===
const VOLUME_MIN_DB: float = -50.0
const VOLUME_MAX_DB: float = 0.0

# === UI REFERENCES ===
var _main_container: VBoxContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton
var _sound_enabled_check: CheckButton
var _character_skin_option: OptionButton
var _weapon_skin_option: OptionButton
var _device_id_label: Label

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_load_current_values()

# === PUBLIC API ===

## Tab görünür olduğunda değerleri yeniden yükle
func refresh() -> void:
	if is_inside_tree():
		_load_current_values()

func get_master_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("Master"))

func get_music_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("Music"))

func get_sfx_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("SFX"))

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Lobby zaten ScrollContainer ile sarıyor; iç içe scroll layout bozuyor
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.custom_minimum_size = Vector2(0, 500)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	_main_container = VBoxContainer.new()
	_main_container.add_theme_constant_override("separation", 24)
	margin.add_child(_main_container)
	
	# Başlık
	var title = Label.new()
	title.text = "⚙️ Ayarlar"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_container.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Ses ve görüntü"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_container.add_child(subtitle)
	
	# Ses paneli (sadece var olan bus'lar)
	var audio_panel = _create_section_panel("🔊 Ses")
	_main_container.add_child(audio_panel)
	
	var audio_vbox = audio_panel.get_child(0).get_child(0) as VBoxContainer
	if audio_vbox:
		# Ses açık/kapalı (GameData.sound_enabled - backend ile senkron)
		var sound_row = HBoxContainer.new()
		sound_row.add_theme_constant_override("separation", 12)
		audio_vbox.add_child(sound_row)
		var sound_lbl = Label.new()
		sound_lbl.text = "Ses açık"
		sound_lbl.add_theme_font_size_override("font_size", 15)
		sound_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		sound_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sound_row.add_child(sound_lbl)
		_sound_enabled_check = CheckButton.new()
		_sound_enabled_check.toggled.connect(_on_sound_enabled_toggled)
		sound_row.add_child(_sound_enabled_check)
		if AudioServer.get_bus_index("Master") >= 0:
			_master_slider = _add_volume_row(audio_vbox, "Genel ses", "Master")
		if AudioServer.get_bus_index("Music") >= 0:
			_music_slider = _add_volume_row(audio_vbox, "Müzik", "Music")
		if AudioServer.get_bus_index("SFX") >= 0:
			_sfx_slider = _add_volume_row(audio_vbox, "Efektler", "SFX")
		if _master_slider == null and _music_slider == null and _sfx_slider == null:
			_master_slider = _add_volume_row(audio_vbox, "Ses", "Master")
	
	# Görüntü paneli
	var video_panel = _create_section_panel("🖥️ Görüntü")
	_main_container.add_child(video_panel)
	
	var video_vbox = video_panel.get_child(0).get_child(0) as VBoxContainer
	if video_vbox:
		var fullscreen_row = HBoxContainer.new()
		fullscreen_row.add_theme_constant_override("separation", 12)
		video_vbox.add_child(fullscreen_row)
		var fullscreen_label = Label.new()
		fullscreen_label.text = "Tam ekran"
		fullscreen_label.add_theme_font_size_override("font_size", 16)
		fullscreen_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
		fullscreen_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fullscreen_row.add_child(fullscreen_label)
		_fullscreen_check = CheckButton.new()
		_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		fullscreen_row.add_child(_fullscreen_check)
	
	# Oyun paneli (backend: tutorial_completed)
	var game_panel = _create_section_panel("🎮 Oyun")
	_main_container.add_child(game_panel)
	var game_vbox = game_panel.get_child(0).get_child(0) as VBoxContainer
	if game_vbox:
		var tutorial_row = HBoxContainer.new()
		tutorial_row.add_theme_constant_override("separation", 12)
		game_vbox.add_child(tutorial_row)
		var tutorial_lbl = Label.new()
		tutorial_lbl.text = "Öğreticiyi tekrar göster"
		tutorial_lbl.add_theme_font_size_override("font_size", 15)
		tutorial_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		tutorial_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tutorial_row.add_child(tutorial_lbl)
		var tutorial_btn = Button.new()
		tutorial_btn.text = "Sıfırla"
		tutorial_btn.custom_minimum_size = Vector2(80, 36)
		tutorial_btn.pressed.connect(_on_tutorial_reset_pressed)
		tutorial_row.add_child(tutorial_btn)
	
	# Görünüm paneli (backend: character_skin_id, weapon_skin_id)
	var skin_panel = _create_section_panel("🎨 Görünüm")
	_main_container.add_child(skin_panel)
	var skin_vbox = skin_panel.get_child(0).get_child(0) as VBoxContainer
	if skin_vbox:
		var char_skin_row = HBoxContainer.new()
		char_skin_row.add_theme_constant_override("separation", 12)
		skin_vbox.add_child(char_skin_row)
		var char_lbl = Label.new()
		char_lbl.text = "Karakter skin"
		char_lbl.add_theme_font_size_override("font_size", 15)
		char_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		char_lbl.custom_minimum_size = Vector2(100, 0)
		char_skin_row.add_child(char_lbl)
		_character_skin_option = OptionButton.new()
		_character_skin_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_character_skin_option.item_selected.connect(_on_character_skin_selected)
		char_skin_row.add_child(_character_skin_option)
		var weap_skin_row = HBoxContainer.new()
		weap_skin_row.add_theme_constant_override("separation", 12)
		skin_vbox.add_child(weap_skin_row)
		var weap_lbl = Label.new()
		weap_lbl.text = "Silah skin"
		weap_lbl.add_theme_font_size_override("font_size", 15)
		weap_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		weap_lbl.custom_minimum_size = Vector2(100, 0)
		weap_skin_row.add_child(weap_lbl)
		_weapon_skin_option = OptionButton.new()
		_weapon_skin_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_weapon_skin_option.item_selected.connect(_on_weapon_skin_selected)
		weap_skin_row.add_child(_weapon_skin_option)
	
	# Hesap paneli (backend: device_id, sync)
	var account_panel = _create_section_panel("☁️ Hesap")
	_main_container.add_child(account_panel)
	var account_vbox = account_panel.get_child(0).get_child(0) as VBoxContainer
	if account_vbox:
		var device_row = HBoxContainer.new()
		device_row.add_theme_constant_override("separation", 12)
		account_vbox.add_child(device_row)
		var device_lbl = Label.new()
		device_lbl.text = "Cihaz ID"
		device_lbl.add_theme_font_size_override("font_size", 15)
		device_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
		device_lbl.custom_minimum_size = Vector2(80, 0)
		device_row.add_child(device_lbl)
		_device_id_label = Label.new()
		_device_id_label.name = "DeviceIdLabel"
		_device_id_label.add_theme_font_size_override("font_size", 12)
		_device_id_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		_device_id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_device_id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		device_row.add_child(_device_id_label)
		var sync_row = HBoxContainer.new()
		sync_row.add_theme_constant_override("separation", 12)
		account_vbox.add_child(sync_row)
		var sync_btn = Button.new()
		sync_btn.text = "☁ Buluta senkronize et"
		sync_btn.custom_minimum_size = Vector2(180, 36)
		sync_btn.pressed.connect(_on_sync_pressed)
		sync_row.add_child(sync_btn)
		# VIP durumu (backend: is_vip)
		var gd = get_node_or_null("/root/GameData")
		if gd and gd.is_vip:
			var vip_row = HBoxContainer.new()
			vip_row.add_theme_constant_override("separation", 12)
			account_vbox.add_child(vip_row)
			var vip_lbl = Label.new()
			vip_lbl.text = "👑 VIP"
			vip_lbl.add_theme_font_size_override("font_size", 16)
			vip_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
			vip_row.add_child(vip_lbl)
	
	# Not
	var note = Label.new()
	note.text = "Tüm ayarlar bulut ile senkronize edilir."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_container.add_child(note)

func _create_section_panel(section_title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.16, 0.92)
	style.set_border_width_all(2)
	style.border_color = Color(0.35, 0.25, 0.55, 0.7)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 16)
	inner_margin.add_theme_constant_override("margin_right", 16)
	inner_margin.add_theme_constant_override("margin_top", 12)
	inner_margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner_margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	inner_margin.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = section_title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	vbox.add_child(title_label)
	
	return panel

func _add_volume_row(container: VBoxContainer, label_text: String, bus_name: String) -> HSlider:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	container.add_child(row)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	label.custom_minimum_size = Vector2(100, 0)
	row.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_volume_slider_changed.bind(bus_name))
	row.add_child(slider)
	
	return slider

func _get_bus_volume_db(bus_name: String) -> float:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return VOLUME_MAX_DB
	return AudioServer.get_bus_volume_db(idx)

func _set_bus_volume_db(bus_name: String, db: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, clampf(db, VOLUME_MIN_DB, VOLUME_MAX_DB))

func _percent_to_db(p: float) -> float:
	p = clampf(p / 100.0, 0.0, 1.0)
	if p <= 0.0:
		return VOLUME_MIN_DB
	return VOLUME_MIN_DB + (VOLUME_MAX_DB - VOLUME_MIN_DB) * p

func _db_to_percent(db: float) -> int:
	if db <= VOLUME_MIN_DB:
		return 0
	var range_db = VOLUME_MAX_DB - VOLUME_MIN_DB
	var p = (db - VOLUME_MIN_DB) / range_db
	return clampi(int(round(p * 100)), 0, 100)

func _load_current_values() -> void:
	if not is_inside_tree():
		return
	if _master_slider:
		_master_slider.value = _db_to_percent(_get_bus_volume_db("Master"))
	if _music_slider:
		_music_slider.value = _db_to_percent(_get_bus_volume_db("Music"))
	if _sfx_slider:
		_sfx_slider.value = _db_to_percent(_get_bus_volume_db("SFX"))
	if _fullscreen_check:
		_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if _sound_enabled_check:
		var gd = get_node_or_null("/root/GameData")
		_sound_enabled_check.button_pressed = gd.sound_enabled if gd else true
	if _character_skin_option:
		_populate_skin_options()
	if _device_id_label:
		var backend = get_node_or_null("/root/BackendService")
		var did: String = backend.get_device_id() if backend else ""
		_device_id_label.text = (did.left(12) + "...") if did.length() > 12 else (did if did else "-")

func _on_volume_slider_changed(value: float, bus_name: String) -> void:
	var db = _percent_to_db(value)
	_set_bus_volume_db(bus_name, db)
	volume_changed.emit(bus_name, value)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	fullscreen_changed.emit(toggled_on)

func _populate_skin_options() -> void:
	var gd = get_node_or_null("/root/GameData")
	if not gd:
		return
	var char_skins: Array = gd.owned_character_skins if gd.owned_character_skins.size() > 0 else ["default"]
	var weap_skins: Array = gd.owned_weapon_skins if gd.owned_weapon_skins.size() > 0 else ["default"]
	_character_skin_option.clear()
	for sid in char_skins:
		_character_skin_option.add_item(sid.capitalize(), _character_skin_option.item_count)
	var char_idx := char_skins.find(gd.character_skin_id)
	_character_skin_option.select(maxi(0, char_idx))
	_weapon_skin_option.clear()
	for sid in weap_skins:
		_weapon_skin_option.add_item(sid.capitalize(), _weapon_skin_option.item_count)
	var weap_idx := weap_skins.find(gd.weapon_skin_id)
	_weapon_skin_option.select(maxi(0, weap_idx))

func _on_sound_enabled_toggled(enabled: bool) -> void:
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.sound_enabled = enabled
		gd.save_data()
	sound_enabled_changed.emit(enabled)

func _on_tutorial_reset_pressed() -> void:
	var gd = get_node_or_null("/root/GameData")
	if gd:
		gd.tutorial_completed = false
		gd.save_data()
	tutorial_reset_requested.emit()

func _on_character_skin_selected(idx: int) -> void:
	var gd = get_node_or_null("/root/GameData")
	if not gd or idx < 0:
		return
	var skins: Array = gd.owned_character_skins if gd.owned_character_skins.size() > 0 else ["default"]
	if idx >= skins.size():
		return
	var sid := str(skins[idx])
	if gd.set_character_skin(sid):
		skin_changed.emit("character", sid)

func _on_weapon_skin_selected(idx: int) -> void:
	var gd = get_node_or_null("/root/GameData")
	if not gd or idx < 0:
		return
	var skins: Array = gd.owned_weapon_skins if gd.owned_weapon_skins.size() > 0 else ["default"]
	if idx >= skins.size():
		return
	var sid := str(skins[idx])
	if gd.set_weapon_skin(sid):
		skin_changed.emit("weapon", sid)

func _on_sync_pressed() -> void:
	var backend = get_node_or_null("/root/BackendService")
	if backend and backend.has_method("push_cloud_save"):
		backend.push_cloud_save()
