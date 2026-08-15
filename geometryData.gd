class_name GeometryData

var shapes:Array[ShapeWithHoles]
var chunkShape:ChunkShape
var contour:ContourData
var shapeData_map := {} # { ShapeWithHoles : ShapeData }

var use_chunks:bool

const CHUNK_SIZE = 400

func set_shapes(new_shapes:Array[ShapeWithHoles]):

	# Update shapes
	shapes = new_shapes

	# rebuild chunkShape
	chunkShape = ChunkShape.create_chunked(shapes, CHUNK_SIZE)

	# Calculate new shape contours
	shapeData_map.clear()
	for swh in shapes:
		shapeData_map[swh] = create_shapeData(swh)

	# Calculate overall contour
	var shapeDatas = shapeData_map.values()
	contour = shapeDatas[0].contour
	for i in range(1, len(shapeDatas)):
		var shapeData = shapeDatas[i]
		contour = contour.add(shapeData.contour)





class ShapeData:
	var solid:PolygonData
	var holes:Dictionary = {} # { HoleRef : PolygonData }
	var contour:ContourData


static func create_shapeData(swh:ShapeWithHoles) -> ShapeData:
	var sd = ShapeData.new()
	sd.solid = create_polygonData(swh.solid)
	var combined_contour:ContourData = sd.solid.contour
	for holeRef in swh.holeRefs:
		holeRef = holeRef as ShapeWithHoles.HoleRef 
		var data := create_polygonData(holeRef.points, true)
		sd.holes[holeRef] = data
		combined_contour = combined_contour.add(data.contour)
	sd.contour = combined_contour
	return sd







class PolygonData: #Contour data + Properties that are only relevant for simple polygon contours
	var contour:ContourData
	var IQ:float
	var diameter:float
	var diameter_segment:PackedVector2Array
	
	func _init():
		contour = ContourData.new()

class ContourData:
	var n:int #Number of sides
	var area:float
	var centroid:Vector2 # ## Relative to geometry origin
	var moment_factor:float # ## Relative to geometry origin. Compare to InertiaData
	var perimeter:float
	#number of shapes
	#number of solids
	#number of holes
	#area of holes
	
	func get_moment_factor_about_com() -> float:
		var I_origin = moment_factor
		var A = area
		var C = centroid

		return I_origin - A * C.length_squared()



	func add(other:ContourData) -> ContourData: # Assuming disjoint contours 
		var new = ContourData.new()
		new.n = n + other.n
		new.area = area + other.area
		new.centroid = (centroid * area + other.centroid * other.area) / new.area
		new.moment_factor = moment_factor + other.moment_factor
		new.perimeter = perimeter + other.perimeter
		return new

	func subtract(other:ContourData) -> ContourData: # Assuming disjoint contours 
		var new = ContourData.new()
		new.n = n - other.n
		new.area = area - other.area
		if new.area < .00001:
			new.area = 0.
			return new
		new.centroid = (centroid * area - other.centroid * other.area) / new.area
		new.moment_factor = moment_factor - other.moment_factor
		new.perimeter = perimeter - other.perimeter
		return new






static func create_polygonData(poly:PackedVector2Array, inver := false) -> PolygonData:
	var data = PolygonData.new()
	data.contour.n = poly.size()
	calc_area_and_centroid_offset(data, poly)


	assert(data.contour.area) # TODO: We need to CATCH THIS CONDITION!
	#TODO: Check if area too small
	calc_moment(data, poly)
	calc_perimeter(data, poly)
	calc_IQ(data)
	calc_diameter(data, poly)
	
	if inver:
		data.contour.area = -data.contour.area
		data.contour.moment_factor = -data.contour.moment_factor
		
	return data
















'''PROPERTY CALCULATORS'''

'''Returns [area,COM] pair'''
static func calc_area_and_centroid_offset(data:PolygonData, points:PackedVector2Array): #calculated together for performance
	assert(points)
	assert(data.contour.n)

	var area_sum = 0.0
	var centroid_sum = Vector2.ZERO

	for i in range(data.contour.n):
		var v1 = points[i]
		var v2 = points[(i + 1) % data.contour.n]

		var cross_product = v1.cross(v2)
		area_sum += cross_product

		centroid_sum += (v1 + v2) * cross_product

	area_sum = abs(area_sum*.5)

	data.contour.area = area_sum

	if data.contour.area > 0:
		data.contour.centroid = centroid_sum / (6.0 * area_sum)


static func calc_moment(data:PolygonData, points:PackedVector2Array):
	assert(points)
	assert(data.contour.n)

	var total_I = 0.0

	for i in range(data.contour.n):
		var v1 = points[i]
		var v2 = points[(i + 1) % data.contour.n]
		var det = v1.cross(v2)

		total_I += det * (v1.dot(v1) + v1.dot(v2) + v2.dot(v2))

	data.contour.moment_factor = total_I / 12.0




