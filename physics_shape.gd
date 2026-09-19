class_name PhysicsShape

''' Is physicsShape an API to the physics engine or does it store data? can it do both? '''

var object:GameObject

var collisionMap: = CollisionShapeMap.new()
var body:SolidBody#PhysicsBody
var physicsMaterial:PhysicsMaterial
#var inertiaData:InertiaData
var transform:Transform2D # Geometry origin relative to body origin

var CHUNK_SIZE = 400
var use_chunks = true



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











# ## Body API

func get_mass() -> float:
	return body.mass


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
	return body.global_transform * transform

func to_local(v:Vector2) -> Vector2:
	assert(body)
	return get_global_transform().affine_inverse() * v
