# 🎵 VOLUME CONTROL MOLECULE
# Atomic Design: Molecule (LabelAtom + ProgressBarAtom + ButtonAtom)
# Ses kontrolü için molekül: Label + Slider + Mute button
class_name VolumeControlMolecule
extends HBoxContainer

# === CONFIG ===
@export var label_text: String = "Volume":
	set(value):
		label_text = value
		if is_inside_tree() and volume_label:
			volume_label.set_text(label_text)

@export var default_volume: int = 80:
	set(value):
		default_volume = clamp(value, 0, 100)
		if is_inside_tree() and volume_slider:
			volume_slider.set_value(default_volume)

@export var show_mute_button: bool = true:
	set(value):
		show_mute_button = value
		if is_inside_tree():
			_update_mute_button_visibility()

@export var bus_name: String = "Master":
	set(value):
		bus_name = value
		if is_inside_tree():
			_update_bus_settings()

# === NODES ===
@onready var volume_label: LabelAtom = $VolumeLabel
@onready var volume_slider: ProgressBarAtom = $VolumeSlider
@onready var mute_button: ButtonAtom = $MuteButton

# === STATE ===
var is_muted: bool = false
var current_volume: int = 80
var saved_volume_before_mute: int = 80
var is_initialized: bool = false

# === EVENTS ===
signal volume_changed(volume: int, bus_name: String)
signal mute_toggled(is_muted: bool, bus_name: String)
signal control_initialized

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç değerlerini ayarla
	_initialize_components()
	
	# Event bağlantıları
	_connect_events()
	
	# UI'yi güncelle
	_update_ui()
	
	is_initialized = true
	control_initialized.emit()

# === PUBLIC API ===

func set_volume(value: int) -> void:
	"""Volume değerini ayarla (0-100 arası)"""
	var clamped_value = clamp(value, 0, 100)
	current_volume = clamped_value
	
	if volume_slider:
		volume_slider.set_value(clamped_value)
	
	# Eğer muted ise, unmute et
	if is_muted and clamped_value > 0:
		toggle_mute(false)
	
	volume_changed.emit(clamped_value, bus_name)
	
	# AudioSystem'e uygula
	_apply_to_audio_system()

func get_volume() -> int:
	"""Current volume değerini al"""
	return current_volume

func toggle_mute(force_state: Variant = null) -> void:
	"""Mute/unmute toggle — force_state null ise toggle, bool ise o değere ayarla"""
	var new_muted_state: bool = not is_muted
	if force_state != null and force_state is bool:
		new_muted_state = force_state
	
	if new_muted_state != is_muted:
		is_muted = new_muted_state
		
		if is_muted:
			# Mute: Volume'ü kaydet ve 0 yap
			saved_volume_before_mute = current_volume
			_apply_mute_to_audio_system(true)
		else:
			# Unmute: Kaydedilen volume'ü geri yükle
			_apply_mute_to_audio_system(false)
			if saved_volume_before_mute > 0:
				set_volume(saved_volume_before_mute)
		
		_update_mute_button_ui()
		mute_toggled.emit(is_muted, bus_name)

func is_volume_muted() -> bool:
	"""Volume muted mı?"""
	return is_muted

func set_label_text(text: String) -> void:
	"""Label text'ini ayarla"""
	label_text = text
	if volume_label:
		volume_label.set_text(text)

func set_bus_name(name: String) -> void:
	"""Audio bus name ayarla"""
	bus_name = name
	_update_bus_settings()

func reset_to_default() -> void:
	"""Default değerlere dön"""
	set_volume(default_volume)
	toggle_mute(false)

func save_state() -> Dictionary:
	"""Current state'i kaydet"""
	return {
		"volume": current_volume,
		"is_muted": is_muted,
		"saved_volume_before_mute": saved_volume_before_mute,
		"bus_name": bus_name
	}

