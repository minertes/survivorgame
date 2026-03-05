# 🎮 CHARACTER SELECTOR ATOM
# Karakter seçimi için atomic bileşen
@tool
class_name CharacterSelectorAtom
extends Control

# === SIGNALS ===
signal character_selected(character_id: String)
signal character_purchased(character_id: String)
signal character_preview_requested(character_id: String)

# === CONSTANTS ===
const CHARACTERS: Dictionary = {
	"male_soldier": {
		"name": "BIG BOSS",
		"description": "Deneyimli asker, yüksek dayanıklılık",
		"cost": 0,
		"unlocked_by_default": true,
		"stats": {
			"health": 160,
			"speed": 1.0,
			"armor": "medium",
			"ability": "Rapid Fire"
		},
		"sprite_row": 0
	},
	"female_soldier": {
		"name": "NIGHT STALKER",
		"description": "Hızlı ve çevik, gizli operasyon uzmanı",
		"cost": 500,
		"unlocked_by_default": false,
		"stats": {
			"health": 120,
			"speed": 1.3,
			"armor": "light",
			"ability": "Stealth Mode"
		},
		"sprite_row": 1
	},
	"heavy_gunner": {
		"name": "HEAVY GUNNER",
		"description": "Ağır zırh, yüksek hasar",
		"cost": 800,
		"unlocked_by_default": false,
		"stats": {
			"health": 200,
			"speed": 0.8,
			"armor": "heavy",
			"ability": "Shield Wall"
		},
		"sprite_row": 2
	},
	"scout": {
		"name": "SCOUT",
		"description": "Uzun menzil, keskin nişancı",
		"cost": 600,
		"unlocked_by_default": false,
		"stats": {
			"health": 100,
			"speed": 1.2,
			"armor": "light",
			"ability": "Eagle Eye"
		},
		"sprite_row": 3
	}
}

# === PROPERTIES ===
var current_character_id: String = "male_soldier"
var owned_characters: Array = ["male_soldier"]
var player_xp: int = 0

# === UI REFERENCES ===
var _character_grid: GridContainer
var _preview_container: Control
var _selected_indicator: Control

# === LIFECYCLE ===

func _ready() -> void:
	_build_ui()
	_refresh_display()

# === PUBLIC API ===

func set_player_data(xp: int, owned_chars: Array, selected_char: String) -> void:
	player_xp = xp
	owned_characters = owned_chars
	current_character_id = selected_char
	if _character_grid != null:
		_refresh_display()

func get_selected_character() -> Dictionary:
	return CHARACTERS.get(current_character_id, CHARACTERS["male_soldier"])

func get_character_cost(character_id: String) -> int:
	return CHARACTERS.get(character_id, {}).get("cost", 0)

func can_purchase_character(character_id: String) -> bool:
	if character_id in owned_characters:
		return false
	var cost = get_character_cost(character_id)
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
	title_label.text = "👤 Karakter Seçimi"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)
	
	# Açıklama
	var desc_label = Label.new()
	desc_label.text = "Kartın üzerine tıklayarak seçin veya satın alın"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.95))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(desc_label)
	
	# Karakter grid
	_character_grid = GridContainer.new()
	_character_grid.columns = 2
	_character_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_character_grid.add_theme_constant_override("h_separation", 24)
	_character_grid.add_theme_constant_override("v_separation", 24)
	main_vbox.add_child(_character_grid)
	
	# Önizleme alanı
	_preview_container = Control.new()
	_preview_container.custom_minimum_size = Vector2(0, 200)
	_preview_container.visible = false
	main_vbox.add_child(_preview_container)

func _refresh_display() -> void:
	if _character_grid == null:
		return
	# Temizle
	for child in _character_grid.get_children():
		child.queue_free()
	
	# Karakter kartlarını oluştur
	for char_id in CHARACTERS.keys():
		var char_card = _create_character_card(char_id)
		_character_grid.add_child(char_card)

