# ⚙️ LOBBY SETTINGS ATOM
# Lobi içinde ses ve görüntü ayarları (basit sayfa)
class_name LobbySettingsAtom
extends Control

# === SIGNALS ===
signal volume_changed(bus_name: String, value: float)
signal fullscreen_changed(enabled: bool)

# === CONSTANTS ===
const VOLUME_MIN_DB: float = -50.0
const VOLUME_MAX_DB: float = 0.0

# === UI REFERENCES ===
var _main_container: VBoxContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fullscreen_check: CheckButton

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_load_current_values()

# === PUBLIC API ===

func get_master_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("Master"))

func get_music_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("Music"))

func get_sfx_volume_percent() -> int:
	return _db_to_percent(_get_bus_volume_db("SFX"))

# === PRIVATE METHODS ===

func _build_ui() -> void:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)
	
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
		if AudioServer.get_bus_index("Master") >= 0:
			_master_slider = _add_volume_row(audio_vbox, "Genel ses", "Master")
		if AudioServer.get_bus_index("Music") >= 0:
			_music_slider = _add_volume_row(audio_vbox, "Müzik", "Music")
		if AudioServer.get_bus_index("SFX") >= 0:
			_sfx_slider = _add_volume_row(audio_vbox, "Efektler", "SFX")
		if _master_slider == null and _music_slider == null and _sfx_slider == null:
			# En azından Master varsayılan olarak 0. bus
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
	
	# Not
	var note = Label.new()
	note.text = "Tüm ayarlar için Ana Menü → Ayarlar"
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
	if _master_slider:
		_master_slider.value = _db_to_percent(_get_bus_volume_db("Master"))
	if _music_slider:
		_music_slider.value = _db_to_percent(_get_bus_volume_db("Music"))
	if _sfx_slider:
		_sfx_slider.value = _db_to_percent(_get_bus_volume_db("SFX"))
	if _fullscreen_check:
		_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

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
