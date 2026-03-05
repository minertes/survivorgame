# 🎮 CONTROLS SETTINGS SECTION
# Kontrol ayarları bölümü
class_name ControlsSettingsSection
extends Control

# === NODES ===
@onready var keybind_container: VBoxContainer = $KeybindContainer

# === STATE ===
var current_settings: Dictionary = {
	"move_up": "W",
	"move_down": "S",
	"move_left": "A",
	"move_right": "D",
	"shoot": "MOUSE_LEFT",
	"reload": "R",
	"interact": "E"
}

var keybind_buttons: Dictionary = {}
var listening_for_keybind: bool = false
var current_listening_action: String = ""
var current_listening_button: Button = null

# === EVENTS ===
signal setting_changed(key: String, value)
signal controls_settings_updated(settings: Dictionary)
signal keybind_listening_started(action: String)
signal keybind_listening_stopped(action: String, key: String)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_ui()
	_initialize_keybind_buttons()

# === PUBLIC API ===

func load_settings(settings: Dictionary) -> void:
	for key in current_settings.keys():
		if key in settings:
			current_settings[key] = settings[key]
	
	_update_keybind_display()

func save_settings() -> Dictionary:
	return current_settings.duplicate()

func reset_to_defaults() -> void:
	current_settings = {
		"move_up": "W",
		"move_down": "S",
		"move_left": "A",
		"move_right": "D",
		"shoot": "MOUSE_LEFT",
		"reload": "R",
		"interact": "E"
	}
	_update_keybind_display()
	
	for action in current_settings:
		setting_changed.emit(action, current_settings[action])

func get_current_settings() -> Dictionary:
	return current_settings.duplicate()

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	if keybind_container:
		# Temel keybind container setup
		pass

func _initialize_keybind_buttons() -> void:
	if not keybind_container:
		return
	
	# Mevcut child'ları temizle
	for child in keybind_container.get_children():
		child.queue_free()
	
	keybind_buttons.clear()
	
	# Her action için bir buton oluştur
	for action in current_settings.keys():
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label = Label.new()
		label.text = _get_action_display_name(action) + ":"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var button = Button.new()
		button.text = current_settings[action]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_keybind_button_pressed.bind(action, button))
		
		hbox.add_child(label)
		hbox.add_child(button)
		keybind_container.add_child(hbox)
		
		keybind_buttons[action] = button

func _get_action_display_name(action: String) -> String:
	var display_names = {
		"move_up": "Yukarı Hareket",
		"move_down": "Aşağı Hareket",
		"move_left": "Sola Hareket",
		"move_right": "Sağa Hareket",
		"shoot": "Ateş Et",
		"reload": "Yeniden Yükle",
		"interact": "Etkileşim"
	}
	return display_names.get(action, action.capitalize())

func _update_keybind_display() -> void:
	for action in keybind_buttons:
		var button = keybind_buttons[action]
		if button:
			button.text = current_settings.get(action, "")

func _start_keybind_listening(action: String, button: Button) -> void:
	if listening_for_keybind:
		_stop_keybind_listening(false)
	
	listening_for_keybind = true
	current_listening_action = action
	current_listening_button = button
	
	button.text = "[TUŞ BEKLENİYOR...]"
	keybind_listening_started.emit(action)

func _stop_keybind_listening(success: bool = true) -> void:
	if not listening_for_keybind:
		return
	
	listening_for_keybind = false
	
	if success and current_listening_action and current_listening_button:
		# Display'i güncelle
		_update_keybind_display()
	
	keybind_listening_stopped.emit(current_listening_action, 
		current_settings.get(current_listening_action, ""))
	
	current_listening_action = ""
	current_listening_button = null

# === EVENT HANDLERS ===

func _on_keybind_button_pressed(action: String, button: Button) -> void:
	_start_keybind_listening(action, button)

func _input(event: InputEvent) -> void:
	if not listening_for_keybind:
		return
	
	if event is InputEventKey and event.pressed:
		# Klavye tuşu
		var key_name = OS.get_keycode_string(event.keycode)
		if key_name and key_name != "":
			current_settings[current_listening_action] = key_name
			_stop_keybind_listening(true)
			setting_changed.emit(current_listening_action, key_name)
			controls_settings_updated.emit(current_settings.duplicate())
	
	elif event is InputEventMouseButton and event.pressed:
		# Fare tuşu
		var mouse_button = ""
		match event.button_index:
			MOUSE_BUTTON_LEFT: mouse_button = "MOUSE_LEFT"
			MOUSE_BUTTON_RIGHT: mouse_button = "MOUSE_RIGHT"
			MOUSE_BUTTON_MIDDLE: mouse_button = "MOUSE_MIDDLE"
			MOUSE_BUTTON_WHEEL_UP: mouse_button = "MOUSE_WHEEL_UP"
			MOUSE_BUTTON_WHEEL_DOWN: mouse_button = "MOUSE_WHEEL_DOWN"
		
		if mouse_button != "":
			current_settings[current_listening_action] = mouse_button
			_stop_keybind_listening(true)
			setting_changed.emit(current_listening_action, mouse_button)
			controls_settings_updated.emit(current_settings.duplicate())

# === DEBUG ===

func print_debug_info() -> void:
	print("=== ControlsSettingsSection Debug ===")
	print("Current Settings: %s" % str(current_settings))
	print("Listening for Keybind: %s" % str(listening_for_keybind))
	print("Current Listening Action: %s" % current_listening_action)
	print("Keybind Buttons: %d" % keybind_buttons.size())
	print("Keybind Container: %s" % ("Loaded" if keybind_container else "Not Loaded"))