tool
class_name AnyCharacter

extends Spatial

export(String, "NONE", "Player", "Benny", "Don", "Kat", "Sarah", "TonyMacaroni", "Troy") var who = "Player" setget set_who


func set_who(new_who: String):
	who = new_who
	if has_node("Sprites"):
		for child in $Sprites.get_children():
			if child.name == who:
				child.visible = true
			else:
				child.visible = false


func _ready():
	set_who(who)
	$AnimationPlayer.play("Sway")
