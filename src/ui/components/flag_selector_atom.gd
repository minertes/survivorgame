# 🌍 FLAG SELECTOR ATOM
# Bayrak seçimi için atomic bileşen
class_name FlagSelectorAtom
extends Control

# === SIGNALS ===
signal flag_selected(flag_id: String)
signal flag_purchased(flag_id: String)
signal flag_preview_requested(flag_id: String)

# === CONSTANTS ===
const FLAGS: Dictionary = {
	"turkey": {
		"name": "Türkiye",
		"emoji": "🇹🇷",
		"code": "TR",
		"cost": 0,
		"unlocked_by_default": true,
		"bonus": "+10% XP Kazanımı",
		"color": Color(0.9, 0.2, 0.2)
	},
	"usa": {
		"name": "ABD",
		"emoji": "🇺🇸",
		"code": "US",
		"cost": 100,
		"unlocked_by_default": false,
		"bonus": "+15% Hasar",
		"color": Color(0.2, 0.2, 0.9)
	},
	"germany": {
		"name": "Almanya",
		"emoji": "🇩🇪",
		"code": "DE",
		"cost": 120,
		"unlocked_by_default": false,
		"bonus": "+20% Zırh",
		"color": Color(0.9, 0.9, 0.2)
	},
	"japan": {
		"name": "Japonya",
		"emoji": "🇯🇵",
		"code": "JP",
		"cost": 150,
		"unlocked_by_default": false,
		"bonus": "+25% Hız",
		"color": Color(0.9, 0.2, 0.9)
	},
	"france": {
		"name": "Fransa",
		"emoji": "🇫🇷",
		"code": "FR",
		"cost": 180,
		"unlocked_by_default": false,
		"bonus": "+30% Can",
		"color": Color(0.2, 0.9, 0.9)
	},
	"uk": {
		"name": "İngiltere",
		"emoji": "🇬🇧",
		"code": "GB",
		"cost": 200,
		"unlocked_by_default": false,
		"bonus": "+35% Kritik Şans",
		"color": Color(0.9, 0.5, 0.2)
	},
	"brazil": {
		"name": "Brezilya",
		"emoji": "🇧🇷",
		"code": "BR",
		"cost": 220,
		"unlocked_by_default": false,
		"bonus": "+40% Ateş Hızı",
		"color": Color(0.2, 0.9, 0.2)
	},
	"russia": {
		"name": "Rusya",
		"emoji": "🇷🇺",
		"code": "RU",
		"cost": 300,
		"unlocked_by_default": false,
		"bonus": "+50% Patlama Hasarı",
		"color": Color(0.9, 0.9, 0.9)
	},
	"china": {
		"name": "Çin",
		"emoji": "🇨🇳",
		"code": "CN",
		"cost": 320,
		"unlocked_by_default": false,
		"bonus": "+60% Mermi Sayısı",
		"color": Color(0.9, 0.2, 0.2)
	},
	"south_korea": {
		"name": "Güney Kore",
		"emoji": "🇰🇷",
		"code": "KR",
		"cost": 350,
		"unlocked_by_default": false,
		"bonus": "+70% Teknik Hasar",
		"color": Color(0.2, 0.2, 0.9)
	}
}

# === PROPERTIES ===
var current_flag_id: String = "turkey"
var owned_flags: Array = ["turkey"]
var player_xp: int = 0

# === UI REFERENCES ===
var _flag_grid: GridContainer
var _selected_flag_display: Control

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_refresh_display()

# === PUBLIC API ===

func set_player_data(xp: int, owned_flgs: Array, selected_flag: String) -> void:
	player_xp = xp
	owned_flags = owned_flgs
	current_flag_id = selected_flag
	if _flag_grid != null:
		_refresh_display()

func get_selected_flag() -> Dictionary:
	return FLAGS.get(current_flag_id, FLAGS["turkey"])

func get_flag_cost(flag_id: String) -> int:
	return FLAGS.get(flag_id, {}).get("cost", 0)

func can_purchase_flag(flag_id: String) -> bool:
	if flag_id in owned_flags:
		return false
	var cost = get_flag_cost(flag_id)
	return player_xp >= cost

# === PRIVATE METHODS ===

func _build_ui() -> void:
	# Ana container (padding ile)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# Başlık
	var title_label = Label.new()
	title_label.text = "🌍 Bayrak Seçimi"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	# Açıklama
	var desc_label = Label.new()
	desc_label.text = "Kartın üzerine tıklayarak seçin veya satın alın"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.95, 0.75))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(desc_label)
	
	# Bayrak grid
	_flag_grid = GridContainer.new()
	_flag_grid.columns = 3
	_flag_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flag_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_flag_grid.add_theme_constant_override("h_separation", 16)
	_flag_grid.add_theme_constant_override("v_separation", 16)
	main_vbox.add_child(_flag_grid)
	
	# Seçili bayrak gösterimi
	_selected_flag_display = _create_selected_flag_display()
	main_vbox.add_child(_selected_flag_display)

func _refresh_display() -> void:
	if _flag_grid == null:
		return
	# Temizle
	for child in _flag_grid.get_children():
		child.queue_free()
	
	# Bayrak kartlarını oluştur
	for flag_id in FLAGS.keys():
		var flag_card = _create_flag_card(flag_id)
		_flag_grid.add_child(flag_card)
	
	# Seçili bayrak gösterimini güncelle
	_update_selected_flag_display()

