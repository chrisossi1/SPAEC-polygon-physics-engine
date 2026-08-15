class_name PolyFuncs


# FACTORY
static func _generate_regular_polygon(sides, size) -> PackedVector2Array:
	var pts = []
	for i in range(sides):
		pts.append(size*Vector2.RIGHT.rotated(2*PI*float(i)/sides))
	
	return PackedVector2Array(pts)




'''
# FUNCTIONS
static func center_centroid(poly:Polygon):
	var new_points := []
	for p in poly.points:
		new_points.append(p - poly.centroid)
	poly.points = new_points
	#TODO: Use transform2D instead of looping
'''










#      CALCULATE PROPERTIES

#Polygon: The polygon to calculate propertes for
#Defer: If true, only calculates area and centroid offset but does not shift centroid or calcluate other properties
#Call again to complete calculation after a deferred creation
static func calculate_properties(polygon: Polygon, defer := false):
	assert(polygon.points)
	if not polygon.area:
		polygon.n = len(polygon.points)
		calc_area_and_centroid_offset(polygon)

		if polygon.area > .0000001:
			polygon.valid = true

		if not polygon.valid:return
		calc_perimeter(polygon)
		calculate_IQ(polygon)
		calculate_diameter(polygon)

	if not defer:
		if not polygon.valid:return
		center_centroid(polygon)
		calc_moment(polygon)



'''PROPERTY CALCULATORS'''

'''Returns [area,COM] pair'''
static func calc_area_and_centroid_offset(polygon:Polygon): #calculated together for performance
	assert(polygon.points)
	assert(polygon.n)
	polygon.convex = true

	var area_sum = 0.0
	var centroid_sum = Vector2.ZERO

	var points = polygon.points

	for i in range(polygon.n):
		var v1 = points[i]
		var v2 = points[(i + 1) % polygon.n]

		var cross_product = v1.cross(v2)
		
		if polygon.convex and cross_product < .00001:
			polygon.convex = false
		
		area_sum += cross_product

		centroid_sum += (v1 + v2) * cross_product

	area_sum = abs(area_sum*.5)
	if area_sum == 0.0:
		polygon.area = -1

	var COM = centroid_sum / (6.0 * area_sum)

	polygon.area = area_sum
	polygon.centroid_offset = COM


static func center_centroid(polygon:Polygon):
	assert(polygon.centroid_offset != Vector2.INF)
	var xform = Transform2D(0., -polygon.centroid_offset)
	polygon.points = xform * polygon.points
	polygon.diameter_segment = xform * polygon.diameter_segment
	polygon.centered = true


static func calc_moment(polygon:Polygon):
	assert(polygon.points)
	assert(polygon.n)
	assert(polygon.centered)

	var points = polygon.points
	var total_I = 0.0

	for i in range(polygon.n):
		var v1 = points[i]
		var v2 = points[(i + 1) % polygon.n]
		# The cross product here IS the signed area * 2
		var det = v1.cross(v2) 
		# This is the standard second moment of area integral for a triangle segment
		total_I += det * (v1.dot(v1) + v1.dot(v2) + v2.dot(v2))

	# Final Division: 
	# 6.0 comes from the integral of r^2 over a triangle
	# We divide by (6 * area) to get the "unit inertia" (mass-agnostic)
	polygon.moment_factor = abs(total_I) / (6.0 * abs(polygon.area))
	



'''
static func calc_sides(polygon:Polygon): #Todo: Replace with a function that calculates sides on the fly if memory becomes an issue
	assert(polygon.points)
	assert(polygon.n)

	polygon.sides = []
	var p_prev = polygon.points[0]
	for i in range(polygon.n):
		var p = polygon.points[(i+1)%polygon.n]
		polygon.sides.append([p_prev,p])
		p_prev = p
'''

static func calc_perimeter(polygon:Polygon):
	assert(polygon.n > 2)

	var sum:=0.0
	for i in range(polygon.n):
		var side_start = polygon.points[i]
		var side_end = polygon.points[(i+1) % polygon.n]
		var v = side_start.distance_to(side_end)
		sum += v
	polygon.perimeter = sum
	assert(polygon.perimeter)

static func calculate_IQ(polygon:Polygon):
	assert(polygon.area)
	assert(polygon.perimeter)
	polygon.IQ = (4 * PI * polygon.area) / (polygon.perimeter * polygon.perimeter)


static func calculate_diameter(polygon:Polygon):
	assert(polygon.points)
	assert(polygon.n)

	var poly = Geometry2D.convex_hull(polygon.points)

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

	polygon.diameter = sqrt(maxDistSquared)
	polygon.diameter_segment = PackedVector2Array(maxSegment)

	
#util func for area of a tri
static func triangleArea(p:Vector2, q:Vector2, r:Vector2) -> float:
	return abs((p.x * q.y + q.x * r.y + r.x * p.y) - (p.y * q.x + q.y * r.x + r.y * p.x))





static func close_poly(p:PackedVector2Array) -> PackedVector2Array:
	return p + PackedVector2Array([p[0]])


static func _calc_area(points:PackedVector2Array):
	assert(points)
	var area_sum = 0.0
	for i in range(points.size()):
		var v1 = points[i]
		var v2 = points[(i + 1) % points.size()]
		var cross_product = v1.cross(v2)
		area_sum += cross_product
	area_sum = abs(area_sum*.5)
	return area_sum
