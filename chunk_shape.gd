class_name ChunkShape

var chunk_size:float
var margin:float
var chunks := {} # Vector2i index : Array[Chunk] pairs


class Chunk:
	## A single chunk of geometry belonging to a larger body.
	## Stores the polygon and its spatial index
	var index: Vector2i
	var poly: PackedVector2Array#:set = set_poly_debug

	func _init(_index := Vector2i(), _poly := PackedVector2Array()):
		index = _index
		poly = _poly




func get_max_chunks_per_index() -> int:
	var max := 0
	for chunk_list in chunks.values():
		if chunk_list.size() > max:
			max = chunk_list.size()
	
	return max



# One chunk per solid
static func create_unchunked(ms:Array[ShapeWithHoles]) -> ChunkShape:
	var new_chunkShape := ChunkShape.new()
	new_chunkShape.chunk_size = -1

	for m in ms:
		var solids := _subtract_holes_from_solids([m.solid], m.holes, 99999999999.)
		for solid in solids:
			new_chunkShape.add_chunk(Vector2i(), solid)

	return new_chunkShape

# Grid chunk
static func create_chunked(shapes:Array[ShapeWithHoles], size: float, _margin: float = 0) -> ChunkShape:
	if _margin < 0:
		_margin = size/4

	var cs := ChunkShape.new()
	cs.chunk_size = size
	cs.margin = _margin

	## Splits a polygon into chunk-local sub-polygons.
	for swh in shapes:
		cs.add_polygon(swh.solid)
		for hole in swh.holes:
			cs = ChunkShape.clip_polyon(cs, hole) # (chunkshape to update, polygon defining bounding box, update source)

	return cs

# ### ^^^^ Instead of punching out holes, we will get all chunks in the AABB of the hole and update them per the swhs??
# ### SWH Sync updates: consider 100 SWHs, We need to check 100 AABBs...
# ####### Or the worst case scenarios of 100 overlapping AABBs... that's 100 geometry overlap checks
# ### Chunk boolean updates: 1 AABB check (indexed). + directly iterate over affected chunks
















# ### CHUNKS UPDATE API ### #
# All modifications need to update the queue

var to_add = []
var to_update = []
var to_remove = []

func get_chunks(index: Vector2i) -> Array:
	return chunks.get(index, [])

func get_all_chunks() -> Array[Chunk]:
	var all_chunks:Array[Chunk] = []
	for chunk_list in chunks.values():
		all_chunks.append_array(chunk_list)
	return all_chunks

func add_chunk(index: Vector2i, poly:PackedVector2Array) -> Chunk:
	poly = clean_poly(poly, chunk_size)
	if not is_valid_poly(poly):return null

	var chunk := Chunk.new()
	chunk.poly = poly
	chunk.index = index
	_save_chunk(chunk)
	return chunk


func _save_chunk(chunk:Chunk):
	if not chunks.has(chunk.index):
		chunks[chunk.index] = []
	assert(not(chunks[chunk.index].has(chunk)))
	chunks[chunk.index].append(chunk)
	to_add.append(chunk)


func remove_chunk(chunk: Chunk) -> void:
	var index := chunk.index
	assert(chunks.has(index))
	chunks[index].erase(chunk)
	if chunks[index].is_empty():
		chunks.erase(index)
	to_remove.append(chunk) #Remove from to_update and to_add?

func update_chunk(chunk: Chunk, poly:PackedVector2Array) -> Chunk:
	poly = clean_poly(poly, chunk_size)
	if not is_valid_poly(poly):
		#remove_chunk(chunk)
		return null

	chunk.poly = poly
	to_update.append(chunk) #If already in to_add, dont do anything?
	
	return chunk

func clear_index(idx:Vector2i):
	for chunk in get_chunks(idx):
		remove_chunk(chunk)

func duplicate():
	var new_chunkShape = ChunkShape.new()
	new_chunkShape.chunk_size = chunk_size
	new_chunkShape.margin = margin
	new_chunkShape.chunks = chunks.duplicate(true)
	new_chunkShape.to_add = to_add.duplicate(true)
	new_chunkShape.to_remove = to_remove.duplicate(true)
	new_chunkShape.to_update = to_update.duplicate(true)
	return new_chunkShape































