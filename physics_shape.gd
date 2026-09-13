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



# Update collision shapes in physics engine
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











func get_global_transform() -> Transform2D:
	return body.global_transform
