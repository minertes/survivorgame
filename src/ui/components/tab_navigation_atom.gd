# 📑 TAB NAVIGATION ATOM
# Tab navigasyonu için atomic bileşen
class_name TabNavigationAtom
extends Control

# === SIGNALS ===
signal tab_changed(tab_index: int, tab_name: String)
signal tab_hovered(tab_index: int)
signal tab_selected(tab_index: int)

# === CONSTANTS ===
enum Tab {
	CHARACTER = 0,
	WEAPON = 1,
	FLAG = 2,
	STATS = 3,
	SETTINGS = 4
}

const TAB_DATA: Array[Dictionary] = [
	{"name": "Karakter", "icon": "👤", "id": Tab.CHARACTER},
	{"name": "Silah", "icon": "🔫", "id": Tab.WEAPON},
	{"name": "Bayrak", "icon": "🌍", "id": Tab.FLAG},
	{"name": "İstatistik", "icon": "📊", "id": Tab.STATS},
	{"name": "Ayarlar", "icon": "⚙️", "id": Tab.SETTINGS}
]

# === PROPERTIES ===
var current_tab: int = Tab.CHARACTER
var tab_buttons: Array[Button] = []
var tab_indicators: Array[Control] = []

# === UI REFERENCES ===
var _tab_container: HBoxContainer
var _indicator_container: Control

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	set_current_tab(current_tab, false)

# === PUBLIC API ===

func set_current_tab(tab_index: int, emit_signal: bool = true) -> void:
	if tab_index < 0 or tab_index >= TAB_DATA.size():
		return
	
	current_tab = tab_index
	_update_tab_appearance()
	
	if emit_signal:
		tab_changed.emit(tab_index, TAB_DATA[tab_index]["name"])
		tab_selected.emit(tab_index)

func get_current_tab() -> int:
	return current_tab

func get_tab_name(tab_index: int) -> String:
	if tab_index >= 0 and tab_index < TAB_DATA.size():
		return TAB_DATA[tab_index]["name"]
	return ""

func get_tab_count() -> int:
	return TAB_DATA.size()

func set_tab_enabled(tab_index: int, enabled: bool) -> void:
	if tab_index >= 0 and tab_index < tab_buttons.size():
		tab_buttons[tab_index].disabled = not enabled
		
		if not enabled and current_tab == tab_index:
			# Eğer devre dışı bırakılan tab seçiliyse, ilk enabled tab'e geç
			for i in range(TAB_DATA.size()):
				if i != tab_index and (i < tab_buttons.size() and not tab_buttons[i].disabled):
					set_current_tab(i)
					break

func set_tab_notification(tab_index: int, has_notification: bool) -> void:
	if tab_index >= 0 and tab_index < tab_buttons.size():
		var button = tab_buttons[tab_index]
		
		# Notification dot ekle/kaldır
		var notification_node = button.get_node_or_null("Notification")
		if has_notification:
			if not notification_node:
				notification_node = Control.new()
				notification_node.name = "Notification"
				button.add_child(notification_node)
				
				var dot = ColorRect.new()
				dot.color = Color(1.0, 0.2, 0.2)
				dot.size = Vector2(8, 8)
				dot.position = Vector2(button.size.x - 10, 5)
				notification_node.add_child(dot)
		elif notification_node:
			notification_node.queue_free()

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Ana container
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)
	
	# Tab container
	_tab_container = HBoxContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_constant_override("separation", 0)
	main_vbox.add_child(_tab_container)
	
	# Tab butonlarını oluştur
	for tab_info in TAB_DATA:
		var tab_button = _create_tab_button(tab_info)
		_tab_container.add_child(tab_button)
		tab_buttons.append(tab_button)
	
	# Indicator container
	_indicator_container = Control.new()
	_indicator_container.custom_minimum_size = Vector2(0, 3)
	main_vbox.add_child(_indicator_container)
	
	# Indicator'ları oluştur
	_create_tab_indicators()

func _create_tab_button(tab_info: Dictionary) -> Button:
	var button = Button.new()
	button.text = "  %s  %s" % [tab_info["icon"], tab_info["name"]]
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(100, 52)
	button.add_theme_font_size_override("font_size", 14)
	
	# Signal bağla
	button.pressed.connect(_on_tab_pressed.bind(tab_info["id"]))
	button.mouse_entered.connect(_on_tab_hovered.bind(tab_info["id"]))
	
	return button

func _create_tab_indicators() -> void:
	for i in range(TAB_DATA.size()):
		var indicator = ColorRect.new()
		indicator.color = Color(0.4, 0.7, 1.0, 0.0)  # Başlangıçta şeffaf
		indicator.size = Vector2(0, 3)
		_indicator_container.add_child(indicator)
		tab_indicators.append(indicator)

func _update_tab_appearance() -> void:
	var tab_width = size.x / TAB_DATA.size()
	
	for i in range(TAB_DATA.size()):
		var button = tab_buttons[i]
		var indicator = tab_indicators[i]
		var is_active = (i == current_tab)
		
		# Buton stilini güncelle
		var button_style = StyleBoxFlat.new()
		if is_active:
			button_style.bg_color = Color(0.15, 0.1, 0.25, 0.9)
			button_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
			button.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
		else:
			button_style.bg_color = Color(0.08, 0.06, 0.15, 0.7)
			button_style.border_color = Color(0.3, 0.3, 0.5, 0.3)
			button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
		
		button_style.set_border_width_all(0)
		button_style.border_width_bottom = 2
		button.add_theme_stylebox_override("normal", button_style)
		
		# Hover stili
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.2, 0.15, 0.35, 0.9)
		hover_style.border_color = Color(0.5, 0.8, 1.0, 0.6)
		hover_style.set_border_width_all(0)
		hover_style.border_width_bottom = 2
		button.add_theme_stylebox_override("hover", hover_style)
		
		# Indicator pozisyonu ve rengi
		var indicator_x = i * tab_width
		var indicator_target_width = tab_width if is_active else 0
		var indicator_target_color = Color(0.4, 0.7, 1.0, 1.0) if is_active else Color(0.4, 0.7, 1.0, 0.0)
		
		# Animasyon
		var tween = create_tween()
		tween.tween_property(indicator, "size:x", indicator_target_width, 0.2)
		tween.parallel().tween_property(indicator, "color", indicator_target_color, 0.2)
		tween.parallel().tween_property(indicator, "position:x", indicator_x, 0.2)

func _on_tab_pressed(tab_index: int) -> void:
	set_current_tab(tab_index)

func _on_tab_hovered(tab_index: int) -> void:
	tab_hovered.emit(tab_index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		# Pencere boyutu değiştiğinde indicator'ları güncelle
		call_deferred("_update_tab_appearance")

# === DEBUG ===
func print_debug_info() -> void:
	print("=== TabNavigationAtom ===")
	print("Current Tab: %d (%s)" % [current_tab, get_tab_name(current_tab)])
	print("Total Tabs: %d" % TAB_DATA.size())
	print("Tab Buttons: %d" % tab_buttons.size())