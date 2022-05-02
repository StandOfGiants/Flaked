extends Spatial


func _process(_delta):
	var player_inside = false
	for body in $OnStage.get_overlapping_bodies():
		if body is Player:
			player_inside = true

	get_tree().call_group("player", "is_inside", "stage", player_inside)
