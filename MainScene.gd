extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("RESET")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("Entry")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func go_to_stage():
	$AnimationPlayer.play("Go To Stage")
