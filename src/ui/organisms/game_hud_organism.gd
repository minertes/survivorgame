# 🎯 GAME HUD ORGANISM
# Atomic Design: Game HUD organism (HealthBar + XPBar + WeaponInfo + Inventory)
# Kompleks UI bölümü: Oyun HUD'ını yönetir
class_name GameHUDOrganism
extends Control

# === CONFIG ===
@export var show_health_bar: bool = true:
	set(value):
		show_health_bar = value
		if is_inside_tree():
			_update_health_bar_visibility()

@export var show_xp_bar: bool = true:
	set(value):
		show_xp_bar = value
		if is_inside_tree():
			_update_xp_bar_visibility()

@export var show_weapon_info: bool = true:
	set(value):
		show_weapon_info = value
		if is_inside_tree():
			_update_weapon_info_visibility()

@export var show_inventory: bool = true:
	set(value):
		show_inventory = value
		if is_inside_tree():
			_update_inventory_visibility()

@export var show_minimap: bool = true:
	set(value):
		show_minimap = value
		if is_inside_tree():
			_update_minimap_visibility()

@export var update_interval: float = 0.1:
	set(value):
		update_interval = value
		if is_inside_tree():
			_update_timer()

# === NODES ===
@onready var health_bar: HealthBarMolecule = $TopLeft/HealthBar
@onready var xp_bar: ProgressBarAtom = $TopLeft/XPBar
@onready var level_label: LabelAtom = $TopLeft/LevelLabel
@onready var weapon_card: WeaponCardMolecule = $TopRight/WeaponCard
@onready var inventory_panel: PanelAtom = $BottomCenter/InventoryPanel
@onready var inventory_slots: Array = [
	$BottomCenter/InventoryPanel/Slot1,
	$BottomCenter/InventoryPanel/Slot2,
	$BottomCenter/InventoryPanel/Slot3,
	$BottomCenter/InventoryPanel/Slot4,
	$BottomCenter/InventoryPanel/Slot5,
	$BottomCenter/InventoryPanel/Slot6
]
@onready var minimap_container: PanelAtom = $TopRight/MinimapContainer
@onready var update_timer: Timer = $UpdateTimer

# === STATE ===
var player_entity: Node = null
var player_components: Dictionary = {}
var current_weapon_id: String = ""
var current_level: int = 1
var current_xp: float = 0.0
var xp_to_next_level: float = 100.0
var is_initialized: bool = false

# === EVENTS ===
signal hud_initialized
signal hud_visibility_changed(is_visible: bool)
signal player_bound(player: Node)
signal player_unbound
signal weapon_changed(old_weapon: String, new_weapon: String)
signal level_changed(old_level: int, new_level: int)
signal inventory_updated

# === LIFECYCLE ===

func _ready() -> void:
	# Başlangıç durumunu güncelle
	_update_visibility()
	_update_timer()
	
	# Timer'ı başlat
	update_timer.timeout.connect(_on_update_timer_timeout)
	
	# EventBus subscription'ları
	_setup_event_bus_subscriptions()
	
	# Inventory slot'larını başlat
	_initialize_inventory_slots()
	
	is_initialized = true
	hud_initialized.emit()

# === PUBLIC API ===

func bind_to_player(player: Node) -> void:
	player_entity = player
	player_components.clear()
	
	# Player component'larını bul
	if player.has_method("get_component"):
		# Component-based architecture
		player_components["health"] = player.get_component("HealthComponent")
		player_components["experience"] = player.get_component("ExperienceComponent")
		player_components["inventory"] = player.get_component("InventoryComponent")
		player_components["weapon"] = player.get_component("WeaponComponent")
	
	# HealthBar'ı bağla
	if player_components.has("health"):
		health_bar.bind_to_entity(player)
	
	# XP ve Level bilgilerini güncelle
	_update_player_stats()
	
	# Weapon bilgisini güncelle
	_update_weapon_info()
	
	# Inventory'yi güncelle
	_update_inventory()
	
	player_bound.emit(player)

func unbind_from_player() -> void:
	if player_components.has("health"):
		health_bar.unbind_from_entity()
	
	player_entity = null
	player_components.clear()
	player_unbound.emit()

func set_visibility(show_health: bool, show_xp: bool, show_weapon: bool, show_inv: bool, show_map: bool) -> void:
	show_health_bar = show_health
	show_xp_bar = show_xp
	show_weapon_info = show_weapon
	show_inventory = show_inv
	show_minimap = show_map
	
	_update_visibility()
	hud_visibility_changed.emit(visible)

func show_hud() -> void:
	visible = true
	hud_visibility_changed.emit(true)

func hide_hud() -> void:
	visible = false
	hud_visibility_changed.emit(false)

