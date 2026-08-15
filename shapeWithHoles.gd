class_name ShapeWithHoles

var solid:PackedVector2Array
var holes:Array[PackedVector2Array]:get = _get_holes #Do not append directly to holes
var holeRefs:Array[HoleRef] = [] #Holes are packed in holeRef so they can be referenced and mapped data to



func _init(_solid:PackedVector2Array, _holes:Array[PackedVector2Array] = []):
	solid = _solid
	for h in _holes:
		add_hole(h)



# A hack to allow easy object-reference to individual holes
class HoleRef:
	var points:PackedVector2Array
	func serialize():
		var dict = {"points":points}
		return dict
	static func deserialize(dict)->HoleRef:
		var h = HoleRef.new()
		h.points = dict["points"]
		return h

func add_hole(hole: PackedVector2Array):
	var ref = HoleRef.new()
	ref.points = hole
	holeRefs.append(ref)

func _get_holes():
	var array:Array[PackedVector2Array] = []
	for ref in holeRefs:
		array.append(ref.points)
	return array



static func merge_polygon(swh:ShapeWithHoles, merger:PackedVector2Array) -> Array[ShapeWithHoles]:
	var result:Array[ShapeWithHoles]
	var merged := merge_simple_polygons(swh.solid, merger)
	
	if merged.size() == 2:
		result = [swh, ShapeWithHoles.new(merger)]
		return result
	
	result = merged

	for hole in swh.holes:
		var hole_merge_results := clip_simple_polygon(hole, merger)
		# Cases:
		# Hole removed: s=0, h=0
		# Hole unaffected or affected simply: s=1, h=0
		# Hole split in n pieces s=n, h=0
		# Created Island inside hole: s=1, h=1

		var num_solids = hole_merge_results.size()
		var num_holes = hole_merge_results.reduce(func(a,s):return a+s.holes.size(), 0)

		if num_solids == 0 and num_holes == 0:
			continue
		elif num_solids >= 1 and num_holes == 0:
			for new_hole in hole_merge_results:
				result[0].add_hole(new_hole.solid)
		elif num_solids == 1 and num_holes == 1:
				result.append(ShapeWithHoles.new(hole_merge_results[0].holes[0]))
		else: assert(false)

	return result


# Clips a polygon from a ShapeWithHoles

static func clip_polygon(ms:ShapeWithHoles, cutter:PackedVector2Array) -> Array[ShapeWithHoles]:
	
	# TODO: Check AABB
	
	# ## Classify holes as overlapping_cutter vs. unaffected. Inherit all unaffected holes.

	var non_overlapping_holes:Array[PackedVector2Array] = []
	var new_solids:Array[ShapeWithHoles] = []
	var new_cutter:PackedVector2Array = cutter

	for hole in ms.holes:
		var merged = merge_simple_polygons(new_cutter, hole)
		if merged.size() == 2: #No overlap between hole and cutter
			non_overlapping_holes.append(hole)
			continue
		merged = merged[0] as ShapeWithHoles #Overlap between hole and cutter, merges into single hole maybe with solids inside
		new_cutter = merged.solid
		for internal_solid in merged.holes: #A hole in the cutter is a solid
			new_solids.append(ShapeWithHoles.new(internal_solid))

	# ## Clip the solid with the new cutter
	var clipped = clip_simple_polygon(ms.solid, new_cutter)
	new_solids.append_array(clipped)

	#All non-overlapping holes must be assigned to one of the new_solids
	for new_hole in non_overlapping_holes:
		for new_solid in new_solids:
			if contains(new_solid.solid, new_hole):
				new_solid.add_hole(new_hole)
				break

	return new_solids