static func _chunk_rect_polygon(cx: int, cy: int, size: float, margin:float) -> PackedVector2Array:
	var x := cx * size
	var y := cy * size
	return PackedVector2Array([
		Vector2(x - margin,         y - margin),
		Vector2(x + size + margin,  y - margin),
		Vector2(x + size + margin,  y + size + margin),
		Vector2(x - margin,         y + size + margin),
	])

static func polygon_aabb(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()

	var min_x := poly[0].x
	var min_y := poly[0].y
	var max_x := poly[0].x
	var max_y := poly[0].y

	for p in poly:
		min_x = min(min_x, p.x) 
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))











func add_polygon(points:PackedVector2Array):
	assert(chunk_size > 0)
	var aabb := polygon_aabb(points)
	var min_cx := int(floor(aabb.position.x / chunk_size))
	var min_cy := int(floor(aabb.position.y / chunk_size))
	var max_cx := int(ceil((aabb.position.x + aabb.size.x) / chunk_size))
	var max_cy := int(ceil((aabb.position.y + aabb.size.y) / chunk_size))

	for cx in range(min_cx, max_cx):
		for cy in range(min_cy, max_cy):
			var rect_poly := _chunk_rect_polygon(cx, cy, chunk_size, margin)
			var clipped := Geometry2D.intersect_polygons(points, rect_poly)

			for chunk_points in clipped: #No holes?
				add_chunk(Vector2i(cx, cy), chunk_points)
	# Todo : Return chunks?





static var index_range = 0
static var shape_merges = 0

static func merge_polygon(cs: ChunkShape, points:PackedVector2Array, swhs:Array[ShapeWithHoles]) -> ChunkShape:
	var _len
	var _chunk_size = cs.chunk_size
	assert(_chunk_size > 0)

	var new_cs = cs.duplicate()

	index_range = 0
	shape_merges = 0
	
	var idxs := rasterize_polygon_even_odd(points, _chunk_size)
	for idx in idxs:
		update_idx_from_swhs(new_cs, swhs, idx)





	return new_cs


	for idx in idxs:
		index_range += 1


		var rect_poly := _chunk_rect_polygon(idx.x, idx.y, _chunk_size, cs.margin)
		# Todo: Check if fully contained (chunk rect polygon is full rect), then skip other merges if true. Do same for clip_polygon if clipper fully contains cell rect

		var clipped := Geometry2D.intersect_polygons(points, rect_poly) #incoming geometry clipped to grid cell rect

		if clipped.size() == 0:continue # No incoming geometry in chunk

		# If no other geometry in index, add incoming geometry and continue
		if not cs.chunks.keys().has(idx):
			for chunk_points in clipped:
				new_cs.add_chunk(idx, chunk_points)
			continue


		# Merge N incoming geometry pieces with M existing geometry pieces in chunk !!!!
		# We know all elements N are non overlapping and all elements M as well... some simplifications we can make?
		
		# Alternate idea: Do not clip the incoming geometry to cell rect bounds. That way, we only have N + 1 to merge?
		
		# OR... force update from ShapeWithHoless ( 1 SWH intersection per SWH in object )


		var all_polys = clipped

		for c in cs.get_chunks(idx):
			all_polys.append(c.poly)
			new_cs.remove_chunk(c)


		var current = [all_polys.pop_front()]

		for poly in all_polys:
			var next_frontier: Array[PackedVector2Array] = []

			for c in current:
				
				if next_frontier.size() > 5000:
					assert(false)
				
				_len = current.size()
				if not polygon_aabb(c).intersects(polygon_aabb(poly)):
					next_frontier.append(c)
					next_frontier.append(poly)
					continue
				
				shape_merges += 1
				
				var merged := Geometry2D.merge_polygons(poly, c)

				if merged.size() == 1:
					next_frontier.append(merged[0])

				elif merged.size() == 2:
					# merged contains two polygons: hole and outer, or two disjoint solids
					# (based on your convention: clockwise == hole)
					var a := merged[0]
					var b := merged[1]

					if Geometry2D.is_polygon_clockwise(b):
						# b is hole, a is outer

						next_frontier.append(a) #temp
						continue

						var punched := _subtract_holes_from_solids([a], [b], _chunk_size)
						for p in punched:
							next_frontier.append(p)
					elif Geometry2D.is_polygon_clockwise(a):
						# a is hole, b is outer

						next_frontier.append(b) #temp
						continue

						var punched := _subtract_holes_from_solids([b], [a], _chunk_size)
						for p in punched:
							next_frontier.append(p)
					else:
						# Disjoint
						next_frontier.append(a)
						next_frontier.append(b)

				else:
					# Unexpected, but don't lose polygons:
					# keep everything returned
					for p in merged:
						next_frontier.append(p)

			current = next_frontier


		for poly in current:
			new_cs.add_chunk(idx, poly)

	return new_cs


	# Todo : Return created / updated chunks?



