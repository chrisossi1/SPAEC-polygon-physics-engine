class_name CollisionShapeMap

var chunk_size:float
var margin:float # Must be 0 for non buggy collisions?

var cell_map := {} # Vector2i : Cell pairs

class Cell:
	var index:Vector2i
	var shape: ClipShape
	var cpolys: Array[CollisionPolygon2D] = []
	#debug
	var area:float
	var cpoly_area_sum:float



func set_cell(idx:Vector2i, shape:ClipShape, body:RigidBody2D, available_cpolys:Array=[]):
	#assert(shape.size() > 0)
	var cell = Cell.new()
	cell.index = idx
	cell.shape = shape
	
	#var sum:float = 0
	for poly in punch_clipShape(shape):
		var cpoly:CollisionPolygon2D
		if available_cpolys:
			cpoly = available_cpolys.pop_front()
		else:
			cpoly = _add_cpoly(body)
		cpoly.cell = cell
		cpoly.polygon = poly
		cell.cpolys.append(cpoly)
		#var c = ClipShape.new()
		#c.add_path(cpoly.polygon)
		#sum += c.get_area()

	cell_map[idx] = cell
	
	#if chunk_size > 0:
	#	cell.area = shape.get_area()
	#	cell.cpoly_area_sum = sum
	#	assert( cell.cpoly_area_sum <= (chunk_size * chunk_size) )


func remove_cell(idx:Vector2i):
	assert(cell_map.has(idx))
	var cell:Cell = cell_map[idx]
	for cpoly in cell.cpolys:
		_remove_cpoly(cpoly)






# Whole shape is treated as one cell
func init_unchunked(shape:ClipShape, body:RigidBody2D):
	chunk_size = -1
	margin = -1

	var new_cpolys = []

	set_cell(Vector2i(), shape, body)
	new_cpolys.append_array(cell_map[Vector2i()].cpolys)
	
	return new_cpolys
















func init_chunked(shape:ClipShape, body:RigidBody2D, size: float, _margin: float = 0):
	if _margin < 0:
		_margin = size/4

	chunk_size = size
	margin = _margin

	assert(chunk_size > 0)
	var aabb := shape.get_bounds()
	var min_cx := int(floor(aabb.position.x / chunk_size))
	var min_cy := int(floor(aabb.position.y / chunk_size))
	var max_cx := int(ceil((aabb.position.x + aabb.size.x) / chunk_size))
	var max_cy := int(ceil((aabb.position.y + aabb.size.y) / chunk_size))

	var new_cpolys = []

	for cx in range(min_cx, max_cx):
		for cy in range(min_cy, max_cy):
			var idx = Vector2i(cx,cy)
			_build_index(shape, idx, body)
			new_cpolys.append_array(cell_map[idx].cpolys)

	return new_cpolys


func update_local(shape:ClipShape, incoming:PackedVector2Array, body:RigidBody2D):
	var idxs_to_sync:Array[Vector2i]
	if chunk_size < 0:#unchunked
		idxs_to_sync = [Vector2i()]
	else:
		idxs_to_sync = rasterize_polygon_even_odd(incoming, chunk_size)

	var new_cpolys = []
	var to_delete = []
	for idx in idxs_to_sync:
		if cell_map.has(idx): #Clear all existing cells
			to_delete.append_array(cell_map[idx].cpolys)
	
	for idx in idxs_to_sync:
		_build_index(shape, idx, body, to_delete)
		new_cpolys.append_array(cell_map[idx].cpolys)
	
	for cpoly in to_delete:
		_remove_cpoly(cpoly)

	return new_cpolys



func _build_index(shape:ClipShape, idx:Vector2i, body:RigidBody2D, available_cpolys:Array=[]):
	var clipped:ClipShape
	if chunk_size < 0:
		clipped = shape
	else:
		var rect_poly := _idx_cell_points(idx.x, idx.y, chunk_size, margin)
		var rect_shape = ClipShape.new()
		rect_shape.add_path(rect_poly)
		clipped = shape.intersect(rect_shape) # TODO: Empty result? Full result? tiny result? unchanged result?

	if shape.size() == 0:
		cell_map.erase(idx)
		return

	#if idx in cell_map:
	#	remove_cell(idx)
	set_cell(idx, clipped, body, available_cpolys)



















