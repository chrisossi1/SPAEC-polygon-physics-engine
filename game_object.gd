class_name GameObject

var name := ""
var id:int
var geometry:GeometryData

var physicsShape:PhysicsShape

var components:Components

var saved_pstate:PState



class Components:

	var _owner: GameObject
	var _data: Dictionary = {}
	func _init(owner: GameObject) -> void:
		_owner = owner
	func add(component: Component) -> void:
		var type := component.get_type()
		if _data.has(type):
			remove(_data[type])
		_data[type] = component
		component.attach_to_object(_owner)
	func remove(component: Component) -> void:
		var type := component.get_type()
		if _data.get(type) != component:
			return
		_data.erase(type)
		component.detach_from_object()
	func get_component(type: String) -> Component:
		return _data.get(type)
	func get_components() -> Array:
		return _data.values()


class InitData:
	var shape:ClipShape
	var name:String
	var pstate:PState
	func _init(n:String,s:ClipShape,p:PState):
		name = n
		shape = s
		pstate = p


static func initialize_object(ws:WorldState, i:InitData) -> GameObject:
	# Initialize object
	# Initialize geometry
	var o = GameObject.new()
	o.name = i.name
	o.geometry = GeometryData.new()
	o.geometry.shape = i.shape
	o.saved_pstate = i.pstate
	o.components = Components.new(o)
	o.id = ws.get_uuid()
	ws.objects.append(o)
	
	return o


# Builds the object in a standalone body
static func build_object(ws:WorldState, o:GameObject):
	assert(o.geometry)
	assert(o.geometry.shape)
	# Initialize physicsShape
	o.physicsShape = PhysicsShape.new()
	o.physicsShape.object = o
	o.physicsShape.body = ws.solidBodyManager.get_body(ws)
	o.physicsShape.body.physicsShapes.append(o.physicsShape)
	o.physicsShape.body.set_pstate(o.saved_pstate)
	

	o.physicsShape.collisionMap = CollisionShapeMap.new()
	o.physicsShape.update_collision_map(o.geometry.shape)










static func from_query_result(result:Dictionary) -> GameObject:
	var body = result["collider"]
	var shape_idx = result["shape"]
	var body_shape_owner_id = body.shape_find_owner(shape_idx)
	var cpoly = body.shape_owner_get_owner(body_shape_owner_id)
	if not cpoly:return
	assert(cpoly is CollisionPolygon2D_)
	cpoly = cpoly as CollisionPolygon2D_
	var obj = cpoly.physicsShape.object
	assert(obj)
	return obj
