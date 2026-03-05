# Faz 2.1.2 – Nesne havuzlama: mermi havuzu (object pooling)
# Sık spawn/despawn edilen mermileri yeniden kullanır, GC baskısını azaltır.
class_name BulletPool
extends Node

const BULLET_SCENE = preload("res://bullet.tscn")

var _available: Array[Node] = []
var _in_use: Array[Node] = []
var _parent: Node2D
var _initial_size := 24
var _max_pool_size := 120

signal bullet_released(bullet: Node)


func _ready() -> void:
	pass


func setup(parent: Node2D, initial_size: int = 24, max_size: int = 120) -> void:
	_parent = parent
	_initial_size = initial_size
	_max_pool_size = max_size
	for i in _initial_size:
		var b := _create_bullet()
		if b:
			_available.append(b)


func get_bullet() -> Node:
	# Önce geçerli mermi ara — freed referans ataması hatayı tetikler
	var b: Node = null
	for i in range(_available.size() - 1, -1, -1):
		if is_instance_valid(_available[i]):
			b = _available[i]
			_available.remove_at(i)
			break
		else:
			_available.remove_at(i)
	if b == null:
		b = _create_bullet()
	if b and is_instance_valid(b):
		_in_use.append(b)
		if b.has_method("set_from_pool"):
			b.set_from_pool(true)
		if b.has_method("restart_timer"):
			b.restart_timer()
	return b


func release_bullet(bullet: Node) -> void:
	if not is_instance_valid(bullet):
		return
	if bullet not in _in_use:
		return
	_in_use.erase(bullet)
	if _available.size() >= _max_pool_size:
		bullet.queue_free()
		return
	# Devre dışı bırak, havuzda tut
	bullet.visible = false
	bullet.set_deferred("position", Vector2(1e5, 1e5))
	bullet.set_deferred("collision_layer", 0)
	bullet.set_deferred("collision_mask", 0)
	_available.append(bullet)
	bullet_released.emit(bullet)


func _create_bullet() -> Node:
	var b := BULLET_SCENE.instantiate()
	_parent.add_child(b)
	b.visible = false
	b.position = Vector2(1e5, 1e5)
	b.collision_layer = 0
	b.collision_mask = 0
	if not b.bullet_finished.is_connected(_on_bullet_finished):
		b.bullet_finished.connect(_on_bullet_finished)
	return b


func _on_bullet_finished(bullet: Node) -> void:
	release_bullet(bullet)


func get_pool_stats() -> Dictionary:
	return {
		"available": _available.size(),
		"in_use": _in_use.size(),
		"total": _available.size() + _in_use.size()
	}