static func calc_perimeter(data:PolygonData, points:PackedVector2Array):
	assert(points)
	assert(data.contour.n > 2)

	var sum:=0.0
	for i in range(data.contour.n):
		var side_start = points[i]
		var side_end = points[(i+1) % data.contour.n]
		var v = side_start.distance_to(side_end)
		sum += v
	data.contour.perimeter = sum
	assert(data.contour.perimeter)


static func calc_IQ(data:PolygonData):
	assert(data.contour.area)
	assert(data.contour.perimeter)
	data.IQ = (4 * PI * data.contour.area) / (data.contour.perimeter * data.contour.perimeter)


static func calc_diameter(data:PolygonData, points:PackedVector2Array):
	assert(points)
	assert(data.contour.n)

	var poly = Geometry2D.convex_hull(points)

	var n = len(poly) 

	var k := 1
	while (triangleArea(poly[n-1], poly[0], poly[(k+1)%n]) > triangleArea(poly[n-1], poly[0], poly[k])):
		k+=1
 
	var maxDistSquared := 0.
	var maxSegment = []
	var j = k
	for i in range(k):# (int i = 0, j = k; i <= k; i++) {
		while triangleArea(poly[i], poly[(i+1)%n], poly[(j+1)%n]) > triangleArea(poly[i], poly[(i+1)%n], poly[j]):
			maxDistSquared = max(maxDistSquared, poly[i].distance_squared_to(poly[(j+1)%n]))
			j = (j+1) % n
  
		maxDistSquared = max(maxDistSquared, poly[i].distance_squared_to(poly[j]))
		maxSegment = [poly[i],poly[j]]

	data.diameter = sqrt(maxDistSquared)
	data.diameter_segment = PackedVector2Array(maxSegment)

	
#util func for area of a tri
static func triangleArea(p:Vector2, q:Vector2, r:Vector2) -> float:
	return abs((p.x * q.y + q.x * r.y + r.x * p.y) - (p.y * q.x + q.y * r.x + r.y * p.x))




# ### ## #  TODO: A GEOMETRY SERVICE THAT CACHES PROPERTIES? HOW DO I ENFORCE IMMUTABILITY?
# ### ## # No honestly just a C++ geometry system



func draw(ci:CanvasItem, draw_chunkShape := false):
	for swh in shapes:
		swh.draw(ci)
	if draw_chunkShape:
		chunkShape.draw(ci)






# ############## GEOMETRY UPDATES ################ #



func update_geometry(updates:Array[GeometryUpdate]) -> bool:
	for update in updates:
		update.resolve(self)
	if contour.centroid.length_squared() > 500000:
		# Multishape renormalization necessary.
		return false
	return true



class GeometryUpdate:
	pass


class GeometryUpdate_SWH:
	extends GeometryUpdate
	var added:Array[ShapeWithHoles]
	var removed:Array[ShapeWithHoles]
	func resolve(geometry:GeometryData):
		for r in removed:
			assert(geometry.shapes.has(r))
			geometry.shapes.erase(r)
			assert(geometry.shapeData_map.has(r))
			var data = geometry.shapeData_map[r]
			geometry.shapeData_map.erase(r)
			geometry.contour = geometry.contour.subtract(data.contour)
		for a in added:
			assert(not geometry.shapes.has(a))
			geometry.shapes.append(a)
			assert(not geometry.shapeData_map.has(a))
			var data = GeometryData.create_shapeData(a)
			assert(data.contour.area > .0001)
			assert(data.contour.moment_factor > .0001)
			geometry.shapeData_map[a] = data
			geometry.contour = geometry.contour.add(data.contour)



class GeometryUpdate_ChunkShape:
	extends GeometryUpdate
	enum OP {CLIP, EXTEND}
	var points:PackedVector2Array
	var operation:OP = OP.CLIP
	func resolve(geometry:GeometryData):

		if operation == OP.CLIP:
			geometry.chunkShape = ChunkShape.clip_polyon(geometry.chunkShape,points)
		elif operation == OP.EXTEND:
			geometry.chunkShape = ChunkShape.merge_polygon(geometry.chunkShape,points, geometry.shapes)#MARK todo: IMPLEMENT
			

			'''#Debug

			print("Clipping 2")
			var double := ChunkShape.clip_polygon(geometry.chunkShape,points)
			#var triple := ChunkShape.clip_polygon(double,points)

			var unaccounted_indexes = []
			for key in geometry.chunkShape.chunks.keys():
				if key in double.chunks.keys():
					continue
				unaccounted_indexes.append(key)

			for chunk in geometry.chunkShape.to_add + geometry.chunkShape.to_update:
				print("polygon" + chunk.debug)

			#assert(geometry.chunkShape.chunks.keys().size() == double.chunks.keys().size()) # Compare number of indexes 
			assert(unaccounted_indexes.size() == 0)

			# Deep comparison
			for index in geometry.chunkShape.chunks.keys():
				var chunks_at_index = geometry.chunkShape.chunks[index]
				var chunks_at_index1 = double.chunks[index]
				assert(chunks_at_index.size() == chunks_at_index1.size())
			

		'''
