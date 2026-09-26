extends CanvasLayer

@onready var ammo_label: Label = $AmmoLabel

func _ready() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.ammo_changed.connect(_on_ammo_changed)
		_on_ammo_changed(player.ammo, player.max_ammo)

func _on_ammo_changed(new_ammo: int, max_ammo: int):
	ammo_label.text = "%d / %d" % [new_ammo, max_ammo]
	
	if new_ammo == 0: ammo_label.modulate = Color(1.0, 0.3, 0.3)
	elif new_ammo <= 6: ammo_label.modulate = Color(1.0, 0.8, 0.3)
	else: ammo_label.modulate = Color(1.0, 1.0, 1.0)
