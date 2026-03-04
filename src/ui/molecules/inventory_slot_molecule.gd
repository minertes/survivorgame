# 🎯 INVENTORY SLOT MOLECULE
# Atomic Design: Inventory slot molecule (Panel + Icon + Count)
# Belirli bir fonksiyonu var: Envanter slot'u gösterir
class_name InventorySlotMolecule
extends Control

# === CONFIG ===
@export var slot_index: int = 0:
	set(value):
		slot_index = value
		if is_inside_tree():
			_update_slot_info()

@export var show_count: bool = true:
	set(value):
		show_count = value
		if is_inside_tree():
			_update_count_visibility()

@export var show_rarity_border: bool = true:
	set(value):
		show_rarity_border = value
		if is_inside_tree():
			_update_rarity_border()

@export var config_id: String = "molecules.inventory_slot":
	set(value):
		config_id = value
		if is_inside_tree():
			_load_config()

# === NODES ===
@onready var slot_panel: PanelAtom = $SlotPanel
@onready var item_icon: IconAtom = $ItemIcon
@onready var count_label: LabelAtom = $CountLabel
@onready var hotkey_label: LabelAtom = $HotkeyLabel
@onready var selection_highlight: Control = $SelectionHighlight

# === STATE ===
var item_id: String = ""
var item_data: Dictionary = {}
var item_count: int = 0
var item_rarity: String = "common"
var is_empty: bool = true
var is_selected: bool = false
var is_dragging: bool = false
var hotkey: String = ""

# === EVENTS ===
signal slot_clicked(slot_index: int, item_id: String)
signal slot_double_clicked(slot_index: int, item_id: String)
signal slot_right_clicked(slot_index: int, item_id: String)
signal slot_drag_started(slot_index: int, item_id: String)
signal slot_drag_ended(slot_index: int, item_id: String)
signal item_changed(slot_index: int, old_item_id: String, new_item_id: String)
signal count_changed(slot_index: int, old_count: int, new_count: int)

# === LIFECYCLE ===

func _ready() -> void:
	# Config yükle
	_load_config()
	
	# Başlangıç durumunu güncelle
	_update_slot_info()
	_update_count_visibility()
	_update_rarity_border()
	_update_selection_state()
	
	# Event'leri bağla
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# === PUBLIC API ===

func set_item(item_id: String, count: int = 1, rarity: String = "common") -> void:
	var old_item_id = self.item_id
	var old_count = self.item_count
	
	self.item_id = item_id
	self.item_count = count
	self.item_rarity = rarity
	self.is_empty = (item_id.is_empty() or count <= 0)
	
	# Item data'yı yükle
	if not item_id.is_empty() and ConfigManager.is_available():
		item_data = ConfigManager.get_instance().get_item_config(item_id)
	else:
		item_data = {}
	
	# UI'yi güncelle
	_update_display()
	
	# Event'leri emit et
	if old_item_id != item_id:
		item_changed.emit(slot_index, old_item_id, item_id)
	
	if old_count != count:
		count_changed.emit(slot_index, old_count, count)

func clear_slot() -> void:
	set_item("", 0, "common")

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_selection_state()

func set_hotkey(key: String) -> void:
	hotkey = key
	_update_hotkey_label()

func set_show_count(show: bool) -> void:
	show_count = show
	_update_count_visibility()

func set_show_rarity_border(show: bool) -> void:
	show_rarity_border = show
	_update_rarity_border()

func load_config(config_id: String) -> void:
	self.config_id = config_id

func get_item_id() -> String:
	return item_id

func get_item_count() -> int:
	return item_count

func get_item_rarity() -> String:
	return item_rarity

func get_item_data() -> Dictionary:
	return item_data.duplicate()

func is_slot_empty() -> bool:
	return is_empty

func is_slot_selected() -> bool:
	return is_selected

# === CONFIG MANAGEMENT ===

func _load_config() -> void:
	if not ConfigManager.is_available():
		push_warning("ConfigManager not available for InventorySlotMolecule")
		return
	
	var config = ConfigManager.get_instance().get_config_value("ui.json", config_id, {})
	if config.is_empty():
		push_warning("InventorySlotMolecule config not found: %s" % config_id)
		return
	
	# Config değerlerini uygula
	if "show_count" in config:
		show_count = config.show_count
	
	if "show_rarity_border" in config:
		show_rarity_border = config.show_rarity_border
	
	# Slot size'ı ayarla
	if "slot_size" in config:
		var size_str = str(config.slot_size)
		if "," in size_str:
			var parts = size_str.split(",")
			if parts.size() == 2:
				var slot_size = Vector2(float(parts[0]), float(parts[1]))
				custom_minimum_size = slot_size
				slot_panel.custom_minimum_size = slot_size
	
	# Icon size'ı ayarla
	if "icon_size" in config:
		var size_str = str(config.icon_size)
		if "," in size_str:
			var parts = size_str.split(",")
			if parts.size() == 2:
				var icon_size = Vector2(float(parts[0]), float(parts[1]))
				item_icon.set_size(icon_size)

