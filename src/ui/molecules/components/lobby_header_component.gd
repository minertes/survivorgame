# 🏢 LOBBY HEADER COMPONENT
# Lobi header bileşeni (Currency + Back button)
class_name LobbyHeaderComponent
extends PanelContainer

# === NODES ===
@onready var back_button: Button = $HBoxContainer/BackButton
@onready var currency_display: Control = $HBoxContainer/CurrencyDisplayAtom

# === STATE ===
var player_xp: int = 0

# === SIGNALS ===
signal back_pressed()
signal xp_updated(new_xp: int)
signal xp_earned(amount: int)
signal xp_spent(amount: int)

# === LIFECYCLE ===

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	print("✅ LobbyHeaderComponent initialized")

# === PUBLIC API ===

func set_player_xp(xp: int, animate: bool = true) -> void:
	player_xp = xp
	if currency_display:
		currency_display.set_xp_amount(xp, animate)
	else:
		print("⚠️ CurrencyDisplayAtom not found")
	xp_updated.emit(xp)

func add_xp(amount: int, animate: bool = true) -> void:
	player_xp += amount
	if currency_display:
		currency_display.add_xp(amount, animate)
		if animate:
			currency_display.play_earn_effect(amount)
	else:
		print("⚠️ CurrencyDisplayAtom not found")
	xp_earned.emit(amount)
	xp_updated.emit(player_xp)

func spend_xp(amount: int, animate: bool = true) -> bool:
	if player_xp < amount:
		print("❌ Not enough XP: %d < %d" % [player_xp, amount])
		return false
	
	player_xp -= amount
	if currency_display:
		if not currency_display.spend_xp(amount, animate):
			return false
		if animate:
			currency_display.play_spend_effect(amount)
	else:
		print("⚠️ CurrencyDisplayAtom not found")
	
	xp_spent.emit(amount)
	xp_updated.emit(player_xp)
	return true

func get_player_xp() -> int:
	return player_xp

func set_back_button_text(text: String) -> void:
	if back_button:
		back_button.text = text

func set_back_button_visible(visible: bool) -> void:
	if back_button:
		back_button.visible = visible

# === PRIVATE METHODS ===

func _setup_ui() -> void:
	# Header stili
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
	header_style.border_color = Color(0.3, 0.2, 0.5, 0.8)
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 2
	add_theme_stylebox_override("panel", header_style)
	
	custom_minimum_size = Vector2(0, 60)
	
	print("🖥️ Header UI setup completed")

func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		print("🔗 Back button signal connected")
	else:
		print("⚠️ Back button not found")
	
	if currency_display:
		currency_display.currency_updated.connect(_on_currency_updated)
		print("🔗 Currency display signal connected")
	else:
		print("⚠️ Currency display not found")

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(color.r + 0.1, color.g + 0.1, color.b + 0.1)
	hover_style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("hover", hover_style)

# === EVENT HANDLERS ===

func _on_back_button_pressed() -> void:
	print("🔙 Back button pressed")
	back_pressed.emit()

func _on_currency_updated(xp_amount: int) -> void:
	player_xp = xp_amount
	xp_updated.emit(xp_amount)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyHeaderComponent ===")
	print("Player XP: %d" % player_xp)
	print("Back Button: %s" % ("Loaded" if back_button else "Not Loaded"))
	print("Currency Display: %s" % ("Loaded" if currency_display else "Not Loaded"))