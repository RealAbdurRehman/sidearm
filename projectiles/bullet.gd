extends CharacterBody2D

@export_group("Bullet Settings")
@export var speed: float = 1200.0
@export var lifetime: float = 6.0
@export var fall_off: float = 280.0

@export_group("Ricochet Settings")
@export var max_bounces: int = 3
@export var bounce_energy: float = 0.75
@export var ricochet_cutoff: float = 0.75

const PICKUP: PackedScene = preload("res://pickups/pickup.tscn")

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
		var collider := col.get_collider()
		
		if collider and collider.is_in_group("enemies"):
			if collider.has_method("take_damage"):
				collider.take_damage(10)
			
			_die()
			
			return
		
		var normal := col.get_normal()
		var incoming := _velocity.normalized()
		var headon := absf(incoming.dot(normal))
		
		if _bounces < max_bounces and headon < ricochet_cutoff:
			_velocity = _velocity.bounce(normal) * bounce_energy
			rotation = _velocity.angle()
			_bounces += 1
		else:
			_die()

func _die() -> void:
	var p := PICKUP.instantiate()
	p.global_position = global_position
	
	get_tree().current_scene.add_child(p)
	
	var eject_dir = -_velocity.normalized()
	eject_dir.y -= 0.5
	
	p.linear_velocity = eject_dir.normalized() * randf_range(150, 250)
	
	queue_free()