func _create_character_card(character_id: String) -> Control:
	var char_data = CHARACTERS[character_id]
	var is_owned = character_id in owned_characters
	var is_selected = character_id == current_character_id
	var can_afford = player_xp >= char_data["cost"]
	
	# Kart container (karta tıklanınca seçim)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 200)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Kart tıklanabilir; hover'da el imleci
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Kart stili
	var card_style = StyleBoxFlat.new()
	if is_selected:
		card_style.bg_color = Color(0.2, 0.4, 0.8, 0.3)
		card_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	elif is_owned:
		card_style.bg_color = Color(0.1, 0.3, 0.1, 0.3)
		card_style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	else:
		card_style.bg_color = Color(0.15, 0.15, 0.2, 0.3)
		card_style.border_color = Color(0.3, 0.3, 0.4, 0.4)
	
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", card_style)
	# Kartın tamamına tıklanınca seç/satın al
	card.gui_input.connect(_on_character_card_gui_input.bind(character_id, is_owned, is_selected, can_afford, char_data["cost"]))
	
	# İçerik (karta tıklanabilsin diye içerik event'i geçirir)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	# Karakter adı
	var name_label = Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = char_data["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", 
		Color(1.0, 0.9, 0.3) if is_selected else Color(0.9, 0.9, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# İkon/placeholder
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(0, 80)
	icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_container)
	
	# İstatistikler
	var stats_text = "❤ %d  ⚡ %.1fx" % [char_data["stats"]["health"], char_data["stats"]["speed"]]
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)
	
	# Yetenek
	var ability_label = Label.new()
	ability_label.text = char_data["stats"]["ability"]
	ability_label.add_theme_font_size_override("font_size", 11)
	ability_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(ability_label)
	
	# Buton
	if is_selected:
		var selected_label = Label.new()
		selected_label.text = "✓ SEÇİLİ"
		selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_label.add_theme_font_size_override("font_size", 12)
		selected_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(selected_label)
	elif is_owned:
		var select_btn = Button.new()
		select_btn.text = "SEÇ"
		select_btn.add_theme_font_size_override("font_size", 12)
		select_btn.pressed.connect(_on_select_character.bind(character_id))
		_style_button(select_btn, Color(0.2, 0.5, 0.2))
		vbox.add_child(select_btn)
	else:
		var buy_btn = Button.new()
		buy_btn.text = "%d XP" % char_data["cost"]
		buy_btn.add_theme_font_size_override("font_size", 12)
		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(_on_buy_character.bind(character_id))
		_style_button(buy_btn, 
			Color(0.6, 0.4, 0.1) if can_afford else Color(0.3, 0.3, 0.3))
		vbox.add_child(buy_btn)
	
	return card

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.1)
	hover_style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("hover", hover_style)

func _on_character_card_gui_input(event: InputEvent, character_id: String, is_owned: bool, is_selected: bool, can_afford: bool, _cost: int) -> void:
	if not event is InputEventMouseButton:
		return
	var ev = event as InputEventMouseButton
	if ev.button_index != MOUSE_BUTTON_LEFT or not ev.pressed:
		return
	if is_selected:
		return
	if is_owned:
		_on_select_character(character_id)
	else:
		if can_afford:
			_on_buy_character(character_id)

func _on_select_character(character_id: String) -> void:
	current_character_id = character_id
	character_selected.emit(character_id)
	_refresh_display()

func _on_buy_character(character_id: String) -> void:
	if can_purchase_character(character_id):
		character_purchased.emit(character_id)

func _on_preview_character(character_id: String) -> void:
	character_preview_requested.emit(character_id)

# === DEBUG ===
func print_debug_info() -> void:
	print("=== CharacterSelectorAtom ===")
	print("Selected: %s" % current_character_id)
	print("Owned: %s" % owned_characters)
	print("XP: %d" % player_xp)
	print("Characters: %d" % CHARACTERS.size())