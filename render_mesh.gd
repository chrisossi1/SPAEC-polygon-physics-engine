extends Node2D
class_name RenderMesh
@onready var mesh:MeshInstance2D = $MeshInstance2D

var pstate:PState
var local_xform:Transform2D
var t:float = 0.

func update_pstate(_pstate:PState, _local_xform:Transform2D):
	pstate = _pstate
	_local_xform = _local_xform
	t = 0.


func _process(delta):
	if not pstate:return
	t += delta
	var body_transform = pstate.project_transform(t)
	global_transform = local_xform * body_transform
