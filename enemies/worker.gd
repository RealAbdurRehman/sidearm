extends CharacterBody2D

@export_group("Movement")
@export var speed: float = 120.0
@export var acceleration: float = 900.0

@export_group("Gravity")
@export var gravity: float = 980.0
@export var terminal_velocity: float = 500.0

@export_group("Health")
@export var health: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var touch_area: Area2D = $TouchArea

var _player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	_player = get_tree().get_first_node_in_group("player")
	
	touch_area.body_entered.connect(_on_touch_body_entered)

func _physics_process(delta: float) -> void:
	if velocity.y < terminal_velocity:
		velocity.y = minf(velocity.y + gravity * delta, terminal_velocity)
	
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	
	if _player:
		var x_diff := _player.global_position.x - global_position.x
		var target_x := signf(x_diff) * speed if absf(x_diff) > 4.0 else 0.0
		velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
		
		if absf(velocity.x) > 5.0:
			sprite.flip_h = velocity.x < 0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	
	move_and_slide()

func _on_touch_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.capture()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()
