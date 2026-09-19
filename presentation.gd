extends Node2D
class_name Presentation


@onready var rmeshPool:RenderMeshPool = $RenderMeshPool
@onready var camera:FollowCamera = $Camera2D


# This notification is weird black-box wise because the camera2D needs the object body reference?
class notif_player_updated:
	extends notif
	var object:GameObject
	func resolve(pres:Presentation):
		pres.camera.target = object.physicsShape.body


class notif_object_created:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.create_render_mesh(object_id)

		var mesh_arrays := shape.triangulate()

		var array_mesh := ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

		rmesh.mesh.mesh = array_mesh



class notif_object_geometry_updated:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.get_render_mesh(object_id)

		var mesh_arrays := shape.triangulate()

		var array_mesh := ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

		rmesh.mesh.mesh = array_mesh


class notif_object_color_updated:
	extends notif_object
	func resolve(pres:Presentation):
		var rmesh = pres.rmeshPool.get_render_mesh(object_id)
		rmesh.mesh.modulate = color

class notif_object_destroyed:
	extends notif_object
	func resolve(pres:Presentation):
		pres.rmeshPool.free_render_mesh(object_id)



class notif_pstate_update:
	extends notif
	var ids:Array[int]=[]
	var local_xforms:Array[Transform2D]=[]
	var pstate:PState
	func _init(body:SolidBody):
		pstate = body.get_pstate()
		for pshape in body.get_physicssShapes():
			var obj:GameObject = pshape.object
			ids.append(obj.id)
			local_xforms.append(obj.physicsShape.transform)
		
	func resolve(pres:Presentation):
		for i in len(ids):
			var id = ids[i]
			var local_xform = local_xforms[i]
			var rmesh = pres.rmeshPool.get_render_mesh(id)
			rmesh.update_pstate(pstate,local_xform)



class notif_object:
	extends notif
	var object_id:int
	var color:Color
	var shape:ClipShape
	func _init(o:GameObject):
		object_id = o.id
		#color = o.color
		shape = o.geometry.shape

class notif:pass





''' NOTIF QUEUE '''



var notifications:Array[notif]=[]

func add_notification(n:notif):
	notifications.append(n)

func resolve_notifications():
	for n in notifications:
		n.resolve(self)
	notifications = []
