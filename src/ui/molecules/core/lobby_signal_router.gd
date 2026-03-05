# 🏢 LOBBY SIGNAL ROUTER
# Lobi sinyal yönlendirici (class_name kaldırıldı — Windows "hides" önlemi)
extends Node

# === COMPONENT REFERENCES ===
var character_selector = null
var weapon_selector = null
var flag_selector = null
var player_data_manager: Node = null

# === SIGNAL CONNECTIONS ===
var signal_connections: Array = []

# === PUBLIC API ===

func setup_signal_routing(components: Dictionary, data_manager: Node) -> void:
	print("🔌 Setting up signal routing...")
	
	# Component referanslarını al
	character_selector = components.get("character_selector")
	weapon_selector = components.get("weapon_selector")
	flag_selector = components.get("flag_selector")
	player_data_manager = data_manager
	
	# Signal'leri bağla
	_connect_atomic_signals()
	
	print("✅ Signal routing setup completed")

func disconnect_all_signals() -> void:
	print("🔌 Disconnecting all signals...")
	
	for conn in signal_connections:
		if conn is Dictionary:
			var src = conn.get("source")
			var sig = conn.get("signal")
			var cb = conn.get("callback")
			if is_instance_valid(src) and sig and cb:
				if src.has_signal(sig):
					src.disconnect(sig, cb)
	
	signal_connections.clear()
	print("✅ All signals disconnected")

# === PRIVATE METHODS ===

func _connect_atomic_signals() -> void:
	print("🔗 Connecting atomic component signals...")
	
	# CharacterSelectorAtom sinyalleri
	if character_selector:
		_connect_signal(character_selector, "character_selected", _on_character_selected)
		_connect_signal(character_selector, "character_purchased", _on_character_purchased)
		print("✅ CharacterSelector signals connected")
	
	# WeaponSelectorAtom sinyalleri
	if weapon_selector:
		_connect_signal(weapon_selector, "weapon_selected", _on_weapon_selected)
		_connect_signal(weapon_selector, "weapon_purchased", _on_weapon_purchased)
		_connect_signal(weapon_selector, "weapon_upgraded", _on_weapon_upgraded)
		print("✅ WeaponSelector signals connected")
	
	# FlagSelectorAtom sinyalleri
	if flag_selector:
		_connect_signal(flag_selector, "flag_selected", _on_flag_selected)
		_connect_signal(flag_selector, "flag_purchased", _on_flag_purchased)
		print("✅ FlagSelector signals connected")

func _connect_signal(source: Object, signal_name: String, callback: Callable) -> void:
	if source.has_signal(signal_name):
		var connection = source.connect(signal_name, callback)
		if connection != OK:
			print("❌ Failed to connect signal: %s" % signal_name)
		else:
			signal_connections.append({
				"source": source,
				"signal": signal_name,
				"callback": callback
			})
	else:
		print("⚠️ Signal not found: %s" % signal_name)

# === EVENT HANDLERS ===

func _on_character_selected(character_id: String) -> void:
	print("🔗 Signal: Character selected: %s" % character_id)
	if player_data_manager:
		player_data_manager.select_character(character_id)

func _on_character_purchased(character_id: String) -> void:
	print("🔗 Signal: Character purchased: %s" % character_id)
	if character_selector and player_data_manager:
		var cost = character_selector.get_character_cost(character_id)
		player_data_manager.purchase_character(character_id, cost)

func _on_weapon_selected(weapon_id: String) -> void:
	print("🔗 Signal: Weapon selected: %s" % weapon_id)
	if player_data_manager:
		player_data_manager.select_weapon(weapon_id)

func _on_weapon_purchased(weapon_id: String) -> void:
	print("🔗 Signal: Weapon purchased: %s" % weapon_id)
	if weapon_selector and player_data_manager:
		var cost = weapon_selector.get_weapon_cost(weapon_id)
		player_data_manager.purchase_weapon(weapon_id, cost)

func _on_weapon_upgraded(weapon_id: String, new_level: int) -> void:
	print("🔗 Signal: Weapon upgraded: %s to level %d" % [weapon_id, new_level])
	if weapon_selector and player_data_manager:
		var cost = weapon_selector.get_upgrade_cost(weapon_id)
		player_data_manager.upgrade_weapon(weapon_id, cost)

func _on_flag_selected(flag_id: String) -> void:
	print("🔗 Signal: Flag selected: %s" % flag_id)
	if player_data_manager:
		player_data_manager.select_flag(flag_id)

func _on_flag_purchased(flag_id: String) -> void:
	print("🔗 Signal: Flag purchased: %s" % flag_id)
	if flag_selector and player_data_manager:
		var cost = flag_selector.get_flag_cost(flag_id)
		player_data_manager.purchase_flag(flag_id, cost)

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbySignalRouter Debug ===")
	print("Component References:")
	print("  Character Selector: %s" % ("Available" if character_selector else "Not Available"))
	print("  Weapon Selector: %s" % ("Available" if weapon_selector else "Not Available"))
	print("  Flag Selector: %s" % ("Available" if flag_selector else "Not Available"))
	print("  Player Data Manager: %s" % ("Available" if player_data_manager else "Not Available"))
	
	print("\nSignal Connections: %d" % signal_connections.size())
	for i in range(signal_connections.size()):
		var conn = signal_connections[i]
		print("  %d. %s → %s" % [i + 1, conn.get("signal", "Unknown"), 
			conn.get("source", "Unknown").get_class() if conn.get("source") else "Unknown"])