extends RigidBody2D

@export var ammo: int = 1
@export var texture_override: Texture2D

@export_group("Physics")
@export var linear_damp_amount: float = 1.5
@export var magnet_delay: float = 0.4

@export_group("Magnet")
@export var magnet_speed: float = 550.0
@export var magnet_accel: float = 1800.0
@export var abandoned_timeout: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var pickup_area: Area2D = $PickupArea
@onready var collect_area: Area2D = $CollectArea

var magnet_delay_override: float = -1.0

var _player: Node2D = null
var _is_magnetized: bool = false
var _can_magnetize: bool = false

func _ready() -> void:
	if texture_override:
		sprite.texture = texture_override
	
	can_sleep = true
	lock_rotation = true 
	linear_damp = linear_damp_amount
	
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	collect_area.body_entered.connect(_on_collect_area_body_entered)
	
	var delay := magnet_delay_override if magnet_delay_override > 0.0 else magnet_delay
	await get_tree().create_timer(delay).timeout
	
	if not is_inside_tree(): return 
	
	_can_magnetize = true
	
	for body in pickup_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_pickup_area_body_entered(body)
			
			break 
	
	for body in collect_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			_on_collect_area_body_entered(body)
			
			break
	
	_start_abandoned_timer()

func _start_abandoned_timer() -> void:
	await get_tree().create_timer(abandoned_timeout).timeout
	
	if not is_inside_tree(): return
	if _is_magnetized: return
	
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if player.ammo >= player.max_ammo:
		queue_free()
		return
	
	_force_magnetize(player)

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _can_magnetize:
		_force_magnetize(body)

func _on_collect_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_ammo(ammo)
		queue_free()

func _physics_process(delta: float) -> void:
	if not _is_magnetized:
		return
	
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not _player:
			return
	
	var to_player := _player.global_position - global_position
	var target_vel := to_player.normalized() * magnet_speed
	
	linear_velocity = linear_velocity.move_toward(target_vel, magnet_accel * delta)
	sprite.rotation += 15.0 * delta

func _force_magnetize(player: Node2D) -> void:
	_player = player
	_is_magnetized = true
	
	sleeping = false
	collision_layer = 8
	collision_mask = 8
