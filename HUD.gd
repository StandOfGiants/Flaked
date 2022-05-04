extends Control


func ensure(error: int):
	if error != 0:
		print("Failed to connect signal: ", error)


func _ready():
	ensure(GameState.connect("update_beers", self, "_on_update_beers"))
	ensure(GameState.connect("update_money", self, "_on_update_money"))

	$Money.text = "Money: $%d" % GameState.get_money()
	$Beers.text = "Beers: %d" % GameState.get_beers()


func _on_update_beers(beers: int):
	$Beers.text = "Beers: %d" % beers


func _on_update_money(money: int):
	$Money.text = "Money: $%d" % money
