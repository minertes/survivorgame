# 🎵 AUDIO PLAYER POOL (ATOM)
# AudioStreamPlayer pool'larını yönetir
class_name AudioPlayerPool
extends Node

# === POOL CONFIG ===
const DEFAULT_POOL_SIZE: int = 10
const MAX_POOL_SIZE: int = 50
const POOL_GROWTH_FACTOR: float = 1.5

# === POOL TYPES ===
enum PoolType {
	SFX_2D,
	SFX_3D,
	UI_SFX,
	VOICE_2D,
	VOICE_3D
}

# === POOL STRUCTURE ===
var _pools: Dictionary = {}  # PoolType → Array[AudioStreamPlayer]
var _pool_sizes: Dictionary = {}  # PoolType → int
var _active_players: Dictionary = {}  # PoolType → Array[AudioStreamPlayer]
var _player_stats: Dictionary = {}  # player → usage stats

# === SIGNALS ===
signal pool_created(pool_type: PoolType, size: int)
signal player_borrowed(pool_type: PoolType, player: AudioStreamPlayer)
signal player_returned(pool_type: PoolType, player: AudioStreamPlayer)
signal pool_resized(pool_type: PoolType, old_size: int, new_size: int)
signal pool_overflow(pool_type: PoolType, requested: int, available: int)

# === LIFECYCLE ===

func _ready() -> void:
	print("AudioPlayerPool initialized")
	
	# Varsayılan pool'ları oluştur
	_create_default_pools()

# === PUBLIC API ===

func get_player(pool_type: PoolType, is_3d: bool = false) -> Node:
	# Pool'dan bir player al
	if not _pools.has(pool_type):
		_create_pool(pool_type, DEFAULT_POOL_SIZE)
	
	var pool = _pools[pool_type]
	
	# Boş player ara
	for player in pool:
		if not player.playing:
			_borrow_player(player, pool_type)
			return player
	
	# Boş player yoksa, pool'u büyüt
	var new_size = int(_pool_sizes[pool_type] * POOL_GROWTH_FACTOR)
	if new_size > MAX_POOL_SIZE:
		new_size = MAX_POOL_SIZE
	
	if new_size > _pool_sizes[pool_type]:
		_resize_pool(pool_type, new_size)
		pool_overflow.emit(pool_type, 1, _pool_sizes[pool_type])
		
		# Yeniden dene
		return get_player(pool_type, is_3d)
	
	# Hala boş player yoksa, en eski player'ı al
	var oldest_player = pool[0]
	_borrow_player(oldest_player, pool_type)
	return oldest_player

func return_player(player: AudioStreamPlayer) -> void:
	# Player'ı pool'a geri döndür
	player.stop()
	player.stream = null
	
	# Hangi pool'a ait olduğunu bul
	for pool_type in _pools:
		if player in _pools[pool_type]:
			if player in _active_players.get(pool_type, []):
				_active_players[pool_type].erase(player)
			player_returned.emit(pool_type, player)
			return
	
	print("Warning: Player not found in any pool: %s" % player.name)

func create_pool(pool_type: PoolType, size: int = DEFAULT_POOL_SIZE) -> void:
	# Yeni pool oluştur
	_create_pool(pool_type, size)

func resize_pool(pool_type: PoolType, new_size: int) -> void:
	# Pool boyutunu değiştir
	_resize_pool(pool_type, new_size)

func get_pool_size(pool_type: PoolType) -> int:
	# Pool boyutunu al
	return _pool_sizes.get(pool_type, 0)

func get_active_players_count(pool_type: PoolType) -> int:
	# Aktif player sayısını al
	return _active_players.get(pool_type, []).size()

func get_available_players_count(pool_type: PoolType) -> int:
	# Boş player sayısını al
	if not _pools.has(pool_type):
		return 0
	
	var available = 0
	for player in _pools[pool_type]:
		if not player.playing:
			available += 1
	
	return available

func stop_all_players() -> void:
	# Tüm player'ları durdur
	for pool_type in _pools:
		for player in _pools[pool_type]:
			if player.playing:
				player.stop()
				return_player(player)

func stop_players_by_type(pool_type: PoolType) -> void:
	# Belirli tipteki player'ları durdur
	if _pools.has(pool_type):
		for player in _pools[pool_type]:
			if player.playing:
				player.stop()
				return_player(player)

func cleanup_unused_players() -> void:
	# Kullanılmayan player'ları temizle
	for pool_type in _pools:
		var pool = _pools[pool_type]
		var to_remove = []
		
		for player in pool:
			if not player.playing and _get_player_idle_time(player) > 60.0:  # 60 saniye
				to_remove.append(player)
		
		# Ters sırada sil (index kaymasını önlemek için)
		to_remove.reverse()
		for player in to_remove:
			pool.erase(player)
			player.queue_free()
		
		if to_remove.size() > 0:
			var old_size = _pool_sizes[pool_type]
			_pool_sizes[pool_type] = pool.size()
			pool_resized.emit(pool_type, old_size, pool.size())

# === PRIVATE METHODS ===

