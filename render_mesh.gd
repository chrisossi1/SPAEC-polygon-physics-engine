extends Node2D
class_name RenderMesh
@onready var mesh:MeshInstance2D = $MeshInstance2D

var pstate:PState.axis_PState
var local_xform:Transform2D
var t:float = 0.

func update_pstate(_pstate:PState.axis_PState, _local_xform:Transform2D):
	pstate = _pstate
	local_xform = _local_xform
	t = 0.


var pframe_duration = 1./Engine.physics_ticks_per_second
func _process(_delta):
	if not pstate:return
	t += _delta
	var body_transform = pstate.project_transform(t-pframe_duration)
	global_transform = local_xform * body_transform