static func intersect_polygon(swh:ShapeWithHoles, mask:PackedVector2Array) -> Array[ShapeWithHoles]:

	var inherited_holes = []
	var current_mask = [mask]

	for hole in swh.holes: #Cut each hole from the mask
		var frontier = []
		for c_mask in current_mask:
			var clipped := Geometry2D.clip_polygons(c_mask, hole)
			if clipped.size() == 0: #Clipped away, no shape left
				continue

			for c in clipped:
				if is_hole(c):
					inherited_holes.append(hole)
					continue
				frontier.append(c)
		current_mask = frontier

	var new_swhs:Array[ShapeWithHoles] = []

	for c in current_mask:
		var solid_intersection := Geometry2D.intersect_polygons(swh.solid, c)
		for s in solid_intersection:
			assert(not is_hole(s))
			if PolyFuncs._calc_area(s) < .0001:continue
			new_swhs.append( ShapeWithHoles.new(s) )

			#All non-overlapping holes must be assigned to one of the new_solids
			for new_hole in inherited_holes:
				if contains(new_swhs[-1].solid, new_hole):
					new_swhs[-1].add_hole(new_hole)
			
			for h in new_swhs[-1].holes:
				inherited_holes.erase(h)


	# Cases:
	# Mask fully overlaps hole -> Keep hole
	# Mask partially overlaps hole -> Clip hole from mask pre-intersection (Can make more than 1 mask!?) or result (NxM?)
	# Mask does not overlap hole -> Discard hole

	return new_swhs








# Clips a polygon from a list of ShapeWithHoless
static func clip_polygon_from_multiple(SWHs:Array[ShapeWithHoles], cutter:PackedVector2Array) -> Array[ShapeWithHoles]:
	var new_SWHs:Array[ShapeWithHoles] = []
	for ms in SWHs:
		var cut_SWHs = clip_polygon(ms, cutter)
		new_SWHs.append_array(cut_SWHs)
	return new_SWHs





















# GENERATORS from PackedVector2Array boolean operation

static func merge_simple_polygons(points:PackedVector2Array, merge_points:PackedVector2Array) -> Array[ShapeWithHoles]:
		var merge_raw = Geometry2D.merge_polygons(points, merge_points)
		#expected 2 solids + 0 holes, or 1 solid + n>=0 holes
		var holes:Array[PackedVector2Array]= []
		var solids = []
		for poly in merge_raw:
			if is_hole(poly):
				poly.reverse()
				holes.append(poly)
			else:
				solids.append(poly)

		assert((solids.size() == 2 and holes.size() == 0) or (solids.size() == 1))

		var result:Array[ShapeWithHoles]
		for s in solids:
			result.append(ShapeWithHoles.new(s, holes))

		assert(result.size() == 1 or result.size() == 2)
		return result


static func clip_simple_polygon(points:PackedVector2Array, clipper_points:PackedVector2Array) -> Array[ShapeWithHoles]:
		var clip_raw = Geometry2D.clip_polygons(points, clipper_points)
		#Expected 1 solid + 1 hole, or 0 holes and >=1 solids, OR 0 solids + 0 holes (clipped away)
		var holes:Array[PackedVector2Array] = []
		var solids = []
		for poly in clip_raw:
			if is_hole(poly):
				poly.reverse()
				holes.append(poly)
			else:
				solids.append(poly)

		assert((solids.size() == 0 and holes.size() == 0) or (solids.size() == 1 and holes.size() == 1) or (holes.size() == 0 and solids.size() >= 1))

		var result:Array[ShapeWithHoles]
		for s in solids:
			result.append(ShapeWithHoles.new(s, holes))

		return result

# CLIP RESULTS
# s=0 & h=0 : clipped away
# s=1 & h=1 : created hole
# s>=1 & h = 0 : split solid










# PackedVector2Array Utilities

static func contains(outer:PackedVector2Array, inner:PackedVector2Array) -> bool:
	return Geometry2D.is_point_in_polygon(inner[0], outer)

static func is_hole(poly:PackedVector2Array) -> bool:
	return Geometry2D.is_polygon_clockwise(poly)






func draw(ci:CanvasItem):
	ci.draw_polyline(PolyFuncs.close_poly(solid), Color.YELLOW, 3)
	for h in holes:
		ci.draw_polyline(PolyFuncs.close_poly(h), Color.GREEN, 2)




# Serialization

func serialize():
	var dict = {"solid":solid,"holes":holes}
	return dict

static func deserialize(dict:Dictionary)->ShapeWithHoles:
	return ShapeWithHoles.new(dict["solid"], dict["holes"])
