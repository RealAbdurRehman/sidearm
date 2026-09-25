extends CharacterBody2D

@export_group("Bullet Settings")
@export var speed: float = 1200.0
@export var lifetime: float = 6.0
@export var fall_off: float = 280.0

@export_group("Ricochet Settings")
@export var max_bounces: int = 3
@export var bounce_energy: float = 0.75
@export var ricochet_cutoff: float = 0.75

var direction: Vector2 = Vector2.RIGHT

var _bounces: int = 0
var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_velocity = direction * speed
	rotation = direction.angle()
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	_velocity.y += fall_off * delta
	
	var col := move_and_collide(_velocity * delta)
	if col:
		var normal := col.get_normal()
		var incoming := _velocity.normalized()
		
		var headon := absf(incoming.dot(normal))
		if _bounces < max_bounces and headon < ricochet_cutoff:
			_velocity = _velocity.bounce(normal) * bounce_energy
			rotation = _velocity.angle()
			_bounces += 1
		else:
			queue_free()