static func update_idx_from_swhs(cs: ChunkShape, swhs:Array[ShapeWithHoles], idx:Vector2i ):
	var mask = _chunk_rect_polygon(idx.x, idx.y, cs.chunk_size, cs.margin)
	var result:Array[PackedVector2Array]
	for swh in swhs:
		for intersected_swh in ShapeWithHoles.intersect_polygon(swh, mask):
			var punched = _subtract_holes_from_solids([intersected_swh.solid], intersected_swh.holes, cs.chunk_size)
			result.append_array(punched)


	# 1. get existing chunks
	var idx_chunks = cs.get_chunks(idx) # Array[Chunk]
	# 2. update existing chunks with new points
	# 3. remove all remaining existing chunks OR
	# 4. add new chunks for all remaining new points

	# Old: clear all chunks then add new chunks
	cs.clear_index(idx)
	for poly in result:
		cs.add_chunk(idx, poly) 

	# TODO: Return updated chunks? For what purpose?


static func clip_polyon(cs: ChunkShape, clipping_poly: PackedVector2Array) -> ChunkShape:
	var new_chunkShape = cs.duplicate()
	var _chunk_size = cs.chunk_size
	if cs.chunk_size < 0:
		var index = Vector2i()
		clip_chunks_at_index(new_chunkShape, clipping_poly, cs.chunk_size, index)
		return new_chunkShape


	var margin = cs.margin

	var idxs := rasterize_polygon_AABB(clipping_poly, _chunk_size)
	
	for idx in idxs:
		clip_chunks_at_index(new_chunkShape, clipping_poly, cs.chunk_size, idx)

	return new_chunkShape








# #### Functions to calculate which grid indices overlap incoming geometry:

# By taking AABB
static func rasterize_polygon_AABB(points:PackedVector2Array, _chunk_size) -> Array[Vector2i]:
	assert(_chunk_size > 0)

	var idxs:Array[Vector2i] = []

	var aabb := polygon_aabb(points)
	var min_cx := int(floor(aabb.position.x / _chunk_size))
	var min_cy := int(floor(aabb.position.y / _chunk_size))
	var max_cx := int(ceil((aabb.position.x + aabb.size.x) / _chunk_size))
	var max_cy := int(ceil((aabb.position.y + aabb.size.y) / _chunk_size))

	for cx in range(min_cx, max_cx):
		for cy in range(min_cy, max_cy):
			idxs.append(Vector2i(cx,cy))

	return idxs

# Even-odd polygon rasterization on an N x N grid of unit cells.
# Input:
#  - poly: PackedVector2Array (closed/simple polygon; last point may or may not repeat first)
#  - N: grid size (cells are [0..N-1] in both x and y)
# Output:
#  - Array[Vector2i] of grid cell indices that intersect polygon interior or edge.
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

































static func clip_chunks_at_index(new_chunkShape:ChunkShape, clipping_poly:PackedVector2Array, _chunk_size:float, index:Vector2i):
	for chunk in new_chunkShape.get_chunks(index).duplicate():
		var clipped := Geometry2D.clip_polygons(chunk.poly, clipping_poly)

		if clipped.is_empty(): # If chunk.poly is fully contained in clipping_poly:
			new_chunkShape.remove_chunk(chunk)
			continue

		var solids:Array[PackedVector2Array] = []
		var holes:Array[PackedVector2Array] = []
		for poly in clipped:
			if Geometry2D.is_polygon_clockwise(poly):
				poly.reverse()
				holes.append(poly)
			else:
				solids.append(poly)

		var max_seam_length
		max_seam_length = 9999999999.0 if _chunk_size < 0 else _chunk_size 
		
		var final_solids := _subtract_holes_from_solids(solids, holes, max_seam_length)

		new_chunkShape.update_chunk(chunk, final_solids[0])
		for i in range(1, final_solids.size()):
			var _new = new_chunkShape.add_chunk(index, final_solids[i])






#Todo: This creates uneccessary seams?
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



