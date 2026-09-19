class_name FollowCamera
extends Camera2D

var target:Node2D#GameObject
var sp = .15
var obj_offset:Vector2

func _process(_delta):
	if not target:return
	var target_pos = target.global_transform * obj_offset
	global_position = global_position*(1.-sp) + target_pos*sp #TODO: How does objectfollower do it?