func _create_flag_card(flag_id: String) -> Control:
	var flag_data = FLAGS[flag_id]
	var is_owned = flag_id in owned_flags
	var is_selected = flag_id == current_flag_id
	var can_afford = player_xp >= flag_data["cost"]
	
	# Kart container (karta tıklanınca seçim)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(110, 130)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Kart tıklanabilir; hover'da el imleci
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Kart stili
	var card_style = StyleBoxFlat.new()
	if is_selected:
		card_style.bg_color = Color(0.2, 0.8, 0.4, 0.3)
		card_style.border_color = Color(0.4, 1.0, 0.6, 0.8)
	elif is_owned:
		card_style.bg_color = Color(0.1, 0.3, 0.1, 0.3)
		card_style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	else:
		card_style.bg_color = Color(0.15, 0.2, 0.15, 0.3)
		card_style.border_color = Color(0.3, 0.4, 0.3, 0.4)
	
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", card_style)
	# Kartın tamamına tıklanınca seç/satın al
	card.gui_input.connect(_on_flag_card_gui_input.bind(flag_id, is_owned, is_selected, can_afford))
	
	# İçerik (karta tıklanabilsin diye içerik event'i geçirir)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Bayrak emojisi
	var emoji_label = Label.new()
	emoji_label.text = flag_data["emoji"]
	emoji_label.add_theme_font_size_override("font_size", 32)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(emoji_label)
	
	# Ülke kodu
	var code_label = Label.new()
	code_label.text = flag_data["code"]
	code_label.add_theme_font_size_override("font_size", 12)
	code_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(code_label)
	
	# Bonus
	var bonus_label = Label.new()
	bonus_label.text = flag_data["bonus"]
	bonus_label.add_theme_font_size_override("font_size", 9)
	bonus_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bonus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bonus_label)
	
	# Buton
	if is_selected:
		var selected_label = Label.new()
		selected_label.text = "✓"
		selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_label.add_theme_font_size_override("font_size", 14)
		selected_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(selected_label)
	elif is_owned:
		var select_btn = Button.new()
		select_btn.text = "SEÇ"
		select_btn.add_theme_font_size_override("font_size", 10)
		select_btn.pressed.connect(_on_select_flag.bind(flag_id))
		_style_button(select_btn, Color(0.2, 0.5, 0.2))
		vbox.add_child(select_btn)
	else:
		var buy_btn = Button.new()
		buy_btn.text = "%d" % flag_data["cost"]
		buy_btn.add_theme_font_size_override("font_size", 10)
		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(_on_buy_flag.bind(flag_id))
		_style_button(buy_btn, 
			Color(0.5, 0.3, 0.1) if can_afford else Color(0.3, 0.3, 0.3))
		vbox.add_child(buy_btn)
	
	return card

func _create_selected_flag_display() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.1, 0.05, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 20)
	panel.add_child(hbox)
	
	# Bayrak emojisi
	var emoji_label = Label.new()
	emoji_label.name = "SelectedFlagEmoji"
	emoji_label.add_theme_font_size_override("font_size", 40)
	hbox.add_child(emoji_label)
	
	# Bayrak bilgileri
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.name = "SelectedFlagName"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	info_vbox.add_child(name_label)
	
	var bonus_label = Label.new()
	bonus_label.name = "SelectedFlagBonus"
	bonus_label.add_theme_font_size_override("font_size", 14)
	bonus_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	info_vbox.add_child(bonus_label)
	
	return panel

func _update_selected_flag_display() -> void:
	var flag_data = get_selected_flag()
	# Etiketler panel -> HBoxContainer -> (emoji) ve (info_vbox -> name, bonus)
	var hbox = _selected_flag_display.get_child(0) if _selected_flag_display.get_child_count() > 0 else null
	var emoji_label: Label = hbox.get_node_or_null("SelectedFlagEmoji") if hbox else null
	var info_vbox = hbox.get_child(1) if hbox and hbox.get_child_count() > 1 else null
	var name_label: Label = info_vbox.get_node_or_null("SelectedFlagName") if info_vbox else null
	var bonus_label: Label = info_vbox.get_node_or_null("SelectedFlagBonus") if info_vbox else null
	
	if emoji_label:
		emoji_label.text = flag_data["emoji"]
	if name_label:
		name_label.text = "%s (%s)" % [flag_data["name"], flag_data["code"]]
	if bonus_label:
		bonus_label.text = "Bonus: %s" % flag_data["bonus"]

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.1)
	hover_style.set_corner_radius_all(3)
	button.add_theme_stylebox_override("hover", hover_style)

func _on_flag_card_gui_input(event: InputEvent, flag_id: String, is_owned: bool, is_selected: bool, can_afford: bool) -> void:
	if not event is InputEventMouseButton:
		return
	var ev = event as InputEventMouseButton
	if ev.button_index != MOUSE_BUTTON_LEFT or not ev.pressed:
		return
	if is_selected:
		return
	if is_owned:
		_on_select_flag(flag_id)
	else:
		if can_afford:
			_on_buy_flag(flag_id)

func _on_select_flag(flag_id: String) -> void:
	current_flag_id = flag_id
	flag_selected.emit(flag_id)
	_refresh_display()

func _on_buy_flag(flag_id: String) -> void:
	if can_purchase_flag(flag_id):
		flag_purchased.emit(flag_id)

func _on_preview_flag(flag_id: String) -> void:
	flag_preview_requested.emit(flag_id)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== FlagSelectorAtom ===")
	print("Selected: %s" % current_flag_id)
	print("Owned: %s" % owned_flags)
	print("XP: %d" % player_xp)
	print("Flags: %d" % FLAGS.size())