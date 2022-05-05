class_name Player

extends KinematicBody

signal out_of_dialog

const MAX_SPEED = 3
const JUMP_SPEED = 5
const ACCELERATION = 2
const DECELERATION = 4

onready var gravity = -ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity: Vector3

var chat_overlay = preload("res://chat_overlay/chat_overlay.tscn")
var general_text = preload("res://entities/player/General.tres")
var running_talk = false


func start_intro():
	run_dialog("begin", general_text)


func end_dialog():
	run_dialog("ending", general_text)


func look_around():
	$AnimationPlayer.play("LookRight")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("LookLeft")


func look_right():
	$AnimationPlayer.play("LookRight")


func look_left():
	$AnimationPlayer.play("LookLeft")


var nearbyNPCs = []


func ensure(error: int):
	if error != 0:
		print("FAILED TO CONNECT: ", error)


func inform_of_npc(npc: NPC):
	ensure(npc.connect("can_converse", self, "on_can_converse"))
	ensure(npc.connect("cannot_converse", self, "on_cannot_converse"))


func on_can_converse(npc: NPC):
	if not npc in nearbyNPCs:
		nearbyNPCs.push_back(npc)


func on_cannot_converse(npc: NPC):
	if npc in nearbyNPCs:
		nearbyNPCs.remove(nearbyNPCs.find(npc))


func _on_Stage_player_enter():
	run_dialog("on_stage", general_text)


func run_dialog(id: String, resource: DialogResource):
	var dialog = yield(DialogManager.get_next_dialog_line(id, resource), "completed")
	if dialog != null:
		var overlay = chat_overlay.instance()
		overlay.dialog = dialog
		add_child(overlay)
		run_dialog(yield(overlay, "actioned"), resource)
	else:
		emit_signal("out_of_dialog")


var no_dialog_frames = 0


func in_dialog() -> bool:
	return no_dialog_frames <= 5


func _process(_delta):
	if has_node("ChatOverlay"):
		no_dialog_frames = 0
	else:
		no_dialog_frames += 1

	if not nearbyNPCs.empty() and Input.is_action_just_pressed("ui_accept") and not in_dialog():
		var nearestNPC = nearbyNPCs[0]
		if nearestNPC.call:
			$SFX.stream = nearestNPC.call
			$SFX.play()
		run_dialog("begin", nearestNPC.dialog)

	if Input.is_action_just_pressed("pause") and not in_dialog():
		get_tree().paused = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Don't do any movement while chat overlay is open.
	if in_dialog():
		velocity = Vector3()
		$AnimatedSprite3D.play("default")
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
		$AnimatedSprite3D.rotation.y = lerp($AnimatedSprite3D.rotation.y, PI, .25)
	elif velocity.x < -0.1:
		$AnimatedSprite3D.rotation.y = lerp($AnimatedSprite3D.rotation.y, 0, .25)

	if velocity.length_squared() > 0.1:
		$AnimatedSprite3D.play("Walk")
	else:
		$AnimatedSprite3D.play("default")


func _on_Footstep_Timer_timeout():
	if velocity.length_squared() > 0.1:
		$WalkingSound.play()