# Creates and prepares new cpoly child, with pooling
# TODO: Pooling should be at the body level not physicsShape
const cpoly_scene = preload("res://collision_polygon_2d.tscn")
var cpolys:Array[CollisionPolygon2D] = []
func _add_cpoly(body:RigidBody2D) -> CollisionPolygon2D:
	if cpolys:
		var cpoly:CollisionPolygon2D = cpolys.pop_front()
		assert(cpoly.disabled)
		cpoly.disabled = false
		cpoly.visible = true
		return cpoly
	var cpoly:CollisionPolygon2D = cpoly_scene.instantiate()
	body.add_child(cpoly)
	return cpoly

func _remove_cpoly(cpoly:CollisionPolygon2D):
	assert(not(cpoly in cpolys))
	assert(not cpoly.disabled)
	cpoly.disabled = true
	cpoly.visible = false
	cpoly.polygon = PackedVector2Array()
	cpolys.append(cpoly)




















# #### GEOMETRY HELPERS #### #
# Uses triangulation TDDO: Use convex decomposition
func punch_clipShape_tri(shape:ClipShape) -> Array:
	var has_holes := false
	var paths = shape.to_packed_paths()
	for path in paths:
		if GeometryData.is_hole(path):
			has_holes = true
			break
	if not has_holes:
		return paths

	var tris = shape.triangulate()
	return mesh_arrays_to_triangles(tris)







# Converts the Array returned by ClipShape.triangulate()
# into an Array of PackedVector2Array triangles.
func mesh_arrays_to_triangles(mesh_arrays: Array) -> Array[PackedVector2Array]:
	var triangles: Array[PackedVector2Array] = []

	if mesh_arrays.size() <= Mesh.ARRAY_VERTEX:
		return triangles

	var vertices: PackedVector2Array = mesh_arrays[Mesh.ARRAY_VERTEX]

	if vertices.is_empty():
		return triangles

	# Indexed mesh.
	if mesh_arrays.size() > Mesh.ARRAY_INDEX:
		var indices: PackedInt32Array = mesh_arrays[Mesh.ARRAY_INDEX]

		for i in range(0, indices.size() - 2, 3):
			var ia: int = indices[i]
			var ib: int = indices[i + 1]
			var ic: int = indices[i + 2]

			if (
				ia < 0 or ia >= vertices.size()
				or ib < 0 or ib >= vertices.size()
				or ic < 0 or ic >= vertices.size()
			):
				push_warning("Skipping triangle with invalid vertex index.")
				continue

			var triangle := PackedVector2Array([
				vertices[ia],
				vertices[ib],
				vertices[ic]
			])

			triangles.append(triangle)

		return triangles

	# Non-indexed fallback: every three vertices form one triangle.
	for i in range(0, vertices.size() - 2, 3):
		var triangle := PackedVector2Array([
			vertices[i],
			vertices[i + 1],
			vertices[i + 2]
		])

		triangles.append(triangle)

	return triangles








var max_seam_length = 999999.

# Uses keyholing
func punch_clipShape(shape:ClipShape) -> Array[PackedVector2Array]:
	var solids:Array[PackedVector2Array] = []
	var holes:Array[PackedVector2Array] = []
	for path in shape.to_packed_paths():
		if GeometryData.is_hole(path):
			holes.append(path)
			continue
		solids.append(path)
	
	var solid_shape = ClipShape.new()
	solid_shape.add_paths(solids)
	
	var holes_shape := ClipShape.new()
	for hole in holes:
		# Add seam to hole to avoid ccw holes
		var seam := PackedVector2Array([hole[0], hole[0] + Vector2(max_seam_length, 0)])
		var seam_poly := Geometry2D.offset_polyline(seam, .02)
		var hole_and_seam_poly := Geometry2D.merge_polygons(hole, seam_poly[0])[0]
		holes_shape.add_path(hole_and_seam_poly)
		#TODO: Only for solids overlapping the original solid, no seams
	
	var clipped = solid_shape.clip(holes_shape)
	var result:Array[PackedVector2Array] = []
	for path in clipped.to_packed_paths():
		assert (not GeometryData.is_hole(path))
		result.append(path)
	return result


