tool
class_name NPC

extends KinematicBody

export(StreamTexture) var full_body setget set_sprite_texture
export(Resource) var dialog
export(AudioStream) var call

signal can_converse(npc)
signal cannot_converse(npc)

onready var initial_y = translation.y
var player
var was_near_player = false
var acceleration = -1
var velocity = 0


func set_sprite_texture(tex: StreamTexture):
	full_body = tex
	$Sprite3D.texture = full_body


func _ready():
	$Sprite3D.texture = full_body

	if not Engine.editor_hint:
		player = get_parent().get_parent().get_node("Player")
		if player:
			player.inform_of_npc(self)


func _process(delta):
	if Engine.editor_hint:
		return

	var is_near_player = $Area.overlaps_body(player)
	if is_near_player and not was_near_player:
		emit_signal("can_converse", self)
	if not is_near_player and was_near_player:
		emit_signal("cannot_converse", self)
	was_near_player = is_near_player

	if translation.y <= initial_y:
		acceleration = 0
		velocity = 0
		translation.y = initial_y

	if translation.y == initial_y and is_near_player:
		velocity = 1
		acceleration = -5

	velocity += acceleration * delta
	translation.y += velocity * delta
