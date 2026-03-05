# 🏢 LOBBY CONTENT MANAGER
# Lobi içerik yöneticisi
class_name LobbyContentManager
extends Control

# === DEPENDENCIES ===
var character_selector = null
var weapon_selector = null
var flag_selector = null
var stats_display = null
var lobby_settings = null
var tab_navigation = null

# === NODES ===
@onready var content_container: Control = $ContentContainer
@onready var play_button: Button = $PlayButton

# === STATE ===
var current_tab: int = 0

# === SIGNALS ===
signal tab_changed(tab_index: int, tab_name: String)
signal play_button_pressed()
signal component_loaded(component_name: String, success: bool)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_ui()
	_initialize_components()
	_show_tab_content(current_tab)

# === PUBLIC API ===

func set_tab_navigation(navigation) -> void:
	tab_navigation = navigation
	if tab_navigation:
		tab_navigation.tab_changed.connect(_on_tab_changed)
		if not tab_navigation.get_parent():
			add_child(tab_navigation)
			# Tab bar üstte görünsün — ilk sıraya taşı
			move_child(tab_navigation, 0)
		tab_navigation.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tab_navigation.offset_left = 0
		tab_navigation.offset_top = 0
		tab_navigation.offset_right = 0
		tab_navigation.offset_bottom = 51
		tab_navigation.custom_minimum_size = Vector2(0, 51)
		tab_navigation.visible = true
		content_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_container.offset_top = 56
		content_container.offset_bottom = -(_PLAY_BTN_H + _CONTENT_PADDING * 2)
		content_container.offset_left = _CONTENT_PADDING
		content_container.offset_right = -_CONTENT_PADDING
		component_loaded.emit("tab_navigation", true)
		_show_tab_content(current_tab)

func set_character_selector(selector: CharacterSelectorAtom) -> void:
	character_selector = selector
	if character_selector:
		component_loaded.emit("character_selector", true)

func set_weapon_selector(selector) -> void:
	weapon_selector = selector
	if weapon_selector:
		component_loaded.emit("weapon_selector", true)

func set_flag_selector(selector: FlagSelectorAtom) -> void:
	flag_selector = selector
	if flag_selector:
		component_loaded.emit("flag_selector", true)

func set_stats_display(display) -> void:
	stats_display = display
	if stats_display:
		component_loaded.emit("stats_display", true)

func set_lobby_settings(settings) -> void:
	lobby_settings = settings
	if lobby_settings:
		component_loaded.emit("lobby_settings", true)

func show_tab(tab_index: int) -> void:
	current_tab = tab_index
	_show_tab_content(tab_index)

func get_current_tab() -> int:
	return current_tab

func set_play_button_text(text: String) -> void:
	if play_button:
		play_button.text = text

func set_play_button_enabled(enabled: bool) -> void:
	if play_button:
		play_button.disabled = not enabled

func set_play_button_visible(visible: bool) -> void:
	if play_button:
		play_button.visible = visible

# === PRIVATE METHODS ===

# Tasarım sabitleri (720x1280) — buton ekran içinde kalsın
const _PLAY_BTN_W := 280
const _PLAY_BTN_H := 52
const _CONTENT_PADDING := 16

func _setup_ui() -> void:
	if not content_container:
		content_container = Control.new()
		content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_container.name = "ContentContainer"
		add_child(content_container)
	if not play_button:
		play_button = Button.new()
		play_button.name = "PlayButton"
		add_child(play_button)
	# Stil ve boyut hem sahne hem kodla oluşturulanda aynı olsun
	_apply_play_button_style()
	if not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)

func _apply_play_button_style() -> void:
	if not play_button:
		return
	play_button.text = "▶ OYUNA BAŞLA"
	play_button.custom_minimum_size = Vector2(_PLAY_BTN_W, _PLAY_BTN_H)
	play_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play_button.offset_left = -int(_PLAY_BTN_W / 2)
	play_button.offset_top = -_PLAY_BTN_H - _CONTENT_PADDING
	play_button.offset_right = int(_PLAY_BTN_W / 2)
	play_button.offset_bottom = -_CONTENT_PADDING
	play_button.add_theme_font_size_override("font_size", 22)
	play_button.add_theme_color_override("font_color", Color(0.98, 1.0, 0.98))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.42, 0.14)
	style.set_corner_radius_all(12)
	style.border_color = Color(0.28, 0.75, 0.32, 0.9)
	style.set_border_width_all(2)
	play_button.add_theme_stylebox_override("normal", style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.55, 0.22)
	hover_style.set_corner_radius_all(12)
	hover_style.border_color = Color(0.4, 0.9, 0.45, 1.0)
	hover_style.set_border_width_all(2)
	play_button.add_theme_stylebox_override("hover", hover_style)

