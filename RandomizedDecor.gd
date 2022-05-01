tool
extends RigidBody

export var seed_value = 10 setget set_seed
var random = RandomNumberGenerator.new()


func set_seed(seed_in):
	seed_value = seed_in
	showhide_items()


func showhide_items():
	random.set_seed(seed_value)
	for child in $decor.get_children():
		if random.randi() % 5 == 0:
			child.visible = true
			if "collision_layer" in child:
				child.collision_layer = 1
				child.collision_mask = 1
		else:
			child.visible = false
			if "collision_layer" in child:
				child.collision_layer = 0
				child.collision_mask = 0


func _ready():
	showhide_items()
