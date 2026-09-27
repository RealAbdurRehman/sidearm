extends Node2D

@export var worker_scene: PackedScene
@export var spawn_interval: float = 1.0
@export var initial_delay: float = 2.0

var _current_worker: Node = null

func _ready() -> void:
	await get_tree().create_timer(initial_delay).timeout
	_spawn()

func _spawn() -> void:
	if _current_worker and is_instance_valid(_current_worker):
		return
	
	_current_worker = worker_scene.instantiate()
	_current_worker.global_position = global_position
	get_tree().current_scene.add_child(_current_worker)
	
	_current_worker.tree_exiting.connect(_on_worker_died)

func _on_worker_died() -> void:
	_current_worker = null
	await get_tree().create_timer(spawn_interval).timeout
	
	_spawn()
