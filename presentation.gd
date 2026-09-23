extends Node2D
class_name Presentation


@onready var rmeshPool:RenderMeshPool = $RenderMeshPool
@onready var camera:FollowCamera = $Camera2D


# This notification is weird black-box wise because the camera2D needs the object body reference?
class notif_player_updated:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh := pres.rmeshPool.get_render_mesh(object_id)
		pres.camera.target = rmesh
		if not pres.camera.target:
			return -1


class notif_object_created:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.create_render_mesh(object_id)

		var mesh_arrays := shape.triangulate()

		var array_mesh := ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

		rmesh.mesh.mesh = array_mesh

		log = "creating rmesh"



class notif_object_geometry_updated:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.get_render_mesh(object_id)

		var mesh_arrays := shape.triangulate()

		var array_mesh := ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

		rmesh.mesh.mesh = array_mesh
		
		log = "updating rmesh geometry"


class notif_object_color_updated:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.get_render_mesh(object_id)
		rmesh.mesh.modulate = color

class notif_object_destroyed:
	extends notif_object
	func resolve(pres:Presentation):
		pres.rmeshPool.free_render_mesh(object_id)
		log = "freeing rmesh"

class notif_pstate_update:
	extends notif
	var ids:Array[int]=[]
	var local_xforms:Array[Transform2D]=[]
	var pstate:PState
	func _init(body:SolidBody):
		pstate = body.get_axis_pstate()
		pstate.transform = body.space.to_game_transform(pstate.transform)
		for pshape in body.get_physicsShapes():
			var obj:GameObject = pshape._owner
			ids.append(obj.id)
			local_xforms.append(obj.physicsShape.transform)
		
	func resolve(pres:Presentation):
		for i in len(ids):
			var id = ids[i]
			var local_xform = local_xforms[i]
			var rmesh = pres.rmeshPool.get_render_mesh(id)
			if not rmesh:continue
			rmesh.update_pstate(pstate,local_xform)












class notif_object:
	extends notif
	var object_id:int
	var color:Color
	var shape:ClipShape
	func _init(o:GameObject):
		object_id = o.id
		#color = o.color
		shape = o.shape
		
		log_func = o.add_log
	
	var log_func:Callable
	var log := ""
	func add_log(extra = ""):
		if log:
			log_func.call(log+extra)

class notif:pass





''' NOTIF QUEUE '''



var notifications:Array[notif]=[]

func add_notification(n:notif):
	notifications.append(n)

func resolve_notifications():
	var retry:Array[notif]=[]
	for n in notifications:
		var success = n.resolve(self)
		if success == -1:
			retry.append(n)
		if n is notif_object:
			n.add_log("; success = " + str(success!=-1))

	notifications = retry
