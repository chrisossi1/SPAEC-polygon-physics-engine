class_name GameObject

# UNREGISTERED
var name := ""
var shape:ClipShape
var components:Components
var saved_pstate:PState

# REGISTERED
var id:int

# BUILT
var geometry:GeometryData
var physicsShape:PhysicsShape


var state:STATE=STATE.UNREGISTERED

enum STATE {UNREGISTERED, REGISTERED, BUILT, ACTIVE}


var log:=[]
func add_log(s:String):
	log.append( str(Engine.get_process_frames()) +": "+ s )



static func register_object(ws:WorldState, o:GameObject):
	o.add_log("REGISTERING OBJ")

	assert(o.state == GameObject.STATE.UNREGISTERED)
	o.state = GameObject.STATE.REGISTERED
	o.id = ws.get_uuid()
	ws.objects.append(o)
	ws.chunkMap.save_object(o)
	if o.components:
		ws.has_components.append(o)





# Builds the object in a standalone body. Todo: Pass in a Body argument
static func build_object(o:GameObject, body:SolidBody):
	o.add_log("BUILDING OBJ")

	assert(o.state == GameObject.STATE.REGISTERED)
	o.state = GameObject.STATE.BUILT
	
	# Calculate geometry
	o.geometry = GeometryData.new() # TODO: 2 many extra layers ??
	o.geometry.contour = GeometryData.calculate_contour(o.shape)

	# Initialize physicsShape + body
	o.physicsShape = PhysicsShape.new(o)
	o.physicsShape.body = body
	o.physicsShape.body.physicsShapes.append(o.physicsShape)
	var transformed_pstate = o.saved_pstate.duplicate()
	transformed_pstate.transform = body.space.to_physEngine_transform(o.saved_pstate.transform)
	o.physicsShape.body.init_pstate(transformed_pstate)

	o.physicsShape.collisionMap = CollisionShapeMap.new()
	o.physicsShape.update_collision_map(o.shape)

	var new_data = calculate_inertiaData(o)
	o.physicsShape.update_inertiaData(new_data)

	if o.components:
		for component in o.components.get_components():
			component = component as Component
			component.attach_to_object(o)




static func calculate_inertiaData(o:GameObject):
	var data = InertiaData.new()
	data.mass = o.geometry.contour.area
	data.moment = o.geometry.contour.get_moment_factor_about_com()
	data.center_of_mass = o.geometry.contour.centroid

	return data





class Components:
	var _data: Dictionary = {}
	var _owner: GameObject
	func _init(owner: GameObject) -> void:
		_owner = owner
	func add(component: Component) -> void:
		var type := component.get_type()
		if _data.has(type):
			remove(_data[type])
		_data[type] = component
		#component.attach_to_object(_owner) #Only called upon building!
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





static func from_query_result(result:Dictionary) -> GameObject:
	var body = result["collider"]
	var shape_idx = result["shape"]
	var body_shape_owner_id = body.shape_find_owner(shape_idx)
	var cpoly = body.shape_owner_get_owner(body_shape_owner_id)
	if not cpoly:return
	assert(cpoly is CollisionPolygon2D_)
	cpoly = cpoly as CollisionPolygon2D_
	var obj = cpoly.physicsShape._owner
	assert(obj)
	return obj
