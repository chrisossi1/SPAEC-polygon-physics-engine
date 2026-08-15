class_name PhysicsShape

''' Is physicsShape an API to the physics engine or does it store data? can it do both? '''

var object:GameObject

var collisionMap: = CollisionShapeMap.new()
var body:SolidBody#PhysicsBody
var physicsMaterial:PhysicsMaterial
#var inertiaData:InertiaData
var transform:Transform2D # Geometry origin relative to body origin




# Update collision shapes in physics engine
func update_collision_map(chunkShape:ChunkShape):
	# Update collision polygons from chunk shape
	var new_cpolys := collisionMap.update_cpolys(chunkShape, body)

	for cpoly in new_cpolys:
		cpoly.physicsShape = self
		cpoly.transform = transform * cpoly.transform











func get_global_transform() -> Transform2D:
	return body.global_transform