func _initialize_components() -> void:
	pass

func _show_tab_content(tab_index: int) -> void:
	# Mevcut içeriği temizle: bileşenleri remove_child ile ayır (tekrar kullanacağız), placeholder'ları sil
	for child in content_container.get_children():
		content_container.remove_child(child)
		# Placeholder (Label) ise sil; bileşen (selector vb.) ise sadece ayırdık
		if child is Label:
			child.queue_free()
	
	# Eklenecek düğüm zaten bir ebeveyndeyse önce çıkar (aynı düğüm tekrar eklenmesin)
	var node_to_show: Node = null
	match tab_index:
		0:  # CHARACTER
			node_to_show = character_selector
		1:  # WEAPON
			node_to_show = weapon_selector
		2:  # FLAG
			node_to_show = flag_selector
		3:  # STATS
			node_to_show = stats_display
		4:  # SETTINGS
			node_to_show = lobby_settings
		_:
			_show_placeholder("İÇERİK YÜKLENİYOR...")
			return
	
	if node_to_show:
		if node_to_show.get_parent():
			node_to_show.get_parent().remove_child(node_to_show)
		# ScrollContainer ile sar — uzun listeler kaydırılabilir olsun
		var scroll := ScrollContainer.new()
		scroll.name = "TabScroll"
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.offset_left = 0
		scroll.offset_top = 0
		scroll.offset_right = 0
		scroll.offset_bottom = 0
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size = Vector2(0, 200)
		content_container.add_child(scroll)
		scroll.add_child(node_to_show)
		node_to_show.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node_to_show.size_flags_vertical = Control.SIZE_EXPAND_FILL
		node_to_show.custom_minimum_size = Vector2(0, 400)
		# İstatistik/Ayarlar: node artık sahnede, GameData'dan yenile
		if (tab_index == 3 or tab_index == 4) and node_to_show.has_method("refresh"):
			node_to_show.refresh()
	else:
		match tab_index:
			0: _show_placeholder("👤 Karakter seçimi yüklenemedi")
			1: _show_placeholder("🔫 Silah seçimi yüklenemedi")
			2: _show_placeholder("🌍 Bayrak seçimi yüklenemedi")
			3: _show_placeholder("📊 İstatistikler yüklenemedi")
			4: _show_placeholder("⚙️ Ayarlar yüklenemedi")
			_: _show_placeholder("İÇERİK YÜKLENİYOR...")

func _show_placeholder(text: String) -> void:
	var placeholder = Label.new()
	placeholder.text = text
	placeholder.add_theme_font_size_override("font_size", 24)
	placeholder.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_container.add_child(placeholder)

# === EVENT HANDLERS ===

func _on_tab_changed(tab_index: int, tab_name: String) -> void:
	current_tab = tab_index
	_show_tab_content(tab_index)
	tab_changed.emit(tab_index, tab_name)

func _on_play_button_pressed() -> void:
	play_button_pressed.emit()

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyContentManager ===")
	print("Current Tab: %d" % current_tab)
	print("Content Container: %s" % ("Loaded" if content_container else "Not Loaded"))
	print("Play Button: %s" % ("Loaded" if play_button else "Not Loaded"))
	print("Components:")
	print("  Character Selector: %s" % ("Loaded" if character_selector else "Not Loaded"))
	print("  Weapon Selector: %s" % ("Loaded" if weapon_selector else "Not Loaded"))
	print("  Flag Selector: %s" % ("Loaded" if flag_selector else "Not Loaded"))
	print("  Stats Display: %s" % ("Loaded" if stats_display else "Not Loaded"))
	print("  Tab Navigation: %s" % ("Loaded" if tab_navigation else "Not Loaded"))