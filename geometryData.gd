class_name GeometryData

var shape:ClipShape
var contour:ContourData


# Todo: Queue updates for tick
func set_shape(new_shape:ClipShape):
	shape = new_shape
	contour = calculate_contour(shape)





static func calculate_contour(shape:ClipShape) -> ContourData:

	var combined_contour:ContourData = ContourData.new()
	for path in shape.to_packed_paths():
		var data:PolygonData
		if is_hole(path):
			path.reverse()
			data = create_polygonData(path, true)
		else:
			data = create_polygonData(path)
		combined_contour = combined_contour.add(data.contour)

	return combined_contour





static func is_hole(poly:PackedVector2Array) -> bool:
	return Geometry2D.is_polygon_clockwise(poly)




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



func draw(ci:CanvasItem, ):
	for path in shape.to_packed_paths():
		var col := Color.RED if is_hole(path) else Color.BLUE
		ci.draw_polyline(path+PackedVector2Array([path[0]]), col)