func _create_default_pools() -> void:
	# Varsayılan pool'ları oluştur
	_create_pool(PoolType.SFX_2D, DEFAULT_POOL_SIZE)
	_create_pool(PoolType.SFX_3D, DEFAULT_POOL_SIZE / 2)
	_create_pool(PoolType.UI_SFX, DEFAULT_POOL_SIZE / 3)
	_create_pool(PoolType.VOICE_2D, DEFAULT_POOL_SIZE / 4)
	_create_pool(PoolType.VOICE_3D, DEFAULT_POOL_SIZE / 5)

func _create_pool(pool_type: PoolType, size: int) -> void:
	# Yeni pool oluştur
	if _pools.has(pool_type):
		print("Pool already exists: %s" % PoolType.keys()[pool_type])
		return
	
	var pool: Array = []
	
	for i in range(size):
		var player = _create_player_for_pool(pool_type)
		if player:
			player.name = "AudioPlayer_%s_%d" % [PoolType.keys()[pool_type], i]
			add_child(player)
			pool.append(player)
			
			# Stats initialize
			_player_stats[player] = {
				"borrow_count": 0,
				"total_play_time": 0.0,
				"last_borrow_time": 0.0,
				"last_return_time": 0.0
			}
	
	_pools[pool_type] = pool
	_pool_sizes[pool_type] = size
	_active_players[pool_type] = []
	
	pool_created.emit(pool_type, size)
	print("Created pool: %s with %d players" % [PoolType.keys()[pool_type], size])

func _create_player_for_pool(pool_type: PoolType) -> Node:
	# Pool tipine göre player oluştur
	match pool_type:
		PoolType.SFX_3D, PoolType.VOICE_3D:
			var player = AudioStreamPlayer3D.new()
			player.max_distance = 50.0
			player.unit_size = 1.0
			player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
			return player
		_:
			return AudioStreamPlayer.new()

func _resize_pool(pool_type: PoolType, new_size: int) -> void:
	# Pool boyutunu değiştir
	if not _pools.has(pool_type):
		return
	
	var pool = _pools[pool_type]
	var current_size = pool.size()
	
	if new_size > current_size:
		# Pool'u büyüt
		for i in range(current_size, new_size):
			var player = _create_player_for_pool(pool_type)
			if player:
				player.name = "AudioPlayer_%s_%d" % [PoolType.keys()[pool_type], i]
				add_child(player)
				pool.append(player)
				
				# Stats initialize
				_player_stats[player] = {
					"borrow_count": 0,
					"total_play_time": 0.0,
					"last_borrow_time": 0.0,
					"last_return_time": 0.0
				}
	else:
		# Pool'u küçült (kullanılmayan player'ları sil)
		var to_remove = []
		var keep_count = new_size
		
		# Önce kullanılmayan player'ları bul
		for player in pool:
			if not player.playing and keep_count > 0:
				to_remove.append(player)
				keep_count -= 1
		
		# Ters sırada sil
		to_remove.reverse()
		for player in to_remove:
			pool.erase(player)
			_player_stats.erase(player)
			player.queue_free()
	
	_pool_sizes[pool_type] = pool.size()
	pool_resized.emit(pool_type, current_size, pool.size())

func _borrow_player(player: AudioStreamPlayer, pool_type: PoolType) -> void:
	# Player'ı ödünç al
	player.stop()
	player.stream = null
	
	if not _active_players.has(pool_type):
		_active_players[pool_type] = []
	
	_active_players[pool_type].append(player)
	
	# Stats güncelle
	var stats = _player_stats.get(player, {}).duplicate()
	stats["borrow_count"] = stats.get("borrow_count", 0) + 1
	stats["last_borrow_time"] = Time.get_ticks_msec() / 1000.0
	_player_stats[player] = stats
	
	player_borrowed.emit(pool_type, player)

func _get_player_idle_time(player: AudioStreamPlayer) -> float:
	# Player'ın boşta kalma süresini al
	var stats = _player_stats.get(player, {})
	var last_return = stats.get("last_return_time", 0.0)
	
	if last_return > 0:
		return (Time.get_ticks_msec() / 1000.0) - last_return
	
	return 0.0

# === DEBUG ===

func get_pool_stats() -> Dictionary:
	# Tüm pool'ların istatistiklerini al
	var stats = {}
	
	for pool_type in _pools:
		var pool = _pools[pool_type]
		var active_count = _active_players.get(pool_type, []).size()
		var available_count = get_available_players_count(pool_type)
		
		stats[PoolType.keys()[pool_type]] = {
			"total_players": pool.size(),
			"active_players": active_count,
			"available_players": available_count,
			"utilization": float(active_count) / float(pool.size()) if pool.size() > 0 else 0.0
		}
	
	return stats

func print_pool_stats() -> void:
	var stats = get_pool_stats()
	print("=== AudioPlayerPool Stats ===")
	
	for pool_name in stats:
		var pool_stats = stats[pool_name]
		print("%s:" % pool_name)
		print("  Total Players: %d" % pool_stats["total_players"])
		print("  Active Players: %d" % pool_stats["active_players"])
		print("  Available Players: %d" % pool_stats["available_players"])
		print("  Utilization: %.1f%%" % (pool_stats["utilization"] * 100))

func _to_string() -> String:
	var total_players = 0
	var active_players = 0
	
	for pool_type in _pools:
		total_players += _pools[pool_type].size()
		active_players += _active_players.get(pool_type, []).size()
	
	return "[AudioPlayerPool: %d/%d players active]" % [active_players, total_players]