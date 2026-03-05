# 🏢 LOBBY MOLECULE BASE
# Lobi molekülü temel sınıfı
class_name LobbyMoleculeBase
extends Control

# === SIGNALS ===
signal lobby_initialized()
signal player_data_updated()
signal game_start_requested(character_id: String, weapon_id: String, flag_id: String)
signal purchase_made(item_type: String, item_id: String, cost: int)
signal navigation_back()

# === STATE ===
var is_initialized: bool = false

# === LIFECYCLE ===

func _ready() -> void:
	if has_node("/root/Log"):
		Log.info("LobbyMoleculeBase: initializing")
	_initialize()
	is_initialized = true
	lobby_initialized.emit()
	if has_node("/root/Log"):
		Log.info("LobbyMoleculeBase: initialized")

# === PUBLIC API ===

func start_game() -> void:
	game_start_requested.emit("", "", "")

func go_back() -> void:
	navigation_back.emit()

func mark_purchase(item_type: String, item_id: String, cost: int) -> void:
	purchase_made.emit(item_type, item_id, cost)

func notify_player_data_updated() -> void:
	player_data_updated.emit()

# === PROTECTED METHODS ===

func _initialize() -> void:
	# Alt sınıflar bu metodu override edecek
	pass

# === DEBUG ===

func print_debug_info() -> void:
	print("=== LobbyMoleculeBase ===")
	print("Initialized: %s" % str(is_initialized))
	print("Class: %s" % get_class())