class_name CollisionShapeMap

#Updates map and collisionPolygon2D
var cpoly_map := {} # Chunk : CollisionPolygon2D pairs

func get_cpolys():
	return cpoly_map.values()



const cpoly_scene = preload("res://collision_polygon_2d.tscn")

'''Updates collision polygon based on chunkShape updates'''
func update_cpolys(chunkShape:ChunkShape, body:RigidBody2D) -> Array[CollisionPolygon2D]:
	
	# Todo; This should be done in chunkShape
	for chunk in chunkShape.to_add + chunkShape.to_update:
		chunk = chunk as ChunkShape.Chunk
		if not Geometry2D.decompose_polygon_in_convex(chunk.poly):
			print("Fixing Chunk Geometry")
			chunk.poly = _remove_duplicates(chunk.poly)

	
	var new_cpolys:Array[CollisionPolygon2D] = []
	for c in chunkShape.to_remove:
		_remove_chunk_cpoly(c)
	for c in chunkShape.to_add:
		var new_cpoly = _add_chunk_cpoly(c, body)
		new_cpolys.append(new_cpoly)
	for c in chunkShape.to_update:
		var updated_cpoly = _update_chunk_cpoly(c)

	# Deboog
	print(cpoly_map.size(), ": ", body.get_child_count())
	#print(cpoly_map.values(), ": ", body.get_children())

	# Todo: Check shape owners to make sure geometry worked

	chunkShape.to_add.clear()
	chunkShape.to_remove.clear()
	chunkShape.to_update.clear()
	return new_cpolys








'''
Options for dupliate points: 
	1. Nudge points to unique positions
	2. Delete duplicate
	
	A. Deduplicate exact floats
	B. Deduplicate quantized check. (If quantized how do we nudge successfully?)
	C. Quantize points and deduplicate
	
	- Deduplicate SWH solid points
	- Deduplicate every chunk polygon NOT NECESSARY
	- Deduplicate every CollisionPolygon2D points YES
		dedupe cpoly points more aggressively due to already failing swh dedupe
'''

static func _remove_duplicates(points:PackedVector2Array) -> PackedVector2Array:
	var q = .01
	var out := PackedVector2Array()

	var seen = {}
	var n = points.size()
	for i in range(n):
		var p := points[i]
		seen[p] = 0

	for i in points.size():
		var p := points[i]
		if seen[p] > 0:
			
			var dir = ( (points[(i+1)%n]-p).normalized()  + (points[(n+i-1)%n]-p).normalized() )
			
			out.append(p + dir * q)
			continue
		seen[p] += 1
		out.append(p)
	return out














func clear_cpolys():
	for cpoly in get_cpolys():
		cpoly.queue_free()
	cpoly_map = {}




var cpolys:Array[CollisionPolygon2D] = []
func get_cpoly() -> CollisionPolygon2D:
	if cpolys:
		var cpoly:CollisionPolygon2D = cpolys.pop_front()
		return cpoly
	return cpoly_scene.instantiate()



#TODO: Pooling?

func _add_chunk_cpoly(chunk:ChunkShape.Chunk, body:RigidBody2D) -> CollisionPolygon2D:
	assert(not cpoly_map.has(chunk))
	var cpoly := get_cpoly()
	cpoly.polygon = chunk.poly
	if cpoly.disabled: # Used as an indicator if the polygon is coming from pool or not.
		cpoly.disabled = false # If coming from pool, just enable it
	else:
		body.add_child(cpoly) # If newly created, add it to the body.

	cpoly_map[chunk] = cpoly
	
	return cpoly


func _remove_chunk_cpoly(chunk:ChunkShape.Chunk):
	assert(cpoly_map.has(chunk))
	var cpoly:CollisionPolygon2D = cpoly_map[chunk]
	cpoly.disabled = true
	cpolys.append(cpoly)
	cpoly_map.erase(chunk)

func _update_chunk_cpoly(chunk:ChunkShape.Chunk):
	assert(cpoly_map.has(chunk))
	cpoly_map[chunk].polygon = chunk.poly
