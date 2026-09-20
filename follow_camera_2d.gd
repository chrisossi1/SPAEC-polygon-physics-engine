class_name FollowCamera
extends Camera2D

var target:RenderMesh#Node2D#GameObject
var sp = .23

func _process(_delta):
	if not target:return
	var target_pos = target.global_transform * target.pstate.axis
	global_position = global_position*(1.-sp) + target_pos*sp #TODO: How does objectfollower do it?