func toggle_hud() -> void:
	visible = not visible
	hud_visibility_changed.emit(visible)

func set_update_interval(interval: float) -> void:
	update_interval = interval
	_update_timer()

func get_player_entity() -> Node:
	return player_entity

func is_player_bound() -> bool:
	return player_entity != null

# === STATE MANAGEMENT ===

func _update_visibility() -> void:
	if not is_inside_tree():
		return
	
	_update_health_bar_visibility()
	_update_xp_bar_visibility()
	_update_weapon_info_visibility()
	_update_inventory_visibility()
	_update_minimap_visibility()

func _update_health_bar_visibility() -> void:
	if not is_inside_tree():
		return
	
	health_bar.visible = show_health_bar

func _update_xp_bar_visibility() -> void:
	if not is_inside_tree():
		return
	
	xp_bar.visible = show_xp_bar
	level_label.visible = show_xp_bar

func _update_weapon_info_visibility() -> void:
	if not is_inside_tree():
		return
	
	weapon_card.visible = show_weapon_info

func _update_inventory_visibility() -> void:
	if not is_inside_tree():
		return
	
	inventory_panel.visible = show_inventory

func _update_minimap_visibility() -> void:
	if not is_inside_tree():
		return
	
	minimap_container.visible = show_minimap

func _update_timer() -> void:
	if not is_inside_tree():
		return
	
	update_timer.wait_time = update_interval
	if update_interval > 0:
		update_timer.start()
	else:
		update_timer.stop()

func _update_player_stats() -> void:
	if not player_components.has("experience"):
		return
	
	var exp_component = player_components["experience"]
	
	# Level bilgisini al
	if exp_component.has_method("get_current_level"):
		current_level = exp_component.get_current_level()
	elif "current_level" in exp_component:
		current_level = exp_component.current_level
	
	# XP bilgisini al
	if exp_component.has_method("get_current_experience"):
		current_xp = exp_component.get_current_experience()
	elif "current_experience" in exp_component:
		current_xp = exp_component.current_experience
	
	# Next level XP'yi al
	if exp_component.has_method("get_experience_for_next_level"):
		xp_to_next_level = exp_component.get_experience_for_next_level()
	elif "experience_for_next_level" in exp_component:
		xp_to_next_level = exp_component.experience_for_next_level
	
	# UI'yi güncelle
	level_label.set_text("Level %d" % current_level)
	xp_bar.set_value(current_xp)
	xp_bar.set_range(0.0, xp_to_next_level)
	xp_bar.set_show_percentage(true)

func _update_weapon_info() -> void:
	if not player_components.has("weapon"):
		return
	
	var weapon_component = player_components["weapon"]
	var old_weapon_id = current_weapon_id
	
	# Current weapon ID'yi al
	if weapon_component.has_method("get_current_weapon_id"):
		current_weapon_id = weapon_component.get_current_weapon_id()
	elif "current_weapon_id" in weapon_component:
		current_weapon_id = weapon_component.current_weapon_id
	
	# WeaponCard'ı güncelle
	if current_weapon_id and not current_weapon_id.is_empty():
		weapon_card.load_weapon(current_weapon_id)
		
		# Event emit et
		if old_weapon_id != current_weapon_id:
			weapon_changed.emit(old_weapon_id, current_weapon_id)

func _update_inventory() -> void:
	if not player_components.has("inventory"):
		return
	
	var inventory_component = player_components["inventory"]
	
	# Inventory slot'larını güncelle
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if i < inventory_slots.size():
			# Slot bilgilerini al (simülasyon)
			# Gerçek implementasyonda inventory component'ından alınacak
			slot.set_item("item_" + str(i + 1), i + 1, "common")
	
	inventory_updated.emit()

func _initialize_inventory_slots() -> void:
	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if slot:
			slot.slot_index = i
			slot.hotkey = str(i + 1)  # 1-6 hotkeys
			
			# Slot event'lerini bağla
			slot.slot_clicked.connect(_on_inventory_slot_clicked.bind(i))
			slot.slot_double_clicked.connect(_on_inventory_slot_double_clicked.bind(i))
			slot.slot_right_clicked.connect(_on_inventory_slot_right_clicked.bind(i))

# === EVENT BUS INTEGRATION ===

