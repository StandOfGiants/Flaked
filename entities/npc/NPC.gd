class_name NPC

extends KinematicBody

export(StreamTexture) var full_body
export(Resource) var dialog

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var initial_y = translation.y


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite3D.texture = full_body
	pass  # Replace with function body.


var is_near_player = false
var acceleration = -1
var velocity = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	is_near_player = false
	for body in $Area.get_overlapping_bodies():
		if body is Player:
			is_near_player = true
			body.set_near_npc(self)

	if translation.y <= initial_y:
		acceleration = 0
		velocity = 0
		translation.y = initial_y

	if translation.y == initial_y and is_near_player:
		velocity = 1
		acceleration = -5

	velocity += acceleration * delta
	translation.y += velocity * delta

	# $Sprite3D.flip_v = is_near_player
