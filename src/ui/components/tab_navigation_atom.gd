# 📑 TAB NAVIGATION ATOM
# Tab navigasyonu için atomic bileşen
class_name TabNavigationAtom
extends Control

# === SIGNALS ===
signal tab_changed(tab_index: int, tab_name: String)
signal tab_hovered(tab_index: int)
signal tab_selected(tab_index: int)

# === CONSTANTS === (tasarım: 720 viewport)
const DESIGN_W := 720.0
const TAB_BAR_H := 48
const TAB_FONT_SIZE := 15
const TAB_MIN_W := 80
const TAB_MAX_W := 160

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
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)

	_tab_container = HBoxContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_constant_override("separation", 4)
	main_vbox.add_child(_tab_container)

	for tab_info in TAB_DATA:
		var tab_btn := _create_tab_button(tab_info)
		_tab_container.add_child(tab_btn)
		tab_buttons.append(tab_btn)

	_indicator_container = Control.new()
	_indicator_container.custom_minimum_size = Vector2(0, 3)
	main_vbox.add_child(_indicator_container)
	_create_tab_indicators()

func _create_tab_button(tab_info: Dictionary) -> Button:
	var button := Button.new()
	button.text = " %s %s " % [tab_info["icon"], tab_info["name"]]
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(TAB_MIN_W, TAB_BAR_H)
	# Button'da custom_maximum_size yok; sadece minimum kullan
	button.add_theme_font_size_override("font_size", TAB_FONT_SIZE)
	button.pressed.connect(_on_tab_pressed.bind(tab_info["id"]))
	button.mouse_entered.connect(_on_tab_hovered.bind(tab_info["id"]))
	return button

func _create_tab_indicators() -> void:
	for i in range(TAB_DATA.size()):
		var indicator := ColorRect.new()
		indicator.color = Color(0.4, 0.65, 0.35, 0.0)
		indicator.custom_minimum_size = Vector2(0, 3)
		indicator.size = Vector2(0, 3)
		_indicator_container.add_child(indicator)
		tab_indicators.append(indicator)

func _update_tab_appearance() -> void:
	var total_w := maxf(size.x, 1.0)
	var tab_count := TAB_DATA.size()
	var tab_width := total_w / tab_count

	for i in range(tab_count):
		if i >= tab_buttons.size() or i >= tab_indicators.size():
			continue
		var button: Button = tab_buttons[i]
		var indicator: Control = tab_indicators[i]
		if not button or not indicator:
			continue
		var is_active := (i == current_tab)

		var button_style := StyleBoxFlat.new()
		if is_active:
			button_style.bg_color = Color(0.14, 0.12, 0.2)
			button_style.border_color = Color(0.45, 0.6, 0.35, 0.9)
			button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
		else:
			button_style.bg_color = Color(0.08, 0.07, 0.12)
			button_style.border_color = Color(0.25, 0.25, 0.35, 0.4)
			button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		button_style.set_corner_radius_all(6)
		button_style.set_border_width_all(1)
		button_style.border_width_bottom = 2
		button.add_theme_stylebox_override("normal", button_style)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.18, 0.16, 0.26)
		hover_style.border_color = Color(0.5, 0.65, 0.4, 0.7)
		hover_style.set_corner_radius_all(6)
		hover_style.set_border_width_all(1)
		hover_style.border_width_bottom = 2
		button.add_theme_stylebox_override("hover", hover_style)

		var ind_x := i * tab_width
		var ind_w := tab_width if is_active else 0.0
		var ind_color := Color(0.4, 0.75, 0.35, 1.0) if is_active else Color(0.4, 0.6, 0.35, 0.0)

		indicator.set_anchors_preset(Control.PRESET_TOP_LEFT)
		indicator.offset_left = ind_x
		indicator.offset_top = 0
		indicator.offset_right = ind_x + ind_w
		indicator.offset_bottom = 3
		indicator.color = ind_color

func _on_tab_pressed(tab_index: int) -> void:
	set_current_tab(tab_index)

func _on_tab_hovered(tab_index: int) -> void:
	tab_hovered.emit(tab_index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and tab_buttons.size() == TAB_DATA.size():
		call_deferred("_update_tab_appearance")

# === DEBUG ===
func print_debug_info() -> void:
	print("=== TabNavigationAtom ===")
	print("Current Tab: %d (%s)" % [current_tab, get_tab_name(current_tab)])
	print("Total Tabs: %d" % TAB_DATA.size())
	print("Tab Buttons: %d" % tab_buttons.size())