#Todo: This creates uneccessary seams?
# KEYHOLING
static func _subtract_holes_from_solids(solids: Array[PackedVector2Array], holes: Array[PackedVector2Array], max_seam_length:float) -> Array[PackedVector2Array]:
	## Removes hole polygons from solid polygons.
	if holes.is_empty():
		return solids

	var result:Array[PackedVector2Array] = []

	for hole in holes:

		# Add seam to hole to avoid ccw holes
		var seam := PackedVector2Array([hole[0], hole[0] + Vector2(max_seam_length, 0)])
		var seam_poly := Geometry2D.offset_polyline(seam, .02)
		var hole_and_seam_poly := Geometry2D.merge_polygons(hole, seam_poly[0])[0]

		#TODO: Only for solids overlapping the original solid, no seams
		for solid in solids:
			var clipped := Geometry2D.clip_polygons(solid, hole_and_seam_poly)
			for poly in clipped:
				if not Geometry2D.is_polygon_clockwise(poly):
					result.append(poly)
				else:
					assert(false) # It must be clockwise, the seam guarantees no holes

	return result




static func _idx_cell_points(cx: int, cy: int, size: float, margin:float) -> PackedVector2Array:
	var x := cx * size
	var y := cy * size
	return PackedVector2Array([
		Vector2(x - margin,         y - margin),
		Vector2(x + size + margin,  y - margin),
		Vector2(x + size + margin,  y + size + margin),
		Vector2(x - margin,         y + size + margin),
	])



# ### INCOMING POLYGON RASTERIZATION INTO GRID CELLS

# Even-odd polygon rasterization on an N x N grid of unit cells.
# Input:
#  - poly: PackedVector2Array (closed/simple polygon; last point may or may not repeat first)
#  - N: grid size (cells are [0..N-1] in both x and y)
# Output:
#  - Array[Vector2i] of grid cell indices that intersect polygon interior or edge.

static func rasterize_polygon_aabb(
		poly: PackedVector2Array,
		_chunk_size: float
	) -> Array[Vector2i]:
	if poly.size() < 3:
		return []
	
	assert(_chunk_size > 0)

	var shape = ClipShape.new()
	shape.add_path(poly)
	var bounds:Rect2 = shape.get_bounds()
	
	# Grid-cell indices containing the minimum and maximum bounds.
	var min_cell := Vector2i(
		floori(bounds.position.x / _chunk_size),
		floori(bounds.position.y / _chunk_size)
	)

	# Subtracting one after ceili prevents including a cell that only
	# touches the AABB at its maximum edge.
	var max_cell := Vector2i(
		ceili(bounds.end.x / _chunk_size) - 1,
		ceili(bounds.end.y / _chunk_size) - 1
	)

	var result: Array[Vector2i] = []

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			result.append(Vector2i(x, y))

	return result





static func rasterize_polygon_even_odd(
		poly: PackedVector2Array,
		_chunk_size: float
	) -> Array[Vector2i]:
	if poly.size() < 3:
		return []
	
	assert(_chunk_size > 0)

	# Copy to Array[Vector2] and ensure closed
	var pts: Array[Vector2] = []
	pts.resize(poly.size())
	for i in poly.size():
		pts[i] = poly[i]
	if pts[0] != pts[pts.size() - 1]:
		pts.append(pts[0])

	# Compute polygon AABB
	var aabb := Rect2()
	var first := pts[0]
	aabb.position = first
	aabb.size = Vector2(0, 0)

	for i in range(1, pts.size()):
		var p := pts[i]
		aabb = aabb.expand(p)

	# Convert world AABB to grid index ranges
	# We use floor/ceil so we include any partially covered cells.
	var min_i := Vector2(
		floor(aabb.position.x / _chunk_size),
		floor(aabb.position.y / _chunk_size)
	)
	var max_i := Vector2(
		ceil((aabb.position.x + aabb.size.x) / _chunk_size) - 1.0,
		ceil((aabb.position.y + aabb.size.y) / _chunk_size) - 1.0
	)

	# Clamp/convert to ints
	var min_x := int(min_i.x)
	var min_y := int(min_i.y)
	var max_x := int(max_i.x)
	var max_y := int(max_i.y)

	var result: Array[Vector2i] = []
	result.resize(0)

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			# Cell rectangle in world coordinates
			var cell_min := Vector2(x * _chunk_size, y * _chunk_size)
			var cell_max := cell_min + Vector2(_chunk_size, _chunk_size)

			if _polygon_intersects_rect(pts, cell_min, cell_max):
				result.append(Vector2i(x, y))
				continue

			var c := cell_min + Vector2(_chunk_size * 0.5, _chunk_size * 0.5)
			if _point_in_polygon_even_odd(c, pts):
				result.append(Vector2i(x, y))

	return result