func load_state(state: Dictionary) -> void:
	"""Saved state'i yükle"""
	if "volume" in state:
		set_volume(state.volume)
	if "is_muted" in state:
		toggle_mute(state.is_muted)
	if "saved_volume_before_mute" in state:
		saved_volume_before_mute = state.saved_volume_before_mute
	if "bus_name" in state:
		bus_name = state.bus_name

# === PRIVATE METHODS ===

func _initialize_components() -> void:
	# Label text'ini ayarla
	if volume_label:
		volume_label.set_text(label_text)
	
	# Slider değerini ayarla
	if volume_slider:
		volume_slider.set_value(default_volume)
		current_volume = default_volume
	
	# Mute button visibility
	_update_mute_button_visibility()
	
	# Mute button UI
	_update_mute_button_ui()

func _connect_events() -> void:
	# Slider event'ini bağla
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_slider_changed)
	
	# Mute button event'ini bağla
	if mute_button:
		mute_button.button_pressed.connect(_on_mute_button_pressed)

func _update_ui() -> void:
	# Tüm UI bileşenlerini güncelle
	if volume_label:
		volume_label.set_text(label_text)
	
	if volume_slider:
		volume_slider.set_value(current_volume)
	
	_update_mute_button_ui()
	_update_mute_button_visibility()

func _update_mute_button_visibility() -> void:
	# Mute button visibility
	if mute_button:
		mute_button.visible = show_mute_button

func _update_mute_button_ui() -> void:
	# Mute button text ve style'ını güncelle
	if mute_button:
		if is_muted:
			mute_button.set_text("🔇")  # Muted icon
			mute_button.set_tooltip_text("Unmute %s" % bus_name)
			mute_button.add_theme_color_override("font_color", Color.RED)
		else:
			mute_button.set_text("🔊")  # Unmuted icon
			mute_button.set_tooltip_text("Mute %s" % bus_name)
			mute_button.remove_theme_color_override("font_color")

func _update_bus_settings() -> void:
	# Audio bus settings güncelle
	# Burada AudioSystem ile entegrasyon yapılabilir
	pass

func _apply_to_audio_system() -> void:
	"""Volume değerini AudioSystem'e uygula"""
	if not is_muted:
		# dB hesapla (0-100 linear to -80 to 0 dB)
		var volume_db = linear_to_db(float(current_volume) / 100.0)
		
		# EventBus üzerinden AudioSystem'e bildir
		if EventBus.is_available():
			EventBus.emit_now_static("set_volume", {
				"bus_name": bus_name,
				"volume_db": volume_db,
				"volume_percent": current_volume
			})

func _apply_mute_to_audio_system(mute: bool) -> void:
	"""Mute state'ini AudioSystem'e uygula"""
	if EventBus.is_available():
		EventBus.emit_now_static("toggle_mute", {
			"bus_name": bus_name,
			"muted": mute
		})

# === EVENT HANDLERS ===

func _on_volume_slider_changed(value: float) -> void:
	# Slider değeri değişti
	var int_value = int(value)
	if int_value != current_volume:
		current_volume = int_value
		volume_changed.emit(int_value, bus_name)
		_apply_to_audio_system()

func _on_mute_button_pressed() -> void:
	# Mute button'a tıklandı
	toggle_mute()

# === DEBUG ===

func _to_string() -> String:
	return "[VolumeControlMolecule: %s, Volume: %d%%, Muted: %s]" % [
		bus_name,
		current_volume,
		str(is_muted)
	]

func print_debug_info() -> void:
	print("=== VolumeControlMolecule Debug ===")
	print("Bus Name: %s" % bus_name)
	print("Current Volume: %d%%" % current_volume)
	print("Is Muted: %s" % str(is_muted))
	print("Label Text: %s" % label_text)
	print("Default Volume: %d%%" % default_volume)
	print("Show Mute Button: %s" % str(show_mute_button))
	print("Is Initialized: %s" % str(is_initialized))
	print("Saved Volume Before Mute: %d%%" % saved_volume_before_mute)