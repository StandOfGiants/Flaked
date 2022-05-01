class_name Player

extends KinematicBody

const MAX_SPEED = 3
const JUMP_SPEED = 5
const ACCELERATION = 2
const DECELERATION = 4

onready var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity: Vector3

var chat_overlay = preload("res://chat_overlay/chat_overlay.tscn")
var running_talk = false


func run_dialog(id: String, resource: DialogResource):
	var dialog = yield(DialogManager.get_next_dialog_line(id, resource), "completed")
	if dialog != null:
		var overlay = chat_overlay.instance()
		overlay.dialog = dialog
		add_child(overlay)
		run_dialog(yield(overlay, "actioned"), resource)


func _process(_delta):
	if (
		nearestNPC != null
		and Input.is_action_just_pressed("ui_select")
		and not has_node("ChatOverlay")
	):
		run_dialog("begin", nearestNPC.dialog)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Don't do any movement while chat overlay is open.
	if has_node("ChatOverlay"):
		velocity = Vector3()
		return

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

	if velocity.x > 0.1:
		$Sprite3D.rotation.y = lerp($Sprite3D.rotation.y, PI, .25)
	elif velocity.x < -0.1:
		$Sprite3D.rotation.y = lerp($Sprite3D.rotation.y, 0, .25)


var nearestNPC = null


func set_near_npc(npc):
	nearestNPC = npc