# ---------- Geometry helpers ----------

static func _point_in_polygon_even_odd(p: Vector2, pts: Array[Vector2]) -> bool:
	# Even-odd rule using ray casting to +X.
	# Treat points on edges as inside by doing a separate segment check first.
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		if _point_on_segment(p, a, b):
			return true

	var inside := false
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]

		# Check if edge straddles the horizontal ray at y = p.y
		# We use a standard trick to avoid double-counting vertices:
		# Consider intersections where (a.y > p.y) != (b.y > p.y)
		var ay := a.y
		var by := b.y
		if (ay > p.y) == (by > p.y):
			continue

		# Compute x coordinate of intersection of the segment with the ray y = p.y
		# p.x_ray crosses at x_int; toggle if x_int > p.x
		var t := (p.y - ay) / (by - ay)
		var x_int := a.x + t * (b.x - a.x)

		if x_int > p.x:
			inside = !inside

	return inside


static func _polygon_intersects_rect(pts: Array[Vector2], rmin: Vector2, rmax: Vector2) -> bool:
	# Returns true if polygon edges intersect the rectangle or a vertex is inside rect.
	# Also catches polygon entirely covering the rect by checking rect corners, but that
	# still misses rare "fully inside polygon without touching edges" unless we also check
	# corners. We do that at the end.

	# Vertex inside rect -> boundary intersects (we consider it raster hit)
	for i in range(pts.size() - 1):
		var v := pts[i]
		if v.x >= rmin.x and v.x <= rmax.x and v.y >= rmin.y and v.y <= rmax.y:
			return true

	# Edge-rect intersection via segment intersection with rectangle edges
	var rect_edges := [
		[Vector2(rmin.x, rmin.y), Vector2(rmax.x, rmin.y)], # bottom
		[Vector2(rmax.x, rmin.y), Vector2(rmax.x, rmax.y)], # right
		[Vector2(rmax.x, rmax.y), Vector2(rmin.x, rmax.y)], # top
		[Vector2(rmin.x, rmax.y), Vector2(rmin.x, rmin.y)]  # left
	]

	# Check segment intersections
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		for e in rect_edges:
			var c = e[0]
			var d = e[1]
			if _segments_intersect(a, b, c, d):
				return true

	# If rect corners are inside polygon, polygon covers rect interior without edges crossing it.
	# (This is exactly the case "polygon completely contains the cell".)
	var corners := [
		Vector2(rmin.x, rmin.y),
		Vector2(rmax.x, rmin.y),
		Vector2(rmax.x, rmax.y),
		Vector2(rmin.x, rmax.y),
	]
	for k in corners:
		if _point_in_polygon_even_odd(k, pts):
			return true

	return false


static func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	# Proper + collinear overlap intersection check.
	var o1 := _orient(a, b, c)
	var o2 := _orient(a, b, d)
	var o3 := _orient(c, d, a)
	var o4 := _orient(c, d, b)

	# General case
	if (o1 > 0 and o2 < 0) or (o1 < 0 and o2 > 0):
		if (o3 > 0 and o4 < 0) or (o3 < 0 and o4 > 0):
			return true

	# Collinear cases
	if abs(o1) <= 1e-9 and _point_on_segment(c, a, b): return true
	if abs(o2) <= 1e-9 and _point_on_segment(d, a, b): return true
	if abs(o3) <= 1e-9 and _point_on_segment(a, c, d): return true
	if abs(o4) <= 1e-9 and _point_on_segment(b, c, d): return true

	# Otherwise no intersection
	return false


static func _point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> bool:
	# Check collinearity + bounding box.
	var ab := b - a
	var ap := p - a
	var cross := ab.x * ap.y - ab.y * ap.x
	if abs(cross) > 1e-9:
		return false

	var minx:float = min(a.x, b.x) - 1e-9
	var maxx:float = max(a.x, b.x) + 1e-9
	var miny:float = min(a.y, b.y) - 1e-9
	var maxy:float = max(a.y, b.y) + 1e-9
	return (p.x >= minx and p.x <= maxx and p.y >= miny and p.y <= maxy)


static func _orient(a: Vector2, b: Vector2, c: Vector2) -> float:
	# Signed area * 2: >0 ccw, <0 cw, 0 collinear
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