func _setup_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	# Player events
	EventBus.subscribe_static(EventBus.PLAYER_HEALTH_CHANGED, _on_player_health_changed)
	EventBus.subscribe_static(EventBus.PLAYER_EXPERIENCE_CHANGED, _on_player_experience_changed)
	EventBus.subscribe_static(EventBus.PLAYER_LEVEL_UP, _on_player_level_up)
	
	# Weapon events
	EventBus.subscribe_static(EventBus.WEAPON_CHANGED, _on_weapon_changed)
	EventBus.subscribe_static(EventBus.WEAPON_UPGRADED, _on_weapon_upgraded)
	
	# Inventory events
	EventBus.subscribe_static(EventBus.INVENTORY_CHANGED, _on_inventory_changed)
	EventBus.subscribe_static(EventBus.ITEM_PICKED_UP, _on_item_picked_up)
	
	# Game state events
	EventBus.subscribe_static(EventBus.GAME_PAUSED, _on_game_paused)
	EventBus.subscribe_static(EventBus.GAME_RESUMED, _on_game_resumed)

func _remove_event_bus_subscriptions() -> void:
	if not EventBus.is_available():
		return
	
	EventBus.get_instance().unsubscribe_all_for_object(self)

# === EVENT HANDLERS ===

func _on_update_timer_timeout() -> void:
	if player_entity:
		_update_player_stats()
		_update_weapon_info()
		_update_inventory()

func _on_player_health_changed(event: EventBus.Event) -> void:
	# HealthBar zaten otomatik güncelleniyor
	pass

func _on_player_experience_changed(event: EventBus.Event) -> void:
	_update_player_stats()

func _on_player_level_up(event: EventBus.Event) -> void:
	var old_level = current_level
	_update_player_stats()
	
	if current_level != old_level:
		level_changed.emit(old_level, current_level)
		
		# Level up effect (simülasyon)
		level_label.pulse_color(Color.YELLOW, 1.0)

func _on_weapon_changed(event: EventBus.Event) -> void:
	_update_weapon_info()

func _on_weapon_upgraded(event: EventBus.Event) -> void:
	_update_weapon_info()
	
	# Upgrade effect (simülasyon)
	weapon_card.pulse_color(Color.GREEN, 0.5)

func _on_inventory_changed(event: EventBus.Event) -> void:
	_update_inventory()

func _on_item_picked_up(event: EventBus.Event) -> void:
	_update_inventory()
	
	# Item pickup effect (simülasyon)
	# İlgili slot'u highlight et

func _on_game_paused(event: EventBus.Event) -> void:
	# HUD'ı biraz şeffaflaştır
	modulate = Color(1.0, 1.0, 1.0, 0.7)

func _on_game_resumed(event: EventBus.Event) -> void:
	# HUD'ı normale döndür
	modulate = Color.WHITE

func _on_inventory_slot_clicked(slot_index: int, item_id: String) -> void:
	print("Inventory slot clicked: %d, Item: %s" % [slot_index, item_id])
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "InventorySlot",
			"slot_index": slot_index,
			"item_id": item_id,
			"action": "select"
		})

func _on_inventory_slot_double_clicked(slot_index: int, item_id: String) -> void:
	print("Inventory slot double clicked: %d, Item: %s" % [slot_index, item_id])
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "InventorySlot",
			"slot_index": slot_index,
			"item_id": item_id,
			"action": "use"
		})

func _on_inventory_slot_right_clicked(slot_index: int, item_id: String) -> void:
	print("Inventory slot right clicked: %d, Item: %s" % [slot_index, item_id])
	
	# EventBus'a bildir
	if EventBus.is_available():
		EventBus.emit_now_static(EventBus.UI_BUTTON_CLICKED, {
			"component": "InventorySlot",
			"slot_index": slot_index,
			"item_id": item_id,
			"action": "context_menu"
		})

# === CLEANUP ===

func _exit_tree() -> void:
	_remove_event_bus_subscriptions()
	unbind_from_player()

# === DEBUG ===

func _to_string() -> String:
	var player_name = player_entity.name if player_entity else "Unbound"
	return "[GameHUDOrganism: Player: %s, Level: %d, Weapon: %s]" % [
		player_name,
		current_level,
		current_weapon_id
	]

func print_debug_info() -> void:
	print("=== GameHUDOrganism Debug ===")
	print("Is Initialized: %s" % str(is_initialized))
	print("Player Bound: %s" % str(is_player_bound()))
	print("Player: %s" % (player_entity.name if player_entity else "None"))
	print("Current Level: %d" % current_level)
	print("Current XP: %.1f/%.1f" % [current_xp, xp_to_next_level])
	print("Current Weapon: %s" % current_weapon_id)
	print("Show Health Bar: %s" % str(show_health_bar))
	print("Show XP Bar: %s" % str(show_xp_bar))
	print("Show Weapon Info: %s" % str(show_weapon_info))
	print("Show Inventory: %s" % str(show_inventory))
	print("Show Minimap: %s" % str(show_minimap))
	print("Update Interval: %.2f" % update_interval)
	print("Player Components: %s" % str(player_components.keys()))