# === STATE MANAGEMENT ===

func _update_display() -> void:
	if not is_inside_tree():
		return
	
	if is_empty:
		# Boş slot
		item_icon.visible = false
		count_label.visible = false
		slot_panel.set_style("default")
	else:
		# Dolu slot
		item_icon.visible = true
		
		# Item icon'u (simülasyon)
		# item_icon.set_icon(load(item_data.get("icon_path", "")))
		
		# Count label
		if item_count > 1:
			count_label.set_text(str(item_count))
			count_label.visible = show_count
		else:
			count_label.visible = false
		
		# Rarity border
		_update_rarity_border()
	
	# Hotkey label
	_update_hotkey_label()

func _update_slot_info() -> void:
	if not is_inside_tree():
		return
	
	# Slot index'i hotkey label'da göster
	_update_hotkey_label()

func _update_count_visibility() -> void:
	if not is_inside_tree():
		return
	
	if is_empty or item_count <= 1:
		count_label.visible = false
	else:
		count_label.visible = show_count

func _update_rarity_border() -> void:
	if not is_inside_tree() or not show_rarity_border:
		return
	
	if is_empty or not ConfigManager.is_available():
		slot_panel.set_style("default")
		return
	
	# Rarity colors config'ini al
	var rarity_colors = ConfigManager.get_instance().get_config_value("ui.json", "molecules.inventory_slot.rarity_colors", {})
	
	if item_rarity in rarity_colors:
		# Özel rarity style'ı oluştur
		var color_str = rarity_colors[item_rarity]
		var rarity_color = _parse_color(color_str)
		
		# Panel style'ını güncelle
		slot_panel.set_style("highlight")
		# Not: PanelAtom'da border color'ı dynamic olarak değiştirmek için
		# daha gelişmiş bir sistem gerekebilir
	else:
		slot_panel.set_style("default")

func _update_selection_state() -> void:
	if not is_inside_tree():
		return
	
	selection_highlight.visible = is_selected
	
	if is_selected:
		selection_highlight.modulate = Color(1.0, 1.0, 1.0, 0.3)
	else:
		selection_highlight.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _update_hotkey_label() -> void:
	if not is_inside_tree():
		return
	
	if hotkey:
		hotkey_label.set_text(hotkey)
		hotkey_label.visible = true
	else:
		hotkey_label.visible = false

# === EVENT HANDLERS ===

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Single click
				slot_clicked.emit(slot_index, item_id)
				
				if mouse_event.double_click:
					# Double click
					slot_double_clicked.emit(slot_index, item_id)
				
				# Drag start
				if not is_empty:
					is_dragging = true
					slot_drag_started.emit(slot_index, item_id)
			else:
				# Drag end
				if is_dragging:
					is_dragging = false
					slot_drag_ended.emit(slot_index, item_id)
		
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# Right click
			slot_right_clicked.emit(slot_index, item_id)

func _on_mouse_entered() -> void:
	if not is_empty:
		# Hover effect
		modulate = Color(1.1, 1.1, 1.1, 1.0)

func _on_mouse_exited() -> void:
	# Reset hover effect
	modulate = Color.WHITE

# === UTILITY ===

func _parse_color(color_str: String) -> Color:
	if color_str.begins_with("#"):
		return Color(color_str)
	return Color(color_str)

# === DEBUG ===

func _to_string() -> String:
	var item_name = item_data.get("name", "Empty") if not item_data.is_empty() else "Empty"
	return "[InventorySlotMolecule: Slot %d, %s x%d (%s)]" % [
		slot_index,
		item_name,
		item_count,
		item_rarity
	]

func print_debug_info() -> void:
	print("=== InventorySlotMolecule Debug ===")
	print("Slot Index: %d" % slot_index)
	print("Item ID: %s" % item_id)
	print("Item Count: %d" % item_count)
	print("Item Rarity: %s" % item_rarity)
	print("Show Count: %s" % str(show_count))
	print("Show Rarity Border: %s" % str(show_rarity_border))
	print("Config ID: %s" % config_id)
	print("Is Empty: %s" % str(is_empty))
	print("Is Selected: %s" % str(is_selected))
	print("Is Dragging: %s" % str(is_dragging))
	print("Hotkey: %s" % hotkey)
	print("Item Data: %s" % str(item_data))