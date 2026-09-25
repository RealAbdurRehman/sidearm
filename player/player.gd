extends CharacterBody2D

@export_group("Gun Settings")
@export var recoil: float = 400.0
@export var damping: float = 2.8 
@export var max_speed: float = 800.0
@export var max_upward_velocity: float = 480.0 
@export var fire_rate: float = 6.0
@export var spread_degrees: float = 4.0

@export_group("Gravity Settings")
@export var gravity: float = 600.0
@export var terminal_velocity: float = 500.0
@export var restitution: float = 0.3

@onready var muzzle: Marker2D = $Muzzle

const BULLET: PackedScene = preload("res://projectiles/bullet.tscn")

var _cooldown: float = 0.0
var can_fire: bool = true

func _physics_process(delta: float) -> void:
	if velocity.y < terminal_velocity:
		velocity.y = minf(velocity.y + gravity * delta, terminal_velocity)
	
	velocity.x *= exp(-damping * delta)
	
	if velocity.y > terminal_velocity:
		var excess := velocity.y - terminal_velocity
		excess *= exp(-damping * delta)
		
		velocity.y = terminal_velocity + excess
	
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	var col := move_and_collide(velocity * delta)
	if col:
		var normal := col.get_normal()
		velocity -= (1.0 + restitution) * velocity.dot(normal) * normal

func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta)
	
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 1.0:
		rotation = aim.angle()
	
	if can_fire and _cooldown <= 0.0 and Input.is_action_just_pressed("shoot"):
		_fire()

func _fire() -> void:
	_cooldown = 1.0 / fire_rate
	
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	
	var spread_rad := deg_to_rad(spread_degrees)
	var offset := randf_range(-spread_rad, spread_rad)
	var bullet_dir := Vector2.RIGHT.rotated(rotation + offset)
	
	var b := BULLET.instantiate()
	b.global_position = muzzle.global_position
	b.direction = bullet_dir
	
	get_tree().current_scene.add_child(b)
	
	velocity -= aim_dir * recoil
	if velocity.y < -max_upward_velocity:
		velocity.y = -max_upward_velocity
