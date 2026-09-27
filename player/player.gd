extends CharacterBody2D

signal ammo_changed(new_ammo: int, max_ammo: int)

@export_group("Gun Settings")
@export var recoil: float = 460.0
@export var damping: float = 2.8 
@export var max_speed: float = 800.0
@export var max_upward_velocity: float = 480.0 
@export var fire_rate: float = 6.0
@export var spread_degrees: float = 4.0

@export_group("Gravity Settings")
@export var gravity: float = 980.0
@export var terminal_velocity: float = 500.0
@export var restitution: float = 0.3

@export_group("Ammo")
@export var max_ammo: int = 12
@export var dry_fire_mult: float = 0.25

@export_group("Visual Recoil")
@export var kickback: float = 13.0
@export var kick_rotation_deg: float = -15.0
@export var kick_recovery: float = 9.0

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D

const BULLET: PackedScene = preload("res://projectiles/bullet.tscn")
const PICKUP: PackedScene = preload("res://pickups/pickup.tscn")

const MERCY_TEXTURE: Texture2D = preload("res://assets/pickups/ammo.png")

var ammo: int = 0
var can_fire: bool = true

var _cooldown: float = 0.0

var _kick_rotation: float = 0.0
var _kick_offset: Vector2 = Vector2.ZERO
var _sprite_base_pos: Vector2 = Vector2.ZERO

var _mercy_dropped: bool = false

func _ready() -> void:
	_sprite_base_pos = sprite.position
	
	ammo = max_ammo
	add_to_group("player")
	
	ammo_changed.emit.call_deferred(ammo, max_ammo)

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
	
	_kick_offset = _kick_offset.lerp(Vector2.ZERO, kick_recovery * delta)
	_kick_rotation = lerpf(_kick_rotation, 0.0, kick_recovery * delta)
	
	sprite.position = _sprite_base_pos + _kick_offset
	sprite.rotation = _kick_rotation
	
	var aim := get_global_mouse_position() - global_position
	if aim.length_squared() > 1.0:
		rotation = aim.angle()
	
	if can_fire and _cooldown <= 0.0 and Input.is_action_just_pressed("shoot"):
		_fire()

func _fire() -> void:
	_cooldown = 1.0 / fire_rate
	
	var aim_dir := Vector2.RIGHT.rotated(rotation)
	
	if ammo > 0:
		ammo -= 1
		
		var spread_rad := deg_to_rad(spread_degrees)
		var offset := randf_range(-spread_rad, spread_rad)
		var bullet_dir := Vector2.RIGHT.rotated(rotation + offset)
		
		var b := BULLET.instantiate()
		b.global_position = muzzle.global_position
		b.direction = bullet_dir
		
		get_tree().current_scene.add_child(b)
		
		velocity -= aim_dir * recoil
		
		_kick_offset.x -= kickback
		_kick_rotation += deg_to_rad(kick_rotation_deg)
		
		ammo_changed.emit(ammo, max_ammo)
		
		if ammo == 0 and not _mercy_dropped:
			_spawn_mercy_drop()
			_mercy_dropped = true
	else:
		velocity -= aim_dir * recoil * dry_fire_mult
		
		_kick_offset.x -= kickback * dry_fire_mult
		_kick_rotation += deg_to_rad(kick_rotation_deg) * dry_fire_mult
	
	if velocity.y < -max_upward_velocity:
		velocity.y = -max_upward_velocity

func _spawn_mercy_drop() -> void:
	var p := PICKUP.instantiate()
	p.texture_override = MERCY_TEXTURE
	p.global_position = global_position + Vector2(0, -40)
	
	p.linear_velocity = Vector2(
		randf_range(-180, 180),
		randf_range(-560, -420)
	)
	
	p.magnet_delay_override = 1.2
	
	var roll := randf()
	if roll < 0.2: p.ammo = 1
	elif roll < 0.7: p.ammo = 2
	else: p.ammo = 3
	
	get_tree().current_scene.add_child(p)

func add_ammo(amount: int) -> void:
	ammo = mini(ammo + amount, max_ammo)
	ammo_changed.emit(ammo, max_ammo)
	
	if ammo >= max_ammo / 2.0:
		_mercy_dropped = false
