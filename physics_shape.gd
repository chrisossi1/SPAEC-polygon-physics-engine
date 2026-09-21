class_name PhysicsShape

''' Is physicsShape an API to the physics engine or does it store data? can it do both? '''


var _owner: GameObject
func _init(owner: GameObject) -> void:
	_owner = owner

var collisionMap: = CollisionShapeMap.new()
var body:SolidBody#PhysicsBody
var physicsMaterial:PhysicsMaterial
var inertiaData:InertiaData
var transform:Transform2D # Geometry origin relative to body origin

var CHUNK_SIZE = 1000
var use_chunks = false #TODO: Where should this be defined? This is like initialization data for the ChunkShape






# Update or initialize collision shapes in physics engine
func update_collision_map(shape:ClipShape, incoming:PackedVector2Array = []):
	# Update collision polygons from chunk shape
	var new_cpolys:Array
	if incoming:
		new_cpolys = collisionMap.update_local(shape, incoming, body)
	else:
		if use_chunks:
			new_cpolys = collisionMap.init_chunked(shape, body, CHUNK_SIZE)
		else:
			new_cpolys = collisionMap.init_unchunked(shape, body)

	for cpoly in new_cpolys:
		cpoly.physicsShape = self
		cpoly.transform = transform * cpoly.transform





func update_inertiaData(new_shape_data:InertiaData):
	assert(new_shape_data.valid())

	var old_shape_data := inertiaData
	inertiaData = new_shape_data

	var new_body_data := InertiaData.new()

	# If 0 or 1 physicsShapes no need to compute compound properties
	if true:#body.links.get_shapes().size() < 2: #TODO: Links size function
		new_body_data.mass = new_shape_data.mass
		new_body_data.center_of_mass = transform * new_shape_data.center_of_mass # Shift COM to body reference frame
		new_body_data.moment = new_shape_data.moment

	body.set_inertiaData(new_body_data)


	if not old_shape_data:return

	# Angular Momentum Conservation 
	if new_shape_data.moment > old_shape_data.moment:
		body.angular_velocity = body.angular_velocity * old_shape_data.moment/new_shape_data.moment

	# Linear Momentum Conservation
	#if new_shape_data.mass > old_shape_data.mass:
	#	body.linear_velocity = body.linear_velocity * old_shape_data.mass/new_shape_data.mass








# ## Body API

func get_mass() -> float:
	return inertiaData.mass


func get_pstate() -> PState:
	assert(body)
	var pstate := PState.new()
	pstate.transform = get_global_transform() #Todo: COM?
	pstate.linear_velocity = body.linear_velocity #at COM
	pstate.angular_velocity = body.angular_velocity
	return pstate


#func get_global_center_of_mass() -> Vector2:
#	assert(body)
#	return get_global_transform() * inertiaData.center_of_mass



func get_global_transform() -> Transform2D:
	assert(body)
	return body.space.to_game_transform( body.global_transform * transform )

func to_local(v:Vector2) -> Vector2:
	assert(body)
	return get_global_transform().affine_inverse() * v
