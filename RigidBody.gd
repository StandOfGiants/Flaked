extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_SPEED = 3
const JUMP_SPEED = 5
const ACCELERATION = 2
const DECELERATION = 4

onready var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity: Vector3


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dir = Vector3()
	dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	dir.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")

	if dir.length_squared() > 1:
		dir /= dir.length()

	velocity.y += delta * gravity

	var hvel = velocity
	hvel.y = 0

	var target = dir * MAX_SPEED
	var acceleration
	if dir.dot(hvel) > 0:
		acceleration = ACCELERATION
	else:
		acceleration = DECELERATION

	hvel = hvel.linear_interpolate(target, acceleration * delta)

	velocity.x = hvel.x
	velocity.z = hvel.z
	velocity = move_and_slide(velocity, Vector3.UP)

	if velocity.x > 0:
		$Sprite3D.rotation.y = lerp($Sprite3D.rotation.y, 0, .25)
	else:
		$Sprite3D.rotation.y = lerp($Sprite3D.rotation.y, PI, .25)