static func merge_polys(polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var overlaps = get_possible_overlaps(polys)
	
	var merged = {}
	
	var islands = {} # { index, island array: [PackedVector2] Holes????? }
	
	for i in overlaps.keys():
		for j in overlaps[i]:
			var id = str(min(i,j)) + ',' + str(max(i,j))
			if merged.has(id):continue
			merged[id] = true

			if islands.has(i):
				islands[i]


	return polys
	
	
	
# Alternate:
	# Get grid squares overlapping incoming geometry
	# Update each grid square to its multishape
	


static func get_possible_overlaps(polys: Array[PackedVector2Array]) -> Dictionary:
	var result := {}
	for i in range(polys.size()):
		result[i] = []

	var rects: Array[Rect2] = []
	rects.resize(polys.size())

	for i in range(polys.size()):
		rects[i] = polygon_aabb(polys[i])

	var events: Array[Dictionary] = []
	events.resize(0)

	for i in range(rects.size()):
		var r := rects[i]
		events.append({ "x": r.position.x,          "t": 1,  "i": i }) # enter
		events.append({ "x": r.position.x + r.size.x, "t": -1, "i": i }) # leave

	events.sort_custom(func(a, b):
		if a["x"] == b["x"]:
			# leave (-1) before enter (+1)
			return a["t"] < b["t"]
		return a["x"] < b["x"]
	)

	var active: Array[int] = []

	for e in events:
		var idx: int = e["i"]
		var t: int = e["t"]

		if t == 1:
			# entering: check AABB intersection with everything currently active
			for a in active:
				if rects[a].intersects(rects[idx]):
					result[a].append(idx)
					result[idx].append(a)
			active.append(idx)
		else:
			# leaving
			active_remove(active, idx)

	return result



static func active_remove(active: Array[int], idx: int) -> void:
	for k in range(active.size()):
		if active[k] == idx:
			active.remove_at(k)
			return

























# ######################## CLEANING ######################### #





static func clean_poly(poly:PackedVector2Array, chunk_size:float) -> PackedVector2Array:
	#return poly
	#poly = snap_poly(poly)
	poly = clean_small_edges(poly)
	poly = snap_to_chunk_boundaries(poly, chunk_size)
	#poly = remove_duplicate_points(poly)
	#poly = remove_collinear_points(poly)
	#poly = remove_near_edge_points(poly, 1.)
	poly = ensure_ccw(poly)
	#assert(is_valid_poly(poly))
	return poly
	

static func clean_small_edges(poly:PackedVector2Array) -> PackedVector2Array:
	var cutoff = 50
	var distance = 10.
	if poly.size() < cutoff: return poly

	var new_poly:=PackedVector2Array([poly[0]])
	var curr_p := poly[0]

	var first_point = true #Iterate points starting at second point
	for p in poly:
		if first_point:
			first_point =  false
			continue

		if curr_p.distance_to(p) < distance:
			continue

		curr_p = p
		new_poly.append(curr_p)
		
	return new_poly






static func snap_to_chunk_boundaries(
	poly: PackedVector2Array,
	chunk_size: float,
	eps := 0.5
) -> PackedVector2Array:
	if chunk_size <= 0.0:
		return poly

	var out := PackedVector2Array()
	for p in poly:
		var x := p.x
		var y := p.y

		var gx = round(x / chunk_size) * chunk_size
		var gy = round(y / chunk_size) * chunk_size

		# Only snap if we're already close to a boundary
		if abs(x - gx) < eps:
			x = gx
		if abs(y - gy) < eps:
			y = gy

		out.append(Vector2(x, y))
	return out





static func ensure_ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(poly):
		var p := poly.duplicate()
		p.reverse()
		return p
	return poly


static func is_valid_poly(poly: PackedVector2Array) -> bool:
	return true
	'''
	#if has_bad_triangles(poly):
	#	return false
	var area = GeometryData._calc_area(poly)
	if (area <= 0.):
		return false

	if poly.size() < 3:
		return false
	for p in poly:
		if not p.is_finite():
			return false
	return true

	'''




static func snap_poly(poly:PackedVector2Array) -> PackedVector2Array:
	var new_poly:=PackedVector2Array([])
	for p in poly:
		var s = 10.
		var new_p = s*Vector2(round(p.x/s), round(p.y/s)) 
		new_poly.append(new_p)

	return new_poly


static func remove_duplicate_points(poly: PackedVector2Array, eps := 0.01) -> PackedVector2Array:
	if poly.size() <= 1:
		return poly
	var out := PackedVector2Array()
	for p in poly:
		if out.is_empty() or out[-1].distance_to(p) > eps:
			out.append(p)
	# close loop duplicate
	if out.size() > 1 and out[0].distance_to(out[-1]) < eps:
		out.remove_at(out.size() - 1)
	return out


static func remove_collinear_points(poly: PackedVector2Array, eps := 10.) -> PackedVector2Array:
	if poly.size() <= 3:
		return poly
	var out := PackedVector2Array()
	for i in range(poly.size()):
		var a = poly[(i - 1 + poly.size()) % poly.size()]
		var b = poly[i]
		var c = poly[(i + 1) % poly.size()]
		var cross = (b - a).cross(c - b)
		if abs(cross) > eps:
			out.append(b)
	return out


static func remove_tiny_edges(poly: PackedVector2Array, min_len := 0.5) -> PackedVector2Array:
	if poly.size() <= 3:
		return poly
	var out := PackedVector2Array()
	for i in range(poly.size()):
		var a = poly[i]
		var b = poly[(i + 1) % poly.size()]
		if a.distance_to(b) > min_len:
			out.append(a)
	return out


static func remove_near_edge_points(poly: PackedVector2Array, eps := 0.01) -> PackedVector2Array:
	var n := poly.size()
	if n < 3:
		return poly
	
	# track indices we want to keep
	var keep_indices := []
	var eps_sq := eps * eps

	for i in range(n):
		var p := poly[i]
		var is_on_edge := false

		# Test against all non-adjacent edges of the ORIGINAL polygon
		for j in range(n):
			# Skip adjacent edges: (j, j+1) is adjacent to point i if j == i or j+1 == i
			var next_j = (j + 1) % n
			if i == j or i == next_j:
				continue

			var a := poly[j]
			var b := poly[next_j]

			# distance from p to segment ab (using squared length for performance)
			var ab := b - a
			var l2 := ab.length_squared()
			
			# If the edge is a single point, just check distance to that point
			if l2 == 0.0:
				if p.distance_squared_to(a) < eps_sq:
					is_on_edge = true
					break
				continue

			var t = clamp((p - a).dot(ab) / l2, 0.0, 1.0)
			var proj = a + ab * t
			
			if p.distance_squared_to(proj) < eps_sq:
				is_on_edge = true
				break
		
		if not is_on_edge:
			keep_indices.append(i)

	# Build the new array from the marked indices
	var out := PackedVector2Array()
	for idx in keep_indices:
		out.append(poly[idx])
		
	return out



static func has_bad_triangles(
	poly: PackedVector2Array,
	min_area := .01
	
	,
	min_angle_deg := 2.
) -> bool:
	# Step 1: convex decomposition (matches physics engine)
	var convexes := Geometry2D.decompose_polygon_in_convex(poly)

	for convex in convexes:
		# Step 2: triangulate convex piece
		var indices := Geometry2D.triangulate_polygon(convex)
		if indices.size() % 3 != 0:
			return true  # triangulation failed → invalid polygon

		# Step 3: evaluate each triangle
		for i in range(0, indices.size(), 3):
			var a := convex[indices[i]]
			var b := convex[indices[i+1]]
			var c := convex[indices[i+2]]

			# --- Area check ---
			var area = abs((b - a).cross(c - a)) * 0.5
			if area < min_area:
				return true
			continue

			# --- Angle check ---
			var ab := b - a
			var bc := c - b
			var ca := a - c

			var angle_a = acos(clamp(ab.normalized().dot(-ca.normalized()), -1, 1))
			var angle_b = acos(clamp(bc.normalized().dot(-ab.normalized()), -1, 1))
			var angle_c = PI - angle_a - angle_b

			if min(angle_a, angle_b) < deg_to_rad(min_angle_deg):
				if min(angle_b, angle_c) < deg_to_rad(min_angle_deg):
					if min(angle_a, angle_c) < deg_to_rad(min_angle_deg):
						return true

	return false








func draw(ci:CanvasItem):
	for chunk in get_all_chunks():
		var xform := Transform2D(0.,Vector2(randf(),randf()) * 3)
		var col = Color.from_hsv(randf(),1,1)
		ci.draw_polyline(xform*PolyFuncs.close_poly(chunk.poly), col)
